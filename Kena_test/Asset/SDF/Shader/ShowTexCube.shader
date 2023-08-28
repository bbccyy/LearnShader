Shader "Test/ShowTexCube"
{
    Properties
    {
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Name "ShowTextureCube"
            Tags {"RenderPipeline" = "UniversalPipeline"}
            ZWrite Off ZTest Always Cull Back Blend Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            SamplerState my_bilinear_repeat_sampler;
            Texture3D<half> _SDF;

            CBUFFER_START(UnitPerMaterial)
            
            float3 _AABB_SIZE;
            float3 _AABB_MIN;

            float3 _uvw_delta;

            CBUFFER_END

            half3 HsvToRgb(half3 c)
            {
                const half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            /// A ray with pre-calculated reciprocals to avoid divisions.
            struct dmnsn_optimized_ray
            {
                float3 x0;    ///< The origin of the ray.
                float3 n_inv; ///< The inverse of each component of the ray's slope
            };

            struct dmnsn_aabb
            {
                float3 min;
                float3 max;
            };

            bool aabb_contains(dmnsn_aabb box, float3 p)
            {
                return all(p > box.min && p < box.max);
            }


#if SHADER_API_GLES
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
#else
            struct Attributes
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
#endif

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldDir : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

#if SHADER_API_GLES
                float4 pos = input.positionOS;
                float2 uv = input.uv;
#else
                float4 pos = GetFullScreenTriangleVertexPosition(input.vertexID);
                float2 uv = GetFullScreenTriangleTexCoord(input.vertexID);
#endif
                //output.vertex = TransformObjectToHClip(input.vertex.xyz);
                output.vertex = pos;
                output.uv = uv;
                
                //入参DeviceZ == 0 -> 对应DepthTexture中黑色部分 -> 对应远裁剪面
                float3 rayFarSideWS = ComputeWorldSpacePosition(uv.xy, 0, UNITY_MATRIX_I_VP);
                output.worldDir = rayFarSideWS - _WorldSpaceCameraPos.xyz;

                //float4 ndc = float4(uv * 2 - 1, 0, 1);
                //float4 worldRay = mul(UNITY_MATRIX_I_VP, ndc);
                //output.worldDir = worldRay.xyz / worldRay.w - _WorldSpaceCameraPos.xyz;

                return output;
            }

            half4 Frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                half4 col = 1; 
                col.rgb = (i.worldDir);

                col.rgb = HsvToRgb(half3(i.uv.x, 0.8, 0.7));

                return col;
            }
            ENDHLSL
        }
    }
}