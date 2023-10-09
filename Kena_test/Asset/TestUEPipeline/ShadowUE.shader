Shader "Custom/ShadowUE"
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
            Name "ShadowUE"

            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag
            #pragma multi_compile _ USE_DEFAULT_TEX 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Deferred.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            TEXTURE2D_X_FLOAT(_GBuffer4);
            SamplerState my_point_clamp_sampler;
            TEXTURE2D(_Tex); SAMPLER(sampler_Tex);

            half4 frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
#if USE_DEFAULT_TEX
                half4 col = half4(0, 1, 1, 0);
                float depth = SAMPLE_TEXTURE2D_X_LOD(_GBuffer4, my_point_clamp_sampler, uv, 0).x;
                float3 WorldPosition = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
                float4 shadowCoord = TransformWorldToShadowCoord(WorldPosition.xyz);
                half realtimeShadow = MainLightRealtimeShadow(shadowCoord);
                col.x = realtimeShadow;  //TODO: convert to fully-functional Screen-space shadow texture 
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
