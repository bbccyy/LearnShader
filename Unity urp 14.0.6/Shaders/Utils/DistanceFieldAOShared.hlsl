
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// Must match C++
#define NUM_CONE_STEPS 10
// Must match C++
#define NUM_CONE_DIRECTIONS 9
// Must match C++
#define AO_DOWNSAMPLE_FACTOR 2

#ifndef TRACE_DOWNSAMPLE_FACTOR 				// GConeTraceDownsampleFactor == 4 
#define TRACE_DOWNSAMPLE_FACTOR 4 
#endif


SamplerState my_point_clamp_sampler;
SamplerState my_bilinear_clamp_sampler;
uniform Texture2D<float4> _GBuffer2;			//Normal
uniform Texture2D<float> _GBuffer4;				//Depth

Texture2D<float4> _NormalDepth;					//the output RT of ComputeDistanceFieldNormalPS -> Half Resolution (set before use!)

Texture2D<float4> _BentNorm_History;			//used for UpdateHistoryDepthRejectionPS pass <- grabbed from last frame bent normal texture output

Texture3D<half> _GlobalDistanceFieldTexture0;	//SDF lod0	(readonly)	-> TODO ... 
Texture3D<half> _GlobalDistanceFieldTexture1;	//SDF lod1	(readonly)	-> TODO ...

RWBuffer<uint> RWScreenGridConeVisibility;		//used for CombineConeVisibilityCS pass <- stores 9 direction Cone-size tracing results(visibility)

RWTexture2D<float4> RWCombinedDFBentNormal;		//used for CombineConeVisibilityCS pass
Texture2D<float4> _CombinedDFBentNormal;		//used for UpdateHistoryDepthRejectionPS pass <- set before use

Texture2D<float2> _MotionVectorTexture;			//used for UpdateHistoryDepthRejectionPS pass <- it's global
float MotionVectorFactor;

float4 View_BufferSizeAndInvSize;		//[1708, 960, 1/1708, 1/960]
float4 View_ScreenPositionScaleBias;	//[0.5, +-0.5, 0.5, 0.5] 

uint2 ScreenGridConeVisibilitySize;		//213,120
float4 ScreenGridBufferAndTexelSize;	//[213, 120, 1/213, 1/120]
float2 JitterOffset;					//[0, 2]
float2 DistanceFieldGBufferJitterOffset;//JitterOffset * BaseLevelSizeAndTexelSize.zw
float4 BaseLevelSizeAndTexelSize;		//[854, 480, 1/854, 1/480]

float4 GlobalVolumeCenterAndExtent[2];	//Vector4 array
float4 GlobalVolumeWorldToUVAddAndMul[2]; 
float AOGlobalMaxOcclusionDistanceAndInv[2];
float GlobalVolumeTexelSize;

float4x4 _PrevInvViewProjMatrix;		//updated by MotionVectorRenderPass every frame

//#define UNITY_MATRIX_PRE_I_VP _PrevInvViewProjMatrix;

float TanConeHalfAngle;

float4 AOSamples2_SampleDirections[NUM_CONE_DIRECTIONS];

float BentNormalNormalizeFactor;

float Pow2(float x)
{
	return x * x;
}

// Relative error : < 0.4% over full
// Precise format : ~small float
// 1 ALU
float rcpFast(float x)
{
	int i = asint(x);
	i = 0x7EF311C2 - i;
	return asfloat(i);
}

bool3 IsFinite(float3 In)
{
	return (asuint(In) & 0x7F800000) != 0x7F800000;
}

float3 MakeFinite(float3 In)
{
	return !IsFinite(In) ? 0 : In;
}

//ͨ�������ConeTracingGridCoordinate����Լ200x100���ķֱ��ʣ�ӳ�䵽���ڴ������BentNormal��ͼ�ķֱ��ʣ���Լ854x480
//�ڼ侭��Jitter�����ؼ�ƫ�ƣ��Լ�0.5���ص�Offset�����ͨ�����Զ�Ӧ���سߴ磨����UV�ĳߴ磺1/854, 1/480����ӳ�����ĻUV 
float2 GetBaseLevelScreenUVFromScreenGrid(uint2 OutputCoordinate, float JitterScale) //input: DispatchThreadId.xy, 1 
{
	float2 BaseLevelScreenUV = (OutputCoordinate * TRACE_DOWNSAMPLE_FACTOR + JitterOffset * JitterScale + float2(.5f, .5f)) * BaseLevelSizeAndTexelSize.zw;
	return BaseLevelScreenUV;
}

float2 GetBaseLevelScreenUVFromScreenGrid(uint2 OutputCoordinate)
{
	return GetBaseLevelScreenUVFromScreenGrid(OutputCoordinate, 1);
}

//ͨ�������ConeTracingGridCoordinate����Լ200x100���ķֱ��ʣ�ӳ�䵽��Ļ�ֱ��ʣ�1708x960����
//�ڼ侭��Jitter�����ؼ�ƫ�ƣ��Լ�0.5���ص�Offset�����ͨ���������سߴ磨����UV�ĳߴ磻1/1708,1/960����ӳ�����ĻUV 
float2 GetFullResUVFromBufferGrid(uint2 PixelCoordinate, float JitterScale = 1.0f)
{
	float2 ScreenUV = ((PixelCoordinate * TRACE_DOWNSAMPLE_FACTOR + JitterOffset * JitterScale) * AO_DOWNSAMPLE_FACTOR + float2(.5f, .5f)) * View_BufferSizeAndInvSize.zw;
	return ScreenUV;
}

//Return Wolrd Normal and DeviceZ Depth
void GetNormalDepthGBuffer(float2 UV, out float3 Norm, out float Depth)
{
	//float4 norm_depth =  _NormalDepth.SampleLevel(my_point_clamp_sampler, UV, 0).xyzw;
	float4 norm_depth = SAMPLE_TEXTURE2D_LOD(_NormalDepth, my_point_clamp_sampler, UV, 0).xyzw;
	Norm = norm_depth.xyz;
	//Depth = norm_depth.w <= 0 ? 1 : norm_depth.w;  //TODO
	Depth = norm_depth.w;  //TODO

}

//Build Tangent and Bitangent to form TBN matrix 
void FindTangentXY(float3 normal, out float3 tanX, out float3 tanY)
{
	float3 Up = abs(normal.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
	tanX = normalize(cross(Up, normal));
	tanY = normalize(cross(normal, tanX));
}

//Box -> AABB  
//Assuming InPoint lays inside the Box, otherwise returns a zero value 
float ComputeDistanceFromBoxToPointInside(float3 BoxCenter, float3 BoxExtent, float3 InPoint)
{
	float3 distFromMinSide = InPoint - (BoxCenter - BoxExtent);
	float3 distFromMaxSide = (BoxCenter + BoxExtent) - InPoint;
	float3 closestDist = min(distFromMinSide, distFromMaxSide); //per channel max 
	return max(0, min(closestDist.x, min(closestDist.y, closestDist.z))); 
}

float GetStepOffset(float StepIndex)
{
	float tmp = 0.5f * StepIndex;				//AOStepExponentScale=0.5
	return 0.01 * 2.91636 * (tmp * tmp + 1);	//AOStepScale=2.91636
}

float3 ComputeGlobalUV(float3 WorldPosition, uint ClipmapIndex)
{
	float4 WorldToUVAddAndScale = GlobalVolumeWorldToUVAddAndMul[ClipmapIndex];
	return WorldPosition * WorldToUVAddAndScale.www + WorldToUVAddAndScale.xyz;
}

float ConvertSampleSDFToRealDistance(float RawData, int ClipmapIndex)
{
	return RawData * GlobalVolumeCenterAndExtent[ClipmapIndex].w * 2; 
}

float SampleGlobalDistanceField(int ClipmapIndex, float3 UV)
{
	float rawDist = 0;
	if (ClipmapIndex == 0)
	{
		//rawDist = _GlobalDistanceFieldTexture0.SampleLevel(my_bilinear_clamp_sampler, UV, 0).r;
		rawDist = SAMPLE_TEXTURE2D_LOD(_GlobalDistanceFieldTexture0, my_bilinear_clamp_sampler, UV, 0).r;
	}
	else  
	{
		//rawDist = _GlobalDistanceFieldTexture1.SampleLevel(my_bilinear_clamp_sampler, UV, 0).r;
		rawDist = SAMPLE_TEXTURE2D_LOD(_GlobalDistanceFieldTexture1, my_bilinear_clamp_sampler, UV, 0).r;
	}

	return ConvertSampleSDFToRealDistance(rawDist, ClipmapIndex).x;
}

uint2 GridIndexToCoordination(uint GridIndex)
{
	return uint2(GridIndex % ScreenGridConeVisibilitySize.x, GridIndex / ScreenGridConeVisibilitySize.x);
}


//��֪ƽ�淽�̺Ͳ�����������ռ��е����꣬�����㵽ƽ�����̾��� -> PlaneDistance
//ʹ�ò������������Ϊ��һ�����ӣ��������㷵�ػ��ڡ����롱��Ȩ��
//��Ȩ�ؾ����������ԣ�
//1�����������Ŀ��ƽ��Խ����Ȩ��Խ��
//2�������������Խ��Ȩ��Խ�� 
float ComputeSampleWeightBasedOnPosition(float4 ReferencePlane, float2 SampleScreenUV, float SampleDeviceZDepth)
{
	float3 SampleWorldPosition = ComputeWorldSpacePosition(SampleScreenUV, SampleDeviceZDepth, UNITY_MATRIX_I_VP);
	float PlaneDistance = abs(dot(ReferencePlane, float4(SampleWorldPosition, 1)));

	float SampleSceneDepth = LinearEyeDepth(SampleDeviceZDepth, _ZBufferParams);
	const float Epsilon = 0.0001f;
	float RelativeDistance = 10.0f * PlaneDistance / SampleSceneDepth;
	return min(10.0f / (RelativeDistance + Epsilon), 1);  //-> min(SampleSceneDepth / (PlaneDistance + Epsilon), 1)
}


//����4�����ߣ����㷨����������֮��ĵ��
//����4�������������������ߵ����ƶ�(ͨ������������)
void GetNormalWeights(float2 UV, float2 TexelSize, float3 WorldNormal, out float4 NormalWeights)
{
	{
		float3 SampleWorldNormal; float Temp;
		GetNormalDepthGBuffer(UV, SampleWorldNormal, Temp); //���ڿհ�����SampleWorldNormal����0���Ӷ����¸÷���NormalWeightsҲΪ0 -> ����Ԥ��
		NormalWeights.x = dot(SampleWorldNormal, WorldNormal);
	}
	{
		float3 SampleWorldNormal; float Temp;
		GetNormalDepthGBuffer(UV + float2(TexelSize.x, 0), SampleWorldNormal, Temp);
		NormalWeights.y = dot(SampleWorldNormal, WorldNormal);
	}
	{
		float3 SampleWorldNormal; float Temp;
		GetNormalDepthGBuffer(UV + float2(0, TexelSize.y), SampleWorldNormal, Temp);
		NormalWeights.z = dot(SampleWorldNormal, WorldNormal);
	}
	{
		float3 SampleWorldNormal; float Temp;
		GetNormalDepthGBuffer(UV + TexelSize.xy, SampleWorldNormal, Temp);
		NormalWeights.w = dot(SampleWorldNormal, WorldNormal);
	}
	NormalWeights = max(NormalWeights, 0.0001f);
}


//input UVAndScreenPos ��Ӧ��ֱ���BufferSize 
void GeometryAwareUpsample(float4 UVAndScreenPos, out float4 OutBentNormal)
{
	float3 WorldNormal;
	float DeviceZ;
	GetNormalDepthGBuffer(UVAndScreenPos.xy, WorldNormal, DeviceZ);

	float3 WorldPosition = ComputeWorldSpacePosition(UVAndScreenPos.xy, DeviceZ, UNITY_MATRIX_I_VP); //ԭʼ�������Ӧ���������� -> shading point in world space

	//UV in ScreenGrid resolution, aligned at left down corner, aka min of uv equals 00
	float2 Corner00UV = floor((UVAndScreenPos.xy - DistanceFieldGBufferJitterOffset) * ScreenGridBufferAndTexelSize.xy) * ScreenGridBufferAndTexelSize.zw;

	//������һ��ScreenGridTexel�����ڲ�������Jitter���ԭʼUV��ȷ���Ĳ����㣬֮���������½�(Corner)�ľ��룬xy��ȡֵ��Χ��[0,1]
	float2 BilinearWeights = ((UVAndScreenPos.xy - DistanceFieldGBufferJitterOffset) - Corner00UV) * ScreenGridBufferAndTexelSize.xy;

	float2 LowResUV = Corner00UV + 0.5f * ScreenGridBufferAndTexelSize.zw; //����ScreenGridTexel�������ĵ��ĵͷֱ���UV

	//����4�������֣�-> ע�⣬���ܲ�����0ֵ -> ��Ӧ��Ⱦ����֮��Ĳ���������
	float4 Value00 = SAMPLE_TEXTURE2D_LOD(_CombinedDFBentNormal, my_point_clamp_sampler, LowResUV, 0);
	float4 Value10 = SAMPLE_TEXTURE2D_LOD(_CombinedDFBentNormal, my_point_clamp_sampler, LowResUV + float2(ScreenGridBufferAndTexelSize.z, 0), 0);
	float4 Value01 = SAMPLE_TEXTURE2D_LOD(_CombinedDFBentNormal, my_point_clamp_sampler, LowResUV + float2(0, ScreenGridBufferAndTexelSize.w), 0);
	float4 Value11 = SAMPLE_TEXTURE2D_LOD(_CombinedDFBentNormal, my_point_clamp_sampler, LowResUV + ScreenGridBufferAndTexelSize.zw, 0);

	//����UVƫ���ϵĵ���Ȩ��
	//��Ϊ������Jitter����������Ȼ�������ָ����С�ǣ����ǰ�ֱ��ʲ����㣨�߾���λ�ã���ʵ��������ܸ��ӿ���ĳһ�����أ�ͨ������UVWeights�ɵ��ڲ������ںϵ�Ȩ��
	float4 UVWeights = float4(
		(1 - BilinearWeights.y) * (1 - BilinearWeights.x), 	//��BilinearWeights.xy����Сʱ(jitter��ĵ�ǳ��ӽ�corner00UV)���������ָ����½ǲ���Ȩ��
		(1 - BilinearWeights.y) * BilinearWeights.x,		//��jitter���uv����V���򿿽�corner00UV������U����Զ��ʱ���������ָ����½�Ȩ�� 
		BilinearWeights.y * (1 - BilinearWeights.x), 		//�����߼�
		BilinearWeights.y * BilinearWeights.x
		);

	//����4�ܲ����㵽���Ĳ���������ƽ��ľ�������������Ȩ��
	//���䣺�˾�����ָ ÿ��������ת������������ �� ԭʼ����������ƽ��(����ռ�) �ľ���
	float4 DistWeights;
	float4 FourDepths = float4(Value00.w, Value10.w, Value01.w, Value11.w);	//ע�⣬�����ŵ���DeviceZDepth
	float4 ReferencePlane = float4(WorldNormal, -dot(WorldPosition, WorldNormal));  //��Ӧƽ�淽��ax+by+cz+d=0�е�abcd
	DistWeights.x = ComputeSampleWeightBasedOnPosition(ReferencePlane, LowResUV, FourDepths.x);
	DistWeights.y = ComputeSampleWeightBasedOnPosition(ReferencePlane, LowResUV + float2(ScreenGridBufferAndTexelSize.z, 0), FourDepths.y);
	DistWeights.z = ComputeSampleWeightBasedOnPosition(ReferencePlane, LowResUV + float2(0, ScreenGridBufferAndTexelSize.w), FourDepths.z);
	DistWeights.w = ComputeSampleWeightBasedOnPosition(ReferencePlane, LowResUV + ScreenGridBufferAndTexelSize.zw, FourDepths.w); 

	//�������ܷ��������ķ��ߵ����ƶ������Ȩ��
	float4 NormalWeights;
	float2 BaseLevelUV = UVAndScreenPos.xy;
	GetNormalWeights(BaseLevelUV, ScreenGridBufferAndTexelSize.zw, WorldNormal, NormalWeights);

	float4 FinalWeights = UVWeights * DistWeights * NormalWeights;

	float InvSafeWeight = 1.0f / max(dot(FinalWeights, 1), .00001f);

	float3 AverageBentNormal = 
			( FinalWeights.x * Value00.xyz
			+ FinalWeights.y * Value10.xyz
			+ FinalWeights.z * Value01.xyz
			+ FinalWeights.w * Value11.xyz )
		* InvSafeWeight;

	OutBentNormal = float4(AverageBentNormal, DeviceZ);

	float BentNormalLength = length(OutBentNormal.rgb);
	float3 NormalizedBentNormal = OutBentNormal.rgb / max(BentNormalLength, .0001f);
	OutBentNormal.rgb = NormalizedBentNormal * BentNormalLength;
}

float ComputeHistoryWeightBasedOnPosition(float2 UV, float DeviceZ, float2 OldUV, float OldDeviceZ)
{
	float3 WorldPosition = ComputeWorldSpacePosition(UV, DeviceZ, UNITY_MATRIX_I_VP);
	float3 OldWorldPosition = ComputeWorldSpacePosition(OldUV, OldDeviceZ, _PrevInvViewProjMatrix); 

	float DistanceToHistoryValue = length(OldWorldPosition - WorldPosition);

	const float HistoryDistanceThreshold = 30;
	float RelativeHistoryDistanceThreshold = HistoryDistanceThreshold / 10.0f;

	float SceneDepth = LinearEyeDepth(DeviceZ, _ZBufferParams);

	return DistanceToHistoryValue / SceneDepth > RelativeHistoryDistanceThreshold ? 0.0f : 1.0f;
}
