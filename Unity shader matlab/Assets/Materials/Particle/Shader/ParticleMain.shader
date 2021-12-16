Shader "MaterialLib/ParticleMain"
{
    Properties
    {
        // blend
        _BlendMode ("混合模式", Float) = 0
        _SrcBlend ("SrcBlend", Float) = 1
        _DstBlend ("DstBlend", Float) = 0

        // zwrite
        [Toggle(ZWrite)] _ZWrite ("深度写入", Float) = 1
        [Toggle(ZTest)] _ZTest ("深度测试", Float) = 0

        // cull
        [Enum(CullMode)] _CullMode ("剔除模式", Float) = 0

        // MainTex
        _MainTex ("MainTex", 2D) = "white" {}
        _AlphaScale ("AlphaScale", Range(0, 1)) = 1
        _TintColor ("TintColor", color) = (1, 1, 1, 1)
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

        // dissolve
        _DissolveTex ("DissolveTex", 2D) = "black" {}
        _DissolveUSpeed ("DissolveUSpeed", Float) = 0.0
        _DissolveVSpeed ("DissolveVSpeed", Float) = 0.0
        _DissolveCutout ("DissolveCutout", Range(0, 1)) = 0
        _SoftEdgeWidth ("SoftEdgeWidth", Range(0, 0.5)) = 0
        _EdgeWidth ("EdgeWidth", Range(0, 1)) = 0
        _EdgeColorInside ("EdgeColorInside", color) = (1, 1, 1, 1)
        _EdgeColorOutSide ("EdgeColorOutside", color) = (1, 1, 1, 1)

        // sequence animation
        _HorizontalLen ("Sequence Anim Horizontal Len", Float) = 4
        _VerticalLen ("Sequence Anim Vertical Len", Float) = 4
        _SequenceSpeed ("Sequence Anim Speed", Range(1, 100)) = 30
    }

    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" "PreviewType" = "Plane" "RenderPipeline" = "UniversalPipeline"}
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend [_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_particles
            #pragma multi_compile_instancing
            #pragma multi_compile _ _UV_ANIMATION _DISSOLVE _SEQUENCE_ANIMATION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);        SAMPLER(sampler_MaskTex);
            TEXTURE2D(_NoiseTex);       SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_DissolveTex);    SAMPLER(sampler_DissolveTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST, _MaskTex_ST, _NoiseTex_ST, _DissolveTex_ST;
                float4 _TintColor, _EdgeColorInside, _EdgeColorOutSide;
                half _AlphaScale, _MainUSpeed, _MainVSpeed, _MaskUSpeed, _MaskVSpeed, _NoiseUSpeed, _NoiseVSpeed, _NoiseStrength;
                half _DissolveUSpeed, _DissolveVSpeed, _DissolveCutout, _SoftEdgeWidth, _EdgeWidth;
                half _HorizontalLen, _VerticalLen, _SequenceSpeed;
            CBUFFER_END

            struct input {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
                float4 uv : TEXCOORD0;

                #if defined(_DISSOLVE)
                    float4 noiseUV : TEXCOORD1;
                #endif
            };

            v2f Vert (input v)
            {
                v2f o = (v2f)0;

                o.color = v.color;

                // uv - xy MainUV zw MaskUV
                #if defined(_UV_ANIMATION)
                    o.uv.xy = TRANSFORM_TEX((v.uv + float2(_MainUSpeed, _MainVSpeed) * _Time.y), _MainTex);
                    o.uv.zw = TRANSFORM_TEX((v.uv + float2(_MaskUSpeed, _MaskVSpeed) * _Time.y), _MaskTex);
                #else
                    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex);
                #endif

                #if defined(_DISSOLVE)
                    // noise uv
                    o.noiseUV.xy = TRANSFORM_TEX((v.uv + float2(_NoiseUSpeed, _NoiseVSpeed) * _Time.y), _NoiseTex);
                    o.noiseUV.zw = TRANSFORM_TEX((v.uv + float2(_DissolveUSpeed, _DissolveVSpeed) * _Time.y), _DissolveTex);
                #endif

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 Frag(v2f i) : SV_Target
            {
                #if defined (_SEQUENCE_ANIMATION)
                    float step = floor(_Time.y * _SequenceSpeed);
                    float row = floor(step / _HorizontalLen);
                    float column = step - row * _HorizontalLen;
                    half2 mainUV = i.uv.xy + half2(column, -row);
                    mainUV.x /= _HorizontalLen;
                    mainUV.y /= _VerticalLen;

                    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV);
                    col.a *= _AlphaScale;

                    return col;
                #elif defined (_DISSOLVE)
                    // sample col
                    half4 colMask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.zw);

                    // sample noise
                    float2 uvNoise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseUV).rg * _NoiseStrength - 0.5 * _NoiseStrength;

                    // uv change
                    float2 uvMain = i.uv.xy + uvNoise;
                    float2 uvDissolve = i.noiseUV.zw + uvNoise;

                    // sample main
                    half4 col = _TintColor * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);

                    // sample dissolve
                    half dissolveFactor = saturate(SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, uvDissolve).r + 0.001);
                    dissolveFactor = dissolveFactor - (1.0 - i.color.a + _DissolveCutout); // 便于粒子控制器用alpha控制溶解程度

                    half dissolve = smoothstep(0.0, _SoftEdgeWidth, dissolveFactor);
                    half edgeFactor = smoothstep(_EdgeWidth, 0, dissolveFactor);
                    half3 edgeCol = lerp(_EdgeColorInside, _EdgeColorOutSide, edgeFactor);
                    col.rgb = lerp(col, edgeCol, edgeFactor * step(0.0001, dissolve));

                    col.a = dissolve * col.a * colMask.r * _TintColor.a * _AlphaScale;
                    return col;
                #else
                    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                    half4 maskCol = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.zw);

                    col *= maskCol.r;
                    col.a *= _AlphaScale;
                    return col;
                #endif
            }

            ENDHLSL
        }
    }

    CustomEditor "ParticleMainGUI"
}