
//------------------    Math Lib Start  ------------------
#if 1 
static float acos(float a) {
    float a2 = a * a;   // a squared
    float a3 = a * a2;  // a cubed
    if (a >= 0) {
        return (float)sqrt(1.0 - a) * (1.5707288 - 0.2121144 * a + 0.0742610 * a2 - 0.0187293 * a3);
    }
    return 3.14159265358979323846
        - (float)sqrt(1.0 + a) * (1.5707288 + 0.2121144 * a + 0.0742610 * a2 + 0.0187293 * a3);
}

static float asin(float a) {
    float a2 = a * a;   // a squared
    float a3 = a * a2;  // a cubed
    if (a >= 0) {
        return 1.5707963267948966
            - (float)sqrt(1.0 - a) * (1.5707288 - 0.2121144 * a + 0.0742610 * a2 - 0.0187293 * a3);
    }
    return -1.5707963267948966 + (float)sqrt(1.0 + a) * (1.5707288 + 0.2121144 * a + 0.0742610 * a2 + 0.0187293 * a3);
}

// Relative error : < 0.7% over full
// Precise format : ~small float
// 1 ALU
float sqrtFast(float x)
{
	int i = asint(x);
	i = 0x1FBD1DF5 + (i >> 1);
	return asfloat(i);
}

// max absolute error 9.0x10^-3
// Eberly's polynomial degree 1 - respect bounds
// 4 VGPR, 12 FR (8 FR, 1 QR), 1 scalar
// input [-1, 1] and output [0, PI]
float acosFast(float inX)
{
	float x = abs(inX);
	float res = -0.156583f * x + (0.5 * PI);
	res *= sqrt(1.0f - x);
	return (inX >= 0) ? res : PI - res;
}

// Same cost as acosFast + 1 FR
// Same error
// input [-1, 1] and output [-PI/2, PI/2]
float asinFast(float x)
{
	return (0.5 * PI) - acosFast(x);
}

inline float Pow2(float a)
{
    return a * a;
}

inline float3 Pow2(float3 x)
{
    return x * x;
}

inline float Pow5(float x)
{
    float xx = x * x;
    return xx * xx * x;
}
#endif 
//------------------    Math Lib End    ------------------

//------------------    GBuffer Structure Start  ------------------
#if 1
struct FGBufferData
{
	// normalized
	float3 WorldNormal;
	// normalized, only valid if GBUFFER_HAS_TANGENT
	float3 WorldTangent;
	// 0..1 (derived from BaseColor, Metalness, Specular)
	float3 DiffuseColor;
	// 0..1 (derived from BaseColor, Metalness, Specular)
	float3 SpecularColor;
	// 0..1, white for SHADINGMODELID_SUBSURFACE_PROFILE and SHADINGMODELID_EYE (apply BaseColor after scattering is more correct and less blurry)
	float3 BaseColor;
	float3 StoredBaseColor;
	float StoredSpecular;
	float4 CustomData;
	float Metallic; // 0..1
	float Specular; // 0..1
	float Roughness; // 0..1
	float GBufferAO; // 0..1
	float IndirectIrradiance; // 0..1
	uint ShadingModelID; // 0..15 
	uint SelectiveOutputMask; // 0..255 
	float Anisotropy;
	// in unreal units (linear), can be used to reconstruct world position,
	// only valid when decoding the GBuffer as the value gets reconstructed from the Z buffer
	float Depth;
};
#endif
//------------------    GBuffer Structure End    ------------------

//------------------    Utility Start   ------------------
#if 1
float LuminanceUE(float3 aColor)
{
    return dot(aColor, float3(0.3, 0.59, 0.11));
}

float DielectricSpecularToF0(float Specular)
{
	return 0.08f * Specular;
}

float3 ComputeF0(float Specular, float3 BaseColor, float Metallic)
{
	return lerp(DielectricSpecularToF0(Specular).xxx, BaseColor, Metallic.xxx);
}

float3 DecodeNormalUE(float3 N)
{
    return N * 2.0f - 1.0f;
}

uint DecodeShadingModelId(float InPackedChannel)
{
    return ((uint)round(InPackedChannel * (float)0xFF)) & SHADINGMODELID_MASK;
}

uint DecodeSelectiveOutputMask(float InPackedChannel)
{
    return ((uint)round(InPackedChannel * (float)0xFF)) & (~SHADINGMODELID_MASK);
}

float ConvertFromDeviceZ(float DeviceZ)
{
	// Supports ortho and perspective, see CreateInvDeviceZToWorldZTransform()
	return DeviceZ * InvDeviceZToWorldZTransform[0] + InvDeviceZToWorldZTransform[1] + 1.0f / (DeviceZ * InvDeviceZToWorldZTransform[2] - InvDeviceZToWorldZTransform[3]);
}

bool CheckerFromSceneColorUV(float2 UVSceneColor)
{
	// relative to left top of the rendertarget (not viewport)
	//uint2 PixelPos = uint2(UVSceneColor * View_BufferSizeAndInvSize.xy); 
	uint2 PixelPos = uint2(UVSceneColor * _ScreenParams.xy);
	uint TemporalAASampleIndex = 3;
	return (PixelPos.x + PixelPos.y + TemporalAASampleIndex) & 1;
}

float3 ExtractSubsurfaceColor(FGBufferData BufferData)
{
	return Pow2(BufferData.CustomData.yzw);
}

uint ExtractSubsurfaceProfileInt(FGBufferData BufferData)
{
	// can be optimized
	return uint(BufferData.CustomData.y * 255 + 0.5f);
}

float ApproximateConeConeIntersection(float ArcLength0, float ArcLength1, float AngleBetweenCones)
{
	float AngleDifference = abs(ArcLength0 - ArcLength1);

	float Intersection = smoothstep(
		0,
		1.0,
		1.0 - saturate((AngleBetweenCones - AngleDifference) / (ArcLength0 + ArcLength1 - AngleDifference)));

	return Intersection;
}

float2 SvPositionToBufferUV(float4 SvPosition)
{
	//return SvPosition.xy * View_BufferSizeAndInvSize.zw;
	//_ScreenParams
	return SvPosition.xy / _ScreenParams.xy;  //注意，使用_ScreenParams时必须确保重建Pass使用的屏幕分辨率参数与截帧一致 
}

float4 SvPositionToScreenPosition(float4 SvPosition)
{
	float2 PixelPos = SvPosition.xy - View_ViewRectMin.xy;
	// NDC (NormalizedDeviceCoordinates, after the perspective divide) 
	// 备注: 原式乘子float2(2, -2),带有y的翻转 
	float3 NDCPos = float3((PixelPos * View_ViewSizeAndInvSize.zw - 0.5f) * float2(2, 2), SvPosition.z);
	// SvPosition.w: so .w has the SceneDepth, some mobile code and the DepthFade material expression wants that
	return float4(NDCPos.xyz, 1) * SvPosition.w;
}

uint3 Rand3DPCG16(int3 p)
{
	uint3 v = uint3(p);
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	return v >> 16u;
}
#endif 
//------------------    Utility End     ------------------


//------------------    Gbuffer Start   ------------------
#if 1
bool UseSubsurfaceProfile(int ShadingModel)
{
	return ShadingModel == SHADINGMODELID_SUBSURFACE_PROFILE || ShadingModel == SHADINGMODELID_EYE;
}

void AdjustBaseColorAndSpecularColorForSubsurfaceProfileLighting(inout float3 BaseColor, inout float3 SpecularColor, inout float Specular, bool bChecker)
{
	// because we adjust the BaseColor here, we need StoredBaseColor
	BaseColor = bSubsurfacePostprocessEnabled ? float3(1, 1, 1) : BaseColor;
	// we apply the base color later in SubsurfaceRecombinePS()
	BaseColor = bChecker;
	// in SubsurfaceRecombinePS() does not multiply with Specular so we do it here
	SpecularColor *= !bChecker;
	Specular *= !bChecker;
}

FGBufferData DecodeGBufferData(float3 Normal_Raw, float4 Albedo_Raw, float4 Comp_M_D_R_F_Raw,
	float4 Comp_F_R_X_I_Raw, float4 ShadowTex_Raw, float SceneDepth, bool bChecker)
{
	FGBufferData GBuffer = (FGBufferData)0;

	GBuffer.WorldNormal = normalize(DecodeNormalUE(Normal_Raw));
	GBuffer.Metallic = Comp_M_D_R_F_Raw.r;
	GBuffer.Specular = Comp_M_D_R_F_Raw.g;
	GBuffer.Roughness = Comp_M_D_R_F_Raw.b;

	GBuffer.ShadingModelID = DecodeShadingModelId(Comp_M_D_R_F_Raw.a);
	GBuffer.SelectiveOutputMask = DecodeSelectiveOutputMask(Comp_M_D_R_F_Raw.a);

	GBuffer.BaseColor = Albedo_Raw.rgb;

	GBuffer.StoredBaseColor = Albedo_Raw.rgb; 
	GBuffer.StoredSpecular = Comp_M_D_R_F_Raw.g; 

	GBuffer.GBufferAO = Albedo_Raw.a; //非 static_lighting 模式下，使用传入的a通道作为 GBufferAO 
	GBuffer.IndirectIrradiance = 1;   //环境光强没有波动 

	GBuffer.Anisotropy = 0;   //不带有GBuffer Tangent的话，这里总是0 

	//GBuffer.CustomDepth = 1; 
	GBuffer.Depth = SceneDepth;

	//Kena里只有木+墙部分激活了 Skip_CustomData，其余部分均需要用到 Comp_F_R_X_I_Raw 这样用户定义的纹理和对应逻辑 
	GBuffer.CustomData = (!(GBuffer.SelectiveOutputMask & SKIP_CUSTOMDATA_MASK)) ? Comp_F_R_X_I_Raw.wxyz : float4(0, 0, 0, 0);

	UNITY_FLATTEN
	if (GBuffer.ShadingModelID == SHADINGMODELID_EYE)
	{
		GBuffer.Metallic = 0.0;
	}

	// derived from BaseColor, Metalness, Specular
	{
		GBuffer.SpecularColor = ComputeF0(GBuffer.Specular, GBuffer.BaseColor, GBuffer.Metallic);

		if (UseSubsurfaceProfile(GBuffer.ShadingModelID)) //对皮肤和眼睛来说，会进入此分支 
		{	//对应棋盘状纹理 + 后处理的计算流程 -> 这里需要修改皮肤像素对应的 BaseCol，SpecCol等参数 
			AdjustBaseColorAndSpecularColorForSubsurfaceProfileLighting(GBuffer.BaseColor,
				GBuffer.SpecularColor, GBuffer.Specular, bChecker);
		}

		GBuffer.DiffuseColor = GBuffer.BaseColor - GBuffer.BaseColor * GBuffer.Metallic;
	}

	return GBuffer;
}

FGBufferData GetGBufferDataFromSceneTextures(float2 UV, bool bGetNormalizedNormal = true)
{
	float4 Albedo_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer0, my_point_clamp_sampler, UV, 0);
	float4 Comp_M_D_R_F_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer1, my_point_clamp_sampler, UV, 0);
	float3 Normal_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, UV, 0).rgb;
	float DeviceZ = SAMPLE_TEXTURE2D_X_LOD(_GBuffer4, my_point_clamp_sampler, UV, 0).x;
	float4 Comp_F_R_X_I_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer5, my_point_clamp_sampler, UV, 0);
	float SceneDepth = ConvertFromDeviceZ(DeviceZ);
	float4 ShadowTex_Raw = 0;   //GBufferE: Shadow 
	//float4 GBufferF = 0.5f;     //GBufferF: TANGENT 

	return DecodeGBufferData(Normal_Raw, Albedo_Raw, Comp_M_D_R_F_Raw, Comp_F_R_X_I_Raw, ShadowTex_Raw,
		SceneDepth, CheckerFromSceneColorUV(UV));
}

FGBufferData GetGBufferData(float2 UV, bool bGetNormalizedNormal = true)
{
	float4 Albedo_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer0, my_point_clamp_sampler, UV, 0);
	float4 Comp_M_D_R_F_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer1, my_point_clamp_sampler, UV, 0);
	float3 Normal_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer2, my_point_clamp_sampler, UV, 0).rgb;

	float DeviceZ = SAMPLE_TEXTURE2D_X_LOD(_GBuffer4, my_point_clamp_sampler, UV, 0).x; // raw depth value has UNITY_REVERSED_Z applied on most platforms.
	float4 Comp_F_R_X_I_Raw = SAMPLE_TEXTURE2D_X_LOD(_GBuffer5, my_point_clamp_sampler, UV, 0);

	float SceneDepth = ConvertFromDeviceZ(DeviceZ);
	float4 ShadowTex_Raw = 0;

	return DecodeGBufferData(Normal_Raw, Albedo_Raw, Comp_M_D_R_F_Raw,
		Comp_F_R_X_I_Raw, ShadowTex_Raw, SceneDepth, CheckerFromSceneColorUV(UV));
}

#endif 
//------------------    Gbuffer End     ------------------