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

#define NUM_MARCHING_STEPS 90
#define SDF_NEAR_THRESHOLD 0.007f

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

            bool aabb_contains_minmax(float3 min, float3 max, float3 p)
            {
                return all(p > min && p < max);
            }

            bool aabb_contains(dmnsn_aabb box, float3 p)
            {
                return aabb_contains_minmax(box.min, box.max, p);
            }

            bool dmnsn_ray_box_intersection(dmnsn_optimized_ray optray, dmnsn_aabb box, inout float t)
            {
                t = 999999.0f; //INFINIT

                float tx1 = (box.min.x - optray.x0.x) * optray.n_inv.x;
                float tx2 = (box.max.x - optray.x0.x) * optray.n_inv.x;

                float tmin = min(tx1, tx2);
                float tmax = max(tx1, tx2);

                float ty1 = (box.min.y - optray.x0.y) * optray.n_inv.y;
                float ty2 = (box.max.y - optray.x0.y) * optray.n_inv.y;

                tmin = max(tmin, min(ty1, ty2));
                tmax = min(tmax, max(ty1, ty2));

                float tz1 = (box.min.z - optray.x0.z) * optray.n_inv.z;
                float tz2 = (box.max.z - optray.x0.z) * optray.n_inv.z;

                tmin = max(tmin, min(tz1, tz2));
                tmax = min(tmax, max(tz1, tz2));

                bool ret = tmax >= max(0.0, tmin) && tmin < t;

                t = ret ? tmin : 0;

                return ret;
            }

            half RayMarchingAgainstSDFVolume3D(float3 RayOrig, float3 RayDir, dmnsn_aabb AABB)
            {
                float3 RayLocal = RayOrig - AABB.min; //NUM_MARCHING_STEPS
                float MaxStepOffset = _AABB_SIZE.x * 1.4f;
                float StepOffset = MaxStepOffset / (float)NUM_MARCHING_STEPS;
                float StepDelta = StepOffset;
                float3 aabbInvSize = 1.0f / _AABB_SIZE;
                dmnsn_aabb localAABB = (dmnsn_aabb)0;
                localAABB.min = float3(0, 0, 0);
                localAABB.max = _AABB_SIZE;

                [loop]
                for (uint StepIndex = 0; StepIndex < NUM_MARCHING_STEPS && StepOffset < MaxStepOffset; StepIndex++)
                {
                    float3 StepSamplePos = RayLocal + RayDir * StepOffset;
                    if (aabb_contains(localAABB, StepSamplePos))
                    {
                        float3 StepVolumeUV = StepSamplePos * aabbInvSize + _uvw_delta;
                        half rawDist = SAMPLE_TEXTURE3D_LOD(_SDF, my_bilinear_repeat_sampler, StepVolumeUV, 0);
                        //_SDF.SampleLevel
                        
                        if (rawDist <= SDF_NEAR_THRESHOLD)
                        {
                            return smoothstep(0, 1, StepOffset / MaxStepOffset);
                        }
                    }
                    else
                    {
                        return 0;
                    }
                    StepOffset = StepOffset + StepDelta;
                }
                return 0;
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
                
                dmnsn_aabb aabb = (dmnsn_aabb)0;
                aabb.min = _AABB_MIN;
                aabb.max = _AABB_MIN + _AABB_SIZE;

                dmnsn_optimized_ray ray = (dmnsn_optimized_ray)0;
                ray.x0 = _WorldSpaceCameraPos.xyz;
                half3 dir = normalize(i.worldDir);
                ray.n_inv = float3(1 / dir.x, 1 / dir.y, 1 / dir.z);

                bool canHit = false;
                float3 hitPosWS = 0;
                if (aabb_contains(aabb, ray.x0))
                {
                    canHit = true;
                    hitPosWS = ray.x0;
                }
                else
                {
                    float t = 0;
                    canHit = dmnsn_ray_box_intersection(ray, aabb, t);
                    hitPosWS = ray.x0 * canHit + dir * canHit * t;
                }
                
                half4 col = 0; 
                
                if (canHit)
                {
                    half rate = RayMarchingAgainstSDFVolume3D(hitPosWS, dir, aabb);
                    col.rgb = rate > 0 ? HsvToRgb(half3(rate.x, 0.8, 1.7 * rate.x)) : 0;
                }
                
                return col;
            }
            ENDHLSL
        }
    }
}