
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

uniform Texture2D<float4> _NormalDepth;		// the output RT of ComputeDistanceFieldNormalPS 

Texture3D<half> _GlobalDistanceFieldTexture0; 
Texture3D<half> _GlobalDistanceFieldTexture1; 

RWBuffer<uint> RWScreenGridConeVisibility; 

float4 View_BufferSizeAndInvSize;	//[1708, 960, 1/1708, 1/960]
float4 View_ScreenPositionScaleBias; //[0.5, +-0.5, 0.5, 0.5] 

uint2 ScreenGridConeVisibilitySize;  //213,120
float2 JitterOffset;
float2 BaseLevelTexelSize;

float4 GlobalVolumeCenterAndExtent[2];		//float array 
float4 GlobalVolumeWorldToUVAddAndMul[2]; 
float2 AOGlobalMaxOcclusionDistanceAndInv;
float GlobalVolumeTexelSize;

float TanConeHalfAngle;

float4 AOSamples2_SampleDirections[NUM_CONE_DIRECTIONS];

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

//通过传入的ConeTracingGridCoordinate（大约200x100）的分辨率，映射到用于存放最终BentNormal贴图的分辨率，大约854x480
//期间经过Jitter（像素级偏移）以及0.5像素的Offset，最后通过乘以对应像素尺寸（基于UV的尺寸：1/854, 1/480），映射回屏幕UV 
float2 GetBaseLevelScreenUVFromScreenGrid(uint2 OutputCoordinate, float JitterScale) //input: DispatchThreadId.xy, 1 
{
	float2 BaseLevelScreenUV = (OutputCoordinate * TRACE_DOWNSAMPLE_FACTOR + JitterOffset * JitterScale + float2(.5f, .5f)) * BaseLevelTexelSize; 
	return BaseLevelScreenUV;
}

float2 GetBaseLevelScreenUVFromScreenGrid(uint2 OutputCoordinate)
{
	return GetBaseLevelScreenUVFromScreenGrid(OutputCoordinate, 1);
}

//通过传入的ConeTracingGridCoordinate（大约200x100）的分辨率，映射到屏幕分辨率（1708x960），
//期间经过Jitter（像素级偏移）以及0.5像素的Offset，最后通过乘以像素尺寸（基于UV的尺寸；1/1708,1/960），映射回屏幕UV 
float2 GetFullResUVFromBufferGrid(uint2 PixelCoordinate, float JitterScale = 1.0f)
{
	float2 ScreenUV = ((PixelCoordinate * TRACE_DOWNSAMPLE_FACTOR + JitterOffset * JitterScale) * AO_DOWNSAMPLE_FACTOR + float2(.5f, .5f)) * View_BufferSizeAndInvSize.zw;
	return ScreenUV;
}

//Return Wolrd Normal and DeviceZ Depth 
void GetNormalDepthGBuffer(float2 UV, out float3 Norm, out float Depth)
{
	float4 norm_depth = _NormalDepth.Sample(my_point_clamp_sampler, UV);
	Norm = norm_depth.xyz;
	Depth = norm_depth.w;
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
		rawDist = _GlobalDistanceFieldTexture0.Sample(my_bilinear_clamp_sampler, UV).r;
	}
	else  
	{
		rawDist = _GlobalDistanceFieldTexture1.Sample(my_bilinear_clamp_sampler, UV).r;
	}

	return ConvertSampleSDFToRealDistance(rawDist, ClipmapIndex).x;
}