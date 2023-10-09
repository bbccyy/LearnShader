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


            //���Ժ��֣����û���ڱ�Pass��ǰConfigureInputAttachments�����޷�ʹ��FRAMEBUFFER_INPUT_FLOAT�ӿڻ�ȡ���ݵ� 
            //MRT�׶�������ȫ��Texture����������������ʣ��ο�_GBuffer4��_GBuffer5 
            //����MRT�׶Σ����������UseRenderPass����_GBuffer0 ~ 3 �⼸������ȫ����MemoryLess��������Ȼ������������ 
            //��ˣ������Ҫ�ڼ���SSAO,BentNormalʱ������_GBuffer0~2�����ݣ�����ǲο�DeferredPass���������ڼ����ӳٹ���ǰ 
            //ʹ��һ���򼸸�Pass������Ŀ���������ݣ����⽫Ƭ�ϻ�������ݽ�����SystemMemory�� 
            //TODO: ȷ��SSAO, BentNormal�Լ�SSR��������Ĳ��� 


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
