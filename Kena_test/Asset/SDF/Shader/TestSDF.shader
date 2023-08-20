Shader "Test/TestSDF"
{
    Properties
    {
        _Tex3D ("Texture", 3D) = "white" {}
        _Slice("Slice", range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipelien"="UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "Test SDF Blitable"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE3D_HALF(_Tex3D); SAMPLER(sampler_Tex3D);

            CBUFFER_START(UnityPerMaterial)
                float4 _Tex3D_ST;
                float _Slice;
            CBUFFER_END

            half4 frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                half r = SAMPLE_TEXTURE3D(_Tex3D, sampler_Tex3D, float3(uv, _Slice)).r;
                half4 col = 0;
                col.r = r;
                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Test SDF"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varying 
            {
                float2 uv           : TEXCOORD0;
                float4 vertex       : SV_POSITION;
            };


            TEXTURE3D_HALF(_Tex3D); SAMPLER(sampler_Tex3D);

            CBUFFER_START(UnityPerMaterial)
                float4 _Tex3D_ST;
                float _Slice;
            CBUFFER_END


            Varying vert (Attribute i)
            {
                Varying o;
                o.vertex = TransformObjectToHClip(i.positionOS);
                o.uv = i.uv;
                return o;
            }

            half4 frag(Varying i) : SV_Target
            {
                half r = SAMPLE_TEXTURE3D(_Tex3D, sampler_Tex3D, float3(i.uv, _Slice)).r;
                half4 col = 1;
                col.r = r;
                return col;
            }
            ENDHLSL
        }

    }
}


/*

#ifdef MOTION_V
        Pass
        {
            Name "Test Motion Vector"

            HLSLPROGRAM
            #pragma vertex MotionVectorVertex
            #pragma fragment MotionVectorFragment

            #ifndef UNIVERSAL_MOTION_VECTOR_INCLUDED
            #define UNIVERSAL_MOTION_VECTOR_INCLUDED

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
                //注意这里是使用 TEXCOORD4来获取上帧中的动画蒙皮数据
                float3 positionLast :TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                float4 transferPos  : TEXCOORD1;
                float4 transferPosOld : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings MotionVectorVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                //添加bias 是保证motion vector能正确渲染出来，（不知道为啥，不加的话可能会无法通过深度测试）
            #if UNITY_REVERSED_Z
                output.positionCS.z -= unity_MotionVectorsParams.z * output.positionCS.w;
            #else
                output.positionCS.z += unity_MotionVectorsParams.z * output.positionCS.w;
            #endif
                output.transferPos = mul(UNITY_MATRIX_UNJITTERED_VP, mul(GetObjectToWorldMatrix(), float4(input.position.xyz, 1.0)));
                //带有蒙皮动画的物体
                if (unity_MotionVectorsParams.x > 0)
                {
                    output.transferPosOld = mul(UNITY_MATRIX_PREV_VP, mul(unity_MatrixPreviousM, float4(input.positionLast.xyz, 1.0)));
                }
                else
                {
                    output.transferPosOld = mul(UNITY_MATRIX_PREV_VP, mul(unity_MatrixPreviousM, float4(input.position.xyz, 1.0)));
                }
                return output;

            }

            float2 MotionVectorFragment(Varyings input) : SV_TARGET
            {
                float3 hPos = (input.transferPos.xyz / input.transferPos.w);
                float3 hPosOld = (input.transferPosOld.xyz / input.transferPosOld.w);
                float2 motionVector = hPos - hPosOld;
            #if UNITY_UV_STARTS_AT_TOP
                motionVector.y = -motionVector.y;
            #endif
                // 表示强制更新，不使用历史信息
                 if (unity_MotionVectorsParams.y == 0) return float2(1, 0);
                 return motionVector * 0.5;

            }

            ENDHLSL
            #endif
        }
#endif


*/