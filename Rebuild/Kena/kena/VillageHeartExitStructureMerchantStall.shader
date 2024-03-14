Shader "UE/MRT/VillageHeartExitStructureMerchantStall"
{
    Properties
    {
        _Albedo("Albedo", 2D) = "white" {}
        _Tiling_UV("Tiling_UV", Range(-5, 5)) = 1
        _Color_Intensity("Color_Intensity", Range(0.1, 5)) = 1
        _Color_Overlay("Color_Overlay", Color) = (1, 1, 1, 1)

        [NoScaleOffset] _Normal("Normal", 2D) = "white" {}
        [NoScaleOffset] _Comp_M_R_Ao("Comp_M_R_Ao", 2D) = "white" {}

        _NormalMult("Normal Mult", Vector) = (0, 0, 0, 0)

        _Roughness_Intensty("Roughness", Range(0, 1)) = 1
        _Metallic("Metallic", Range(0, 1)) = 0
        _Specular_Intensity("Specular", Range(0, 1)) = 0.2
        _Desaturate("Desaturate", Range(0, 1)) = 0

        _Emissive_Color("Emissive_Color", Color) = (0, 0, 0, 1)
        _EmissiveAmount("EmissiveAmount", Range(0, 1)) = 0

        _GlobalRoughnessScaler("Global Roughness Scaler", Range(0, 2)) = 1
        _GlobalRoughnessBias("Global Roughness Bias", Range(0, 2)) = 0
        _GlobalBaseColorScaler("Global Base Color Scaler", Range(0, 2)) = 1
        _GlobalBaseColorBias("Global Base Color Bias", Range(0, 2)) = 0
        _GlobalSpecularColorScaler("Global Specular Color Scaler", Range(0, 2)) = 1
        _GlobalSpecularColorBias("Global Specular ColorBias", Range(0, 2)) = 0
        _GlobalNormalScaler("Global Normal Scaler", Range(0, 2)) = 1
        _GlobalNormalBias("Global Normal Bias", Range(0, 2)) = 0
        _GlobalRelectionAmount("Global Relection Amount", Range(0, 2)) = 0

        [Toggle]_RenderingReflectionCaptureMask("RenderingReflectionCaptureMask", float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {

            Name "GBuffer VillageHeartExitStructureMerchantStall"
            Tags { "LightMode" = "UniversalGBuffer" }

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Deferred.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Assets/Art/MRTAssets/MRTInclude.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 NormalOS : NORMAL;
                float4 TangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //float3 PosWS : TEXCOORD2;
                float4 vertex : SV_POSITION;
                float4 NormalWS : TEXCOORD3;
                float4 TangentWS : TEXCOORD4;
                float4 BitangentWS : TEXCOORD5;
            };

            SamplerState my_bilinear_repeat_sampler;

            TEXTURE2D(_Albedo);
            TEXTURE2D(_Normal);
            TEXTURE2D(_Comp_M_R_Ao);

            CBUFFER_START(UnityPerMaterial)
                float4 _Albedo_ST;
                float4 _Color_Overlay;
                float4 _Emissive_Color;
                float4 _NormalMult;

                float _Tiling_UV;

                float _Roughness_Intensty;
                float _Specular_Intensity;
                float _Metallic;
                float _Desaturate;
                float _Color_Intensity;
                float _EmissiveAmount;

                float _GlobalRoughnessScaler;
                float _GlobalRoughnessBias;
                float _GlobalBaseColorScaler;
                float _GlobalBaseColorBias;
                float _GlobalSpecularColorScaler;
                float _GlobalSpecularColorBias;
                float _GlobalNormalScaler;
                float _GlobalNormalBias;
                float _GlobalRelectionAmount;

                float _RenderingReflectionCaptureMask;
            CBUFFER_END

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _Albedo);

                VertexNormalInputs tbn = GetVertexNormalInputsUE(v.NormalOS.xyz, v.TangentOS.xyzw);
                o.NormalWS.xyz = tbn.normalWS;
                o.TangentWS.xyz = tbn.tangentWS;
                o.BitangentWS.xyz = tbn.bitangentWS;

                //o.PosWS = TransformObjectToWorld(v.vertex.xyz);  //TODO: 将平移变换挪出去，在PS中执行 
                return o;
            }

            mrtOut frag(v2f i)
            {
                mrtOut outCols = (mrtOut)0;
                float2 uv = i.uv * _Albedo_ST.xy + _Albedo_ST.zw;
                uv *= _Tiling_UV;

                //Normal
                half3 nTS = UE_UnpackNormalNoNormalize_Fix(SAMPLE_TEXTURE2D(_Normal, my_bilinear_repeat_sampler, uv));
                nTS = nTS * _NormalMult + nTS;
                nTS = nTS * _GlobalNormalScaler + _GlobalNormalBias;
                half3x3 tbn = half3x3(i.TangentWS.xyz, i.BitangentWS.xyz, i.NormalWS.xyz);
                half3 nDirWS = normalize(mul(nTS, tbn));

                //Emittion
                half3 EmitCol = _Emissive_Color * _EmissiveAmount;

                //Base Color
                half3 dBase = SAMPLE_TEXTURE2D(_Albedo, my_bilinear_repeat_sampler, uv).rgb;
                dBase = dBase * _Color_Intensity * _Color_Overlay.rgb;
                dBase = lerp(dBase, Luminance(dBase), _Desaturate);

                //M R D baseAO -> 注意，输入纹理实际通道对应如下: Comp_M_R_Ao
                half3 Ao_M_R = SAMPLE_TEXTURE2D(_Comp_M_R_Ao, my_bilinear_repeat_sampler, uv).zxy;
                half Metallic = saturate(Ao_M_R.y * _Metallic);
                half Roughness = saturate(Ao_M_R.z * _Roughness_Intensty) * _GlobalRoughnessScaler + _GlobalRoughnessBias;
                half Specular = saturate(_Specular_Intensity);
                half baseAO = saturate(Ao_M_R.x);

                //AO
                half3 SpecCol = ComputeF0(Specular, dBase, Metallic);
                SpecCol = SpecCol * _GlobalSpecularColorScaler + _GlobalSpecularColorBias;
                half3 BaseCol = dBase * (1 - Metallic);
                BaseCol = BaseCol * _GlobalBaseColorScaler + _GlobalBaseColorBias;
                bool RenderingReflectionCaptureMask = _RenderingReflectionCaptureMask > 0;
                [branch]
                if (RenderingReflectionCaptureMask)
                {
                    EnvBRDFApproxFullyRough(BaseCol, SpecCol);
                }
                half FinalAO = AOMultiBounce(Luminance(SpecCol), baseAO).r;

                //Base RT Color = ReflectCol + EmitCol
                EnvBRDFApproxFullyRough(BaseCol, SpecCol);
                half3 ReflectCol = BaseCol * _GlobalRelectionAmount;
                half3 BaseRTCol = ReflectCol + max(EmitCol.rgb, 0);  //ReflectCol + EmitCol

                //Final output
                FillMrtOutput(outCols, half4(0, 0, 0, 0), dBase, nDirWS, BaseRTCol, i.vertex.z, FinalAO,
                    Metallic, Specular, Roughness, 177.0f, 1.0f / 3.0f);
                return outCols;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            // Universal Pipeline keywords
            #pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask R
            Cull Back

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}
