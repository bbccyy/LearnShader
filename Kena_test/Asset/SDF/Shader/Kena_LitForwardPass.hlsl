#ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#include "Kena_Lighting.hlsl"

// GLES2 has limited amount of interpolators
#if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
    #define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
#endif

#if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL) || defined(_HAIRON)
    #define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
#endif

// keep this file in sync with LitGBufferPass.hlsl

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 staticLightmapUV : TEXCOORD1;
    float2 dynamicLightmapUV : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv : TEXCOORD0;

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
        float3 positionWS : TEXCOORD1;
    #endif

    float3 normalWS : TEXCOORD2;
    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
        half4 tangentWS : TEXCOORD3;    // xyz: tangent, w: sign
    #endif
    float3 viewDirWS : TEXCOORD4;

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        half4 fogFactorAndVertexLight : TEXCOORD5; // x: fogFactor, yzw: vertex light
    #else
        half fogFactor : TEXCOORD5;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        float4 shadowCoord : TEXCOORD6;
    #endif

    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        half3 viewDirTS : TEXCOORD7;
    #endif

    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
    #ifdef DYNAMICLIGHTMAP_ON
        float2 dynamicLightmapUV : TEXCOORD9; // Dynamic lightmap UVs
    #endif

    float4 positionCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
        inputData.positionWS = input.positionWS;
    #endif

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    #if defined(_NORMALMAP) || defined(_DETAIL)
        float sgn = input.tangentWS.w;      // should be either +1 or -1
        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
        half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

        #if defined(_NORMALMAP)
            inputData.tangentToWorld = tangentToWorld;
        #endif
        inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
    #else
        inputData.normalWS = input.normalWS;
    #endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
        inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
        inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    #else
        inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
    #else
        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
    #endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

    #if defined(DEBUG_DISPLAY)
        #if defined(DYNAMICLIGHTMAP_ON)
            inputData.dynamicLightmapUV = input.dynamicLightmapUV;
        #endif
        #if defined(LIGHTMAP_ON)
            inputData.staticLightmapUV = input.staticLightmapUV;
        #else
            inputData.vertexSH = input.vertexSH;
        #endif
    #endif
}

// 头发高光
float3 HairSpecular(half3 basecolor, float2 UV, float3 bitangentWS, float3 normalWS, float3 viewDir, Light light)
{
    float shift ;
    Unity_SimpleNoise_float(float2(UV.x * 5, UV.y * 0.1), 100, shift);

    float shift1 = shift - _Shift1;
    float shift2 = shift - _Shift2;
    float3 worldBinormal = bitangentWS;
    float3 worldNormal = normalWS;
    float3 worldBinormal1 = normalize(worldBinormal + shift1 * worldNormal);
    float3 worldBinormal2 = normalize(worldBinormal + shift2 * worldNormal);
    float3 H = normalize(light.direction + viewDir);

    //计算第一条高光
    float dotTH1 = dot(worldBinormal1, H);
    float sinTH1 = sqrt(1.0 - dotTH1 * dotTH1);
    float dirAtten1 = smoothstep(-1, 0, dotTH1);
    float gloss1 = lerp(8, 256, _Gloss1);
    float S1 = dirAtten1 * pow(sinTH1, gloss1);
    //计算第二条高光
    float dotTH2 = dot(worldBinormal2, H);
    float sinTH2 = sqrt(1.0 - dotTH2 * dotTH2);
    float dirAtten2 = smoothstep(-1, 0, dotTH2);
    float gloss2 = lerp(8, 256, _Gloss2);

    float S2 = dirAtten2 * pow(sinTH2, gloss2);

    float3 specular = _SpecularColor.rgb * light.color * saturate(S1 + S2 * basecolor.rgb);
    
    return specular;
}
///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    half fogFactor = 0;
    #if !defined(_FOG_FRAGMENT)
        fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    #endif

    output.uv = input.texcoord;

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
    


    //树叶法线
    #if defined(_LEAF_ON)
        output.normalWS.xyz = TransformObjectToWorldDir(input.positionOS.xyz, false) ;
        output.normalWS.xyz = output.normalWS.xyz - TransformObjectToWorldDir(_LeafCenter.xyz, false);
        output.normalWS.xyz = normalize(output.normalWS.xyz);
    #endif





    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        real sign = input.tangentOS.w * GetOddNegativeScale();
        half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
    #endif
    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
        output.tangentWS = tangentWS;
    #endif

    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
        half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
        output.viewDirTS = viewDirTS;
    #endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
    #ifdef DYNAMICLIGHTMAP_ON
        output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
    #else
        output.fogFactor = fogFactor;
    #endif

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
        output.positionWS = vertexInput.positionWS;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        output.shadowCoord = GetShadowCoord(vertexInput);
    #endif

    output.positionCS = vertexInput.positionCS;

    return output;
}


#if SHADER_API_GLES3 && SHADER_LIBRARY_VERSION_MAJOR < 10
    #define FRONT_FACE_SEMANTIC_REAL VFACE
#else
    #define FRONT_FACE_SEMANTIC_REAL FRONT_FACE_SEMANTIC
#endif
// Used in Standard (Physically Based) shader
half4 LitPassFragment(Varyings input, FRONT_FACE_TYPE vertexFace : FRONT_FACE_SEMANTIC_REAL) : SV_Target

// half4 LitPassFragment(Varyings input) : SV_Target

{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    #if defined(_PARALLAXMAP)
        #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
            half3 viewDirTS = input.viewDirTS;
        #else
            half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
            half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
        #endif
        ApplyPerPixelDisplacement(viewDirTS, input.uv);
    #endif





    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);


    //苔藓    kena
    #if defined(_DEADMOSS)
        half DeadMossMap = SAMPLE_TEXTURE2D(_DeadMossMap, sampler_BaseMap, input.uv * _DeadMossMap_ST.xy + _DeadMossMap_ST.zw).r;
        half DeadMossBaseArea = pow(max(0, DeadMossMap), 0.8f) + DeadMossMap;  //苔藓基础区域
        half DeadMossBrightArea = pow(max(0, DeadMossBaseArea), 7);   //苔藓亮部区域
        half DeadMossDarkArea = pow(1 - DeadMossBaseArea, 5);   //苔藓暗部区域
        half3 Deadcolor = lerp(_DarkColor.rgb, _MossMiddleColor.rgb, DeadMossMap);    //苔藓基础颜色
        Deadcolor = lerp(Deadcolor.rgb, _BrightColor.rgb, DeadMossBrightArea);    //加上亮部区域
        Deadcolor = lerp(Deadcolor.rgb, _DarkColor.rgb, DeadMossDarkArea);   //压暗暗部区域
        Deadcolor *= _DeadColorIntensity;
        half4 DeadMossMask = SAMPLE_TEXTURE2D(_DeadMossMask, sampler_BaseMap, input.uv * _DeadMossMask_ST.xy + _DeadMossMask_ST.zw);
        DeadMossMask.b = SAMPLE_TEXTURE2D(_DeadMossMask, sampler_BaseMap, input.uv).b;

        #if BUMP_SCALE_NOT_SUPPORTED
            half3 DeadMossNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DeadMossNnrmal, sampler_BaseMap, input.uv * _DeadMossNnrmal_ST.xy + _DeadMossNnrmal_ST.zw));
        #else
            half3 DeadMossNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DeadMossNnrmal, sampler_BaseMap, input.uv * _DeadMossNnrmal_ST.xy + _DeadMossNnrmal_ST.zw), _DeadMossNnrmalScale);
        #endif
        
        DeadMossNormalTS = normalize(DeadMossNormalTS);

        
        float DeadRange = pow(saturate(dot(input.normalWS, normalize(float3(_DeadDeviation_X, _DeadDeviation_Y, _DeadDeviation_Z)))), lerp(64, 1, _DeadRange));
        DeadMossMask.b = lerp(DeadMossMask.b, DeadRange, _DeadRangeMask);
        
        surfaceData.albedo = lerp(surfaceData.albedo, Deadcolor, DeadMossMask.b);
        surfaceData.normalTS = lerp(surfaceData.normalTS, DeadMossNormalTS, DeadMossMask.b);
        surfaceData.metallic = lerp(surfaceData.metallic, 0, DeadMossMask.b);
        surfaceData.smoothness = lerp(surfaceData.smoothness, DeadMossMask.a * _DeadMossSmoothness, DeadMossMask.b);
        surfaceData.occlusion = lerp(surfaceData.occlusion, DeadMossMask.g, DeadMossMask.b);
    #endif


    //  return half4(surfaceData.albedo,1);


    InputData inputData;
    // InitializeInputData(input, surfaceData.normalTS, inputData);
    //下面是改的InitializeInputData （因为头发需要付切线）

    inputData = (InputData)0;

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
        inputData.positionWS = input.positionWS;
    #endif

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    float3 bitangent = 0;
    #if defined(_NORMALMAP) || defined(_DETAIL) || defined(_HAIRON)
        float sgn = input.tangentWS.w;      // should be either +1 or -1
        bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
        half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

        #if defined(_NORMALMAP)
            inputData.tangentToWorld = tangentToWorld;
        #endif
        inputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, tangentToWorld);
    #else
        inputData.normalWS = input.normalWS;
    #endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
        inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
        inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    #else
        inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
    #else
        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
    #endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

    #if defined(DEBUG_DISPLAY)
        #if defined(DYNAMICLIGHTMAP_ON)
            inputData.dynamicLightmapUV = input.dynamicLightmapUV;
        #endif
        #if defined(LIGHTMAP_ON)
            inputData.staticLightmapUV = input.staticLightmapUV;
        #else
            inputData.vertexSH = input.vertexSH;
        #endif
    #endif









    #if !defined(_LEAF_ON)
        if (IS_FRONT_VFACE(vertexFace, true, false) == false)
            inputData.normalWS = -inputData.normalWS;
    #endif

    SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

    #ifdef _DBUFFER
        ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
    #endif

    // half4 color = UniversalFragmentPBR(inputData, surfaceData);


    //下面这部分是用UniversalFragmentPBR改的
    #if defined(_SPECULARHIGHLIGHTS_OFF)
        bool specularHighlightsOff = true;
    #else
        bool specularHighlightsOff = false;
    #endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    #if defined(DEBUG_DISPLAY)
        half4 debugColor;

        if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
        {
            return debugColor;
        }
    #endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);

    // #if defined(_SKINON)           //试着用这个办法去掉SSAO 去不掉
    //     aoFactor.indirectAmbientOcclusion = surfaceData.occlusion;
    //     aoFactor.directAmbientOcclusion = 1;

    // #endif


    uint meshRenderingLayers = GetMeshRenderingLightLayer();
    
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    mainLight.color *= aoFactor.indirectAmbientOcclusion;


    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
    inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
    inputData.normalWS, inputData.viewDirectionWS);




    // lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
    // mainLight,
    // inputData.normalWS, inputData.viewDirectionWS,
    // surfaceData.clearCoatMask, specularHighlightsOff);


    //这里用LightingPhysicallyBased改的

    half NdotL = dot(inputData.normalWS, mainLight.direction);
    // NdotL = smoothstep(0, 0.2, NdotL);

    #if defined(_CLOTH)       //布料做透光效果用ABS         //kena
        if (NdotL < 0)
            NdotL = abs(NdotL * 0.3);
    #endif


    float shadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation ;


    half3 radiance = 0;
    #if defined(_SKINON)        //皮肤效果
        float halfNdotL = NdotL * 0.5 + 0.5;
        float VdotL = dot(inputData.viewDirectionWS, mainLight.direction);
        float SkinMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, input.uv).a;        //这里存的是曲率  SSS

        float lutU = lerp(0.05, 0.95, halfNdotL);         //这里本来应该是采样0到1  但是UV精度问题 采样到0 和1的时候会有一两个像素的偏移 所以往回降一点
        float lutV = lerp(0.1, 0.95, saturate(-VdotL) * (1 - SkinMask));         //负的Vdotl是让视线方向和光方向在越靠近同一个半球的时候越没有皮肤的透光效果

        half3 SkinLight = SAMPLE_TEXTURE2D(_Skin_LUT_Map, sampler_BaseMap, float2(lutU, lutV)).rgb;

        radiance = mainLight.color * shadow * (SkinLight + ((1 - SkinLight) * _SkinLightInt));
    #elif defined(_EYEON)
        radiance = mainLight.color * shadow * (NdotL * 0.5 + 0.5);
    #else
        radiance = mainLight.color * shadow * saturate(NdotL);
    #endif




    half3 brdf = brdfData.diffuse;
    #ifndef _SPECULARHIGHLIGHTS_OFF
        [branch] if (!specularHighlightsOff)
        {
            #if defined(_HAIRON)
                half3 specular = HairSpecular(brdf, input.uv, bitangent, inputData.normalWS, inputData.viewDirectionWS, mainLight);
                brdf += specular;
            #else
                brdf += brdfData.specular * DirectBRDFSpecular(brdfData, inputData.normalWS, mainLight.direction, inputData.viewDirectionWS);
            #endif

            #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
                // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
                // We rely on the compiler to merge these and compute them only once.
                half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, inputData.normalWS, mainLight.direction, inputData.viewDirectionWS);

                // Mix clear coat and base layer using khronos glTF recommended formula
                // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
                // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
                half NoV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
                // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
                // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
                half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

                brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
            #endif // _CLEARCOAT

        }
    #endif

    


    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    {
        lightingData.mainLightColor = brdf * radiance;
    }




    //LightingPhysicallyBased改的到这里结束






    #if defined(_ADDITIONAL_LIGHTS)
        uint pixelLightCount = GetAdditionalLightsCount();

        #if USE_CLUSTERED_LIGHTING
            for (uint lightIndex = 0; lightIndex < min(_AdditionalLightsDirectionalCount, MAX_VISIBLE_LIGHTS); lightIndex++)
            {
                Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

                if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
                {
                    lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                    inputData.normalWS, inputData.viewDirectionWS,
                    surfaceData.clearCoatMask, specularHighlightsOff);
                }
            }
        #endif

        LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
            inputData.normalWS, inputData.viewDirectionWS,
            surfaceData.clearCoatMask, specularHighlightsOff);
        }
        LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif



    half4 color = CalculateFinalColor(lightingData, surfaceData.alpha);

    ///UniversalFragmentPBR到这里结束


















    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    color.a = OutputAlpha(color.a, _Surface);

    #if !defined(_HDREMISSION)
        color = saturate(color);
    #endif

    return color;
}

#endif
