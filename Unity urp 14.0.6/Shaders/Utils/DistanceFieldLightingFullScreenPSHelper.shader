
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
            ZWrite Off ZTest Always Cull Back Blend Off

            HLSLPROGRAM
            #pragma vertex Vert 
            #pragma fragment FragCopyNormAndDepth 

            float4 FragCopyNormAndDepth(Varyings IN) : SV_Target
            {
                 float3 norm = _GBuffer2.Sample(my_point_clamp_sampler,IN.texcoord.xy).xyz;
                 float depth = _GBuffer4.Sample(my_point_clamp_sampler, IN.texcoord.xy).x;
                 return float4(norm * 2.0f - 1.0f, depth);
            }
            ENDHLSL
        }

        Pass
        {
            Name "UpdateHistroyDepthRejectionPS"
            Tags {"RenderPipeline" = "UniversalPipeline"}
            ZWrite Off ZTest Always Cull Back Blend Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragUpdateHistoryDepthRejection

            void FragUpdateHistoryDepthRejection(
                in Varyings IN,
                out float4 UpsampledBentNormal : SV_Target0
            )
            {
                float4 NewValue;
                float4 UVAndScreenPos = float4(IN.texcoord.xy, IN.texcoord.xy * 2.0f - 1.0f); //no need to revert screenPos.y -> the build-in Vert already did the uv revertion for us

                GeometryAwareUpsample(UVAndScreenPos, NewValue);

                float2 ScreenVelocity = 0;

                float2 FullResTexel = UVAndScreenPos.xy - 0.5f * View_BufferSizeAndInvSize.zw;  //convert BaseLevelTexelSize to FullScreenTexelSize
                float2 VelocityUV = SAMPLE_TEXTURE2D_LOD(_BentNormalMotionVectorTexture, my_point_clamp_sampler, FullResTexel, 0).rg; //VelocityUV = (posNDC.xy - prevPosNDC.xy) * 0.5f

                float2 PreScreenPos = UVAndScreenPos.zw - VelocityUV * 2.0f;
                float2 PreUV = PreScreenPos * 0.5f + 0.5f;

                float EffectiveHistoryWeight = HistoryWeight;  //const value, but could be setted outside
                [flatten]
                if (any(PreUV > 0.9999) || any(PreUV < 0.0001) || NewValue.w <= 0)  //todo 
                {
                    EffectiveHistoryWeight = 0;
                }

                PreUV = clamp(PreUV, 0.0001, 0.9999); //do not sample an invalid place

                float4 HistoryValue = SAMPLE_TEXTURE2D_LOD(_BentNorm_History, my_point_clamp_sampler, PreUV, 0);

                float PositionWeight = ComputeHistoryWeightBasedOnPosition(UVAndScreenPos.xy, NewValue.w, PreUV, HistoryValue.w);
                EffectiveHistoryWeight *= PositionWeight;

                UpsampledBentNormal.rgb = lerp(NewValue.rgb, HistoryValue.rgb, EffectiveHistoryWeight);  //todo: FIX EffectiveHistoryWeight!
                UpsampledBentNormal.rgb = MakeFinite(UpsampledBentNormal.rgb);
                UpsampledBentNormal.rgb *= NewValue.w == 0 ? 0 : 1; //do not make the edge fluffy
                UpsampledBentNormal.a = NewValue.w;
                UpsampledBentNormal.a *= EffectiveHistoryWeight > 0 ? 1 : -1;
            }
            ENDHLSL
        }

        Pass
        {
            Name "FilterHistoryPS"
            Tags {"RenderPipeline" = "UniversalPipeline"}
            ZWrite Off ZTest Always Cull Back Blend Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragFilterHistory

            #define HALF_HISTORY_FILL_KERNEL_SIZE 2

            void FragFilterHistory(
                in Varyings IN,
                out float4 OutBentNormal : SV_Target0
            )
            {
                float2 BufferUV = IN.texcoord.xy;
                float4 CurrentValue = SAMPLE_TEXTURE2D_LOD(_BentNorm, my_point_clamp_sampler, BufferUV, 0);

                if (CurrentValue.w < 0)
                {
                    float4 HistoryValue = CurrentValue;  //Find out History value that had been rejected by previous pass
                    float  DeviceZ = abs(HistoryValue.w);
                    float4 Accumulation = 0;
                    
                    for (float y = -HALF_HISTORY_FILL_KERNEL_SIZE; y <= HALF_HISTORY_FILL_KERNEL_SIZE; y++)
                    {
                        for (float x = -HALF_HISTORY_FILL_KERNEL_SIZE; x <= HALF_HISTORY_FILL_KERNEL_SIZE; x++)
                        {
                            float2 SampleBufferUV = BufferUV + BaseLevelSizeAndTexelSize.zw * float2(x, y);

                            float4 TextureValue = SAMPLE_TEXTURE2D_LOD(_BentNorm, my_point_clamp_sampler, SampleBufferUV, 0);
                            float ValidMask = TextureValue.w > 0;

                            float SampleDeviceZ = abs(TextureValue.w);

                            float DepthWeight = exp2(-1000 * abs(SampleDeviceZ - DeviceZ) / DeviceZ); //TODO: how about using scene depth?
                            float2 SSWeight = exp2(-abs(float2(x, y) * 10.0f / HALF_HISTORY_FILL_KERNEL_SIZE));
                            float ScreenSpaceSpatialWeight = max(SSWeight.x, SSWeight.y);

                            
                            float Weight = ValidMask * ScreenSpaceSpatialWeight * DepthWeight;

                            Accumulation.rgb += TextureValue.rgb * Weight;
                            Accumulation.a += Weight;
                        }
                    }

                    if (Accumulation.a > 0)
                    {
                        float InvWeight = 1.0f / Accumulation.a;
                        CurrentValue.xyz = lerp(HistoryValue.xyz, Accumulation.xyz * InvWeight, HistoryWeight);
                    }
                }

                OutBentNormal = float4(CurrentValue.rgb, abs(CurrentValue.a));
            }
            ENDHLSL
        }
    }
}
