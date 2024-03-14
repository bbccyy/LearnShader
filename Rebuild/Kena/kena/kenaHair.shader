Shader "UE/MRT/KenaHair"
{
    Properties
    {
        _Albedo("Root", 2D) = "white" {}                                        //hair_ROOT
        _Tiling_UV("Tiling_UV", Range(-5, 5)) = 1
        _Noisetiling("Noisetiling", Range(0.1, 25)) = 24

        [NoScaleOffset] _Depth("Hair Depth", 2D) = "white" {}                   //hair_DEPTH
        [NoScaleOffset] _Alpha("Hair Alpha", 2D) = "white" {}                   //hair_ALPHA
        [NoScaleOffset] _Unique_Hair_Value("Unique_Hair_Value", 2D) = "white" {}//hair_DEPTH
        [NoScaleOffset] _NoiseTex("Noise Tex", 2D) = "white" {}                 //Noise_cloudsmed
        [NoScaleOffset] _NoiseTilingTex("Noise Tiling Tex", 2D) = "white" {}    //Good64x64TilingNoiseHighFreq

        _Brightness("Brightness", Range(0, 1)) = 0
        _WetA("Wet A", float) = 0
        _WetB("Wet B", float) = 0
        _MaxWet("MaxWet", float) = 0.7
        _WetLength("WetLength", float) = 0

        _Roughness("Roughness", Range(0, 1)) = 0.35
        _DyeRoughness("DyeRoughness", Range(0, 1)) = 0.5
        _Scatter("Scatter", Range(0, 1)) = 0.36127
        _Spec("Spec", Range(0, 1)) = 0.2
    
        //_Fringe("Fringe", float) = 2
        //_MipBias("MipBias", float) = -1
        _TipPower("TipPower", float) = 1
        _OcclusionAmtRootTip("OcclusionAmtRootTip", float) = 0.8
        _OcclusionAmtRoot("OcclusionAmtRoot", float) = 0

        _Emissive_Color("Emissive_Color", Color) = (0, 0, 0, 1)
        _EmissiveAmount("EmissiveAmount", Range(0, 1)) = 0
        _DissolveAmount("DissolveAmount", Range(0, 1)) = 0
        _EmissiveBlend("EmissiveBlend", Range(0, 1)) = 0

        _Tangent("Tangent", Vector) = (0, 0, 1, 0)         //对应UE4 (0,-1,0)
        _TangentA("TangentA", Vector) = (0, 0.3, 0, 0)     //对应UE4 (0, 0, 0.3)
        _TangentB("TangentB", Vector) = (0, -0.3, 0, 0)    //对应UE4 (0, 0, -0.3)

        _RandomValueVariation("Random Value Variation", float) = 0
        _DissolveEmissiveAmount("DissolveEmissiveAmount", float) = 50
        _PixelDepthOffset("PixelDepthOffset", float) = 1

        _GlowColor("Glow Color", Color) = (0, 0.5, 1, 1)
        _EmissiveTint("EmissiveTint", Color) = (0, 0, 0, 1)
        _TipColor("TipColor", Color) = (0.020897, 0.028864, 0.045139, 1)
        _RootColor("RootColor", Color) = (0.011024, 0.012202, 0.020833, 1)

        _GlobalRoughnessScaler("Global Roughness Scaler", Range(0, 2)) = 1
        _GlobalRoughnessBias("Global Roughness Bias", Range(0, 2)) = 0
        _GlobalBaseColorScaler("Global Base Color Scaler", Range(0, 2)) = 1
        _GlobalBaseColorBias("Global Base Color Bias", Range(0, 2)) = 0
        _GlobalSpecularColorScaler("Global Specular Color Scaler", Range(0, 2)) = 1
        _GlobalSpecularColorBias("Global Specular ColorBias", Range(0, 2)) = 0
        _GlobalNormalScaler("Global Normal Scaler", Range(0, 2)) = 1
        _GlobalNormalBias("Global Normal Bias", Range(0, 2)) = 0
        _GlobalRelectionAmount("Global Relection Amount", Range(0, 2)) = 0
        _GlobalBouncingColorIntensity("Global Bouncing Color Intensity", float) = 1

        [Toggle]_RenderingReflectionCaptureMask("RenderingReflectionCaptureMask", float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {

            Name "GBuffer KenaHair"
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
                float3 PosWS : TEXCOORD2;
                float4 vertex : SV_POSITION;
                float4 NormalWS : TEXCOORD3;
                float4 TangentWS : TEXCOORD4;
                float4 BitangentWS : TEXCOORD5;
            };

            SamplerState my_bilinear_repeat_sampler;

            TEXTURE2D(_Albedo);
            TEXTURE2D(_Depth);
            TEXTURE2D(_Alpha);
            TEXTURE2D(_Unique_Hair_Value);
            TEXTURE2D(_NoiseTex);
            TEXTURE2D(_NoiseTilingTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Albedo_ST;
                float4 _Emissive_Color;
                float4 _GlowColor;
                float4 _EmissiveTint;
                float4 _TipColor;
                float4 _RootColor;

                float4 _Tangent;
                float4 _TangentA;
                float4 _TangentB;

                float _Tiling_UV;
                float _Noisetiling;

                float _Brightness;
                float _WetA;
                float _WetB;
                float _MaxWet;
                float _WetLength;

                float _Roughness;
                float _DyeRoughness;
                float _Scatter;
                float _Spec;

                //float _Fringe;
                //float _MipBias;
                float _TipPower;
                float _OcclusionAmtRootTip;
                float _OcclusionAmtRoot;

                float _EmissiveAmount;
                float _EmissiveBlend;
                float _DissolveAmount;
                float _RandomValueVariation;
                float _DissolveEmissiveAmount;
                float _PixelDepthOffset;

                float _GlobalRoughnessScaler;
                float _GlobalRoughnessBias;
                float _GlobalBaseColorScaler;
                float _GlobalBaseColorBias;
                float _GlobalSpecularColorScaler;
                float _GlobalSpecularColorBias;
                float _GlobalNormalScaler;
                float _GlobalNormalBias;
                float _GlobalRelectionAmount;
                float _GlobalBouncingColorIntensity;

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

                o.PosWS = TransformObjectToWorld(v.vertex.xyz);  //TODO: 将平移变换挪出去，在PS中执行 
                return o;
            }

            mrtOut frag(v2f i, in bool isFront : VFACE, out float oDepth : DEPTH)
            {
                mrtOut outCols = (mrtOut)0;
                float2 uv = i.uv * _Albedo_ST.xy + _Albedo_ST.zw;
                uv *= _Tiling_UV;

                //i.vertex -> (screenPixelIdx.xy + 0.5, NDC.z, Clip.w)
                float clipZ = i.vertex.z * i.vertex.w;
                float clipW = i.vertex.w;  //着色点到摄像机的Z轴距离(单位米) 

                //ViewDir
                float3 ViewVector = _WorldSpaceCameraPos.xyz - i.PosWS.xyz;
                float ViewDistance = length(ViewVector);
                float3 ViewDirWS = ViewVector / ViewDistance;

                //Tangent as Normal
                half hairDepth = SAMPLE_TEXTURE2D(_Depth, my_bilinear_repeat_sampler, uv).r;
                half3 TangentTS = lerp(_TangentA, _TangentB, hairDepth) + _Tangent; //depth越小，lerp倾向TanA，越垂直向上 
                TangentTS = normalize(TangentTS);
                TangentTS = TangentTS * _GlobalNormalScaler + _GlobalNormalBias;
                TangentTS = normalize(TangentTS);
                half3x3 tbn = half3x3(i.TangentWS.xyz, i.BitangentWS.xyz, i.NormalWS.xyz);
                half3 nDirWS = normalize(mul(TangentTS, tbn));  //Treat tangent as normal
                nDirWS = isFront ? nDirWS : -nDirWS;

                //Emittion
                half targetNoise = 0;   //源码中有开关控制，在0和0.02之间切换，此处略 
                half noise = SAMPLE_TEXTURE2D(_NoiseTex, my_bilinear_repeat_sampler, uv).r;
                half3 glowCol = 0;
                [branch]
                if (abs(targetNoise - noise) > 0)  //相似度不为100%则进入此分支 
                {
                    [branch]
                    if (targetNoise >= noise) //控制区域范围大小 
                    {
                        glowCol = _GlowColor.rgb;
                    }
                }
                half3 EmitCol = _DissolveEmissiveAmount * glowCol + _EmissiveTint.rgb;
                EmitCol = lerp(EmitCol, _Emissive_Color.rgb, _EmissiveBlend);

                //Base Color
                half root = SAMPLE_TEXTURE2D(_Albedo, my_bilinear_repeat_sampler, uv).r;
                half3 hairCol = lerp(_RootColor.rgb, _TipColor.rgb, root);
                half tilingNoise = SAMPLE_TEXTURE2D(_NoiseTilingTex, my_bilinear_repeat_sampler, i.uv * _Noisetiling).r;
                half3 dBase = (hairCol * tilingNoise + hairCol) * _Brightness;
                dBase = max(dBase, 0.001);
                dBase = min(dBase, 0.999);

                //Roughness
                half wetA = max(0, _WetA);
                wetA = min(wetA, _MaxWet);
                wetA -= 1;
                half wetB = max(0, _WetB);
                wetB = min(wetB, _MaxWet);
                wetB -= 1;
                float wetDistance = max(_WetLength, 0.001);
                half DistFactor = saturate((1 - ViewDistance / wetDistance) * 6.667);
                half RoughnessIntense = abs(wetB) - DistFactor + 1;
                RoughnessIntense = min(RoughnessIntense, 1);
                RoughnessIntense *= abs(wetA);
                half R = saturate(RoughnessIntense * _Roughness);

                //Hair Alpha -> Conditional Discard Pixel
                half hairVal = SAMPLE_TEXTURE2D(_Unique_Hair_Value, my_bilinear_repeat_sampler, uv).r;
                half hairValSq = Pow2(max(hairVal, 0));
                half NoV = dot(i.NormalWS.xyz, ViewDirWS.xyz);
                half rate = lerp(-1, 2, 1.5 * NoV);     //todo: meaning of -1 and 2 
                rate = lerp(_DyeRoughness, 1, rate);
                half alphaAdjust = lerp(hairValSq, 1, rate);
                half hairAlpha = SAMPLE_TEXTURE2D(_Alpha, my_bilinear_repeat_sampler, uv).r;
                half alpha = hairAlpha * alphaAdjust;
                //alpha = alpha * ConditionValA;  //原式中ConditionValA为某个switch开关控制，几乎恒为1 
                clip(alpha - 0.33);

                //Dissolve
                bool needDiscard = DissolveMix2(i.vertex.xy, _DissolveAmount);
                clip(needDiscard);

                //Calc new depth -> Dither
                uint2 screenIdx = uint2(i.vertex.xy + 3); // cb0[151].x == 3 (有时是4)
                half random_0_to_4 = (screenIdx.y << 1 + screenIdx.x) % 5;  // [0, 4]
                half time_frac = abs(frac(_Time.x)) * 0.1;
                half rawDitherNoise = SAMPLE_TEXTURE2D(_NoiseTilingTex, my_bilinear_repeat_sampler, (i.vertex.xy / 64).xy).r;
                half hair_depth = (random_0_to_4 + rawDitherNoise) * 0.166667 - hairVal + 0.5;  // 0.166667 == 1/6
                hair_depth = hair_depth * _PixelDepthOffset + clipW;    //clipW == EyeDepth
                float rNDCZ = clipZ / hair_depth;
                rNDCZ = min(rNDCZ, i.vertex.z);

                //M R D baseAO 
                half Metallic = saturate(_Scatter);
                half Roughness = R * _GlobalRoughnessScaler + _GlobalRoughnessBias;
                half Specular = saturate(_Spec);
                half baseAO = 1;

                //Custom Data
                half2 HorizontalDir = nDirWS.xz / dot(nDirWS, half3(1, 1, 1)); //水平方向上朝向 
                bool IsTipDown = nDirWS.y <= 0;
                half2 UnitDir = HorizontalDir > 0 ? 1 : -1;
                half2 FixDir = UnitDir.xy * (1 - HorizontalDir.yx);
                half2 CustomDataXY = IsTipDown ? FixDir : HorizontalDir;
                CustomDataXY = CustomNormXZ * 0.5 + 0.5;  //custom data 只保存了水平朝向 
                root = max(root, 0.00001);
                half OccBlender = pow(root, _TipPower);
                half CustomDataZ = lerp(_OcclusionAmtRoot, _OcclusionAmtRootTip, OccBlender);

                //Final AO
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
                FillMrtOutput(outCols, half4(CustomDataXY, CustomDataZ, 0), dBase, nDirWS, BaseRTCol, rNDCZ, FinalAO,
                    Metallic, Specular, Roughness, 167.0f, 1.0f / 3.0f);

                oDepth = rNDCZ;

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
