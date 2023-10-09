Shader "Custom/SSAO"
{
    Properties
    {
        _Tex ("Tex", 2D) = "blue" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "Ssao"

            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag
            #pragma multi_compile _ USE_DEFAULT_TEX 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"


            //测试后发现，如果没有在本Pass提前ConfigureInputAttachments，是无法使用FRAMEBUFFER_INPUT_FLOAT接口获取数据的 
            //MRT阶段设置了全局Texture的纹理可以正常访问，参考_GBuffer4和_GBuffer5 
            //但是MRT阶段，如果开启了UseRenderPass，则_GBuffer0 ~ 3 这几张纹理全部是MemoryLess，所以任然不可正常访问 
            //因此，如果需要在计算SSAO,BentNormal时，访问_GBuffer0~2的数据，最好是参考DeferredPass的做法，在计算延迟光照前 
            //使用一个或几个Pass来计算目标纹理数据，避免将片上缓存的数据交换到SystemMemory上 
            //TODO: 确认SSAO, BentNormal以及SSR计算所需的参数 


            //#define GBUFFER3 3
            //FRAMEBUFFER_INPUT_FLOAT(GBUFFER3);
        
            //TEXTURE2D_X_HALF(_GBuffer4);
            //SamplerState dio_point_clamp_sampler;

            TEXTURE2D(_Tex); SAMPLER(sampler_Tex);

    half frag(Varyings input) : SV_Target
    {
#if USE_DEFAULT_TEX
                half col = 1;
#else
                float2 uv = input.texcoord;
                // sample the texture
                half col = SAMPLE_TEXTURE2D(_Tex, sampler_Tex, uv).r;

                //float d = LOAD_FRAMEBUFFER_INPUT(GBUFFER3, input.positionCS.xy).x;
                //half4 gbuffer = SAMPLE_TEXTURE2D_X_LOD(_GBuffer4, dio_point_clamp_sampler, uv, 0);
#endif
                return col;
            }

            ENDHLSL 
        }
    }
}
