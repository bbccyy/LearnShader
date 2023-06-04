
#include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/KenaDefineCommon.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/KenaRenderingParams.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/KenaRenderingUtil.hlsl"

//------------------Define Struct Start------------------
struct FHairTransmittanceData
{
	// Average front/back scattering for a given L, V, T (tangent)
	float3 Transmittance;
	float3 A_front;
	float3 A_back;

	float OpaqueVisibility;
	float HairCount;

	// TEMP: for fastning iteration times
	float3 LocalScattering;
	float3 GlobalScattering;

	uint ScatteringComponent;
};
//------------------Define Struct End------------------


//------------------Declare Buffer Start------------------  TODO 
// TEXTURE2D_X_FLOAT(_Depth); SAMPLER(sampler_Depth);
// TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
// TEXTURE2D(_Comp_M_D_R_F); SAMPLER(sampler_Comp_M_D_R_F);
// TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
// TEXTURE2D(_Comp_F_R_X_I); SAMPLER(sampler_Comp_F_R_X_I); 

TEXTURE2D(_LUT2); SAMPLER(sampler_LUT2); //PreIntegratedGF
TEXTURE2D(_SSAO); SAMPLER(sampler_SSAO);
TEXTURECUBE(_IBL); SAMPLER(sampler_IBL);
TEXTURECUBE(_Sky); SAMPLER(sampler_Sky);
TEXTURECUBE(_Ambientmap); SAMPLER(sampler_Ambientmap);
//------------------Declare Buffer End------------------


//------------------HairShading Start------------------
#if 1
FHairTransmittanceData InitHairTransmittanceData()
{
	FHairTransmittanceData o;
	o.Transmittance = 1;
	o.A_front = 1;
	o.A_back = 1;
	o.OpaqueVisibility = 1;
	o.HairCount = 0;

	// TEMP: for fastning iteration times
	o.LocalScattering = 0;
	o.GlobalScattering = 1;
	o.ScatteringComponent = HAIR_COMPONENT_R | HAIR_COMPONENT_TT | HAIR_COMPONENT_TRT;

	return o;
}


float Hair_g(float B, float Theta)
{
	return exp(-0.5 * Pow2(Theta) / (B * B)) / (sqrt(2 * PI) * B);
}

float Hair_F(float CosTheta)
{
	const float n = 1.55;
	const float F0 = Pow2((1 - n) / (1 + n));
	return F0 + (1 - F0) * Pow5(1 - CosTheta);
}

float3 KajiyaKayDiffuseAttenuation(FGBufferData GBuffer, float3 L, float3 Vp, half3 N, float Shadow)
{
	// Use soft Kajiya Kay diffuse attenuation
	float KajiyaDiffuse = 1 - abs(dot(N, L));

	float3 FakeNormal = normalize(Vp);

	N = FakeNormal;

	// Hack approximation for multiple scattering.
	float Wrap = 1;
	float NoL = saturate((dot(N, L) + Wrap) / Pow2(1 + Wrap));
	float DiffuseScatter = (1 / PI) * lerp(NoL, KajiyaDiffuse, 0.33) * GBuffer.Metallic;
	float Luma = LuminanceUE(GBuffer.BaseColor);
	float3 ScatterTint = pow(GBuffer.BaseColor / Luma, 1 - Shadow);
	return sqrt(GBuffer.BaseColor) * DiffuseScatter * ScatterTint;
}

float3 HairShading(FGBufferData GBuffer, float3 L, float3 V, half3 N, float Shadow, FHairTransmittanceData HairTransmittance, float Backlit, float Area, uint2 Random, bool bEvalMultiScatter)
{
	float ClampedRoughness = clamp(GBuffer.Roughness, 1 / 255.0f, 1.0f);

	const float VoL = dot(V, L);
	const float SinThetaL = dot(N, L);
	const float SinThetaV = dot(N, V);
	float CosThetaD = cos(0.5 * abs(asinFast(SinThetaV) - asinFast(SinThetaL)));

	const float3 Lp = L - SinThetaL * N;
	const float3 Vp = V - SinThetaV * N;
	const float CosPhi = dot(Lp, Vp) * rsqrt(dot(Lp, Lp) * dot(Vp, Vp) + 1e-4);
	const float CosHalfPhi = sqrt(saturate(0.5 + 0.5 * CosPhi));

	float n = 1.55;

	float n_prime = 1.19 / CosThetaD + 0.36 * CosThetaD;

	float Shift = 0.035;
	float Alpha[] =
	{
		-Shift * 2,
		Shift,
		Shift * 4,
	};
	float B[] =
	{
		Area + Pow2(ClampedRoughness),
		Area + Pow2(ClampedRoughness) / 2,
		Area + Pow2(ClampedRoughness) * 2,
	};

	float3 S = 0;

	//R
	{
		const float sa = sin(Alpha[0]);
		const float ca = cos(Alpha[0]);
		float Shift = 2 * sa * (ca * CosHalfPhi * sqrt(1 - SinThetaV * SinThetaV) + sa * SinThetaV);

		float Mp = Hair_g(B[0] * sqrt(2.0) * CosHalfPhi, SinThetaL + SinThetaV - Shift);
		float Np = 0.25 * CosHalfPhi;
		float Fp = Hair_F(sqrt(saturate(0.5 + 0.5 * VoL)));
		S += Mp * Np * Fp * (GBuffer.Specular * 2) * lerp(1, Backlit, saturate(-VoL));
	}

	// TT
	{
		float Mp = Hair_g(B[1], SinThetaL + SinThetaV - Alpha[1]);

		float a = 1 / n_prime;

		float h = CosHalfPhi * (1 + a * (0.6 - 0.8 * CosPhi));

		float f = Hair_F(CosThetaD * sqrt(saturate(1 - h * h)));
		float Fp = Pow2(1 - f);

		float3 Tp = pow(GBuffer.BaseColor, 0.5 * sqrt(1 - Pow2(h * a)) / CosThetaD);

		float Np = exp(-3.65 * CosPhi - 3.98);

		S += Mp * Np * Fp * Tp * Backlit;
	}

	// TRT
	{
		float Mp = Hair_g(B[2], SinThetaL + SinThetaV - Alpha[2]);

		float f = Hair_F(CosThetaD * 0.5);
		float Fp = Pow2(1 - f) * f;

		float3 Tp = pow(GBuffer.BaseColor, 0.8 / CosThetaD);

		float Np = exp(17 * CosPhi - 16.78);

		S += Mp * Np * Fp * Tp;
	}

	S += KajiyaKayDiffuseAttenuation(GBuffer, L, Vp, N, Shadow);

	S = -min(-S, 0.0);

	return S;
}
#endif
//------------------HairShading End------------------



//------------------Reflection Share Start------------------
#if 1
#define REFLECTION_CAPTURE_ROUGHEST_MIP 1
#define REFLECTION_CAPTURE_ROUGHNESS_MIP_SCALE 1.2

half ComputeReflectionCaptureMipFromRoughness(half Roughness, half CubemapMaxMip)
{
	// Heuristic that maps roughness to mip level
	// This is done in a way such that a certain mip level will always have the same roughness, regardless of how many mips are in the texture
	// Using more mips in the cubemap just allows sharper reflections to be supported
	half LevelFrom1x1 = REFLECTION_CAPTURE_ROUGHEST_MIP - REFLECTION_CAPTURE_ROUGHNESS_MIP_SCALE * log2(Roughness);
	return CubemapMaxMip - 1 - LevelFrom1x1;
}

float3 GetSkyLightReflection(float3 ReflectionVector, float Roughness)
{
	float AbsoluteSpecularMip = ComputeReflectionCaptureMipFromRoughness(Roughness, ReflectionStruct_SkyLightParameters.x);
	//float3 Reflection = TextureCubeSampleLevel(ReflectionStruct.SkyLightCubemap, ReflectionStruct.SkyLightCubemapSampler, ReflectionVector, AbsoluteSpecularMip).rgb;
	half3 Reflection = SAMPLE_TEXTURECUBE_LOD(_Sky, sampler_Sky, ReflectionVector, AbsoluteSpecularMip).rgb;

	return Reflection * View_SkyLightColor.rgb;
}

float3 GetSkyLightReflectionSupportingBlend(float3 ReflectionVector, float Roughness)
{
	float3 Reflection = GetSkyLightReflection(ReflectionVector, Roughness);

	UNITY_BRANCH
	if (ReflectionStruct_SkyLightParameters.w > 0)
	{
		float AbsoluteSpecularMip = ComputeReflectionCaptureMipFromRoughness(Roughness, ReflectionStruct_SkyLightParameters.x);
		//float3 BlendDestinationReflection = SAMPLE_TEXTURECUBE_LOD(_SkyLightBlend, sampler_SkyLightBlend, ReflectionVector, AbsoluteSpecularMip).rgb;
		float3 BlendDestinationReflection = float3(0,0,0); 
		Reflection = lerp(Reflection, BlendDestinationReflection * View_SkyLightColor.rgb, ReflectionStruct_SkyLightParameters.w);
	}

	return Reflection;
}

float3 GetLookupVectorForSphereCapture(float3 ReflectionVector, float3 WorldPosition,
	float4 SphereCapturePositionAndRadius, float NormalizedDistanceToCapture,
	float3 LocalCaptureOffset, inout float DistanceAlpha)
{
	float3 ProjectedCaptureVector = ReflectionVector;
	float ProjectionSphereRadius = SphereCapturePositionAndRadius.w;
	float SphereRadiusSquared = ProjectionSphereRadius * ProjectionSphereRadius;

	float3 LocalPosition = WorldPosition - SphereCapturePositionAndRadius.xyz;
	float LocalPositionSqr = dot(LocalPosition, LocalPosition);

	// Find the intersection between the ray along the reflection vector and the capture's sphere
	float3 QuadraticCoef = 0;
	QuadraticCoef.x = 1;
	QuadraticCoef.y = dot(ReflectionVector, LocalPosition);
	QuadraticCoef.z = LocalPositionSqr - SphereRadiusSquared;

	float Determinant = QuadraticCoef.y * QuadraticCoef.y - QuadraticCoef.z;

	// Only continue if the ray intersects the sphere
	UNITY_FLATTEN
	if (Determinant >= 0)
	{
		float FarIntersection = sqrt(Determinant) - QuadraticCoef.y;

		float3 LocalIntersectionPosition = LocalPosition + FarIntersection * ReflectionVector;
		ProjectedCaptureVector = LocalIntersectionPosition - LocalCaptureOffset;
		// Note: some compilers don't handle smoothstep min > max (this was 1, .6)
		//DistanceAlpha = 1.0 - smoothstep(.6, 1, NormalizedDistanceToCapture);

		float x = saturate(2.5 * NormalizedDistanceToCapture - 1.5);
		DistanceAlpha = 1 - x * x * (3 - 2 * x);
	}
	return ProjectedCaptureVector;
}

#endif
//------------------Reflection Share End------------------


//------------------BRDF Common Start------------------
#if 1
half3 EnvBRDF(half3 SpecularColor, half Roughness, half NoV)
{
	// Importance sampled preintegrated G * F
	//float2 AB = Texture2DSampleLevel(PreIntegratedGF, PreIntegratedGFSampler, float2(NoV, Roughness), 0).rg;
	float2 AB = SAMPLE_TEXTURE2D(_LUT2, sampler_LUT2, float2(NoV, Roughness)).rg; //todo: 确认y轴上下是否对调 -> 1 - Roughness 
	// Anything less than 2% is physically impossible and is instead considered to be shadowing 
	float3 GF = SpecularColor * AB.x + saturate(50.0 * SpecularColor.g) * AB.y;
	return GF;
}
#endif
//------------------BRDF Common End------------------