
Shader "Test/DistanceFieldLightingHelper"
{
    HLSLINCLUDE
    #pragma target 3.5
    #pragma editor_sync_compilation  //todo: what's this? 
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/DistanceFieldAOShared.hlsl"
    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Name "ComputeDistanceFieldNormalPS"
            Tags {"RenderPipeline" = "UniversalPipeline"}
            ZWrite Off ZTest Always Cull Off Blend Off 

            HLSLPROGRAM
            #pragma vertex Vert 
            #pragma fragment FragCopyNormAndDepth 

            float4 FragCopyNormAndDepth(Varyings IN) : SV_Target
            {
                 float3 norm = _GBuffer2.Sample(my_point_clamp_sampler,IN.texcoord.xy).xyz;
                 float depth = _GBuffer4.Sample(my_point_clamp_sampler, IN.texcoord.xy).x;
                 return float4(norm, depth);
            }
            ENDHLSL
        }
    }
}
