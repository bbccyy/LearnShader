Shader "Custom/Subsurface"
{
    HLSLINCLUDE
#pragma exclude_renderers gles
#pragma exclude_renderers gles
#pragma target 3.5

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

    struct SDiffuseAndSpecular
    {
        float3 Diffuse;
        float3 Specular;
    };

    static float4 InvDeviceZToWorldZTransform = float4(0.00, 0.00, 0.10, -1.00000E-08);
    static float4 View_BufferSizeAndInvSize = float4(1708.00, 960.00, 0.00059, 0.00104);
    static float4 SubsurfaceInput0_ExtentInverse = float4(0, 0, 0.00059, 0.00104);
    static float4 SubsurfaceInput0_UVViewportBilinearMax = float4(1.00, 1.00, 0.99912, 0.99948);

    SamplerState my_point_clamp_sampler;
    TEXTURE2D_X_HALF(_GBuffer0);    //Albedo
    TEXTURE2D_X_HALF(_GBuffer1);    //Comp_M_D_R_F 
    TEXTURE2D_X_HALF(_GBuffer4);    //Depth 


//@ShadingCommon 
#define SHADINGMODELID_UNLIT				0
#define SHADINGMODELID_SUBSURFACE			2
#define SHADINGMODELID_PREINTEGRATED_SKIN	3
#define SHADINGMODELID_SUBSURFACE_PROFILE	5
#define SHADINGMODELID_EYE					9
#define SHADINGMODELID_MASK					0xF		// 4 bits reserved for ShadingModelID 

    bool UseSubsurfaceProfile(int ShadingModel)
    {
        return ShadingModel == SHADINGMODELID_SUBSURFACE_PROFILE || ShadingModel == SHADINGMODELID_EYE;
    }

    float ConvertFromDeviceZ(float DeviceZ)
    {
        // Supports ortho and perspective, see CreateInvDeviceZToWorldZTransform()
        return DeviceZ * InvDeviceZToWorldZTransform[0] + InvDeviceZToWorldZTransform[1] + 1.0f / (DeviceZ * InvDeviceZToWorldZTransform[2] - InvDeviceZToWorldZTransform[3]);
    }

    float CalcSceneDepth(float2 ScreenUV)
    {
        return ConvertFromDeviceZ(SAMPLE_TEXTURE2D_X_LOD(_GBuffer4, my_point_clamp_sampler, ScreenUV, 0).r);
    }

    float4 GatherSceneDepth(float2 UV, float2 InvBufferSize)
    {
        float2 TexelScale = 0.5f * InvBufferSize;
        return float4(
            CalcSceneDepth(UV + (float2(-1, 1) * TexelScale)),
            CalcSceneDepth(UV + (float2(1, 1) * TexelScale)),
            CalcSceneDepth(UV + (float2(1, -1) * TexelScale)),
            CalcSceneDepth(UV + (float2(-1, -1) * TexelScale))
            );
    }

    // can be moved/shared
    half3 LookupSceneColor(float2 SceneUV, half2 PixelOffset)
    {
        // faster
        //return SubsurfaceInput0_Texture.SampleLevel(SharedSubsurfaceSampler0, SceneUV, 0, PixelOffset).rgb;
        return SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, SceneUV + PixelOffset * View_BufferSizeAndInvSize.zw).rgb;
    }

    bool CheckerFromSceneColorUV(float2 UVSceneColor)
    {
        // relative to left top of the rendertarget (not viewport)
        uint2 PixelPos = uint2(UVSceneColor * View_BufferSizeAndInvSize.xy);
        uint TemporalAASampleIndex = 3;
        return (PixelPos.x + PixelPos.y + TemporalAASampleIndex) & 1;
    }

    SDiffuseAndSpecular ReconstructLighting(float2 UVSceneColor)
    {
        SDiffuseAndSpecular Ret = (SDiffuseAndSpecular)0;

        bool bChecker = CheckerFromSceneColorUV(UVSceneColor);
        
        half3 Quant0 = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, UVSceneColor).rgb;

        half3 Quant1 = 0.5f * (
            LookupSceneColor(UVSceneColor, half2(1, 0)) +
            LookupSceneColor(UVSceneColor, half2(-1, 0)));

        Ret.Diffuse = lerp(Quant1, Quant0, bChecker);
        Ret.Specular = lerp(Quant0, Quant1, bChecker);
        return Ret;
    }


    // @param UVSceneColor for the full res rendertarget (BufferSize) e.g. SceneColor or GBuffers
    // @return .RGB Color that should be scattared, .A:1 for subsurface scattering material, 0 for not
    float4 SetupSubsurfaceForOnePixel(float2 UVSceneColor)
    {
        float4 Ret = 0;

        half packedChannel = SAMPLE_TEXTURE2D_X_LOD(_GBuffer1, my_point_clamp_sampler, UVSceneColor, 0).a;
        uint ShadingModelID = ((uint)round(packedChannel * (float)0xFF)) & SHADINGMODELID_MASK;

        UNITY_BRANCH 
        if (UseSubsurfaceProfile(ShadingModelID))
        {

            SDiffuseAndSpecular DiffuseAndSpecular = ReconstructLighting(UVSceneColor);

            Ret.rgb = DiffuseAndSpecular.Diffuse;

            // it's a valid sample
            Ret.a = 1;
        }

        return Ret;
    }


    half4 FragSubsurface(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        float2 BufferUV = UnityStereoTransformScreenSpaceTex(input.texcoord);
        
        half4 InColor = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, BufferUV).xyzw;

        half packedChannel = SAMPLE_TEXTURE2D_X_LOD(_GBuffer1, my_point_clamp_sampler, BufferUV, 0).a;
        uint ShadingModelID = ((uint)round(packedChannel * (float)0xFF)) & SHADINGMODELID_MASK;

        //TODO: 原式中offset分量为float(±0.5f，±0.5f),但是输出效果仍然有棋盘状形态，修改为±1就能解决问题，是原式错了么? 
        float4 A = SetupSubsurfaceForOnePixel(min(BufferUV + float2(-1, 1) * SubsurfaceInput0_ExtentInverse.zw, SubsurfaceInput0_UVViewportBilinearMax.zw));
        float4 B = SetupSubsurfaceForOnePixel(min(BufferUV + float2(1, 1) * SubsurfaceInput0_ExtentInverse.zw, SubsurfaceInput0_UVViewportBilinearMax.zw));
        float4 C = SetupSubsurfaceForOnePixel(min(BufferUV + float2(1, -1) * SubsurfaceInput0_ExtentInverse.zw, SubsurfaceInput0_UVViewportBilinearMax.zw));
        float4 D = SetupSubsurfaceForOnePixel(min(BufferUV + float2(-1, -1) * SubsurfaceInput0_ExtentInverse.zw, SubsurfaceInput0_UVViewportBilinearMax.zw));

        float4 Sum = (A + B) + (C + D);

        float Div = 1.0f / max(Sum.a, 0.00001f);
        float4 OutColor = 0;
        OutColor.rgb = Sum.rgb * Div;

        float4 FourDepth = GatherSceneDepth(BufferUV, SubsurfaceInput0_ExtentInverse);

        half3 albedo = SAMPLE_TEXTURE2D_X_LOD(_GBuffer0, my_point_clamp_sampler, BufferUV, 0).rgb;

        float SingleDepth = dot(FourDepth, float4(A.a, B.a, C.a, D.a)) * Div;

        OutColor.a = SingleDepth;

        if (UseSubsurfaceProfile(ShadingModelID) == false)
        {
            OutColor = InColor;
        }
        else
        {
            OutColor.rgb *= albedo;
        }

        return OutColor;
    }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "Subsurface"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragSubsurface
            ENDHLSL
        }
    }
}
