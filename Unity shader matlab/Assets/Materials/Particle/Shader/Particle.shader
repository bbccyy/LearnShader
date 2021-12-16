Shader "MaterialLib/Particle"
{
    Properties
    {
        _TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)

        _MainTex("Texture", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _NoiseTex("扰乱", 2D) = "white" {}
        _ColorPower("Color Power", Range(0, 4)) = 1
        _InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
        _Intensity("Intensity", Range(0, 2)) = 1
        _Transparency("Transparency", Range(0, 1)) = 0
        _Palstance("角速度", Float) = 0
        _MaskPalstance("遮罩角速度", Float) = 0

        _Turbulence("溶解", 2D) = "white" {}
        _TurbulenceAmount("Turbulence Amount", Range(0, 1)) = 0
        _Cutout("Cut Out", Range(0, 1)) = 0
        _EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
        _EdgeWidth("Edge Width", Range(0, 1)) = 0
        _SoftEdgeWidth("Soft Edge Width", Range(0, 0.5)) = 0

        _ScrollSpeedX("Scroll Speed X", Float) = 0
        _ScrollSpeedY("Scroll Speed y", Float) = 0 // uv animation speed
        _TurSpeedX("Turbulence Speed x", Float) = 0
        _TurSpeedY("Turbulence Speed y", Float) = 0 // turbulence speed

        _HorizontalAmount("Sequence Anim Horizontal Amount", Float) = 4
        _VerticalAmount("Sequence Anim Vertical Amount", Float) = 4
        _SequenceSpeed("Sequence Anim Speed", Range(1, 100)) = 30

        // todo billboard
        _VerticalaBillBoarding("VerticalBillboarding", Range(0, 1)) = 0

        _BlendMode("混合模式", Float) = 0
        _SrcBlend("SrcBlend", Float) = 1
        _DstBlend("DstBlend", Float) = 0
        [Toggle(ZWrite)] _ZWrite("_ZWrite", Float) = 1
        [Enum(CullMode)] _CullMode("剔除模式", Float) = 0
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Toggle(ZTest)] _ZTest("ZTest", Float) = 0
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" "PreviewType" = "Plane" "RenderPipeline" = "UniversalPipeline"}
        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            Blend [_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            Cull [_CullMode]
            ZTest [_ZTest]
            Lighting off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex LitVert
            #pragma fragment LitFrag
            #pragma multi_compile_particles
            #pragma multi_compile_instancing

            #pragma multi_compile _ _RENDERING_UVANIMATION _RENDERING_UVROTATION _RENDERING_DISSOLVE _SEQUENCEANIMATION
            #pragma multi_compile _ _TOGGLETURBULENCE _BILLBOARD _BILLBOARDY _DISSOLVE_ALPHA _DONTMASKSPEED
            #pragma multi_compile _ _USECUTOFF
            #pragma multi_compile _ _PREMULTIPLY_ON
			#pragma exclude_renderers xboxone ps4 psp2 n3ds wiiu

            #define PARTICLE_TRANSPARENT_ADD
            #include "Assets/ShaderLib/ParticleFE.hlsl"

            ENDHLSL
        }
    }
    // CustomEditor "ParticleGUI"
}
