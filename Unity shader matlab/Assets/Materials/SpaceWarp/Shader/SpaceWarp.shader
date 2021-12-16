Shader "MaterialLib/SpaceWarp"
{
    Properties
    {
        // blend
        _BlendMode ("混合模式", Float) = 0
        _SrcBlend ("SrcBlend", Float) = 1
        _DstBlend ("DstBlend", Float) = 0

        // MainTex
        _MainTex ("MainTex", 2D) = "white" {}
        _AlphaScale ("AlphaScale", Range(0, 1)) = 1
        _TintColor ("TintColor", color) = (1, 1, 1, 1)
        _MainUSpeed ("MainUSpeed", Float) = 0.0
        _MainVSpeed ("MainVSpeed", Float) = 0.0

        // Mask
        _MaskTex ("MaskTex", 2D) = "black" {}

        // noise
        _NoiseTex ("NoiseTex", 2D) = "black" {}
        _NoiseUSpeed ("NoiseUSpeed", Float) = 0.0
        _NoiseVSpeed ("NoiseVSpeed", Float) = 0.0
        _NoiseStrength ("NoiseStrength", Range(0, 1)) = 1

        _WarpStrength ("扭曲强度", float) = 0
    }
    SubShader
    {
        Tags {"RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile _ _MAIN_TEX_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);        SAMPLER(sampler_MaskTex);
            TEXTURE2D(_NoiseTex);       SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_ScreenGrabTexture);        SAMPLER(sampler_ScreenGrabTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST, _MaskTex_ST, _NoiseTex_ST, _ScreenGrabTexture_ST;
                float4 _TintColor;
                half _AlphaScale, _MainUSpeed, _MainVSpeed, _MaskUSpeed, _MaskVSpeed, _NoiseUSpeed, _NoiseVSpeed, _NoiseStrength, _WarpStrength;
            CBUFFER_END

            struct input
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 noiseUV : TEXCOORD1;
                float4 positionSS : TEXCOORD2; //GRAB SCREEN POSITION
                half4 vertexColor : COLOR0;
            };

            float4 ComputeGrabScreenPos (float4 pos) {
                #if UNITY_UV_STARTS_AT_TOP
                    float scale = -1.0;
                #else
                    float scale = 1.0;
                #endif

                float4 o = pos * 0.5f;
                o.xy = float2(o.x, o.y*scale) + o.w;
                #ifdef UNITY_SINGLE_PASS_STEREO
                    o.xy = TransformStereoScreenSpaceTex(o.xy, pos.w);
                #endif
                o.zw = pos.zw;
                return o;
            }

            v2f Vert (input v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                o.uv.xy = TRANSFORM_TEX((v.uv + float2(_MainUSpeed, _MainVSpeed) * _Time.y), _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex);

                // noise uv
                o.noiseUV.xy = TRANSFORM_TEX((v.uv + float2(_NoiseUSpeed, _NoiseVSpeed) * _Time.y), _NoiseTex);

                o.vertexColor = v.color;
                o.positionSS = ComputeGrabScreenPos(o.positionCS);
                return o;
            }

            half4 Frag (v2f i) : SV_Target
            {
                float2 uvNoise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseUV).rg * _NoiseStrength - 0.5 * _NoiseStrength;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy + uvNoise);
                half4 colMask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.zw + uvNoise);

                // 粒子控制扭曲强度和颜色(通过vertexColor alpha)
                half3 finalCol = col.xyz * colMask.r * i.vertexColor.rgb * i.vertexColor.a * _TintColor.rgb * _TintColor.a * _AlphaScale;
                float2 offset = col * _WarpStrength * i.vertexColor.a;
                half4 refCol = SAMPLE_TEXTURE2D(_ScreenGrabTexture, sampler_ScreenGrabTexture, (i.positionSS.xy + offset) / i.positionSS.w);

                #if _MAIN_TEX_ON
                    half3 color = finalCol.xyz + refCol.xyz;
                #else
                    half3 color = refCol.xyz;
                #endif
                return half4(color, 1.0);
            }

            ENDHLSL
        }
    }

    CustomEditor "SpaceWarpGUI"
}
