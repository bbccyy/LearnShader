Shader "Test/Tree Bark"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1) 
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5		//Alpha test 裁剪阈值 

		[Header(Albedo Texture)]_Color("Color", Color) = (1,1,1,0)
		_MainTex("Albedo", 2D) = "white" {}										//基础色

		//控制裁剪模式 
		[Enum(Off,0,Front,1,Back,2)]_CullMode("Cull Mode", Int) = 2

		[Header(Normal Texture)]_BumpMap("Normal", 2D) = "bump" {}
		_BumpScale("Normal Strength", Float) = 1

		[Enum(On,0,Off,1)][Header(Detail Settings)]_BaseDetail("Base Detail", Int) = 1
		_DetailColor("Detail Color", Color) = (1,1,1,0)
		_DetailAlbedoMap("Detail", 2D) = "white" {}
		_DetailNormalMap("Detail Normal", 2D) = "bump" {}

		_Height("Height", Range( 0 , 1)) = 0
		_Smooth("Smooth", Range( 0.01 , 0.5)) = 0.02
		_TextureInfluence("Texture Influence", Range( 0 , 1)) = 0.5

		[Header(Other Settings)]_OcclusionStrength("AO strength", Range( 0 , 1)) = 0.6

		//PBR相关 
		_Metallic("Metallic", Range( 0 , 1)) = 0
		_Glossiness("Smoothness", Range( 0 , 1)) = 0

		//Wind effect
		[Header(Wind)]_GlobalWindInfluence("Global Wind Influence", Range( 0 , 1)) = 1

		//占位 
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}

	SubShader
	{
		LOD 0

		
		Tags { 
			"RenderPipeline"="UniversalPipeline" 
			"RenderType"="Opaque" 
			"Queue"="Geometry" 
		}
		
		Cull [_CullMode]
		HLSLINCLUDE
		#pragma target 2.0   //target 3.0?
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero , One Zero
			ZWrite On
			ZTest LEqual

			Offset 0 , 0	//default setting就是0,0，表示不做额外多边形偏移 
			ColorMask RGBA  //default setting就是4个通道全开，全要写
			

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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"  //REMOVE？
			

			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR

			#pragma multi_compile __ LOD_FADE_CROSSFADE

			//Wind Related local value
			float _WindStrength;		//控制整体风强，底噪
			float _RandomWindOffset;
			float _WindPulse;			//控制阵风，脉冲
			float _WindDirection;

			sampler2D _DetailAlbedoMap;
			sampler2D _MainTex;
			sampler2D _DetailNormalMap;
			sampler2D _BumpMap;

			CBUFFER_START( UnityPerMaterial )
			int _CullMode;
			float _GlobalWindInfluence;
			float4 _DetailColor;
			float4 _DetailAlbedoMap_ST;
			float4 _MainTex_ST;
			float4 _Color;
			half _Height;
			half _TextureInfluence;
			half _Smooth;
			int _BaseDetail;
			float4 _DetailNormalMap_ST;
			half _BumpScale;
			float4 _BumpMap_ST;
			float _Metallic;
			float _Glossiness;
			half _OcclusionStrength;
			CBUFFER_END


			struct VertexInput
			{
				float4 vertex : POSITION; 
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 color : COLOR;				//vertex color RGB: ... A: ao
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;		//Unity Lightmap uv and/or Probe sh
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;			//xyz:normalWS,		w:positionWS.x
				float4 tSpace1 : TEXCOORD4;			//xyz:tangentWS,	w:positionWS.y
				float4 tSpace2 : TEXCOORD5;			//xyz:bitangentWS,	w:positionWS.z
				float4 texcoord6 : TEXCOORD6;		
				float4 color : COLOR;
				float4 texcoord7 : TEXCOORD7;		//screen pos
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			float2 DirectionalEquation( float _WindDirection )  //TODO: move to common 
			{
				float d = _WindDirection * 0.0174532924;
				float xL = cos(d) + 1 / 2;
				float zL = sin(d) + 1 / 2;
				return float2(zL,xL);
			}
			
			inline float Dither8x8Bayer( int x, int y )  //TODO: move to common 
			{
				const float dither[ 64 ] = {
					 1, 49, 13, 61,  4, 52, 16, 64,
					33, 17, 45, 29, 36, 20, 48, 32,
					 9, 57,  5, 53, 12, 60,  8, 56,
					41, 25, 37, 21, 44, 28, 40, 24,
					 3, 51, 15, 63,  2, 50, 14, 62,
					35, 19, 47, 31, 34, 18, 46, 30,
					11, 59,  7, 55, 10, 58,  6, 54,
					43, 27, 39, 23, 42, 26, 38, 22
				};
				int r = y * 8 + x;
				return dither[r] / 64; // same # of instructions as pre-dividing due to compiler magic
			}
			

			VertexOutput vert ( VertexInput IN  )
			{
				VertexOutput OUT = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

				//world position
				float3 positionWS = TransformObjectToWorld(IN.vertex).xyz;
				//wind strength
				half windStrength = _WindStrength * _GlobalWindInfluence;
				//world position of model root
				half3 rootWS = TransformObjectToWorld(float4(0, 0, 0, 1)).xyz;
				//calc a random time based on world position
				half randomTime = _Time.x * lerp(
					0.8, 
					(_RandomWindOffset / 2.0) + 0.9, 
					frac(sin(dot(rootWS.xz, half2(12.9898, 78.233))) * 43758.55)
				);

				//Turbulence Intensity
				half turbulence = sin(randomTime * 40.0 - positionWS.z / 15.0) * 0.5;

				//Angle of Turbulence 
				half angleFactor = sin(randomTime * 2 + turbulence - (positionWS.z / 50.0) - (IN.color.r / 20.0)) + 1;	//range:[0,2]
				half angle = windStrength * angleFactor * sqrt(IN.color.r) * 0.2 * _WindPulse;							//wind:0 -> angle:0
				half cosA = cos(angle);
				half sinA = sin(angle);

				//creat random direction on x-z plane 
				half2 xzLerp = DirectionalEquation(_WindDirection);

				//position of vetex after wind modification
				float3 vertexPosWS = float3(0, 0, 0);
				vertexPosWS.x = lerp(positionWS.x, positionWS.y * sinA + positionWS.x * cosA, xzLerp.y);
				vertexPosWS.z = lerp(positionWS.z, positionWS.y * sinA + positionWS.z * cosA, xzLerp.x);
				vertexPosWS.y = positionWS.y * cosA - positionWS.z * sinA;
				
				//pass screen position to ps 
				float4 positionCS = TransformObjectToHClip(IN.vertex);  //未做顶点修改的入参 
				float4 screenPos = ComputeScreenPos(positionCS);		//todo 
				OUT.texcoord7 = screenPos;
				
				OUT.color = IN.color;					//pass vertex color
				OUT.texcoord6.xy = IN.texcoord.xy;		//uv
				OUT.texcoord6.zw = 0;	//setting value to unused interpolator channels and avoid initialization warnings
				
				//re-calc positionWS and positionCS based on final(modified) bark pos in world space 
				positionWS = vertexPosWS;
				positionCS = TransformWorldToHClip(positionWS);
				
				//pass TBN and positionWS to ps
				VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normal, IN.tangent);
				OUT.tSpace0 = float4(normalInput.normalWS, positionWS.x);
				OUT.tSpace1 = float4(normalInput.tangentWS, positionWS.y);
				OUT.tSpace2 = float4(normalInput.bitangentWS, positionWS.z);

				//unity lightmap or probe (GI)
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
				OUT.shadowCoord = GetShadowCoord(vpInputs);		//vetex shadow coordinate
#endif

				OUT.positionCS = positionCS;
				return OUT;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				//prepare params 
				float3 normalWS = normalize(IN.tSpace0.xyz);
				float3 tangentWS = IN.tSpace1.xyz;
				float3 biTangentWS = IN.tSpace2.xyz;
				float3 positionWS = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
				float3 viewDirectionWS = _WorldSpaceCameraPos.xyz - positionWS;
				float4 shadowCoords = float4(0, 0, 0, 0);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					shadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					shadowCoords = TransformWorldToShadowCoord(positionWS);
				#endif

				//Calculate Albedo
				//uv albedo
				float2 uv_mainTex = TRANSFORM_TEX(IN.texcoord6.xy, _MainTex);
				float2 uv_detailAlbedo = TRANSFORM_TEX(IN.texcoord6.xy, _DetailAlbedoMap);
				//sample texture
				half4 albedoFromTex = tex2D(_MainTex, uv_mainTex);
				half4 albedoFromDetail = tex2D(_DetailAlbedoMap, uv_detailAlbedo);
				//base albedo 
				half4 baseAlbedo = _Color * albedoFromTex; 
				//calc detail to base rate 
				float colorEnergy = albedoFromTex.r + albedoFromTex.g + albedoFromTex.b - 0.5;
				float barkDamageBlend = saturate((IN.color.r - _Height + colorEnergy * _TextureInfluence)/ _Smooth);
				//final albedo from two lerps
				float4 lerpdetailToAlbedo = lerp(_DetailColor * albedoFromDetail, baseAlbedo, barkDamageBlend);
				float4 Albedo = lerp(lerpdetailToAlbedo, baseAlbedo, (float)_BaseDetail);

				//Calculate Normal
				//uv normal
				float2 uv_detailNorm = TRANSFORM_TEX(IN.texcoord6.xy, _DetailNormalMap);
				float2 uv_bump = TRANSFORM_TEX(IN.texcoord6.xy, _BumpMap);
				//sampel normal
				float3 detailNormFromTex = UnpackNormalScale(tex2D(_DetailNormalMap, uv_detailNorm), _BumpScale);
				float3 bumpFromTex = UnpackNormalScale(tex2D(_BumpMap, uv_bump), _BumpScale);
				//final normal from two lerps
				float3 lerpNormFirst = lerp(detailNormFromTex, bumpFromTex, barkDamageBlend);
				float3 Normal = lerp(lerpNormFirst, bumpFromTex, (float)_BaseDetail);

				//Smoothness
				//_Glossiness convert to smoothness, 而且越绿越光滑
				float Smoothness = lerp(0.0, albedoFromTex.r, _Glossiness);  

				//AO
				float Occlusion = lerp(1.0, IN.color.a, _OcclusionStrength);

				//alpha
				float4 screenPos = IN.texcoord7;
				float4 screenPosNorm = screenPos / screenPos.w;
				screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
				float2 clipScreen = screenPosNorm.xy * _ScreenParams.xy;
				float dither = Dither8x8Bayer(fmod(clipScreen.x, 8), fmod(clipScreen.y, 8));
				dither = step(dither, unity_LODFade.x);
				float Alpha = 1;
#ifdef LOD_FADE_CROSSFADE
				Alpha = albedoFromTex.a * dither;
#else
				Alpha = albedoFromTex.a;
#endif
				
				float3 Emission = 0;
				float3 Specular = 0.5;			//todo 
				float Metallic = _Metallic;
				float AlphaClipThreshold = 0.5;
				float3 BakedGI = 0;

				InputData inputData;
				inputData.positionWS = positionWS;
				inputData.viewDirectionWS = viewDirectionWS;
				inputData.shadowCoord = shadowCoords;

				#ifdef _NORMALMAP
					inputData.normalWS = normalize(TransformTangentToWorld(Normal, half3x3(tangentWS, biTangentWS, normalWS)));
				#else
					inputData.normalWS = normalize(normalWS);
				#endif

				inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, inputData.normalWS );

				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha);

#ifdef TERRAIN_SPLAT_ADDPASS
				color.rgb = MixFogColor(color.rgb, half3(0, 0, 0), IN.fogFactorAndVertexLight.x);
#else
				color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
#endif
				
				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif
				
				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.positionCS.xyz, unity_LODFade.x );
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile __ LOD_FADE_CROSSFADE

			float _WindStrength;
			float _RandomWindOffset;
			float _WindPulse;
			float _WindDirection;

			sampler2D _MainTex;

			CBUFFER_START( UnityPerMaterial )
			int _CullMode;
			float _GlobalWindInfluence;
			float4 _DetailColor;
			float4 _DetailAlbedoMap_ST;
			float4 _MainTex_ST;
			float4 _Color;
			half _Height;
			half _TextureInfluence;
			half _Smooth;
			int _BaseDetail;
			float4 _DetailNormalMap_ST;
			half _BumpScale;
			float4 _BumpMap_ST;
			float _Metallic;
			float _Glossiness;
			half _OcclusionStrength;
			CBUFFER_END


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 texcoord2 : TEXCOORD2;
				float4 texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			float2 DirectionalEquation( float _WindDirection )
			{
				float d = _WindDirection * 0.0174532924;
				float xL = cos(d) + 1 / 2;
				float zL = sin(d) + 1 / 2;
				return float2(zL,xL);
			}
			
			inline float Dither8x8Bayer( int x, int y )
			{
				const float dither[ 64 ] = {
					 1, 49, 13, 61,  4, 52, 16, 64,
					33, 17, 45, 29, 36, 20, 48, 32,
					 9, 57,  5, 53, 12, 60,  8, 56,
					41, 25, 37, 21, 44, 28, 40, 24,
					 3, 51, 15, 63,  2, 50, 14, 62,
					35, 19, 47, 31, 34, 18, 46, 30,
					11, 59,  7, 55, 10, 58,  6, 54,
					43, 27, 39, 23, 42, 26, 38, 22
				};
				int r = y * 8 + x;
				return dither[r] / 64; // same # of instructions as pre-dividing due to compiler magic
			}
			

			float3 _LightDirection;

			VertexOutput ShadowPassVertex(VertexInput IN)
			{
				VertexOutput OUT = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

				//world position
				float3 positionWS = TransformObjectToWorld(IN.vertex).xyz;
				//wind strength
				half windStrength = _WindStrength * _GlobalWindInfluence;
				//world position of model root
				half3 rootWS = TransformObjectToWorld(float4(0, 0, 0, 1)).xyz;
				//calc a random time based on world position
				half randomTime = _Time.x * lerp(
					0.8,
					(_RandomWindOffset / 2.0) + 0.9,
					frac(sin(dot(rootWS.xz, half2(12.9898, 78.233))) * 43758.55)
				);

				//Turbulence Intensity
				half turbulence = sin(randomTime * 40.0 - positionWS.z / 15.0) * 0.5;

				//Angle of Turbulence 
				half angleFactor = sin(randomTime * 2 + turbulence - (positionWS.z / 50.0) - (IN.color.r / 20.0)) + 1;	//range:[0,2]
				half angle = windStrength * angleFactor * sqrt(IN.color.r) * 0.2 * _WindPulse;							//wind:0 -> angle:0
				half cosA = cos(angle);
				half sinA = sin(angle);

				//creat random direction on x-z plane 
				half2 xzLerp = DirectionalEquation(_WindDirection);

				//position of vetex after wind modification
				float3 vertexPosWS = float3(0, 0, 0);
				vertexPosWS.x = lerp(positionWS.x, positionWS.y * sinA + positionWS.x * cosA, xzLerp.y);
				vertexPosWS.z = lerp(positionWS.z, positionWS.y * sinA + positionWS.z * cosA, xzLerp.x);
				vertexPosWS.y = positionWS.y * cosA - positionWS.z * sinA;

				//pass screen position to ps 
				float4 positionCS = TransformObjectToHClip(IN.vertex);  //未做顶点修改的入参 
				float4 screenPos = ComputeScreenPos(positionCS);		//todo 
				OUT.texcoord3 = screenPos;

				OUT.texcoord2.xy = IN.texcoord.xy;		//uv
				OUT.texcoord2.zw = 0;	//setting value to unused interpolator channels and avoid initialization warnings

				//re-calc positionWS and positionCS based on final(modified) bark pos in world space 
				positionWS = vertexPosWS;
				positionCS = TransformWorldToHClip(positionWS);


#if UNITY_REVERSED_Z
				positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
				positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

				OUT.positionCS = positionCS;
				return OUT;
			}

			half4 ShadowPassFragment(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				float2 uv_mainTex = TRANSFORM_TEX(IN.texcoord2.xy, _MainTex);
				half4 albedoFromTex = tex2D(_MainTex, uv_mainTex);		//sample main texture

				float4 screenPos = IN.texcoord3;
				float4 screenPosNorm = screenPos / screenPos.w;
				screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
				float2 clipScreen = screenPosNorm.xy * _ScreenParams.xy;
				float dither = Dither8x8Bayer(fmod(clipScreen.x, 8), fmod(clipScreen.y, 8));
				dither = step(dither, unity_LODFade.x);

				float AlphaClipThreshold = 0.5;

#ifdef _ALPHATEST_ON
				clip(pAlpha - AlphaClipThreshold);
#endif
#ifdef LOD_FADE_CROSSFADE
				float pAlpha = albedoFromTex.a * dither;
#else
				float pAlpha = albedoFromTex.a;
#endif
				return 0;
			}

			ENDHLSL
		}
	}

	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}