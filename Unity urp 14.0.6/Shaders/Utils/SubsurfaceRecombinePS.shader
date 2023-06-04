Shader "Custom/SubsurfaceRecombinePS"
{
    Properties
    {
    }

    HLSLINCLUDE
#pragma exclude_renderers gles
#pragma exclude_renderers gles
#pragma target 3.5

    uniform float4 SubsurfaceParams;        //[0.18515, 1.11089, 0.00, 0.00] -> cb0_v27 
    uniform float4 Input_ExtentInverse;     //[pixelSizeX, pixelSizeY, 1/pixelSizeX, 1/pixelSizeY] -> half res 

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

    SamplerState my_point_clamp_sampler;
    SamplerState my_bilinear_clamp_sampler;

    TEXTURE2D_X_HALF(_GBuffer0);        //Albedo 
    TEXTURE2D_X_HALF(_GBuffer1);        //Comp_M_D_R_F 
    TEXTURE2D_X_HALF(_GBuffer2);        //Normal 

    TEXTURE2D_X_FLOAT(_GBuffer4);        //Depth 
    TEXTURE2D_X_HALF(_GBuffer5);         //Comp_Custom_F_R_X_I 

    TEXTURE2D_X_FLOAT(SubsurfaceInput1_Texture); //R16G16B16A16 subsurface texture  
    TEXTURE2D(_LUT); 

#include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/KenaDeferredCommon.hlsl"

static const int SUBSURFACE_RADIUS_SCALE = 1024;
#define	SSSS_N_KERNELWEIGHTCOUNT    6 
#define	SSSS_N_KERNELWEIGHTOFFSET  28

#define SSSS_SUBSURFACE_COLOR_OFFSET    0 
#define SUBSURFACE_KERNEL_SIZE  3 

    struct FScreenSpaceData
    {
        // GBuffer (material attributes from forward rendering pass)
        FGBufferData GBuffer;
        // 0..1, only valid in some passes, 1 if off
        float AmbientOcclusion;
    };

    struct SDiffuseAndSpecular
    {
        float3 Diffuse;
        float3 Specular;
    };

    FScreenSpaceData GetScreenSpaceData(float2 UV, bool bGetNormalizedNormal = true)
    {
        FScreenSpaceData Out = (FScreenSpaceData)0;

        Out.GBuffer = GetGBufferData(UV, bGetNormalizedNormal);
        Out.AmbientOcclusion = SAMPLE_TEXTURE2D(_SSAO, sampler_SSAO, UV).r;

        return Out;
    }

    float CalcSceneDepth(float2 ScreenUV)
    {
        return ConvertFromDeviceZ(_GBuffer4.SampleLevel(my_point_clamp_sampler, ScreenUV, 0).r);
    }

    // @return .rgb is the weight for color channel, .a is the sample location
    float4 GetSubsurfaceProfileKernel(uint SampleIndex, uint SubsurfaceProfileInt)
    {
        const float4 TableMax = float4(1, 1, 1, SUBSURFACE_KERNEL_SIZE);

        return _LUT.Load(int3(SampleIndex, 64 - SubsurfaceProfileInt, 0)) * TableMax;
    }

    float3 GetSubsurfaceProfileColor(FGBufferData GBufferData)
    {
        // 0..255, which SubSurface profile to pick
        uint SubsurfaceProfileInt = ExtractSubsurfaceProfileInt(GBufferData);

        return GetSubsurfaceProfileKernel(SSSS_SUBSURFACE_COLOR_OFFSET, SubsurfaceProfileInt).rgb;
    }

    float GetSubsurfaceProfileRadiusScale(FGBufferData GBufferData)
    {
        // 0..255, which SubSurface profile to pick
        uint SubsurfaceProfileInt = ExtractSubsurfaceProfileInt(GBufferData);

        return GetSubsurfaceProfileKernel(SSSS_N_KERNELWEIGHTOFFSET + SSSS_N_KERNELWEIGHTCOUNT - 1, SubsurfaceProfileInt).a;
    }

    // @return 0=don't blend in, 1:fully blend in
    float ComputeFullResLerp(FScreenSpaceData ScreenSpaceData, float2 UVSceneColor, float4 Input_ExtentInverse)
    {
        float SSSScaleX = SubsurfaceParams.x;

        float scale = SSSScaleX / CalcSceneDepth(UVSceneColor);

        float HorizontalScaler = SUBSURFACE_RADIUS_SCALE;

        // Calculate the final step to fetch the surrounding pixels:
        float finalStep = scale * HorizontalScaler;

        finalStep *= GetSubsurfaceProfileRadiusScale(ScreenSpaceData.GBuffer);

        float PixelSizeRadius = finalStep / (Input_ExtentInverse.z * 0.5f);

        // tweaked for skin, a more flat kernel might need a smaller value, around 2 seems reasonable because we do half res
        const float PixelSize = 4.0f;

        float Ret = saturate(PixelSizeRadius - PixelSize);

        // opacity allows to scale the radius - at some point we should fade in the full resolution, we don't have a masking other than that.
        Ret *= saturate(ScreenSpaceData.GBuffer.CustomData.a * 10);

        // todo: Subsurface has some non scatter contribution - all that should come from the Full res
        return Ret;
    }

    // can be moved/shared
    half3 LookupSceneColor(float2 SceneUV, half2 PixelOffset)
    {
        // faster
        //return SubsurfaceInput0_Texture.SampleLevel(SharedSubsurfaceSampler0, SceneUV, 0, PixelOffset).rgb;
        return SAMPLE_TEXTURE2D_X(_BlitTexture, my_point_clamp_sampler, SceneUV + PixelOffset * View_BufferSizeAndInvSize.zw).rgb;
    }

    SDiffuseAndSpecular ReconstructLighting(float2 UVSceneColor)
    {
        SDiffuseAndSpecular Ret = (SDiffuseAndSpecular)0;

        bool bChecker = CheckerFromSceneColorUV(UVSceneColor); //set _ScreenParams -> View_BufferSizeAndInvSize in C# first 

        half3 Quant0 = SAMPLE_TEXTURE2D_X(_BlitTexture, my_point_clamp_sampler, UVSceneColor).rgb; 

        half3 Quant1 = 0.5f * (
            LookupSceneColor(UVSceneColor, half2(1, 0)) +
            LookupSceneColor(UVSceneColor, half2(-1, 0)));

        Ret.Diffuse = lerp(Quant1, Quant0, bChecker);
        Ret.Specular = lerp(Quant0, Quant1, bChecker);
        return Ret;
    }


    half4 FragSubsurfaceRecombine(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        float2 BufferUV = UnityStereoTransformScreenSpaceTex(input.texcoord);

        FScreenSpaceData ScreenSpaceData = GetScreenSpaceData(BufferUV);

        if (!UseSubsurfaceProfile(ScreenSpaceData.GBuffer.ShadingModelID))
        {
            half4 InColor = SAMPLE_TEXTURE2D_X(_BlitTexture, my_point_clamp_sampler, BufferUV).rgba; //��������ColorAttachment 
            return InColor;
        }

        float3 SSSColor = float3(0, 0, 0);
        float LerpFactor = 1;

        // fade out subsurface scattering if radius is too small to be more crips (not blend with half resolution)
        // minor quality improvement (faces are more detailed in distance)
        LerpFactor = ComputeFullResLerp(ScreenSpaceData, BufferUV, Input_ExtentInverse); 

        float4 SSSColorWithAlpha = SAMPLE_TEXTURE2D_X(SubsurfaceInput1_Texture, my_bilinear_clamp_sampler, BufferUV).rgba; 

        // renormalize to dilate RGB to fix half res upsampling artifacts
        SSSColor = 1.0f * SSSColorWithAlpha.rgb / max(SSSColorWithAlpha.a, 0.00001f);

        // we multiply the base color later in to get more crips human skin textures (scanned data always has Subsurface included)
        float3 StoredBaseColor = ScreenSpaceData.GBuffer.StoredBaseColor;
        float StoredSpecular = ScreenSpaceData.GBuffer.StoredSpecular;

        SDiffuseAndSpecular DiffuseAndSpecular = ReconstructLighting(BufferUV);

        float3 ExtractedNonSubsurface = DiffuseAndSpecular.Specular;

        // asset specific color
        float3 SubsurfaceColor = GetSubsurfaceProfileColor(ScreenSpaceData.GBuffer);

        float3 FadedSubsurfaceColor = SubsurfaceColor * LerpFactor;

        // combine potentially half res with full res
        float3 SubsurfaceLighting = lerp(DiffuseAndSpecular.Diffuse, SSSColor, FadedSubsurfaceColor);

        return float4(SubsurfaceLighting * StoredBaseColor + ExtractedNonSubsurface, 0); 
    }


    ENDHLSL

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "SubsurfaceRecombinePS" 

            HLSLPROGRAM
            #pragma vertex Vert 
            #pragma fragment FragSubsurfaceRecombine 
            ENDHLSL
        }
    }
}
