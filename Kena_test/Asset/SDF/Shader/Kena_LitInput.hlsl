#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Kena_Function.hlsl"

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
    #define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST, _BumpMap_ST, _OcclusionMap_ST;
    float4 _DetailAlbedoMap_ST;
    half4 _BaseColor;
    half4 _DetailColor;
    half4 _SpecColor;
    half4 _EmissionColor;
    half _Cutoff;
    half _Smoothness;
    half _Metallic;
    half _BumpScale;
    half _Parallax;
    half _OcclusionStrength;
    half _ClearCoatMask;
    half _ClearCoatSmoothness;
    half _DetailAlbedoMapScale;
    half _DetailNormalMapScale;
    half _Surface;
    // 茅草
    float _Thatch_UV;
    //苔藓
    half _DeadColorIntensity, _DeadMossSmoothness, _DeadDeviation_X, _DeadDeviation_Y, _DeadDeviation_Z, _DeadRange, _DeadMossNnrmalScale, _DeadRangeMask;
    float4 _DeadMossMap_ST, _DeadMossMask_ST, _DeadMossNnrmal_ST;
    half4 _BrightColor, _MossMiddleColor, _DarkColor;

    //Skin
    float _LUTOffset, _SkinLightInt;
    //头发
    float _Gloss1, _Gloss2, _Shift1, _Shift2;
    float4 _SpecularColor;
    //树叶
    #if defined(_LEAF_ON)
        float4 _LeafCenter;
    #endif

    //眼珠
    #if defined(_EYEON)
        float _EyeSize, _EyeNormalSize, _PupilSize, _PupilRange;
    #endif

    //基础颜色控制
    float _ColorInt, _ColorSaturation;

CBUFFER_END

// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
#ifdef UNITY_DOTS_INSTANCING_ENABLED
    UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
    UNITY_DOTS_INSTANCED_PROP(float, _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float, _Smoothness)
    UNITY_DOTS_INSTANCED_PROP(float, _Metallic)
    UNITY_DOTS_INSTANCED_PROP(float, _BumpScale)
    UNITY_DOTS_INSTANCED_PROP(float, _Parallax)
    UNITY_DOTS_INSTANCED_PROP(float, _OcclusionStrength)
    UNITY_DOTS_INSTANCED_PROP(float, _ClearCoatMask)
    UNITY_DOTS_INSTANCED_PROP(float, _ClearCoatSmoothness)
    UNITY_DOTS_INSTANCED_PROP(float, _DetailAlbedoMapScale)
    UNITY_DOTS_INSTANCED_PROP(float, _DetailNormalMapScale)
    UNITY_DOTS_INSTANCED_PROP(float, _Surface)
    UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

    #define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4, Metadata_BaseColor)
    #define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4, Metadata_SpecColor)
    #define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4, Metadata_EmissionColor)
    #define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Cutoff)
    #define _Smoothness             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Smoothness)
    #define _Metallic               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Metallic)
    #define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_BumpScale)
    #define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Parallax)
    #define _OcclusionStrength      UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_OcclusionStrength)
    #define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_ClearCoatMask)
    #define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_ClearCoatSmoothness)
    #define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_DetailAlbedoMapScale)
    #define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_DetailNormalMapScale)
    #define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Surface)
#endif

TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_DetailMask);         SAMPLER(sampler_DetailMask);
TEXTURE2D(_DetailAlbedoMap);    SAMPLER(sampler_DetailAlbedoMap);
TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);
TEXTURE2D(_ClearCoatMap);       SAMPLER(sampler_ClearCoatMap);
TEXTURE2D(_DeadMossMap);        SAMPLER(sampler_DeadMossMap);
TEXTURE2D(_DeadMossMask);      /*  SAMPLER(sampler_DeadMossMask); */
TEXTURE2D(_DeadMossNnrmal);       /* SAMPLER(sampler_DeadMossNnrmal); */
TEXTURE2D(_Skin_LUT_Map);      /*  SAMPLER(sampler_Skin_LUT_Map); */

TEXTURE2D(_EyeMap);


#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

    #ifdef _METALLICSPECGLOSSMAP
        specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _Smoothness;
        #else
            specGloss.a *= _Smoothness;
        #endif
    #else // _METALLICSPECGLOSSMAP
        #if _SPECULAR_SETUP
            specGloss.rgb = _SpecColor.rgb;
        #else
            specGloss.rgb = _Metallic.rrr;
        #endif

        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _Smoothness;
        #else
            specGloss.a = _Smoothness;
        #endif
    #endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
        // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
        #if defined(SHADER_API_GLES)
            return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
        #else
            half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
            return LerpWhiteTo(occ, _OcclusionStrength);
        #endif
    #else
        return half(1.0);
    #endif
}


// Returns clear coat parameters
// .x/.r == mask
// .y/.g == smoothness
half2 SampleClearCoat(float2 uv)
{
    #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);

        #if defined(_CLEARCOATMAP)
            clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
        #endif

        return clearCoatMaskSmoothness;
    #else
        return half2(0.0, 1.0);
    #endif  // _CLEARCOAT

}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
    #if defined(_PARALLAXMAP)
        uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
    #endif
}

// Used for scaling detail albedo. Main features:
// - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
// - No effect is applied if detailAlbedo is 0.5.
half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
{
    // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
    // detailAlbedo *= _DetailAlbedoMapScale;
    // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
    // return detailAlbedo * 2.0f;

    // A bit more optimized
    return half(2.0) * detailAlbedo * scale - scale + half(1.0);
}


half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
{
    #if defined(_DETAIL)
        half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;
        detailAlbedo *= _DetailColor.rgb;
        // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
        #if defined(_DETAIL_SCALED)
            detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
        #else
            detailAlbedo = half(2.0) * detailAlbedo;
        #endif

        return lerp(albedo, detailAlbedo, detailMask);
    #else
        return albedo;
    #endif
}

half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
{
    #if defined(_DETAIL)
        #if BUMP_SCALE_NOT_SUPPORTED
            half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
        #else
            half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
        #endif

        // With UNITY_NO_DXT5nm unpacked vector is not normalized for BlendNormalRNM
        // For visual consistancy we going to do in all cases
        detailNormalTS = normalize(detailNormalTS);

        return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
    #else
        return normalTS;
    #endif
}


inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{

    float2 albedoUV = uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
    float2 normalUV = uv * _BumpMap_ST.xy + _BumpMap_ST.zw;
    float2 aoUV = uv * _OcclusionMap_ST.xy + _OcclusionMap_ST.zw;
    #if defined(_EYEON)      //瞳

        float eyeSize = lerp(16, 0.1, _EyeSize);
        float2 PupilUV1 = uv * eyeSize + ((1 - eyeSize) / 2) + _BaseMap_ST.zw; //瞳膜的UV
        float pupilSize = lerp(3, 0.1, _PupilSize);
        float2 PupilUV2 = PupilUV1 * pupilSize + ((1 - pupilSize) / 2);

        float PupilMask = smoothstep(0.01, _PupilRange, length(PupilUV1 - 0.5));  //这里是计算出来的瞳孔遮罩

        float PupilMask2 = 1 - smoothstep(_PupilRange, _PupilRange + 0.1, length(PupilUV1 - 0.5));  //这里是计算出来的瞳膜遮罩

        albedoUV = lerp(PupilUV2, PupilUV1, PupilMask);       //瞳孔UV
        
        float3 eyeMap = SAMPLE_TEXTURE2D(_EyeMap, sampler_BaseMap, uv).rgb;




    #endif
    
    half4 albedoAlpha = SampleAlbedoAlpha(albedoUV, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));



    #if defined(_THATCH)
        float noise = 0;
        float noise2 = 0;
        Unity_SimpleNoise_float(uv, _Thatch_UV, noise);
        // albedoAlpha.a *= saturate(noise * 2);
        albedoAlpha.rgb = lerp(noise * albedoAlpha.rgb, albedoAlpha.rgb, noise);
    #endif
    







    #if defined(_THATCH_EDGE) && defined(_THATCH)
        outSurfaceData.alpha = Alpha(saturate(noise * 2), _BaseColor, _Cutoff);
    #else
        outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    #endif

    
    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);




    // _BaseColor.rgb = float3(0.520833, 0.330932, 0.154622);
    albedoAlpha.rgb = (albedoAlpha.rgb) * _ColorInt * (_BaseColor.rgb);
    float r0 = dot(albedoAlpha.rgb, float3(0.300000, 0.590000, 0.110000));

    outSurfaceData.albedo = saturate(_ColorSaturation * (r0 - albedoAlpha.rgb) + albedoAlpha.rgb);


    
    #if defined(_EYEON)       //加上眼白
        outSurfaceData.albedo = lerp(eyeMap, outSurfaceData.albedo, PupilMask2);
    #endif


    #if _SPECULAR_SETUP
        outSurfaceData.metallic = half(1.0);
        outSurfaceData.specular = specGloss.rgb;
    #else
        outSurfaceData.metallic = specGloss.r;
        outSurfaceData.specular = half3(0.0, 0.0, 0.0);
    #endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(normalUV, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(aoUV);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

    #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        half2 clearCoat = SampleClearCoat(uv);
        outSurfaceData.clearCoatMask = clearCoat.r;
        outSurfaceData.clearCoatSmoothness = clearCoat.g;
    #else
        outSurfaceData.clearCoatMask = half(0.0);
        outSurfaceData.clearCoatSmoothness = half(0.0);
    #endif

    #if defined(_DETAIL)
        half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
        float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
        outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
        outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
    #endif
    // outSurfaceData.albedo = half3(frac(albedoUV), 0);

}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
