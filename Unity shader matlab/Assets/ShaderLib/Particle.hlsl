#if !defined(SHADER_LIB_PARTICLE_INCLUDED)
#define SHADER_LIB_PARTICLE_INCLUDED

// include
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
    TEXTURE2D(_NoiseTex);        SAMPLER(sampler_NoiseTex);
    TEXTURE2D(_Mask);        SAMPLER(sampler_Mask);
    TEXTURE2D(_CameraDepthTexture);        SAMPLER(sampler_CameraDepthTexture);

    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _Mask_ST, _NoiseTex_ST;
        float4 _TineColor;
        float _InvFade, _ScrollSpeedX, _ScrollSpeedY, _NoiseScrollSpeedX, _NoiseScrollSpeedY;
        float _ColorPower, _TurbulanceAmount, _AlphaScale, _Intensity;
        float _Transparency = 0;
        float4 _ClipRect;

        half _Tran, _RorA;
    CBUFFER_END

    struct Attributes
    {
        float4 positionOS : POSITION;
        float4 color : COLOR;
        float2 uv : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float4 color : COLOR;
        float4 uv : TEXCOORD0;

        #if defined(SOFTPARTICLES_ON)
            float4 projPos : TEXCOORD1;
        #endif

        #if defined()
            float2 uvTurb : TEXCOORD2;
        #endif

        float4 positionOS : TEXCOORD3;
        float FogFactor : TEXCOORD4;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    Varyings LitVert (Attributes v)
    {
        Varyings o = (Varyings)0;

        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        
    }

#endif
