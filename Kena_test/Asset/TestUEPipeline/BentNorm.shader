Shader "Custom/BentNorm"
{
    Properties
    {
        _Tex("Tex", 2D) = "white" {}
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "BentNorm"

            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag
            #pragma multi_compile _ USE_DEFAULT_TEX 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            SamplerState my_point_clamp_sampler;
            TEXTURE2D(_GBuffer2);
            TEXTURE2D(_Tex); SAMPLER(sampler_Tex);

            half4 frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
#if USE_DEFAULT_TEX
                half4 col = 0;
                col.rgb = SAMPLE_TEXTURE2D(_GBuffer2, my_point_clamp_sampler, uv).rgb;
                col.a = 1;
#else
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_Tex, sampler_Tex, uv).xyzw;
#endif

                return col.xyzw;
            }

        ENDHLSL
        }
    }
}
