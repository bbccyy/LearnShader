Shader "Custom/FullScreenMRT"
{
    Properties
    {
        [NoScaleOffset] _Albedo("Albedo", 2D) = "white" {}
        [NoScaleOffset] _Depth("Depth", 2D) = "white" {}
        [NoScaleOffset] _Comp_F_R_X_I("Comp_F_R_X_I", 2D) = "white" {}
        [NoScaleOffset] _Comp_M_D_R_F("Comp_M_D_R_F", 2D) = "white" {}
        [NoScaleOffset] _Normal("Normal", 2D) = "white" {}

        [NoScaleOffset] _SSR("SSR", 2D) = "white" {}  //ScreenSpaceReflectionsTexture -> 可以放到Emission中 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "FullScreenGBufferPass"
            Tags { "LightMode" = "UniversalGBuffer" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Deferred.hlsl"

            struct mrtOut
            {
                float4 o0_BaseColor_AO :    SV_Target0;     //RGBA32          Albedo_RGB_AO_A
                float4 o1_Mask :            SV_Target1;     //RGBA32          Comp_M_D_R_F
                float4 o2_Normal_Flag :     SV_Target2;     //RGB10A2         Normal_RGB
                float4 o3_Emission :        SV_Target3;     //RGBA32          ColorAttachment  
                float  o4_Depth :           SV_Target4;     //R32             Depth
                float4 o5_Additionals :     SV_Target5;     //RGBA32          Comp_Custom_F_R_X_I 
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D_X_FLOAT(_Depth); SAMPLER(sampler_Depth);

            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_Comp_M_D_R_F); SAMPLER(sampler_Comp_M_D_R_F);
            TEXTURE2D(_Comp_F_R_X_I); SAMPLER(sampler_Comp_F_R_X_I);

            TEXTURE2D(_SSR); SAMPLER(sampler_SSR);

            v2f vert (appdata v)
            {
                v2f o;

                //o.vertex = TransformObjectToHClip(v.vertex); //默认方法 
                o.vertex = float4(v.vertex.xy * 2 * float2(1, -1), 0.1, 1); //正确 -> 但是需要配合输入模型=Quad 
                //o.vertex = float4(v.vertex.xy * 2, 0.1, 1);  //这会导致三角形反向，需配合Cull Front来使用，且上下是颠倒的 
                o.uv = v.uv;
                return o;
            }

            mrtOut frag (v2f i) : SV_Target
            {
                mrtOut outCols;
                
                // sample the texture
                float2 UV = i.uv;
                outCols.o0_BaseColor_AO = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, UV);
                outCols.o1_Mask = SAMPLE_TEXTURE2D(_Comp_M_D_R_F, sampler_Comp_M_D_R_F, UV);
                outCols.o2_Normal_Flag = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, UV);
                
                outCols.o3_Emission = SAMPLE_TEXTURE2D(_SSR, sampler_SSR, UV);     //将输出到ColorAttachment 
                outCols.o4_Depth = SAMPLE_TEXTURE2D(_Depth, sampler_Depth, UV).r;
                outCols.o5_Additionals = SAMPLE_TEXTURE2D(_Comp_F_R_X_I, sampler_Comp_F_R_X_I, UV);

                //outCols.o4_Depth.x = pow(outCols.o4_Depth.x, 1);

                //TODO: 调研何为如下一些纹理的rgb通道输入纹理与原始纹理数值不匹配！ 
                //outCols.o2_Normal_Flag.xyz = pow(outCols.o2_Normal_Flag.xyz, 2.2);
                //outCols.o0_BaseColor_AO.xyz = pow(outCols.o0_BaseColor_AO.xyz, 1);
                //outCols.o1_Mask.xyz = pow(outCols.o1_Mask.xyz, 1); 
                //outCols.o5_Additionals.xyz = pow(outCols.o5_Additionals.xyz, 1.5);

                return outCols;
            }
            ENDHLSL
        }
    }
}
