
TEXTURE2D(_SSAO); SAMPLER(sampler_SSAO);
TEXTURE2D(_ShadowTex); SAMPLER(sampler_ShadowTex);
TEXTURE2D(_LUT); SAMPLER(sampler_LUT);

struct FShadowTerms
{
    float	SurfaceShadow;
    float	TransmissionShadow;
    float	TransmissionThickness;
    FHairTransmittanceData HairTransmittance;
};

struct FCapsuleLight
{
    float3	LightPos[2];
    float	Length;
    float	Radius;
    float	SoftRadius;
    float	DistBiasSqr;
};

struct FDeferredLightingSplit
{
    float4 DiffuseLighting;
    float4 SpecularLighting;
};

struct FDirectLighting
{
    float3	Diffuse;
    float3	Specular;
    float3	Transmission;
};

struct FRectTexture
{
    uint Dummy;
};

struct FAreaLight
{
    float		SphereSinAlpha;
    float		SphereSinAlphaSoft;
    float		LineCosSubtended;
    float3		FalloffColor;
    //FRect		Rect;
    //FRectTexture Texture;
    bool		bIsRect;
};

struct BxDFContext
{
    float NoV;
    float NoL;
    float VoL;
    float NoH;
    float VoH;
    float XoH;
    float YoH;
};


FCapsuleLight GetCapsule(float3 ToLight, FDeferredLightData LightData)
{
    FCapsuleLight Capsule;
    Capsule.Length = LightData.SourceLength;
    Capsule.Radius = LightData.SourceRadius;
    Capsule.SoftRadius = LightData.SoftSourceRadius;
    Capsule.DistBiasSqr = 1;
    Capsule.LightPos[0] = ToLight - 0.5 * Capsule.Length * LightData.Tangent;
    Capsule.LightPos[1] = ToLight + 0.5 * Capsule.Length * LightData.Tangent;
    return Capsule;
}

float3 Diffuse_Lambert(float3 DiffuseColor)
{
    return DiffuseColor * (1 / PI);
}

// [Burley 2012, "Physically-Based Shading at Disney"]
float3 Diffuse_Burley(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
    float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
    float FdV = 1 + (FD90 - 1) * Pow5(1 - NoV);
    float FdL = 1 + (FD90 - 1) * Pow5(1 - NoL);
    return DiffuseColor * ((1 / PI) * FdV * FdL);
}

float D_InvGGX(float a2, float NoH)
{
    float A = 4;
    float d = (NoH - a2 * NoH) * NoH + a2;
    return rcp(PI * (1 + A * a2)) * (1 + 4 * a2 * a2 / (d * d));
}

float Vis_Cloth(float NoV, float NoL)
{
    return rcp(4 * (NoL + NoV - NoL * NoV));
}

float New_a2(float a2, float SinAlpha, float VoH)
{
    return a2 + 0.25 * SinAlpha * (3.0 * sqrtFast(a2) + SinAlpha) / (VoH + 0.001);
    //return a2 + 0.25 * SinAlpha * ( saturate(12 * a2 + 0.125) + SinAlpha ) / ( VoH + 0.001 );
    //return a2 + 0.25 * SinAlpha * ( a2 * 2 + 1 + SinAlpha ) / ( VoH + 0.001 );
}

float EnergyNormalization(inout float a2, float VoH, FAreaLight AreaLight)
{
    if (AreaLight.SphereSinAlphaSoft > 0)
    {
        // Modify Roughness
        a2 = saturate(a2 + Pow2(AreaLight.SphereSinAlphaSoft) / (VoH * 3.6 + 0.4));
    }

    float Sphere_a2 = a2;
    float Energy = 1;
    if (AreaLight.SphereSinAlpha > 0)
    {
        Sphere_a2 = New_a2(a2, AreaLight.SphereSinAlpha, VoH);
        Energy = a2 / Sphere_a2;
    }

    if (AreaLight.LineCosSubtended < 1)
    {
        float LineCosTwoAlpha = AreaLight.LineCosSubtended;
        float LineTanAlpha = sqrt((1.0001 - LineCosTwoAlpha) / (1 + LineCosTwoAlpha));
        float Line_a2 = New_a2(Sphere_a2, LineTanAlpha, VoH);
        Energy *= sqrt(Sphere_a2 / Line_a2);
    }
    return Energy;
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
float D_GGX_UE(float a2, float NoH)
{
    float d = (NoH * a2 - NoH) * NoH + 1;		// 2 mad
    return a2 / (PI * d * d);					// 4 mul, 1 rcp
}

// Appoximation of joint Smith term for GGX
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
float Vis_SmithJointApprox(float a2, float NoV, float NoL)
{
    float a = sqrt(a2);
    float Vis_SmithV = NoL * (NoV * (1 - a) + a);
    float Vis_SmithL = NoV * (NoL * (1 - a) + a);
    return 0.5 * rcp(Vis_SmithV + Vis_SmithL);  
}

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
float3 F_Schlick_UE(float3 SpecularColor, float VoH)
{
    float Fc = Pow5(1 - VoH);					// 1 sub, 3 mul
    //return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
    // Anything less than 2% is physically impossible and is instead considered to be shadowing
    return saturate(50.0 * SpecularColor.g) * Fc + (1 - Fc) * SpecularColor;
}

float3 SpecularGGX(float Roughness, float3 SpecularColor, BxDFContext Context, float NoL, FAreaLight AreaLight)
{
    float a2 = Pow4(Roughness);
    float Energy = EnergyNormalization(a2, Context.VoH, AreaLight);

    // Generalized microfacet specular
    float D = D_GGX_UE(a2, Context.NoH) * Energy;
    float Vis = Vis_SmithJointApprox(a2, Context.NoV, NoL);
    float3 F = F_Schlick_UE(SpecularColor, Context.VoH);

    return (D * Vis) * F;
}

float3 SpecularGGX(float Roughness, float Anisotropy, float3 SpecularColor, BxDFContext Context, float NoL, FAreaLight AreaLight)
{
    float Alpha = Roughness * Roughness;
    float a2 = Alpha * Alpha;

    float Energy = EnergyNormalization(a2, Context.VoH, AreaLight);

    // Generalized microfacet specular
    float D = 0;
    float Vis = 0;

    {
        D = D_GGX_UE(a2, Context.NoH) * Energy;
        Vis = Vis_SmithJointApprox(a2, Context.NoV, NoL);
    }

    float3 F = F_Schlick_UE(SpecularColor, Context.VoH);

    return (D * Vis) * F;
}

float3 DualSpecularGGX(float AverageRoughness, float Lobe0Roughness, float Lobe1Roughness, float LobeMix, float3 SpecularColor, BxDFContext Context, float NoL, FAreaLight AreaLight)
{
    float AverageAlpha2 = Pow4(AverageRoughness);
    float Lobe0Alpha2 = Pow4(Lobe0Roughness);
    float Lobe1Alpha2 = Pow4(Lobe1Roughness);

    float Lobe0Energy = EnergyNormalization(Lobe0Alpha2, Context.VoH, AreaLight);
    float Lobe1Energy = EnergyNormalization(Lobe1Alpha2, Context.VoH, AreaLight);

    // Generalized microfacet specular
    float D = lerp(D_GGX_UE(Lobe0Alpha2, Context.NoH) * Lobe0Energy, D_GGX_UE(Lobe1Alpha2, Context.NoH) * Lobe1Energy, LobeMix);
    float Vis = Vis_SmithJointApprox(AverageAlpha2, Context.NoV, NoL); // Average visibility well approximates using two separate ones (one per lobe).
    float3 F = F_Schlick_UE(SpecularColor, Context.VoH);

    return (D * Vis) * F;
}

// Alpha is half of angle of spherical cap
float SphereHorizonCosWrap(float NoL, float SinAlphaSqr)
{
    float SinAlpha = sqrt(SinAlphaSqr);
    if (NoL < SinAlpha)
    {
        NoL = max(NoL, -SinAlpha);
        // Hermite spline approximation
        // Fairly accurate with SinAlpha < 0.8
        // y=0 and dy/dx=0 at -SinAlpha
        // y=SinAlpha and dy/dx=1 at SinAlpha
        NoL = Pow2(SinAlpha + NoL) / (4 * SinAlpha);
    }
    return NoL;
}

// Closest point on line segment to ray
float3 ClosestPointLineToRay(float3 Line0, float3 Line1, float Length, float3 R)
{
    float3 L0 = Line0;
    float3 L1 = Line1;
    float3 Line01 = Line1 - Line0;

    // Shortest distance
    float A = Pow2(Length);
    float B = dot(R, Line01);
    float t = saturate(dot(Line0, B * R - Line01) / (A - B * B));

    return Line0 + t * Line01;
}

void GetProfileDualSpecular(FGBufferData GBuffer, out float AverageToRoughness0, out float AverageToRoughness1, out float LobeMix)
{
    //Branch for -> !FORWARD_SHADING
    // 0..255, which SubSurface profile to pick
    uint SubsurfaceProfileInt = ExtractSubsurfaceProfileInt(GBuffer); 
    //原式如下: 
    //float4 Data = LOAD_TEXTURE2D_X(_LUT, uint2(5, SubsurfaceProfileInt)).xyzw;
    //_LUT -> Width-Height = 98-64 
    //如下，基于y轴需要reverse，采用Texture_Height - SubsurfaceProfileInt的方式确定y的正确位置 
    float3 Data = LOAD_TEXTURE2D(_LUT, uint2(SSSS_DUAL_SPECULAR_OFFSET, 64 - SubsurfaceProfileInt)).xyz;
    AverageToRoughness0 = Data.x * SSSS_MAX_DUAL_SPECULAR_ROUGHNESS;
    AverageToRoughness1 = Data.y * SSSS_MAX_DUAL_SPECULAR_ROUGHNESS;
    LobeMix = Data.z;
}

FGBufferData GetGBufferData(float2 UV, bool bGetNormalizedNormal = true)  
{
    float DeviceZ  = SAMPLE_TEXTURE2D_X_LOD(_GBuffer4, my_point_clamp_sampler, UV, 0).x; // raw depth value has UNITY_REVERSED_Z applied on most platforms.
    half3 Normal_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer0, my_point_clamp_sampler, UV, 0).xyz;
    half4 Albedo_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer1, my_point_clamp_sampler, UV, 0);
    half4 Comp_M_D_R_F_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, UV, 0);
    half4 Comp_F_R_X_I_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer5, my_point_clamp_sampler, UV, 0);

    float4 ShadowTex_Raw = SAMPLE_TEXTURE2D(_ShadowTex, sampler_ShadowTex, UV).xyzw;
    //float4 ShadowTex_Raw = 0;  //TODO: set tex 

    float SceneDepth = ConvertFromDeviceZ(DeviceZ);

    return DecodeGBufferData(Normal_Raw, Albedo_Raw, Comp_M_D_R_F_Raw, 
        Comp_F_R_X_I_Raw, ShadowTex_Raw, SceneDepth, CheckerFromSceneColorUV(UV));
}

float InterleavedGradientNoise(float2 uv, float frameId)
{
    uv += frameId * float2(32.665f, 11.815f);
    const float3 magic = float3(0.06711056f, 0.00583715f, 52.9829189f);
    return frac(magic.z * frac(dot(uv, magic.xy)));
}

/** Returns 0 for positions closer than the fade near distance from the camera, and 1 for positions further than the fade far distance. */
float DistanceFromCameraFade(float SceneDepth)
{
    float2 LightData_DistanceFadeMAD = float2(0.00003, -9); 
    // depth (non radial) based fading over distance
    float Fade = saturate(SceneDepth * LightData_DistanceFadeMAD.x + LightData_DistanceFadeMAD.y);
    return Fade * Fade;
}

float4 GetPerPixelLightAttenuation(float2 UV)
{
    float4 raw_light_atten = SAMPLE_TEXTURE2D(_ShadowTex, sampler_ShadowTex, UV).xyzw;
    return raw_light_atten * raw_light_atten;
}

float ShadowRayCast(float3 RayOriginTranslatedWorld, float3 RayDirection,
    float RayLength, int NumSteps, float StepOffset)
{
    float4 RayStartClip = mul(Matrix_VP, float4(RayOriginTranslatedWorld.xyz, 1));
    float4 RayDirClip = mul(Matrix_VP, float4(RayDirection.xyz * RayLength, 0));
    float4 RayEndClip = RayStartClip + RayDirClip;

    float3 RayStartScreen = RayStartClip.xyz / RayStartClip.w;
    float3 RayEndScreen = RayEndClip.xyz / RayEndClip.w;

    float3 RayStepScreen = RayEndScreen - RayStartScreen;

    float3 RayStartUVz = float3(RayStartScreen.xy * ScreenPositionScaleBias.xy + ScreenPositionScaleBias.zw, RayStartScreen.z);
    float3 RayStepUVz = float3(RayStepScreen.xy * ScreenPositionScaleBias.xy, RayStepScreen.z); //处理朝向无需平移 

    float4 RayDepthClip = RayStartClip + mul(Matrix_P, float4(0, 0, RayLength, 0));
    float3 RayDepthScreen = RayDepthClip.xyz / RayDepthClip.w;

    const float Step = 1.0 / NumSteps;

    const float CompareTolerance = abs(RayDepthScreen.z - RayStartScreen.z) * Step * 2;

    //在相邻的一块屏幕像素区域内，StepOffset彼此不同
    //可用于消除采样误差导致的Alias -> AKA Morie pattern 
    float SampleTime = StepOffset * Step + Step; 

    float FirstHitTime = -1.0;

    UNITY_UNROLL
    for (int i = 0; i < NumSteps; i++)
    {
        float3 SampleUVz = RayStartUVz + RayStepUVz * SampleTime;

        //TODO: 判断是否 DeviceZ == NDC.z， 已知 DeviceZ 近处数值大，远处数值小 
        //float DeviceZ = SAMPLE_TEXTURE2D(_Depth, sampler_Depth, SampleUVz.xy).r; 
        float DeviceZ  = SAMPLE_TEXTURE2D_X_LOD(_GBuffer4, my_point_clamp_sampler, SampleUVz.xy, 0).x;

        float DepthDiff = SampleUVz.z - DeviceZ; //采样光线深度 - 采样点实际深度 

        //当DepthDiff落在(-2*CompareTolerance, 0)区间时，Hit成立 
        bool Hit = abs(DepthDiff + CompareTolerance) < CompareTolerance; 

        //负责记录第一次集中时的位置偏移，如果没击中任何物体，FirstHitTime 始终等于 -1 
        FirstHitTime = (Hit && FirstHitTime < 0.0) ? SampleTime : FirstHitTime; 

        SampleTime += Step; //步进一下 
    }

    float Shadow = FirstHitTime > 0.0 ? 1.0 : 0.0;

    float2 Vignette = max(6.0 * abs(RayStartScreen.xy + RayStepScreen.xy * FirstHitTime) - 5.0, 0.0);
    Shadow *= saturate(1.0 - dot(Vignette, Vignette));

    return 1 - Shadow;
}

void GetShadowTerms(FGBufferData GBuffer, FDeferredLightData LightData, float3 WorldPosition,
    float3 L, float4 LightAttenuation, float Dither, inout FShadowTerms Shadow)
{
    const float ContactShadowLengthScreenScale = Matrix_Inv_P[1][1] * GBuffer.Depth;

    uint2 flag = GBuffer.SelectiveOutputMask & uint2(SKIP_PRECSHADOW_MASK, ZERO_PRECSHADOW_MASK);
    float PrecomputedShadowFactors = flag.y ? 0 : 1;
    PrecomputedShadowFactors = flag.x ? PrecomputedShadowFactors : 1;

    float UsesStaticShadowMap = dot(LightData.ShadowMapChannelMask, float4(1, 1, 1, 1));
    float StaticShadowing = lerp(1, dot(PrecomputedShadowFactors, LightData.ShadowMapChannelMask), UsesStaticShadowMap);

    float DynamicShadowFraction = DistanceFromCameraFade(GBuffer.Depth); //依据距离远近 

    // For a directional light, fade between static shadowing and the whole scene dynamic shadowing based on distance + per object shadows
    float SurfaceShadow = lerp(LightAttenuation.x, StaticShadowing, DynamicShadowFraction); //调和动态和静态阴影 
    // Fade between SSS dynamic shadowing and static shadowing based on distance
    float TransmissionShadow = min(lerp(LightAttenuation.y, StaticShadowing, DynamicShadowFraction), LightAttenuation.w);

    SurfaceShadow *= LightAttenuation.z;
    TransmissionShadow *= LightAttenuation.z;

    float ContactShadowLength = 0;
    UNITY_FLATTEN
    if (LightData.ShadowedBits > 1 && LightData.ContactShadowLength > 0)
    {
        ContactShadowLength = LightData.ContactShadowLength * ContactShadowLengthScreenScale;
    }

    float StepOffset = Dither - 0.5;
    float ContactShadow = 1.0f;

    // TODO: 查明为何ContactShadow效果会和截帧输出不一致(特别是披肩下方的阴影) 
#define USE_CONTACT_SHADOW 0 
#if USE_CONTACT_SHADOW
    ContactShadow = ShadowRayCast(
        WorldPosition - CameraPosWS.xyz,  //对应UE4源码: WorldPosition + View.PreViewTranslation 
        L,
        ContactShadowLength, 
        8,
        StepOffset);
#endif
    SurfaceShadow *= ContactShadow;

    uint2 IsEyeHair = GBuffer.ShadingModelID == uint2(SHADINGMODELID_EYE, SHADINGMODELID_HAIR);
    TransmissionShadow = IsEyeHair.y ?
        TransmissionShadow * ContactShadow :
        (IsEyeHair.x ? TransmissionShadow : TransmissionShadow * (ContactShadow * 0.5 + 0.5));

    Shadow.SurfaceShadow = SurfaceShadow;
    Shadow.TransmissionShadow = TransmissionShadow;
}

// [ de Carpentier 2017, "Decima Engine: Advances in Lighting and AA" ]
void SphereMaxNoH(inout BxDFContext Context, float SinAlpha, bool bNewtonIteration)
{
    if (SinAlpha > 0)
    {
        float CosAlpha = sqrt(1 - Pow2(SinAlpha));

        float RoL = 2 * Context.NoL * Context.NoV - Context.VoL;
        if (RoL >= CosAlpha)
        {
            Context.NoH = 1;
            Context.XoH = 0;
            Context.YoH = 0;
            Context.VoH = abs(Context.NoV);
        }
        else
        {
            float rInvLengthT = SinAlpha * rsqrt(1 - RoL * RoL);
            float NoTr = rInvLengthT * (Context.NoV - RoL * Context.NoL);
            float VoTr = rInvLengthT * (2 * Context.NoV * Context.NoV - 1 - RoL * Context.VoL);

            //if (bNewtonIteration)  -> 似乎总是进入 
            {
                float NxLoV = sqrt(saturate(1 - Pow2(Context.NoL) - Pow2(Context.NoV) - Pow2(Context.VoL) + 2 * Context.NoL * Context.NoV * Context.VoL));

                float NoBr = rInvLengthT * NxLoV;
                float VoBr = rInvLengthT * NxLoV * 2 * Context.NoV;

                float NoLVTr = Context.NoL * CosAlpha + Context.NoV + NoTr;
                float VoLVTr = Context.VoL * CosAlpha + 1 + VoTr;

                float p = NoBr * VoLVTr;
                float q = NoLVTr * VoLVTr;
                float s = VoBr * NoLVTr;

                float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
                float xDenom = p * p + s * (s - 2 * p) + NoLVTr * ((Context.NoL * CosAlpha + Context.NoV) * Pow2(VoLVTr) + q * (-0.5 * (VoLVTr + Context.VoL * CosAlpha) - 0.5));
                float TwoX1 = 2 * xNum / (Pow2(xDenom) + Pow2(xNum));
                float SinTheta = TwoX1 * xDenom;
                float CosTheta = 1.0 - TwoX1 * xNum;
                NoTr = CosTheta * NoTr + SinTheta * NoBr;
                VoTr = CosTheta * VoTr + SinTheta * VoBr;
            }

            Context.NoL = Context.NoL * CosAlpha + NoTr;
            Context.VoL = Context.VoL * CosAlpha + VoTr;

            float InvLenH = rsqrt(2 + 2 * Context.VoL);
            Context.NoH = saturate((Context.NoL + Context.NoV) * InvLenH);
            Context.VoH = saturate(InvLenH + InvLenH * Context.VoL);
        }
    }
    else
    {
        float VoL2 = rsqrt(Context.VoL * 2 + 2);
        Context.NoH = saturate(Context.NoL * Context.NoV * VoL2);
        Context.VoH = saturate(Context.VoL * VoL2 + VoL2);
    }
}

//通用:木+石+土墙+乔木(含枝叶)等的渲染 
FDirectLighting DefaultLitBxDF(FGBufferData GBuffer, half3 N, half3 V, half3 L, float Falloff, float NoL, FAreaLight AreaLight, FShadowTerms Shadow)
{
    BxDFContext Context = (BxDFContext)0;
    Context.NoL = dot(N, L);
    Context.NoV = dot(N, V);
    Context.VoL = dot(V, L);

    SphereMaxNoH(Context, AreaLight.SphereSinAlpha, true);
    Context.NoV = saturate(abs(Context.NoV) + 1e-5); 

    FDirectLighting Lighting = (FDirectLighting)0;
    //原式: Lighting.Diffuse  = AreaLight.FalloffColor * (Falloff * NoL) * Diffuse_Lambert( GBuffer.DiffuseColor ); 
    Lighting.Diffuse = Diffuse_Lambert(GBuffer.DiffuseColor * NoL); 

    Lighting.Specular = AreaLight.FalloffColor * (Falloff * NoL) *
        SpecularGGX(GBuffer.Roughness, GBuffer.Anisotropy, GBuffer.SpecularColor, Context, NoL, AreaLight);

    return Lighting;
}

//草+灌木 
FDirectLighting TwoSidedBxDF(FGBufferData GBuffer, half3 N, half3 V, half3 L, float Falloff, 
    float NoL, FAreaLight AreaLight, FShadowTerms Shadow)
{
    FDirectLighting Lighting = DefaultLitBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);

    float3 SubsurfaceColor = ExtractSubsurfaceColor(GBuffer);

    //原式: 
    //float Wrap = 0.5;
    //float WrapNoL = saturate((-dot(N, L) + Wrap) / Square(1 + Wrap));
    float WrapNoL = saturate(0.9444 - dot(N, L));

    //原式: 
    //Scatter distribution
    //float VoL = dot(V, L);
    //float Scatter = D_GGX_UE(0.6 * 0.6, saturate(-VoL));
    float Scatter = D_GGX_UE(0.36, saturate(-dot(V, L)));

    Lighting.Transmission = WrapNoL * Scatter * SubsurfaceColor; 
    //Lighting.Transmission = 0;

    return Lighting; 
}

//衣服的布料 
FDirectLighting ClothBxDF(FGBufferData GBuffer, half3 N, half3 V, half3 L, float Falloff, 
    float NoL, FAreaLight AreaLight, FShadowTerms Shadow)
{
    const float3 FuzzColor = ExtractSubsurfaceColor(GBuffer);  //来自Tex5.rgb  
    float  Cloth = saturate(GBuffer.CustomData.x); 
    Cloth = 0; 

    BxDFContext Context = (BxDFContext)0;
    Context.NoL = dot(N, L);
    Context.NoV = dot(N, V);
    Context.VoL = dot(V, L);

    SphereMaxNoH(Context, AreaLight.SphereSinAlpha, true);
    Context.NoV = saturate(abs(Context.NoV) + 1e-5);

    //already rule out branch when AreaLight.bIsRect == true 
    float3 Spec1 = NoL * SpecularGGX(GBuffer.Roughness, GBuffer.SpecularColor, Context, NoL, AreaLight);

    //原式: 由于Cloth参数的定义，如下代码不会使用，直接屏蔽 
    // Cloth - Asperity Scattering - Inverse Beckmann Layer
    float D2 = D_InvGGX(Pow4(GBuffer.Roughness), Context.NoH);
    float Vis2 = Vis_Cloth(Context.NoV, NoL);
    float3 F2 = F_Schlick_UE(FuzzColor, Context.VoH);
    float3 Spec2 = NoL * (D2 * Vis2) * F2;

    FDirectLighting Lighting;
    Lighting.Diffuse = NoL * Diffuse_Lambert(GBuffer.DiffuseColor);
    //原式: 
    Lighting.Specular = lerp(Spec1, Spec2, Cloth);
    //Lighting.Specular = Spec1;
    Lighting.Transmission = 0;

    return Lighting;
}

//Kena 对人物皮肤的渲染 
FDirectLighting SubsurfaceProfileBxDF(FGBufferData GBuffer, half3 N, half3 V, half3 L, float Falloff, 
    float NoL, FAreaLight AreaLight, FShadowTerms Shadow)
{

    BxDFContext Context = (BxDFContext)0;
    Context.NoL = dot(N, L);
    Context.NoV = dot(N, V);
    Context.VoL = dot(V, L);

    SphereMaxNoH(Context, AreaLight.SphereSinAlpha, true);
    Context.NoV = saturate(abs(Context.NoV) + 1e-5);

    float AverageToRoughness0 = 1;
    float AverageToRoughness1 = 1;
    float LobeMix = 0;
    GetProfileDualSpecular(GBuffer, AverageToRoughness0, AverageToRoughness1, LobeMix);

    float AverageRoughness = GBuffer.Roughness;
    float Lobe0Roughness = max(saturate(AverageRoughness * AverageToRoughness0), 0.02f);
    float Lobe1Roughness = saturate(AverageRoughness * AverageToRoughness1);

    // Smoothly lerp to default single GGX lobe as Opacity approaches 0, before reverting to SHADINGMODELID_DEFAULT_LIT.
    // See SUBSURFACE_PROFILE_OPACITY_THRESHOLD in ShadingModelsMaterial.ush.
    float Opacity = GBuffer.CustomData.x;
    Lobe0Roughness = lerp(1.0f, Lobe0Roughness, saturate(Opacity * 10.0f));
    Lobe1Roughness = lerp(1.0f, Lobe1Roughness, saturate(Opacity * 10.0f));

    FDirectLighting Lighting = (FDirectLighting)0;

    Lighting.Diffuse = AreaLight.FalloffColor * (Falloff * NoL) * Diffuse_Burley(GBuffer.DiffuseColor, GBuffer.Roughness, Context.NoV, NoL, Context.VoH);

    Lighting.Specular = AreaLight.FalloffColor * (Falloff * NoL) * DualSpecularGGX(AverageRoughness, Lobe0Roughness, Lobe1Roughness, LobeMix, GBuffer.SpecularColor, Context, NoL, AreaLight);

    return Lighting;
}

//头发渲染 
FDirectLighting HairBxDF(FGBufferData GBuffer, half3 N, half3 V, half3 L, float Falloff, float NoL, FAreaLight AreaLight, FShadowTerms Shadow)
{
    FDirectLighting Lighting;
    Lighting.Diffuse = 0;
    Lighting.Specular = 0;
    bool bEvalMultiScatter = true;
    Lighting.Transmission = AreaLight.FalloffColor * Falloff * HairShading(GBuffer, L, V, N, 
        Shadow.TransmissionShadow, Shadow.HairTransmittance, 1, 0, uint2(0, 0), bEvalMultiScatter);
    return Lighting;
}

FDirectLighting IntegrateBxDF(FGBufferData GBuffer, half3 N, half3 V, half3 L, float Falloff, 
    float NoL, FAreaLight AreaLight, FShadowTerms Shadow)
{

    //1739 : mov r11.yzw, l(0, 0, 0, 0)			->Diffuse
    //1740 : mov r12.xyz, l(0, 0, 0, 0)			->Specular
    //1741 : mov r13.xyz, l(0, 0, 0, 0)			->Transmission 

    switch (GBuffer.ShadingModelID)
    {
    case SHADINGMODELID_DEFAULT_LIT:
    case SHADINGMODELID_SINGLELAYERWATER:
    case SHADINGMODELID_THIN_TRANSLUCENT:
        return DefaultLitBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_TWOSIDED_FOLIAGE:
        return TwoSidedBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_CLOTH:
        return ClothBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_SUBSURFACE_PROFILE:
        return SubsurfaceProfileBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_HAIR:
        return HairBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_SUBSURFACE:
        //return SubsurfaceBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_PREINTEGRATED_SKIN:
        //return PreintegratedSkinBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_CLEAR_COAT:
        //return ClearCoatBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
    case SHADINGMODELID_EYE:
        //return EyeBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
        return (FDirectLighting)0;
    default:
        return (FDirectLighting)0;
    }
}

FDirectLighting IntegrateBxDF(FGBufferData GBuffer, half3 N, half3 V, FCapsuleLight Capsule, 
    FShadowTerms Shadow, bool bInverseSquared)
{
    float NoL = 0;
    float Falloff = 0;
    float LineCosSubtended = 1; 

    if (Capsule.Length <= 0 ) // -> Kena 的CapsuleLight.len总是为0 
    {
        float DistSqr = dot(Capsule.LightPos[0], Capsule.LightPos[0]); //LightPos里存的其实是LightDir 
        Falloff = rcp(DistSqr + Capsule.DistBiasSqr);	//todo  
        float3 L = Capsule.LightPos[0] * rsqrt(DistSqr);  //可以直接拿Capsule.LightPos[0]替代，Kena中，这个值本身已经被归一化了 
        NoL = dot(N, L);
    }

    if (Capsule.Radius > 0)
    {
        float SinAlphaSqr = saturate(Pow2(Capsule.Radius) * Falloff); //todo: 含义 
        NoL = SphereHorizonCosWrap(NoL, SinAlphaSqr); 
    }

    NoL = saturate(NoL);
    Falloff = bInverseSquared ? Falloff : 1; //todo 确认 bInverseSquared

    float3 ToLight = Capsule.LightPos[0];
    //if (Capsule.Length > 0) //当前分支不进入，Capsule.Length == 0 
    //{
    //	float3 R = reflect(-V, N);   
    //	ToLight = ClosestPointLineToRay(Capsule.LightPos[0], Capsule.LightPos[1], Capsule.Length, R);
    //}
    float DistSqr = dot(ToLight, ToLight);
    float InvDist = rsqrt(DistSqr);
    float3 L = ToLight * InvDist;

    GBuffer.Roughness = max(GBuffer.Roughness, view_minRoughness);
    float a = Pow2(GBuffer.Roughness);

    FAreaLight AreaLight;
    AreaLight.SphereSinAlpha = saturate(Capsule.Radius * InvDist * (1 - a));
    AreaLight.SphereSinAlphaSoft = saturate(Capsule.SoftRadius * InvDist);
    AreaLight.LineCosSubtended = LineCosSubtended;
    AreaLight.FalloffColor = 1;
    AreaLight.bIsRect = false;

    return IntegrateBxDF(GBuffer, N, V, L, Falloff, NoL, AreaLight, Shadow);
}

/** Calculates lighting for a given position, normal, etc with a fully featured lighting model designed for quality. */ 
FDeferredLightingSplit GetDynamicLightingSplit(
    float3 WorldPosition, float3 CameraVector, FGBufferData GBuffer, float AmbientOcclusion, uint ShadingModelID,
    FDeferredLightData LightData, float4 LightAttenuation, float Dither, uint2 SVPos, FRectTexture SourceTexture,
    inout float SurfaceShadow)
{
    float3 V = -CameraVector;
    float3 N = GBuffer.WorldNormal;

    float3 L = LightData.Direction;	// Already normalized -> 这里是引擎提供的主光方向 
    float3 ToLight = L;

    float LightMask = 1;

    float4 RetDiffuse = 0;
    float4 RetSpecular = 0;
    float3 CommonMultiplier = 0;

    //if (LightMask > 0)		//TRUE -> 假设任何位置都能被 RadialLight 照射到 
    {
        FShadowTerms Shadow = (FShadowTerms)0;
        Shadow.SurfaceShadow = AmbientOcclusion;
        Shadow.TransmissionShadow = 1;
        Shadow.TransmissionThickness = 1;
        Shadow.HairTransmittance = (FHairTransmittanceData)0;
        //Shadow.HairTransmittance.Transmittance = 1; 
        //Shadow.HairTransmittance.OpaqueVisibility = 1; //todo 
        GetShadowTerms(GBuffer, LightData, WorldPosition, L, LightAttenuation, Dither, Shadow); 
        //Shadow.SurfaceShadow = 1;
        //SurfaceShadow = Shadow.SurfaceShadow; 
        
        UNITY_BRANCH
        if (Shadow.SurfaceShadow + Shadow.TransmissionShadow > 0)  //不处于完全黑暗的地方，都需要计算光照！ 
        {
            //todo 
            // const bool bNeedsSeparateSubsurfaceLightAccumulation = UseSubsurfaceProfile(GBuffer.ShadingModelID);
            // float3 LightColor = LightData.Color;
            
            // Kena 进入 ~NON_DIRECTIONAL_DIRECT_LIGHTING 分支，既，有直接光
            FDirectLighting Lighting; 
            //Kena 进入 Capsule light 分支 
            FCapsuleLight Capsule = GetCapsule(ToLight, LightData); 
            Lighting = IntegrateBxDF(GBuffer, N, V, Capsule, Shadow, LightData.bInverseSquared); 

            CommonMultiplier = LightData.Color * LightMask * Shadow.SurfaceShadow;
            
            RetDiffuse.rgb = Lighting.Diffuse * CommonMultiplier;
            float3 ShadowTerm = Shadow.TransmissionShadow * LightData.Color * Lighting.Transmission;

            if (UseSubsurfaceProfile(GBuffer.ShadingModelID) && bCheckerboardSubsurfaceProfileRendering == 0)
            {
                RetDiffuse.a = LuminanceUE(RetDiffuse.rgb);
                RetDiffuse.a += LuminanceUE(ShadowTerm);
            }

            RetDiffuse.rgb += ShadowTerm;
            RetSpecular.rgb = Lighting.Specular * LightData.SpecularScale * CommonMultiplier;
        }
    }

    FDeferredLightingSplit OUT = (FDeferredLightingSplit)0;

    OUT.DiffuseLighting = RetDiffuse;
    OUT.SpecularLighting = RetSpecular;

    return OUT;
}

//float4 positionCS : SV_POSITION;
//float3 screenUV : TEXCOORD1;
//float3 viewDirWS : TEXCOORD2;

float4 FragKenaTest(Varyings IN) : SV_Target
{
    //init all local buffer data
    kena_LightData.ShadowedBits = 3;		  //cb1[2].x=3 -> 需用uint4查看 
    kena_LightData.ContactShadowLength = 0.2; //cb1[1].z=0.2 
    kena_LightData.Direction = float3(0.51555, -0.29836, 0.80324);  //cb1[5].xyz
    kena_LightData.Tangent = float3(0.51555, -0.29836, 0.80324);    //cb1[6].xyz
    kena_LightData.ShadowMapChannelMask = float4(0, 0, 0, 0);	    //cb1[0].xyzw 
    kena_LightData.SourceLength = 0;		//cb1[7].w=0
    kena_LightData.SourceRadius = 0.00467;	//cb1[6].w=0.00467
    kena_LightData.SoftSourceRadius = 0;	//cb1[7].z=0 
    kena_LightData.bInverseSquared = true;	//todo  uint4
    kena_LightData.SpecularScale = 1;		//cb1[5].w=1.0     
    kena_LightData.Color = float4(17.99882, 18.66276, 19.00, 0.00);	//cb1[5].w=1.0  
    //init done! 

    half4 test = half4(0,0,0,1);  //用于测试输出 
	half4 FinalColor = half4(0,0,0,1);  //用于测试输出 

    FGBufferData GBuffer = GetGBufferData(IN.screenUV.xy);
    float3 ViewDirWS = normalize(IN.viewDirWS);
	float3 WorldPosition = ViewDirWS * GBuffer.Depth + CameraPosWS.xyz;

    //验证世界坐标正确性用
	//float4 shouldBeHClipPos = mul(Matrix_VP, float4(WorldPosition - CameraPosWS.xyz, 1));
	//test.rgb = shouldBeHClipPos.xyz / shouldBeHClipPos.w; 

    uint see_flag = GBuffer.ShadingModelID == (uint)SHADINGMODELID_HAIR;
    //test.rgb = see_flag;

    if (GBuffer.ShadingModelID)  //不是天空的进入 
    {
        float3 ViewDirWS = normalize(IN.viewDirWS);
        float3 WorldPosition = ViewDirWS * GBuffer.Depth + CameraPosWS.xyz;

        float3 CameraVector = normalize(WorldPosition - CameraPosWS.xyz);
        //test.xyz = abs(WorldPosition - CameraPosWS.xyz) / 35000; //用于验证世界坐标解码后的正确性 

        //在一定屏幕空间范围内的随机变量，一般用于模糊摩尔纹或其他异样 
        float Dither = InterleavedGradientNoise(IN.positionCS, FrameId); 

        //get shadow terms
        float4 LightAttenuation = GetPerPixelLightAttenuation(IN.screenUV.xy);

        //get ssao 
        float AmbientOcclusion = SAMPLE_TEXTURE2D(_SSAO, sampler_SSAO, IN.screenUV.xy).r;

        //get dumy rect texture 
        FRectTexture SourceTexture = (FRectTexture)0;

        float SurfaceShadow = 1.0f;

        FDeferredLightingSplit light_output = GetDynamicLightingSplit(
            WorldPosition, CameraVector, GBuffer, AmbientOcclusion, GBuffer.ShadingModelID,
            kena_LightData, LightAttenuation, Dither, uint2(IN.positionCS.xy), SourceTexture,
            SurfaceShadow
        );

        FinalColor = light_output.DiffuseLighting * 0.5 + light_output.SpecularLighting * 0.3; //TODO: 结合渲染原理，定位颜色差异问题 

        test = FinalColor;
        //test = light_output.DiffuseLighting;
    }

    return float4(test.rgb , test.a);
}