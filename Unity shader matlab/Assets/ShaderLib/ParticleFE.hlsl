#if !defined(SHADER_LIB_PARTICLE_INCLUDED)
#define SHADER_LIB_PARTICLE_INCLUDED

// include
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    // define texture sampler
    TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
    TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
    TEXTURE2D(_Mask);       SAMPLER(sampler_Mask);
    TEXTURE2D(_Turbulence); SAMPLER(sampler_Turbulence);
    TEXTURE2D(_CameraDepthTexture);   SAMPLER(sampler_CameraDepthTexture);

    // cbuffer
    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _Mask_ST, _NoiseTex_ST, _Turbulence_ST, _NormalMap_ST;
        float4 _TintColor, _EdgeColor;
        float4 _ClipRect;
        half _InvFade, _ScrollSpeedX, _ScrollSpeedY, _TurSpeedX, _TurSpeedY, _Palstance, _MaskPalstance, _HorizontalAmount, _VerticalAmount;
        half _ColorPower, _TurbulenceAmount, _Cutout, _EdgeWidth, _SoftEdgeWidth, _SequenceSpeed, _Cutoff, _Intensity;
        half _VerticalBillboarding;
        half _Transparency = 0;
    CBUFFER_END

    // vert-input
    struct Attributes {
        float4 positionOS : POSITION;
        float4 color : COLOR;
        float2 texcoord : TEXCOORD0;
        float2 texcoord1 : TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    // vert-output
    struct Varyings {
        float4 positionCS : SV_POSITION;
        float4 color : COLOR;
        float4 uv : TEXCOORD0;

        #if defined(_RENDERING_DISSOLVE)
            float4 uv1 : TEXCOORD1;
        #endif

        #if defined(SOFTPARTICLES_ON)
            float4 projPos : TEXCOORD2;
        #endif

        float4 positionOS : TEXCOORD3;
        float FogFactor : TEXCOORD4;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    Varyings LitVert (Attributes v)
    {
        Varyings output = (Varyings)0;

        // GPU Instancing
        UNITY_SETUP_INSTANCE_ID(v);
        // UNITY_INITIALIZE_OUTPUT(Varyings, output); output初始化
        UNITY_TRANSFER_INSTANCE_ID(v, output);
        // VR
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        // billboard
        #if defined(_BILLBOARD) || defined(_BILLBOARDY)
            ///ShadowGun's Billboard
			// 在模型空间中获得相机到模型中点的方向
            // 前提条件：在color的rg通道里提前存储了该顶点到模型中心点的偏移量
			float3 centerOffs = float3(float(0.5).xx - v.color.rg, 0) * v.texcoord1.xyy;
			float3 centerLocal = v.positionOS.xyz + centerOffs;
			float3 viewerLocal = mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos);
			float3 localDir = viewerLocal - centerLocal;

			// 是否忽略y轴的旋转
			#if defined(_BILLBOARD)
				#define VerticalBillboarding 1.0
			#elif defined(_BILLBOARDY)
				#define VerticalBillboarding 0.0
			#endif
			localDir.y = localDir.y * VerticalBillboarding;

			// 计算up和right的方向
			localDir = normalize(localDir);
			// > 0.999f的情况下，就已经是y轴的正方向了
			float3 upLocal = abs(localDir.y) > 0.999f ? float3(0, 0, 1) : float3(0, 1, 0);
			float3 rightLocal = normalize(cross(upLocal, localDir));
			upLocal = normalize(cross(localDir, rightLocal));
			float3 BBLocalPos = centerLocal - (rightLocal * centerOffs.x + upLocal * centerOffs.y);

			output.positionCS = TransformObjectToHClip(BBLocalPos);
        #else
            output.positionCS = TransformObjectToHClip(v.positionOS.xyz);
        #endif

        // soft particles
        #if defined(SOFTPARTICLES_ON)
            output.projPos = ComputeScreenPos(output.positionCS);
            float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
            output.projPos.z = -TransformWorldToView(positionWS).z;
        #endif

        output.color = v.color;
        output.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

        // uv animation / dissolve / rotation
        #if defined(_RENDERING_UVANIMATION) || defined(_RENDERING_DISSOLVE)
            output.uv.xy = TRANSFORM_TEX((v.texcoord + float2(_ScrollSpeedX, _ScrollSpeedY) * _Time.y), _MainTex);
            #if defined(_DONTMASKSPEED)
                output.uv.zw = TRANSFORM_TEX(v.texcoord, _Mask);
            #else
                output.uv.zw = TRANSFORM_TEX((v.texcoord) + float2(_TurSpeedX, _TurSpeedY) * _Time.y), _Mask);
            #endif
        #elif defined(_RENDERING_UVROTATION)
            float4 uv = float4(v.texcoord, v.texcoord);
            output.uv = uv - float4(0.5, 0.5, 0.5, 0.5);
            half speed = _Palstance * _Time.y;
            half maskspeed = _MaskPalstance * _Time.y;

            output.uv.xy = float2(output.uv.x * cos(speed) - output.uv.y * sin(speed), output.uv.x * sin(speed) + output.uv.y * cos(speed));
            output.uv.zw = float2(output.uv.z * cos(maskspeed - output.uv.w * sin(maskspeed), output.uv.z * sin(maskspeed) + output.uv.w * cos(maskspeed)));
            output.uv += float4(0.5, 0.5, 0.5, 0.5);
        #endif

        #if defined(_RENDERING_DISSOLVE)
            output.uv1.xy = TRANSFORM_TEX((v.texcoord + float2(_ScrollSpeedX, _ScrollSpeedY) * _Time.y), _Turbulence);
            output.uv1.zw = TRANSFORM_TEX((v.texcoord + float2(_TurSpeedX, _TurSpeedY) * _Time.y), _NoiseTex);
        #endif

        output.positionOS = v.positionOS;
        output.FogFactor = ComputeFogFactor(output.positionCS.z);
        return output;
    }

    half4 LitFrag (Varyings i) : SV_Target
    {
        // VR
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        // soft particle
        #if defined(SOFTPARTICLES_ON)
            float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, Sampler_CameraDepthTexture, i.projPos.xy / i.projPos.w), _ZBufferParams);
            float partZ = i.projPos.z;
            float fade = saturate(_InvFade * (sceneZ - partZ));
            i.color.a *= fade;
        #endif

        // billboard Question: Is Billboard doesn't need soft particles ?
        #if defined(_BILLBOARD) || defined(_BILLBOARDY)
            i.color = 1.0;
        #endif

        #if defined(_PREMULTIPLY_ON)
            half4 colScale = _ColorPower * i.color * _TintColor * i.color.a;
        #else
            half4 colScale = _ColorPower * i.color * _TintColor;
        #endif

        // maintex sampler
        half4 col = colScale * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

        // uv animation / rotation / dissolve / sequence animation
        #if defined(_RENDERING_UVANIMATION) || defined(_RENDERING_UVROTATION)
            half4 colMask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, i.uv.zw);
            col *= colMask.r;
        #elif defined(_RENDERING_DISSOLVE)
            // 我认为下面分为两种扰动（扰动也就是在某些影响因素的情况下，在原来值的基础上进行小范围的随机性来回波动）
            // 首先是用noiseTex进行了uv的扰动，扰动影响MainTex的uv和MaskTex的uv。
            // 如果后面还进行颜色的扰动，那么也有可能影响取颜色扰动的Tex的uv。
            half4 colMask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, i,uv.zw);
            half2 deltauv = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv1.zw).rg * _TurbulenceAmount - _TurbulenceAmount * 0.5;
            // deltauv：也就是在uv上的小范围变化值，-0.5是为了让扰动出现负值，现在deltauv的变化范围在-0.5到0.5。但这个变化的范围可以根据经验值来控制TurfulenceAmount的范围大小。
            float2 uvDistortMain = deltauv + i.uv.xy;
            float2 uvDistortMask = deltauv + i.uv1.xy; // 这个其实是turbulence的uv

            half4 diffCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvDistortMain);
            #if defined(_TOGGLETURBULENCE)
                half turbulence = saturate(SAMPLE_TEXTURE2D(_Turbulence, sampler_Turbulence, uvDistortMask).r + 0.001);
            #else
                half turbulence = saturate(SAMPLE_TEXTURE2D(_Turbulence, sampler_Turbulence, i.uv1.xy).r + 0.001);
            #endif
            turbulence = turbulence - (1.0 - i.color.a + _Cutout);
            half dissolve = smoothstep(0.0, _SoftEdgeWidth, turbulence);
            half edge = smoothstep(_EdgeWidth, 0.0, turbulence);
            col.rgb = lerp(diffCol * colScale, _EdgeColor, edge).rgb; // 看起来是通过扰动位置，来扰动颜色，不是直接对颜色进行变化
            col.a = dissolve * diffCol.a * colMask.r * _TintColor.a; // 另外我认为调整alpha值可以做到discard的效果
            #if defined(_DISSOLVE_ALPHA)
                col.a *= i.color.a * i.color.a;
            #endif
        #elif defined(_SEQUENCEANIMATION)
            float displacement = floor(_Time.y * _SequenceSpeed);
            float row = floor(displacement / _HorizontalAmount);
            float column = displacement - row * _HorizontalAmount;
            half2 uv = i.uv.xy + half2(column, -row);
            uv.x /= _HorizontalAmount;
            uv.y /= _VerticalAmount;
            col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * colScale;
        #endif

        #if defined(UNITY_UI_CLIP_RECT)
            float2 inside = step(_ClipRect.xy, i.positionOS.xy) * step(i.positionOS.xy, _ClipRect.zw); // _ClipRect.xy是矩形的左下角，zw是右上角
            col.a *= inside.x * inside.y;
        #endif

        #if defined(_USECUTOFF)
            clip(col.a - _Cutoff);
        #endif

        #if defined(PARTICLE_ADDITIVE_SOFT)
            col.rgb *= col.a;
        #endif

        #if defined(PARTICLE_TRANSPARENT_ADD)
            col *= (1 - _Transparency);
        #elif defined(PARTICLE_TRANSPARENT_BLEND)
            col.a *= (1 - _Transparency);
        #endif

        col = clamp(col, 0.0, 1.0);

        // add fog
        col.rgb = MixFog(col.rgb, i.FogFactor);

        return col;
    }

#endif