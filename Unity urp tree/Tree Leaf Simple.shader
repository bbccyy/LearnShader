Shader "Test/Tree Leaf Simple"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5   //Alpha test 裁剪阈值 

		[Header(Albedo Texture)]_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {} //基础色 三通道F0 

		[Enum(Off,0,Front,1,Back,2)]_CullMode("Cull Mode", Int) = 0  //默认关闭双面裁剪 
		_Cutoff("Cutoff", Range(0 , 1)) = 0.5   //同Alpha test 裁剪阈值 

		[Header(Normal Texture)]_BumpMap("Normal Map", 2D) = "bump" {}  //法线贴图 
		_BumpScale("Normal Strength", Float) = 1   //法线强度 

		[Header(Other Settings)]_OcclusionStrength("AO strength", Range(0 , 1)) = 0.6  //AO 强度 
		_Metallic("Metallic", Range(0 , 1)) = 0   //金属度 PBR
		_Glossiness("Smoothness", Range(0 , 1)) = 0  //光滑度 PBR

		[Enum(Off,0,On,1)][Header(Translucency)]_TranslucencyEnum("Translucency", Int) = 1  //默认开启透光
		_Translucency("Strength", Range(0 , 50)) = 4						//透光强度
		_TransNormalDistortion("Normal Distortion", Range(0 , 10)) = 1		//法线扰动强度
		_TransScale("Scale", Range(0 , 10)) = 1								//Trans Salce 
		_TransScattering("Scattering Falloff", Range(0.2 , 5)) = 1			//透光色散强度   
		[HDR]_TranslucencyTint("Translucency Tint", Color) = (1,1,1,0)		//透射染色 Tint

		//[Header(Wind)]
		_WindAmbientStrength("Ambient Strength", Range(0.0, 1.0)) = 0.2
		_WindSpeed("Speed", Range(0.0, 10.0)) = 3.0
		_WindDirection("Direction", vector) = (1,0,0,0)
		_WindVertexRand("Vertex randomization", Range(0.0, 1.0)) = 0.6
		_WindObjectRand("Object randomization", Range(0.0, 1.0)) = 0.5
		_WindRandStrength("Random per-object strength", Range(0.0, 1.0)) = 0.5
		_WindSwinging("Swinging", Range(0.0, 1.0)) = 0.15
		_WindGustStrength("Gusting strength", Range(0.0, 1.0)) = 0.2
		_WindGustFreq("Gusting frequency", Range(0.0, 10.0)) = 4
		[NoScaleOffset] _WindMap("Wind map", 2D) = "black" {}
		_WindGustTint("Gusting tint", Range(0.0, 1.0)) = 0.066

	}

		SubShader
	{
		LOD 0

		Tags {
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}

		Cull[_CullMode]

		HLSLINCLUDE
		#pragma target 3.0   //support VFACE and VPOS 
		ENDHLSL

			Pass
		{

			Name "Forward"
			Tags { "LightMode" = "UniversalForward" }

			Blend One Zero , One Zero
			ZWrite On
			ZTest LEqual


			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog

			#define _NORMALMAP 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR

			#pragma multi_compile __ LOD_FADE_CROSSFADE

			sampler2D _MainTex;   //定义 基础色的采样器
			sampler2D _BumpMap;   //定义 法线贴图的采样器 

			CBUFFER_START(UnityPerMaterial)  //面板参数放在这里 
			float4 _Color;
			float4 _MainTex_ST;
			float _TransScattering;
			float _TransNormalDistortion;
			int _CullMode;
			float4 _BumpMap_ST;
			half _BumpScale;
			float _Translucency;
			float _TransScale;
			float4 _TranslucencyTint;
			int _TranslucencyEnum;
			float _Metallic;
			float _Glossiness;
			half _OcclusionStrength;
			half _Cutoff;

			//Wind
			half _WindAmbientStrength;
			half _WindSpeed;
			half4 _WindDirection;
			half _WindVertexRand;
			half _WindObjectRand;
			half _WindRandStrength;
			half _WindSwinging;
			half _WindGustStrength;
			half _WindGustFreq;
			half _WindGustTint;
			CBUFFER_END

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;

				float4 texcoord1 : TEXCOORD1;   //Litmap
				//color.r = l.distanceFromOrigin/10) * VColBarkModifier
				//color.g = randomWindPhase
				//color.b = blueChannel * VColLeafModifier
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;    //UV
				float4 texcoord3 : TEXCOORD3;   //user defined data to control transcattering 
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;	//shadow coordinate: to apply shadow in ps
				#endif
				float4 tSpace0 : TEXCOORD3;		//xyz:normalWS,		w:positionWS.x
				float4 tSpace1 : TEXCOORD4;		//xyz:tangentWS,	w:positionWS.y
				float4 tSpace2 : TEXCOORD5;		//xyz:bitangentWS,	w:positionWS.z
				float4 color : COLOR;			//vertex color RGBA:  todo 
				float4 texcoord6 : TEXCOORD6;	//xy:IN.texcoord.xy(uv),	zw:IN.texcoord3.xy(vertex texture coord)
				float4 texcoord7 : TEXCOORD7;   //screen position
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			#include "Lib.hlsl" 

			VertexOutput vert(VertexInput IN)
			{
				VertexOutput OUT = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

				float posOffset = ObjectPosRand01();

				float bendMask = 1; 
				WindSettings wind = PopulateWindSettings(_WindAmbientStrength, _WindSpeed, _WindDirection, _WindSwinging, 
					bendMask, _WindObjectRand, _WindVertexRand, _WindRandStrength, _WindGustStrength, _WindGustFreq);

				VertexHolder vertexholder = GetVertexOutput(IN, posOffset, wind);

				//distance
				float D = distance(IN.positionOS.xyz, float3(0, 0, 0));
				//adjust distance rate
				float depth = saturate(D / 2.5);
				IN.color.a = depth;

				//pass screen position to ps 
				//params for applying Disther effect 
				float4 positionCS = TransformObjectToHClip(IN.positionOS);
				float4 screenPos = ComputeScreenPos(positionCS);
				OUT.texcoord7 = screenPos;

				OUT.color = IN.color;					//pass vertex color
				OUT.texcoord6.xy = IN.texcoord.xy;		//uv

				float3 positionWS = vertexholder.positionWS;
				positionCS = vertexholder.positionCS;

				//pass TBN and positionWS to ps
				VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
				OUT.tSpace0 = float4(normalInput.normalWS, positionWS.x);
				OUT.tSpace1 = float4(normalInput.tangentWS, positionWS.y);
				OUT.tSpace2 = float4(normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV(IN.texcoord1, unity_LightmapST, OUT.lightmapUVOrVertexSH.xy);	//Unity lightmap uv
				OUTPUT_SH(normalInput.normalWS.xyz, OUT.lightmapUVOrVertexSH.xyz);					//Unity lightprobe sh

				//pass vertex light and fog factor to ps
				half3 vertexLight = VertexLighting(positionWS, normalInput.normalWS);
				half fogFactor = ComputeFogFactor(positionCS.z);
				OUT.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vpInputs = (VertexPositionInputs)0;
				vpInputs.positionWS = positionWS;
				vpInputs.positionCS = positionCS;
				OUT.shadowCoord = GetShadowCoord(vpInputs);
#endif

				OUT.positionCS = positionCS;
				return OUT;

			}

			half4 frag(VertexOutput IN, half vface : VFACE) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				float3 normalWS = normalize(IN.tSpace0.xyz);
				float3 tangentWS = IN.tSpace1.xyz;
				float3 biTangentWS = IN.tSpace2.xyz;
				float3 positionWS = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
				float3 viewDirectionWS = _WorldSpaceCameraPos.xyz - positionWS;
				float4 shadowCoords = IN.shadowCoord;

				float2 uv_mainTex = TRANSFORM_TEX(IN.texcoord6.xy, _MainTex);

				half4 albedoFromTex = tex2D(_MainTex, uv_mainTex);		//sample main texture
				clip(albedoFromTex.a - _Cutoff);						//clip asap 

				half4 albedo = _Color * albedoFromTex;					//final albedo 

				//normal
				float3 flippedNormalTS = UnpackNormalScale(tex2D(_BumpMap, IN.texcoord6.xy), _BumpScale) * vface;
				//构建tbn 
				float3 tanToWorld0 = float3(tangentWS.x, biTangentWS.x, normalWS.x);
				float3 tanToWorld1 = float3(tangentWS.y, biTangentWS.y, normalWS.y);
				float3 tanToWorld2 = float3(tangentWS.z, biTangentWS.z, normalWS.z);
				//normal in tangent space to normal in world space
				float3 normalTexWS = float3(dot(tanToWorld0, flippedNormalTS), dot(tanToWorld1, flippedNormalTS), dot(tanToWorld2, flippedNormalTS));

				//translucency
				//get view, light and normal dir
				half3 vDir = viewDirectionWS;
				half3 lDir = _MainLightPosition.xyz;   //indicate light dir 
				half3 nDir = normalTexWS;
				//H
				half3 H = normalize(_TransNormalDistortion * nDir + lDir);  //注意此处为 N 和 L的半角 
				//V dot H
				half VdotH = pow(saturate(dot(vDir, -H)), (50.0 - _Translucency)) * _TransScale;  //注意此处为 -H，表示叶子的反方向 
				//trans color Src
				half3 colorSrc = _TranslucencyTint.rgb;
				//col Intensity 
				//half3 I = _TransScattering * (VdotH + colorSrc) * (1.0 - IN.texcoord6.z);
				half3 I = _TransScattering * (VdotH + colorSrc) * IN.color.a;  //TODO 
				//albedo after appling translucent lighting 
				half3 finalAlbedo = lerp(albedo.rgb, (albedo.rgb * I), (float)_TranslucencyEnum);  //_TranslucencyEnum = 1 时使用透射增强的albedo 
				//smoothness
				half smoothness = lerp(0.0, albedoFromTex.r, _Glossiness);
				//AO 
				half AO = lerp(1.0, IN.color.a, _OcclusionStrength);

				//alpha
				float4 screenPos = IN.texcoord7;
				float4 screenPosNorm = screenPos / screenPos.w;
				screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
				float2 clipScreen = screenPosNorm.xy * _ScreenParams.xy;
				float dither = Dither8x8Bayer(fmod(clipScreen.x, 8), fmod(clipScreen.y, 8));
				dither = step(dither, unity_LODFade.x);
#ifdef LOD_FADE_CROSSFADE
				float pAlpha = albedoFromTex.a * dither;
#else
				float pAlpha = albedoFromTex.a;
#endif

				//pack up 
				float3 pAlbedo = finalAlbedo;
				float3 pNormal = normalTexWS;
				float3 pEmission = 0;
				float3 pSpecular = 0.5;
				float pMetallic = _Metallic;
				float pSmoothness = smoothness;
				float pOcclusion = AO;
				float pAlphaClipThreshold = 0.5;
				float3 pBakedGI = 0;

				InputData inputData = (InputData)0;
				inputData.positionWS = positionWS;
				inputData.viewDirectionWS = viewDirectionWS;
				inputData.shadowCoord = shadowCoords;

#ifdef _NORMALMAP
				inputData.normalWS = normalTexWS;
#else
	#if !SHADER_HINT_NICE_QUALITY
				inputData.normalWS = normalWS;
	#else
				inputData.normalWS = normalize(normalWS);
	#endif
#endif

				inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, inputData.normalWS);

				half4 color = UniversalFragmentPBR(
					inputData,
					pAlbedo,
					pMetallic,
					pSpecular,
					pSmoothness,
					pOcclusion,
					pEmission,
					pAlpha);

#ifdef TERRAIN_SPLAT_ADDPASS
				color.rgb = MixFogColor(color.rgb, half3(0, 0, 0), IN.fogFactorAndVertexLight.x);
#else
				color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
#endif

#ifdef _ALPHATEST_ON
				clip(pAlpha - AlphaClipThreshold);
#endif

#ifdef LOD_FADE_CROSSFADE
				LODDitheringTransition(IN.positionCS.xyz, unity_LODFade.x);
#endif
				//return IN.texcoord6.zzzz;
				//return half4(albedo.rgb, 1);
				//return half4(finalAlbedo.rgb, 1);
				return color;
			}

			ENDHLSL
		}


		Pass
		{

			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define _NORMALMAP 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment

			#define SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile __ LOD_FADE_CROSSFADE

			sampler2D _MainTex;   //定义 基础色的采样器

			CBUFFER_START(UnityPerMaterial)  //面板参数放在这里 
				float4 _Color;
				float4 _MainTex_ST;
				float _TransScattering;
				float _TransNormalDistortion;
				int _CullMode;
				float4 _BumpMap_ST;
				half _BumpScale;
				float _Translucency;
				float _TransScale;
				float4 _TranslucencyTint;
				int _TranslucencyEnum;
				float _Metallic;
				float _Glossiness;
				half _OcclusionStrength;
				half _Cutoff;

				//Wind
				half _WindAmbientStrength;
				half _WindSpeed;
				half4 _WindDirection;
				half _WindVertexRand;
				half _WindObjectRand;
				half _WindRandStrength;
				half _WindSwinging;
				half _WindGustStrength;
				half _WindGustFreq;
				half _WindGustTint;
			CBUFFER_END

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 color : COLOR;			//vertex color
				float4 texcoord : TEXCOORD0;    //UV
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};


			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 texcoord2 : TEXCOORD2;
				float4 texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			#include "Lib.hlsl" 

			float3 _LightDirection;

			VertexOutput ShadowPassVertex(VertexInput IN)
			{
				VertexOutput OUT = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

				float posOffset = ObjectPosRand01();

				float bendMask = 1;
				WindSettings wind = PopulateWindSettings(_WindAmbientStrength, _WindSpeed, _WindDirection, _WindSwinging, 
					bendMask, _WindObjectRand, _WindVertexRand, _WindRandStrength, _WindGustStrength, _WindGustFreq);

				VertexHolder vertexholder = GetVertexOutput(IN, posOffset, wind);

				//distance
				float D = distance(IN.positionOS.xyz, float3(0, 0, 0));
				//adjust distance rate
				float depth = saturate(D / 2.5);
				IN.color.a = depth;
				
				//pass screen position to ps 
				float4 positionCS = TransformObjectToHClip(IN.positionOS);
				float4 screenPos = ComputeScreenPos(positionCS);
				OUT.texcoord3 = screenPos;
				OUT.texcoord2.xy = IN.texcoord.xy;		//uv

				float3 positionWS = vertexholder.positionWS;
				positionCS = vertexholder.positionCS;

				float3 normalWS = TransformObjectToWorldDir(IN.normalOS);
				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

		#if UNITY_REVERSED_Z
				clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
		#else
				clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
		#endif
				OUT.positionCS = clipPos;
				return OUT;
			}


			half4 ShadowPassFragment(VertexOutput IN) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				float2 uv_mainTex = TRANSFORM_TEX(IN.texcoord2.xy, _MainTex);
				half4 albedoFromTex = tex2D(_MainTex, uv_mainTex);		//sample main texture
				clip(albedoFromTex.a - _Cutoff);						//clip asap 

				float4 screenPos = IN.texcoord3;
				float4 screenPosNorm = screenPos / screenPos.w;
				screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
				float2 clipScreen = screenPosNorm.xy * _ScreenParams.xy;
				float dither = Dither8x8Bayer(fmod(clipScreen.x, 8), fmod(clipScreen.y, 8));
				dither = step(dither, unity_LODFade.x);
		#ifdef LOD_FADE_CROSSFADE
				float pAlpha = albedoFromTex.a * dither;
		#else
				float pAlpha = albedoFromTex.a;
		#endif
				float AlphaClipThreshold = 0.5;

		#ifdef _ALPHATEST_ON
				clip(pAlpha - AlphaClipThreshold);
		#endif

				return 0;
			}

			ENDHLSL
		}

	}
		Fallback "Hidden/InternalErrorShader"
}
