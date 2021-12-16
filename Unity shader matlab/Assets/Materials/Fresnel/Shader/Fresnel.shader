Shader "MaterialLib/Fresnel"
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

        _MainTex ("Main Tex", 2D) = "white"{}
        [HDR]_TintColor ("Tint Color", Color) = (1, 1, 1, 1)
        [HDR]_FresnelColor ("Fresnel Color", Color) = (1, 1, 1, 1)
        _FresnelRange ("Fresnel Range", Range(0, 1)) = 0.5
        _FresnelIntensity ("Fresnel Intensity", Range(0, 4)) = 1.0
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
        _ColorPower ("Color Power", Range(0, 2)) = 1
    }
    SubShader
    {
        Tags {"IgnoreProjector" = "True" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half _FresnelRange, _FresnelIntensity, _AlphaScale, _ColorPower;
                half4 _FresnelColor, _TintColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);         SAMPLER(sampler_MainTex);

            struct input
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                half4 color : COLOR0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                half3 normalWS : TEXCOORD1;
                half3 viewdirWS : TEXCOORD2;
                half4 colorVertex : COLOR0;
            };

            v2f vert(input v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                float3 posWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewdirWS = GetCameraPositionWS() - posWS;
                o.colorVertex = v.color;
                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                half3 normalWS = normalize(i.normalWS);
                half3 viewdirWS = normalize(i.viewdirWS);
                // fresnel = F + (1 - F) * pow(1 - saturate(dot(n, v)), lerp(0, 11, _FresnelRange))
                // 取F = 0时的情况。
                half fresnel = pow(1 - saturate(dot(normalWS, viewdirWS)), lerp(0, 11, _FresnelRange));

                half3 fresnelColor = fresnel * _FresnelColor.rgb * _FresnelIntensity;
                half fresnelAlpha = fresnel * _FresnelColor.a * _FresnelIntensity;

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

                // （贴图 * 颜色 + 菲涅尔反射）* 强度 * 顶点色
                half alpha = (albedo.a * _TintColor.a + fresnelAlpha) * _AlphaScale * i.colorVertex.a;
                half4 col = half4((albedo.rgb * _TintColor.rgb + fresnelColor) * _ColorPower * i.colorVertex.rgb, alpha);

                return col;
            }

            ENDHLSL
        }
    }

    CustomEditor "FresnelGUI"
}
