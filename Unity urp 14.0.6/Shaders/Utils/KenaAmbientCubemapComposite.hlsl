

// @param MipCount e.g. 10 for x 512x512
half ComputeCubemapMipFromRoughness(half Roughness, half MipCount)
{
	// Level starting from 1x1 mip
	half Level = 3 - 1.15 * log2(Roughness);
	return MipCount - 1 - Level;
}

//float4 _ScreenParam;

half4 FragKenaAmbientCube(Varyings IN) : SV_Target
{
	float4 test = float4(0,0,0,1);

	float2 BufferUV = SvPositionToBufferUV(IN.positionCS); 

	float2 ScreenSpacePos = SvPositionToScreenPosition(IN.positionCS).xy;
	int2 PixelPos = int2(IN.positionCS.xy);

	FGBufferData GBuffer = GetGBufferDataFromSceneTextures(BufferUV);

	float AbsoluteDiffuseMip = AmbientCubemapMipAdjust.z;

	float3 ScreenVector = normalize(mul(Matrix_Inv_VP, float4(ScreenSpacePos, 1, 0)));

	float3 N = GBuffer.WorldNormal;
	float3 V = -ScreenVector;
	float3 R0 = 2 * dot(V, N) * N - V; //Reflection Dir
	float NoV = saturate(dot(N, V));

	float a = Pow2(GBuffer.Roughness);
	float3 R = lerp(N, R0, (1 - a) * (sqrt(1 - a) + a));  //Blurred Reflection Dir based on roughness

	uint2 Random = Rand3DPCG16(uint3(PixelPos, View_StateFrameIndexMod8)).xy;

	float3 NonSpecularContribution = 0;
	float3 SpecularContribution = 0;

	float3 DiffuseLookup = SAMPLE_TEXTURECUBE_LOD(_Ambientmap, sampler_Ambientmap, N, AbsoluteDiffuseMip).rgb;
	NonSpecularContribution += GBuffer.DiffuseColor * DiffuseLookup;


	UNITY_BRANCH
	if (GBuffer.ShadingModelID == SHADINGMODELID_CLEAR_COAT)
	{
		const float ClearCoat = GBuffer.CustomData.x;

		float Mip = ComputeCubemapMipFromRoughness(GBuffer.Roughness, AmbientCubemapMipAdjust.w);
		float3 SampleColor = SAMPLE_TEXTURECUBE_LOD(_Ambientmap, sampler_Ambientmap, R, Mip).rgb;
		float2 AB = SAMPLE_TEXTURE2D(_LUT2, sampler_LUT2, float2(NoV, GBuffer.Roughness)).rg; //PreIntegratedGF
		SpecularContribution += SampleColor * (GBuffer.SpecularColor * AB.x + AB.y * (1 - ClearCoat));

		const float ClearCoatRoughness = GBuffer.CustomData.y;
		Mip = ComputeCubemapMipFromRoughness(ClearCoatRoughness, AmbientCubemapMipAdjust.w);
		SampleColor = SAMPLE_TEXTURECUBE_LOD(_Ambientmap, sampler_Ambientmap, R0, Mip).rgb;

		// F_Schlick
		float F0 = 0.04;
		float Fc = Pow5(1 - NoV);
		float F = Fc + (1 - Fc) * F0;
		F *= ClearCoat;

		float LayerAttenuation = (1 - F);

		NonSpecularContribution *= LayerAttenuation;
		SpecularContribution *= LayerAttenuation;
		SpecularContribution += SampleColor * F;
	}
	else
	{
		float Mip = ComputeCubemapMipFromRoughness(GBuffer.Roughness, AmbientCubemapMipAdjust.w);
		float3 SampleColor = SAMPLE_TEXTURECUBE_LOD(_Ambientmap, sampler_Ambientmap, R, Mip).rgb;
		SpecularContribution += SampleColor * EnvBRDF(GBuffer.SpecularColor, GBuffer.Roughness, NoV);
	}

	UNITY_BRANCH
	if (GBuffer.ShadingModelID == SHADINGMODELID_HAIR)
	{
		FHairTransmittanceData HairTransmittance = InitHairTransmittanceData();
		float3 FakeNormal = normalize(V - N * dot(V, N));
		FakeNormal = normalize(FakeNormal);
		SpecularContribution = SAMPLE_TEXTURECUBE_LOD(_Ambientmap, sampler_Ambientmap, FakeNormal, AbsoluteDiffuseMip).rgb;
		bool bEvalMultiScatter = true;
		SpecularContribution *= PI * HairShading(GBuffer, FakeNormal, V, N, 1, HairTransmittance, 0, 0.2, Random, bEvalMultiScatter);
		NonSpecularContribution = 0;
	}

	// apply darkening from ambient occlusion (does not use PostprocessInput1 to set white texture if SSAO is off)
	float AmbientOcclusion = GBuffer.GBufferAO * SAMPLE_TEXTURE2D(_SSAO, sampler_SSAO, BufferUV).r;

	UNITY_BRANCH 
	if (GBuffer.ShadingModelID == SHADINGMODELID_SUBSURFACE || GBuffer.ShadingModelID == SHADINGMODELID_PREINTEGRATED_SKIN)
	{
		// some view dependent and some non view dependent (hard coded)
		float DependentSplit = 0.5f;
		float3 SubsurfaceColor = ExtractSubsurfaceColor(GBuffer);
		// view independent (shared lookup for diffuse for better performance
		NonSpecularContribution += DiffuseLookup * SubsurfaceColor * (DependentSplit);
		// view dependent (blurriness is hard coded)
		SpecularContribution += SAMPLE_TEXTURECUBE_LOD(_Ambientmap, sampler_Ambientmap, ScreenVector, AbsoluteDiffuseMip - 2.5f).rgb * SubsurfaceColor * (AmbientOcclusion * (1.0f - DependentSplit));
	}

	const bool bNeedsSeparateSubsurfaceLightAccumulation = UseSubsurfaceProfile(GBuffer.ShadingModelID);

	float4 finalCol = (float4)0;

	finalCol.rgb = (NonSpecularContribution + SpecularContribution) * AmbientCubemapColor.rgb;

	UNITY_BRANCH
	if (bCheckerboardSubsurfaceProfileRendering == 0 && bNeedsSeparateSubsurfaceLightAccumulation)
	{
		finalCol.a = LuminanceUE(NonSpecularContribution * AmbientCubemapColor.rgb);
	}

	finalCol *= AmbientOcclusion;

	return finalCol;
}
