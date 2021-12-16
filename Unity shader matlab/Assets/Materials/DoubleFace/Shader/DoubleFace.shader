Shader "MaterialLib/DoubleFace"
{
    Properties
    {
        // blend
        _FrontBlendMode ("混合模式", Float) = 0
        _FrontSrcBlend ("SrcBlend", Float) = 1
        _FrontDstBlend ("DstBlend", Float) = 0

        _BackBlendMode ("混合模式", Float) = 0
        _BackSrcBlend ("SrcBlend", Float) = 1
        _BackDstBlend ("DstBlend", Float) = 0

        // MainTex
        _MainTex ("MainTex", 2D) = "white" {}
        _AlphaScale ("AlphaScale", Range(0, 1)) = 1
        _MainUSpeed ("MainUSpeed", Float) = 0.0
        _MainVSpeed ("MainVSpeed", Float) = 0.0

        // Mask
        _MaskTex ("MaskTex", 2D) = "white" {}
        _MaskUSpeed ("MaskUSpeed", Float) = 0.0
        _MaskVSpeed ("MaskVSpeed", Float) = 0.0

        // noise
        _NoiseTex ("NoiseTex", 2D) = "black" {}
        _NoiseUSpeed ("NoiseUSpeed", Float) = 0.0
        _NoiseVSpeed ("NoiseVSpeed", Float) = 0.0
        _NoiseStrength ("NoiseStrength", Range(0, 1)) = 1


        [HDR]_FrontColor ("Front Color", Color) = (1, 1, 1, 1)
        [HDR]_BackColor ("Back Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
			ZWrite On
			Blend[_FrontSrcBlend][_FrontDstBlend]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);        SAMPLER(sampler_MaskTex);
            TEXTURE2D(_NoiseTex);       SAMPLER(sampler_NoiseTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST, _MaskTex_ST, _NoiseTex_ST;
                half _AlphaScale, _MainUSpeed, _MainVSpeed, _MaskUSpeed, _MaskVSpeed, _NoiseUSpeed, _NoiseVSpeed, _NoiseStrength;
                half4 _FrontColor, _BackColor;
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
                half4 color : COLOR0;
            };

            v2f vert(input v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.color = v.color;

                // uv - xy MainUV zw MaskUV
                o.uv.xy = TRANSFORM_TEX((v.uv + float2(_MainUSpeed, _MainVSpeed) * _Time.y), _MainTex);
                o.uv.zw = TRANSFORM_TEX((v.uv + float2(_MaskUSpeed, _MaskVSpeed) * _Time.y), _MaskTex);

                // noise uv
                o.noiseUV = TRANSFORM_TEX((v.uv + float2(_NoiseUSpeed, _NoiseVSpeed) * _Time.y), _NoiseTex);

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half2 noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseUV).rg * _NoiseStrength - 0.5 * _NoiseStrength;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy + noise);
                half4 colMask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.zw + noise);

                half3 finalCol = col.rgb * _FrontColor * i.color.rgb * colMask.r;
                half alpha = col.a * _AlphaScale * i.color.a;
                return half4(finalCol, alpha);
            }

            ENDHLSL
        }

        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Cull Front
			ZWrite On
			Blend[_BackSrcBlend][_BackDstBlend]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);        SAMPLER(sampler_MaskTex);
            TEXTURE2D(_NoiseTex);       SAMPLER(sampler_NoiseTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST, _MaskTex_ST, _NoiseTex_ST;
                half _AlphaScale, _MainUSpeed, _MainVSpeed, _MaskUSpeed, _MaskVSpeed, _NoiseUSpeed, _NoiseVSpeed, _NoiseStrength;
                half4 _FrontColor, _BackColor;
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
                half4 color : COLOR0;
            };

            v2f vert(input v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.color = v.color;

                // uv - xy MainUV zw MaskUV
                o.uv.xy = TRANSFORM_TEX((v.uv + float2(_MainUSpeed, _MainVSpeed) * _Time.y), _MainTex);
                o.uv.zw = TRANSFORM_TEX((v.uv + float2(_MaskUSpeed, _MaskVSpeed) * _Time.y), _MaskTex);

                // noise uv
                o.noiseUV = TRANSFORM_TEX((v.uv + float2(_NoiseUSpeed, _NoiseVSpeed) * _Time.y), _NoiseTex);

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half2 noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseUV).rg * _NoiseStrength - 0.5 * _NoiseStrength;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy + noise);
                half4 colMask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.zw + noise);

                half3 finalCol = col.rgb * _BackColor * i.color.rgb * colMask.r;
                half alpha = col.a * _AlphaScale * i.color.a;
                return half4(finalCol, alpha);
            }

            ENDHLSL
        }
    }

    CustomEditor "DoubleFaceGUI"
}
