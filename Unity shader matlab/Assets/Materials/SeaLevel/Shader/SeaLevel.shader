Shader "MaterialLib/SeaLevel"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Sea Tex", 2D) = "white" {}
        [NoScaleOffset]_NormalTex ("Normal Tex", 2D) = "bump" {}
        [NoScaleOffset]_NoiseTex ("Noise Tex", 2D) = "black" {}
        [NoScaleOffset]_FlowTex ("Flow Tex", 2D) = "black" {}

        _UJump ("UJump per phase", Range(-0.25, 0.25)) = 0.25
        _VJump ("VJump per phase", Range(-0.25, 0.25)) = 0.25

        _Tiling ("Tiling", Float) = 1
        _Speed ("Speed", Float) = 1

        _FlowStrength ("Flow Strength", Float) = 1
        _FlowOffset ("Flow Offset", Float) = 0
        _Glossiness("Glossiness", Range(0.0, 1.0)) = 0.5
		_SpecularStrength("Specular Strength", Range(0.0, 1.0)) = 0.5

        _CameraPos("Camera Pos", Vector) = (0.0, 0.0, -50.0, 0.0)
		_LightDir("Light Dir", Vector) = (0.0, 0.0, -1.0, 0.0)

        _FarColor ("Far Color", Color) = (1, 1, 1, 1)
        _NearColor ("Near Color", Color) = (0, 0, 0, 0)
        _SpecColor ("Spec Color", Color) = (0, 0, 0, 0)

        _WaveA ("WaveA", Vector) = (1, 1, 0.5, 10)
        _WaveB ("WaveB", Vector) = (0, 1, 0.5, 10)
        _WaveC ("WaveC", Vector) = (0, 1, 0.5, 10)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True"}

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Lighting Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile _ _MESH_WAVE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);      SAMPLER(sampler_NormalTex);
            TEXTURE2D(_NoiseTex);       SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_FlowTex);        SAMPLER(sampler_FlowTex);

            CBUFFER_START(UnityPerMaterial)
                float _UJump, _VJump, _Tiling, _Speed, _FlowStrength, _FlowOffset, _Glossiness, _SpecularStrength;
                float4 _LightDir, _CameraPos, _FarColor, _NearColor, _SpecColor;
                float4 _WaveA, _WaveB, _WaveC;
            CBUFFER_END

            struct input {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            float3 FlowUV(float2 uv, float2 flowVector, float2 jump, float flowOffset, float tiling, float time, bool flowB)
            {
                float offset = flowB ? 0.5 : 0;
                float progress = frac(time + offset);
                float3 uvw;
                uvw.xy = uv - flowVector * (progress + flowOffset);
                uvw.xy *= tiling;
                uvw.xy += offset;
                uvw.xy += (time - progress) * jump;
                uvw.z = 1 - abs(1 - 2 * progress);
                return uvw;
            }

            float4 transPoint(float4 positionOS, float4 wave)
            {
                float steepness = wave.z;
                float wavelength = wave.w;
                float4 transPos = positionOS;
                float k = 2 * PI / wavelength;
                float c = sqrt(9.8 / k);
                float2 d = normalize(wave.xy);
                float f = (dot(d, transPos.xz) - c * _Time.y) * k;
                float a = steepness / k;
                transPos.y = a * sin(f);
                transPos.z = d.x * a * cos(f);
                transPos.x = d.y * a * cos(f);
                return transPos;
            }

            v2f Vert (input v)
            {
                v2f o;

                #if defined(_MESH_WAVE)
                    v.positionOS.xyz += transPoint(v.positionOS, _WaveA).xyz;
                    v.positionOS.xyz += transPoint(v.positionOS, _WaveB).xyz;
                    v.positionOS.xyz += transPoint(v.positionOS, _WaveC).xyz;
                #endif

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;

                // o.viewDir = _CameraPos.xyz - o.positionWS.xyz;
                o.viewDir = _WorldSpaceCameraPos.xyz - o.positionWS.xyz;
                return o;
            }

            half4 Frag (v2f i) : SV_Target
            {
                // albedo
                float2 flowVector = SAMPLE_TEXTURE2D(_FlowTex, sampler_FlowTex, i.uv).xy * _FlowStrength;
                float timeNoise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv).b;
                float2 jump = float2(_UJump, _VJump);
                float time = _Time.y * _Speed + timeNoise;
                float3 uvw1 = FlowUV(i.uv, flowVector, jump, _FlowOffset, _Tiling, time, false);
                float3 uvw2 = FlowUV(i.uv, flowVector, jump, _FlowOffset, _Tiling, time, true);
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvw1.xy) * uvw1.z +
                               SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvw2.xy) * uvw2.z;
                // half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

                // specular
                float3 normal1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uvw1.xy)) * uvw1.z;
                float3 normal2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uvw2.xy)) * uvw2.z;
                float3 normal = normalize(normal1 + normal2);
                float3 normalWS = float3(normal.xy, -1.0);
                half3 viewDir = normalize(i.viewDir);
                half3 lightDir = normalize(_LightDir.xyz);
                half3 reflectDir = normalize(reflect(-lightDir, normalWS));
                half rDotv = saturate(dot(reflectDir, viewDir));
                half specular = pow(rDotv, lerp(64.0, 1024.0, _Glossiness)) * _SpecularStrength;
                half4 specCol = specular * _SpecColor;

                // mix color
                half3 realViewDir = normalize(i.positionWS.xyz - _WorldSpaceCameraPos.xyz);
                half colorMixFactor = realViewDir.z;
                half4 finalColor = _FarColor * colorMixFactor + _NearColor * (1 - colorMixFactor);
                albedo *= finalColor;

                return albedo + specCol;
            }

            ENDHLSL
        }
    }
    CustomEditor "SeaLevelGUI"
}
