Shader "Custom/SSR"
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
            Name "SSR"

            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"


            TEXTURE2D(_Tex); SAMPLER(sampler_Tex);

            half4 frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_Tex, sampler_Tex, uv).xyzw;

                return col.xyzw;
            }

        ENDHLSL
        }
    }
}
