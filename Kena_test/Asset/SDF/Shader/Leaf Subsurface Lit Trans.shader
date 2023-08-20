// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "BOXOPHOBIC/The Vegetation Engine/Default/Leaf Subsurface Lit Trans"
{

	//-------------------------------------------------------------------------------------
	// BEGIN_PROPERTIES
	//-------------------------------------------------------------------------------------

	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[StyledCategory(Render Settings, 5, 10)]_CategoryRender("[ Category Render ]", Float) = 0
		[Enum(Opaque,0,Transparent,1)]_RenderMode("Render Mode", Float) = 0
		[Enum(Off,0,On,1)]_RenderZWrite("Render ZWrite", Float) = 1
		[Enum(Both,0,Back,1,Front,2)]_RenderCull("Render Faces", Float) = 0
		[Enum(Flip,0,Mirror,1,Same,2)]_RenderNormals("Render Normals", Float) = 0
		[HideInInspector]_RenderQueue("Render Queue", Float) = 0
		[HideInInspector]_RenderPriority("Render Priority", Float) = 0
		[Enum(Off,0,On,1)]_RenderSpecular("Render Specular", Float) = 1
		[Enum(Off,0,On,1)]_RenderDecals("Render Decals", Float) = 0
		[Enum(Off,0,On,1)]_RenderSSR("Render SSR", Float) = 0
		[Space(10)]_RenderDirect("Render Direct", Range( 0 , 1)) = 1
		_RenderShadow("Render Shadow", Range( 0 , 1)) = 1
		_RenderAmbient("Render Ambient", Range( 0 , 1)) = 1
		[Enum(Off,0,On,1)][Space(10)]_RenderClip("Alpha Clipping", Float) = 1
		[Enum(Off,0,On,1)]_RenderCoverage("Alpha To Mask", Float) = 0
		_AlphaClipValue("Alpha Treshold", Range( 0 , 1)) = 0.5
		_AlphaFeatherValue("Alpha Feather", Range( 0 , 2)) = 0.5
		[StyledSpace(10)]_SpaceRenderFade("# Space Render Fade", Float) = 0
		_FadeGlancingValue("Fade by Glancing Angle", Range( 0 , 1)) = 0
		_FadeCameraValue("Fade by Camera Distance", Range( 0 , 1)) = 1
		[StyledCategory(Global Settings)]_CategoryGlobal("[ Category Global ]", Float) = 0
		[StyledEnum(TVELayers, Default 0 Layer_1 1 Layer_2 2 Layer_3 3 Layer_4 4 Layer_5 5 Layer_6 6 Layer_7 7 Layer_8 8, 0, 0)]_LayerColorsValue("Layer Colors", Float) = 0
		[StyledEnum(TVELayers, Default 0 Layer_1 1 Layer_2 2 Layer_3 3 Layer_4 4 Layer_5 5 Layer_6 6 Layer_7 7 Layer_8 8, 0, 0)]_LayerExtrasValue("Layer Extras", Float) = 0
		[StyledEnum(TVELayers, Default 0 Layer_1 1 Layer_2 2 Layer_3 3 Layer_4 4 Layer_5 5 Layer_6 6 Layer_7 7 Layer_8 8, 0, 0)]_LayerMotionValue("Layer Motion", Float) = 0
		[StyledEnum(TVELayers, Default 0 Layer_1 1 Layer_2 2 Layer_3 3 Layer_4 4 Layer_5 5 Layer_6 6 Layer_7 7 Layer_8 8, 0, 0)]_LayerVertexValue("Layer Vertex", Float) = 0
		[StyledSpace(10)]_SpaceGlobalLayers("# Space Global Layers", Float) = 0
		[StyledMessage(Info, Procedural Variation in use. The Variation might not work as expected when switching from one LOD to another., _VertexVariationMode, 1 , 0, 10)]_MessageGlobalsVariation("# Message Globals Variation", Float) = 0
		_GlobalColors("Global Color", Range( 0 , 1)) = 1
		_GlobalAlpha("Global Alpha", Range( 0 , 1)) = 1
		_GlobalOverlay("Global Overlay", Range( 0 , 1)) = 1
		_GlobalWetness("Global Wetness", Range( 0 , 1)) = 1
		_GlobalEmissive("Global Emissive", Range( 0 , 1)) = 1
		_GlobalSize("Global Size Fade", Range( 0 , 1)) = 1
		[StyledSpace(10)]_SpaceGlobalLocals("# Space Global Locals", Float) = 0
		[StyledRemapSlider(_ColorsMaskMinValue, _ColorsMaskMaxValue, 0, 1)]_ColorsMaskRemap("Color Mask", Vector) = (0,0,0,0)
		[HideInInspector]_ColorsMaskMinValue("Color Mask Min Value", Range( 0 , 1)) = 0
		[HideInInspector]_ColorsMaskMaxValue("Color Mask Max Value", Range( 0 , 1)) = 0
		_ColorsVariationValue("Color Variation", Range( 0 , 1)) = 0
		[StyledRemapSlider(_AlphaMaskMinValue, _AlphaMaskMaxValue, 0, 1, 10, 0)]_AlphaMaskRemap("Alpha Mask", Vector) = (0,0,0,0)
		_AlphaVariationValue("Alpha Variation", Range( 0 , 1)) = 1
		[StyledRemapSlider(_OverlayMaskMinValue, _OverlayMaskMaxValue, 0, 1)]_OverlayMaskRemap("Overlay Mask", Vector) = (0,0,0,0)
		[HideInInspector]_OverlayMaskMinValue("Overlay Mask Min Value", Range( 0 , 1)) = 0.45
		[HideInInspector]_OverlayMaskMaxValue("Overlay Mask Max Value", Range( 0 , 1)) = 0.55
		_OverlayVariationValue("Overlay Variation", Range( 0 , 1)) = 0
		[StyledSpace(10)]_SpaceGlobalPosition("# Space Global Position", Float) = 0
		[StyledToggle]_ColorsPositionMode("Use Pivot Position for Colors", Float) = 0
		[StyledToggle]_ExtrasPositionMode("Use Pivot Position for Extras", Float) = 0
		[StyledCategory(Main Settings)]_CategoryMain("[Category Main ]", Float) = 0
		[NoScaleOffset][StyledTextureSingleLine]_MainAlbedoTex("Main Albedo", 2D) = "white" {}
		[NoScaleOffset][StyledTextureSingleLine]_MainNormalTex("Main Normal", 2D) = "bump" {}
		[NoScaleOffset][StyledTextureSingleLine]_MainMaskTex("Main Mask", 2D) = "white" {}
		[Space(10)][StyledVector(9)]_MainUVs("Main UVs", Vector) = (1,1,0,0)
		[HDR]_MainColor("Main Color", Color) = (1,1,1,1)
		_MainNormalValue("Main Normal", Range( -8 , 8)) = 1
		_MainOcclusionValue("Main Occlusion", Range( 0 , 1)) = 0
		_MainSmoothnessValue("Main Smoothness", Range( 0 , 1)) = 0
		[StyledCategory(Detail Settings)]_CategoryDetail("[ Category Detail ]", Float) = 0
		[Enum(Off,0,On,1)]_DetailMode("Detail Mode", Float) = 0
		[Enum(Overlay,0,Replace,1)]_DetailBlendMode("Detail Blend", Float) = 1
		[Enum(Vertex Blue,0,Projection,1)]_DetailTypeMode("Detail Type", Float) = 0
		[StyledRemapSlider(_DetailBlendMinValue, _DetailBlendMaxValue,0,1)]_DetailBlendRemap("Detail Blending", Vector) = (0,0,0,0)
		[StyledCategory(Occlusion Settings)]_CategoryOcclusion("[ Category Occlusion ]", Float) = 0
		[HDR]_VertexOcclusionColor("Vertex Occlusion Color", Color) = (1,1,1,1)
		[StyledRemapSlider(_VertexOcclusionMinValue, _VertexOcclusionMaxValue, 0, 1)]_VertexOcclusionRemap("Vertex Occlusion Mask", Vector) = (0,0,0,0)
		[HideInInspector]_VertexOcclusionMinValue("Vertex Occlusion Min Value", Range( 0 , 1)) = 0
		[HideInInspector]_VertexOcclusionMaxValue("Vertex Occlusion Max Value", Range( 0 , 1)) = 1
		[StyledCategory(Subsurface Settings)]_CategorySubsurface("[ Category Subsurface ]", Float) = 0
		_SubsurfaceValue("Subsurface Intensity", Range( 0 , 1)) = 1
		[HDR]_SubsurfaceColor("Subsurface Color", Color) = (0.4,0.4,0.1,1)
		[StyledRemapSlider(_SubsurfaceMaskMinValue, _SubsurfaceMaskMaxValue,0,1)]_SubsurfaceMaskRemap("Subsurface Mask", Vector) = (0,0,0,0)
		[HideInInspector]_SubsurfaceMaskMinValue("Subsurface Mask Min Value", Range( 0 , 1)) = 0
		[HideInInspector]_SubsurfaceMaskMaxValue("Subsurface Mask Max Value", Range( 0 , 1)) = 1
		[Space(10)][DiffusionProfile]_SubsurfaceDiffusion("Subsurface Diffusion", Float) = 0
		[HideInInspector]_SubsurfaceDiffusion_Asset("Subsurface Diffusion", Vector) = (0,0,0,0)
		[HideInInspector][Space(10)][ASEDiffusionProfile(_SubsurfaceDiffusion)]_SubsurfaceDiffusion_asset("Subsurface Diffusion", Vector) = (0,0,0,0)
		[Space(10)]_SubsurfaceScatteringValue("Subsurface Scattering", Range( 0 , 16)) = 2
		_SubsurfaceAngleValue("Subsurface Angle", Range( 1 , 16)) = 8
		_SubsurfaceNormalValue("Subsurface Normal", Range( 0 , 1)) = 0
		_SubsurfaceDirectValue("Subsurface Direct", Range( 0 , 1)) = 1
		_SubsurfaceAmbientValue("Subsurface Ambient", Range( 0 , 1)) = 0.2
		_SubsurfaceShadowValue("Subsurface Shadow", Range( 0 , 1)) = 1
		[StyledCategory(Gradient Settings)]_CategoryGradient("[ Category Gradient ]", Float) = 0
		[HDR]_GradientColorOne("Gradient Color One", Color) = (1,1,1,1)
		[HDR]_GradientColorTwo("Gradient Color Two", Color) = (1,1,1,1)
		[StyledRemapSlider(_GradientMinValue, _GradientMaxValue, 0, 1)]_GradientMaskRemap("Gradient Mask", Vector) = (0,0,0,0)
		[HideInInspector]_GradientMinValue("Gradient Mask Min", Range( 0 , 1)) = 0
		[HideInInspector]_GradientMaxValue("Gradient Mask Max ", Range( 0 , 1)) = 1
		[StyledCategory(Noise Settings)]_CategoryNoise("[ Category Noise ]", Float) = 0
		[StyledRemapSlider(_NoiseMinValue, _NoiseMaxValue, 0, 1)]_NoiseMaskRemap("Noise Mask", Vector) = (0,0,0,0)
		[StyledCategory(Emissive Settings)]_CategoryEmissive("[ Category Emissive]", Float) = 0
		[NoScaleOffset][Space(10)][StyledTextureSingleLine]_EmissiveTex("Emissive Texture", 2D) = "white" {}
		[Space(10)][StyledVector(9)]_EmissiveUVs("Emissive UVs", Vector) = (1,1,0,0)
		[Enum(None,0,Any,10,Baked,20,Realtime,30)]_EmissiveFlagMode("Emissive Baking", Float) = 0
		[HDR]_EmissiveColor("Emissive Color", Color) = (0,0,0,0)
		[StyledEmissiveIntensity]_EmissiveIntensityParams("Emissive Intensity", Vector) = (1,1,1,0)
		[StyledCategory(Perspective Settings)]_CategoryPerspective("[ Category Perspective ]", Float) = 0
		[StyledCategory(Size Fade Settings)]_CategorySizeFade("[ Category Size Fade ]", Float) = 0
		[StyledMessage(Info, The Size Fade feature is recommended to be used to fade out vegetation at a distance in combination with the LOD Groups or with a 3rd party culling system., _SizeFadeMode, 1, 0, 10)]_MessageSizeFade("# Message Size Fade", Float) = 0
		[StyledCategory(Motion Settings)]_CategoryMotion("[ Category Motion ]", Float) = 0
		[StyledMessage(Info, Procedural variation in use. Use the Scale settings if the Variation is splitting the mesh., _VertexVariationMode, 1 , 0, 10)]_MessageMotionVariation("# Message Motion Variation", Float) = 0
		_MotionFacingValue("Motion Facing Direction", Range( 0 , 1)) = 1
		_MotionNormalValue("Motion Normal Direction", Range( 0 , 1)) = 1
		[StyledSpace(10)]_SpaceMotionGlobals("# SpaceMotionGlobals", Float) = 0
		_MotionAmplitude_10("Motion Bending", Range( 0 , 2)) = 0.2
		[IntRange]_MotionSpeed_10("Motion Speed", Range( 0 , 40)) = 2
		_MotionScale_10("Motion Scale", Range( 0 , 20)) = 0
		_MotionVariation_10("Motion Variation", Range( 0 , 20)) = 0
		[Space(10)]_MotionAmplitude_20("Motion Squash", Range( 0 , 2)) = 0.2
		_MotionAmplitude_22("Motion Rolling", Range( 0 , 2)) = 0.2
		[IntRange]_MotionSpeed_20("Motion Speed", Range( 0 , 40)) = 6
		_MotionScale_20("Motion Scale", Range( 0 , 20)) = 0.5
		_MotionVariation_20("Motion Variation", Range( 0 , 20)) = 0
		[Space(10)]_MotionAmplitude_32("Motion Flutter", Range( 0 , 2)) = 0.2
		[IntRange]_MotionSpeed_32("Motion Speed", Range( 0 , 40)) = 20
		_MotionScale_32("Motion Scale", Range( 0 , 20)) = 10
		_MotionVariation_32("Motion Variation", Range( 0 , 20)) = 10
		[Space(10)]_InteractionAmplitude("Interaction Amplitude", Range( 0 , 2)) = 1
		_InteractionMaskValue("Interaction Use Mask", Range( 0 , 1)) = 1
		[StyledSpace(10)]_SpaceMotionLocals("# SpaceMotionLocals", Float) = 0
		[StyledToggle]_MotionValue_20("Use Branch Motion Settings", Float) = 1
		[ASEEnd][StyledToggle]_MotionValue_30("Use Flutter Motion Settings", Float) = 1
		[HideInInspector][StyledToggle]_VertexPivotMode("Enable Pre Baked Pivots", Float) = 0
		[HideInInspector][StyledToggle]_VertexDataMode("Enable Batching Support", Float) = 0
		[HideInInspector][StyledToggle]_VertexDynamicMode("Enable Dynamic Support", Float) = 0
		[HideInInspector]_render_normals("_render_normals", Vector) = (1,1,1,0)
		[HideInInspector]_Cutoff("Legacy Cutoff", Float) = 0.5
		[HideInInspector]_Color("Legacy Color", Color) = (0,0,0,0)
		[HideInInspector]_MainTex("Legacy MainTex", 2D) = "white" {}
		[HideInInspector]_BumpMap("Legacy BumpMap", 2D) = "white" {}
		[HideInInspector]_LayerReactValue("Legacy Layer React", Float) = 0
		[HideInInspector]_VertexRollingMode("Legacy Vertex Rolling", Float) = 1
		[HideInInspector]_MaxBoundsInfo("Legacy Bounds Info", Vector) = (1,1,1,1)
		[HideInInspector]_VertexVariationMode("_VertexVariationMode", Float) = 0
		[HideInInspector]_VertexMasksMode("_VertexMasksMode", Float) = 0
		[HideInInspector]_IsTVEShader("_IsTVEShader", Float) = 1
		[HideInInspector]_IsVersion("_IsVersion", Float) = 700
		[HideInInspector]_HasEmissive("_HasEmissive", Float) = 0
		[HideInInspector]_HasGradient("_HasGradient", Float) = 0
		[HideInInspector]_HasOcclusion("_HasOcclusion", Float) = 0
		[HideInInspector]_IsLeafShader("_IsLeafShader", Float) = 1
		[HideInInspector]_IsSubsurfaceShader("_IsSubsurfaceShader", Float) = 1
		[HideInInspector]_render_cull("_render_cull", Float) = 0
		[HideInInspector]_render_src("_render_src", Float) = 5
		[HideInInspector]_render_dst("_render_dst", Float) = 10
		[HideInInspector]_render_coverage("_render_coverage", Float) = 0
		[HideInInspector]_render_zw("_render_zw", Float) = 1


		[HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
		[HideInInspector]_QueueControl("_QueueControl", Float) = -1

		[HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
		[HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
		[HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		_TransStrength( "Strength", Range( 0, 50 ) ) = 1
		_TransNormal( "Normal Distortion", Range( 0, 1 ) ) = 0.5
		_TransScattering( "Scattering", Range( 1, 50 ) ) = 2
		_TransDirect( "Direct", Range( 0, 1 ) ) = 0.9
		_TransAmbient( "Ambient", Range( 0, 1 ) ) = 0.1
		_TransShadow( "Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	//-------------------------------------------------------------------------------------
	// END_PROPERTIES
	//-------------------------------------------------------------------------------------

	SubShader
	{
		LOD 0

		

		//-------------------------------------------------------------------------------------
		// BEGIN_PASS UNIVERSALPIPELINE
		//-------------------------------------------------------------------------------------
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

		Cull [_render_cull]
		ZWrite [_render_zw]
		ZTest LEqual
		Offset 0,0
		AlphaToMask [_render_coverage]

		

		//-------------------------------------------------------------------------------------
		// BEGIN_DEFINES
		//-------------------------------------------------------------------------------------

		HLSLINCLUDE

		#pragma target 4.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 

		#ifndef ASE_TESS_FUNCS
			#define ASE_TESS_FUNCS
			float4 FixedTess( float tessValue )
			{
				return tessValue;
			}
			
			float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
			{
				float3 wpos = mul(o2w,vertex).xyz;
				float dist = distance (wpos, cameraPos);
				float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
				return f;
			}

			float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
			{
				float4 tess;
				tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
				tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
				tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
				tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
				return tess;
			}

			float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
			{
				float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
				float len = distance(wpos0, wpos1);
				float f = max(len * scParams.y / (edgeLen * dist), 1.0);
				return f;
			}

			float DistanceFromPlane (float3 pos, float4 plane)
			{
				float d = dot (float4(pos,1.0f), plane);
				return d;
			}

			bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
			{
				float4 planeTest;
				planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
				planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
				(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
				return !all (planeTest);
			}

			float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
			{
				float3 f;
				f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
				f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
				f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

				return CalcTriEdgeTessFactors (f);
			}

			float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
			{
				float3 pos0 = mul(o2w,v0).xyz;
				float3 pos1 = mul(o2w,v1).xyz;
				float3 pos2 = mul(o2w,v2).xyz;
				float4 tess;
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
				return tess;
			}

			float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
			{
				float3 pos0 = mul(o2w,v0).xyz;
				float3 pos1 = mul(o2w,v1).xyz;
				float3 pos2 = mul(o2w,v2).xyz;
				float4 tess;

				if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
				{
					tess = 0.0f;
				}
				else
				{
					tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
					tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
					tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
					tess.w = (tess.x + tess.y + tess.z) / 3.0f;
				}
				return tess;
			}
		#endif //ASE_TESS_FUNCS

		ENDHLSL

		//-------------------------------------------------------------------------------------
		// END_PASS UNIVERSALPIPELINE
		//-------------------------------------------------------------------------------------

		
		//-------------------------------------------------------------------------------------
		// BEGIN_PASS UNIVERSALFORWARD
		//-------------------------------------------------------------------------------------
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }
			
			Blend [_render_src] [_render_dst], One Zero
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			HLSLPROGRAM

			#define _SPECULAR_SETUP 1
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#pragma multi_compile _ DOTS_INSTANCING_ON
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _TRANSLUCENCY_ASE 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120100


			//-----------------------------------------------------------------------------
			// DEFINES - (Universal Pipeline keywords) api 12.1.0 thru 14.0.3
			//-----------------------------------------------------------------------------
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _CLUSTERED_RENDERING

			//-----------------------------------------------------------------------------
			// DEFINES - (Unity defined keywords) api 12.1.0 thru 14.0.3
			//-----------------------------------------------------------------------------
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			//-----------------------------------------------------------------------------
			// DEFINES - (Set by User)
			//-----------------------------------------------------------------------------

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local TVE_FEATURE_CLIP
			#pragma shader_feature_local TVE_FEATURE_BATCHING
			//TVE Pipeline Defines
			#define THE_VEGETATION_ENGINE
			#define TVE_IS_UNIVERSAL_PIPELINE
			//TVE Injection Defines
			//SHADER INJECTION POINT BEGIN
			//SHADER INJECTION POINT END
			//TVE Shader Type Defines
			#define TVE_IS_VEGETATION_SHADER


			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					float4 screenPos : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_texcoord9 : TEXCOORD9;
				float4 ase_texcoord10 : TEXCOORD10;
				float4 ase_texcoord11 : TEXCOORD11;
				float4 ase_color : COLOR;
				float4 ase_texcoord12 : TEXCOORD12;
				float3 ase_normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//-------------------------------------------------------------------------------------
			// BEGIN_CBUFFER
			//-------------------------------------------------------------------------------------

			CBUFFER_START(UnityPerMaterial)
				half4 _ColorsMaskRemap;
				half4 _VertexOcclusionRemap;
				half4 _DetailBlendRemap;
				half4 _SubsurfaceMaskRemap;
				float4 _GradientMaskRemap;
				half4 _GradientColorTwo;
				float4 _MaxBoundsInfo;
				half4 _GradientColorOne;
				half4 _MainColor;
				half4 _MainUVs;
				float4 _Color;
				float4 _SubsurfaceDiffusion_Asset;
				half4 _AlphaMaskRemap;
				half4 _EmissiveColor;
				float4 _EmissiveIntensityParams;
				half4 _VertexOcclusionColor;
				float4 _SubsurfaceDiffusion_asset;
				half4 _OverlayMaskRemap;
				float4 _NoiseMaskRemap;
				half4 _SubsurfaceColor;
				half4 _EmissiveUVs;
				half3 _render_normals;
				half _MotionNormalValue;
				half _MotionValue_30;
				half _MotionAmplitude_32;
				half _FadeGlancingValue;
				float _MotionSpeed_32;
				half _FadeCameraValue;
				float _MotionVariation_32;
				float _MotionScale_32;
				half _MotionAmplitude_22;
				half _MotionAmplitude_20;
				half _MotionValue_20;
				half _MotionSpeed_20;
				half _MotionVariation_20;
				half _MotionScale_20;
				half _InteractionMaskValue;
				half _InteractionAmplitude;
				half _SubsurfaceValue;
				half _VertexDynamicMode;
				half _MotionVariation_10;
				float _MotionSpeed_10;
				float _MotionScale_10;
				half _MotionAmplitude_10;
				half _LayerMotionValue;
				half _MotionFacingValue;
				half _VertexDataMode;
				half _GlobalSize;
				half _GlobalAlpha;
				half _GlobalEmissive;
				half _RenderSpecular;
				half _MainNormalValue;
				half _OverlayMaskMaxValue;
				half _OverlayMaskMinValue;
				half _MainSmoothnessValue;
				half _OverlayVariationValue;
				half _LayerExtrasValue;
				half _ExtrasPositionMode;
				half _GlobalOverlay;
				half _ColorsMaskMaxValue;
				half _LayerVertexValue;
				half _ColorsMaskMinValue;
				half _GlobalWetness;
				half _GlobalColors;
				half _LayerColorsValue;
				half _ColorsPositionMode;
				half _VertexOcclusionMaxValue;
				half _VertexOcclusionMinValue;
				half _VertexPivotMode;
				half _MainOcclusionValue;
				half _GradientMaxValue;
				half _GradientMinValue;
				half _AlphaVariationValue;
				half _ColorsVariationValue;
				half _render_zw;
				half _IsLeafShader;
				half _render_coverage;
				half _CategoryOcclusion;
				half _CategoryMain;
				half _CategorySizeFade;
				half _SpaceMotionLocals;
				half _IsVersion;
				half _RenderCoverage;
				half _LayerReactValue;
				half _RenderMode;
				half _RenderPriority;
				half _CategoryMotion;
				half _RenderClip;
				half _RenderAmbient;
				half _CategoryDetail;
				half _CategoryEmissive;
				half _VertexVariationMode;
				half _SpaceGlobalPosition;
				half _MessageSizeFade;
				half _SubsurfaceAngleValue;
				half _HasGradient;
				half _SpaceRenderFade;
				half _HasEmissive;
				half _SpaceGlobalLocals;
				half _DetailMode;
				half _DetailTypeMode;
				half _CategorySubsurface;
				half _VertexMasksMode;
				half _RenderShadow;
				half _SpaceMotionGlobals;
				half _IsTVEShader;
				half _RenderNormals;
				half _CategoryGradient;
				half _SpaceGlobalLayers;
				half _render_dst;
				half _render_cull;
				half _render_src;
				half _SubsurfaceMaskMinValue;
				half _SubsurfaceNormalValue;
				half _MessageMotionVariation;
				half _RenderSSR;
				half _CategoryGlobal;
				half _SubsurfaceScatteringValue;
				half _SubsurfaceShadowValue;
				half _RenderZWrite;
				half _MessageGlobalsVariation;
				half _RenderDirect;
				half _RenderDecals;
				half _AlphaFeatherValue;
				half _EmissiveFlagMode;
				half _CategoryNoise;
				half _CategoryPerspective;
				float _SubsurfaceDiffusion;
				half _CategoryRender;
				half _RenderQueue;
				half _DetailBlendMode;
				half _SubsurfaceDirectValue;
				half _SubsurfaceAmbientValue;
				half _RenderCull;
				half _HasOcclusion;
				half _Cutoff;
				half _AlphaClipValue;
				half _VertexRollingMode;
				half _IsSubsurfaceShader;
				half _SubsurfaceMaskMaxValue;
				#ifdef _TRANSMISSION_ASE
					float _TransmissionShadow;
				#endif
				#ifdef _TRANSLUCENCY_ASE
					float _TransStrength;
					float _TransNormal;
					float _TransScattering;
					float _TransDirect;
					float _TransAmbient;
					float _TransShadow;
				#endif
				#ifdef TESSELLATION_ON
					float _TessPhongStrength;
					float _TessValue;
					float _TessMin;
					float _TessMax;
					float _TessEdgeLength;
					float _TessMaxDisp;
				#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			//-------------------------------------------------------------------------------------
			// END_CBUFFER
			//-------------------------------------------------------------------------------------

			sampler2D _BumpMap;
			half TVE_Enabled;
			sampler2D _MainTex;
			half4 TVE_MotionParams;
			TEXTURE2D_ARRAY(TVE_MotionTex);
			half4 TVE_MotionCoords;
			SAMPLER(sampler_linear_clamp);
			float TVE_MotionUsage[10];
			sampler2D TVE_NoiseTex;
			half4 TVE_NoiseParams;
			half4 TVE_FlutterParams;
			half TVE_MotionFadeEnd;
			half TVE_MotionFadeStart;
			half4 TVE_VertexParams;
			TEXTURE2D_ARRAY(TVE_VertexTex);
			half4 TVE_VertexCoords;
			float TVE_VertexUsage[10];
			half _DisableSRPBatcher;
			sampler2D _MainAlbedoTex;
			half4 TVE_ColorsParams;
			TEXTURE2D_ARRAY(TVE_ColorsTex);
			half4 TVE_ColorsCoords;
			float TVE_ColorsUsage[10];
			sampler2D _MainMaskTex;
			half4 TVE_OverlayColor;
			half4 TVE_ExtrasParams;
			TEXTURE2D_ARRAY(TVE_ExtrasTex);
			half4 TVE_ExtrasCoords;
			float TVE_ExtrasUsage[10];
			sampler2D _MainNormalTex;
			sampler2D _EmissiveTex;
			half TVE_OverlaySmoothness;
			half TVE_CameraFadeStart;
			half TVE_CameraFadeEnd;
			sampler3D TVE_ScreenTex3D;
			half TVE_ScreenTexCoord;
			half TVE_SubsurfaceValue;


			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			float2 DecodeFloatToVector2( float enc )
			{
				float2 result ;
				result.y = enc % 2048;
				result.x = floor(enc / 2048);
				return result / (2048 - 1);
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				half3 Vertex_x = float3(v.vertex.x , 0.0 , 0.0);
				half3 Vertex_yz = float3(0.0 , v.vertex.y , v.vertex.z);
				float3 pos_move = float3(GetObjectToWorldMatrix()[ 0 ][ 3 ] , GetObjectToWorldMatrix()[ 1 ][ 3 ] , GetObjectToWorldMatrix()[ 2 ][ 3 ]);
				float3 Vertex_pivot = float3(v.ase_texcoord3.x , v.ase_texcoord3.z , v.ase_texcoord3.y) * _VertexPivotMode;

				float3 Vertex_pivot_WS = mul( GetObjectToWorldMatrix(), float4( Vertex_pivot , 0.0 ) ).xyz;
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;

				#ifdef TVE_FEATURE_BATCHING
					float3 pos_base = ase_worldPos;
				#else
					float3 pos_base = pos_move + Vertex_pivot_WS;
				#endif

				half2 MotionCoords_uv = TVE_MotionCoords.zw + TVE_MotionCoords.xy * pos_base.xz; 
				float4 Motion_params = lerp(TVE_MotionParams, saturate(SAMPLE_TEXTURE2D_ARRAY_LOD(TVE_MotionTex, sampler_linear_clamp, MotionCoords_uv, _LayerMotionValue, 0.0 )), TVE_MotionUsage[(int)_LayerMotionValue]);
				float3 Motion_params_xy = float3(Motion_params.x , 0.0 , Motion_params.y) * 2.0 - 1.0;

				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				half2 Motion_Direction_Global = (( mul( GetWorldToObjectMatrix(), float4( Motion_params_xy , 0.0 ) ).xyz * ase_parentObjectScale )).xz;
				float2 Motion_pos10 = (( pos_base * ( _MotionScale_10 + 1.0 ) * TVE_NoiseParams.x * 0.0075 )).xz;

				#ifdef TVE_FEATURE_BATCHING
					float Motion_mask1 = v.ase_color.r;
				#else
					float Motion_mask1 = frac( ( ( ( pos_base.x + pos_base.y + pos_base.z + 0.001275 ) * ( 1.0 - _VertexDynamicMode ) ) + v.ase_color.r ) );
				#endif

				Motion_mask1 = clamp( Motion_mask1 , 0.01 , 0.99 );
				float Motion_time10 = ( ( ( _TimeParameters.x * _MotionSpeed_10 * TVE_NoiseParams.y ) + ( _MotionVariation_10 * Motion_mask1 ) ) * 0.03 );

				float4 noise = lerp( tex2Dlod( TVE_NoiseTex, float4( ( Motion_pos10 + ( -Motion_params_xy.xz * frac(Motion_time10) ) ), 0, 0.0) ) , 
				tex2Dlod( TVE_NoiseTex, float4( ( Motion_pos10 + ( -Motion_params_xy.xz * frac((Motion_time10 + 0.5) ) ) ), 0, 0.0) ) ,
				( abs( ( frac( Motion_time10 ) - 0.5 ) ) / 0.5 ));

				float3 noise_motion = pow((abs(noise.rgb) + 0.2), (lerp(1.4, 0.4, Motion_params.z)).xxx) * 1.4 - 0.2;

				float2 Texcoord_w = DecodeFloatToVector2(v.texcoord.w) * 100.0;

				#ifdef TVE_FEATURE_BATCHING
					float Motion_mask2 = v.ase_color.a * v.ase_color.a * Texcoord_w.x * 2.0;
				#else
					float Motion_mask2 = v.ase_color.a * 2.0;
				#endif

				#ifdef TVE_FEATURE_BATCHING
					float Motion_mask3 = Motion_mask2;
				#else
					float Motion_mask3 = lerp( 2.0 , Motion_mask2 , _InteractionMaskValue);
				#endif

				float2 Motion_bending10 = Motion_Direction_Global * lerp((_MotionAmplitude_10 * Motion_params.z * noise_motion.x * Motion_mask2), _InteractionAmplitude * Motion_mask3, saturate((_InteractionAmplitude * Motion_params.w * Motion_params.w)));

				half3 Vertex_pos = Vertex_x + ( Vertex_yz * cos( Motion_bending10.y ) ) + ( cross( float3(1,0,0) , Vertex_yz ) * sin( Motion_bending10.y ) );
				half3 Vertex_z = float3(0.0 , 0.0 , Vertex_pos.z);
				half3 Vertex_xy = float3(Vertex_pos.x , Vertex_pos.y , 0.0);

				half Motion_time20 = sin((((ase_worldPos.x + ase_worldPos.y + ase_worldPos.z) * _MotionScale_20) + ( _MotionVariation_20 * Motion_mask1 ) + ( _TimeParameters.x * _MotionSpeed_20 ) ) );

				float Vertex_motion = dot( normalize( v.vertex.xyz ) , float3(-Motion_Direction_Global.x , 0.0 , -Motion_Direction_Global.y) );

				#ifdef TVE_FEATURE_BATCHING
					float Motion_mask4 = 1.0f;
				#else
					float Motion_mask4 = max( lerp( 1.0 , (Vertex_motion*0.5 + 0.5) , _MotionFacingValue) , 0.001 );
				#endif

				half Motion_amplitude = _MotionValue_20 * Motion_params.z * noise_motion.x * Motion_mask4;
				float2 Texcoord_z = DecodeFloatToVector2( v.texcoord.z );

				half3 Motion_squash20 = (Motion_time20 * 0.2 + 1.0) * Motion_amplitude * _MotionAmplitude_20 * Texcoord_z.x * Texcoord_w.y * float3(Motion_Direction_Global.x , ( Motion_time20 * 0.1 ) , Motion_Direction_Global.y);
				
				Vertex_pos = ((Vertex_z + (Vertex_xy * cos( -Motion_bending10.x ) ) + ( cross( float3(0,0,1) , Vertex_xy ) * sin( -Motion_bending10.x ) ) ) + Motion_squash20 );
				float3 Vertex_y = (float3(0.0 , Vertex_pos.y , 0.0));
				float3 Vertex_xz = (float3(Vertex_pos.x , 0.0 , Vertex_pos.z));

				half Motion_angle = Motion_time20 * Motion_amplitude * _MotionAmplitude_22 * Texcoord_z.x;
				Motion_mask1 = clamp( Motion_mask1 , 0.01 , 0.99 );

				half Motion_fadeout = saturate(((distance(ase_worldPos, _WorldSpaceCameraPos) - TVE_MotionFadeEnd) / (TVE_MotionFadeStart - TVE_MotionFadeEnd)));
				half Motion_amplitude30 = _MotionAmplitude_32 * _MotionValue_30 * Motion_params.z * noise_motion.x * Motion_mask4 * Motion_fadeout;

				half3 Motion_details30 = ( ( sin( ( ( ( ase_worldPos.x + ase_worldPos.y + ase_worldPos.z ) * _MotionScale_32 ) + ( _MotionVariation_32 * Motion_mask1 ) + ( _TimeParameters.x * _MotionSpeed_32 * TVE_FlutterParams.y ) ) )
				* Motion_amplitude30 * TVE_FlutterParams.x * Texcoord_z.y * 0.4 ) * lerp( float3( 1,1,1 ) , v.ase_normal , _MotionNormalValue) );

				#ifdef TVE_FEATURE_BATCHING
					float3 Motion_mask5 = v.vertex.xyz + float3(Motion_bending10.x , 0.0 , Motion_bending10.y) + Motion_squash20 + Motion_details30;
				#else
					float3 Motion_mask5 = Vertex_y + Vertex_xz * cos(Motion_angle) + cross(float3(0,1,0) , Vertex_xz) * sin(Motion_angle) + Motion_details30 + _VertexDataMode;
				#endif

				half2 Vertexcoords_uv = TVE_VertexCoords.zw + TVE_VertexCoords.xy * pos_base.xz;
				float4 Vertex_params = lerp( TVE_VertexParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_VertexTex, sampler_linear_clamp, Vertexcoords_uv, _LayerVertexValue, 0.0 ) , TVE_VertexUsage[(int)_LayerVertexValue]);

				float Vertex_params_w = lerp( 1.0 , saturate( Vertex_params.w ) , _GlobalSize);

				#ifdef TVE_FEATURE_BATCHING
					float3 Motion_mask6 = 1;
				#else
					float3 Motion_mask6 = float3(Vertex_params_w , Vertex_params_w , Vertex_params_w);
				#endif
				
				o.ase_texcoord8.x = saturate( ( ( v.ase_color.a - _GradientMinValue ) / ( _GradientMaxValue - _GradientMinValue ) ) );
				o.ase_texcoord8.y = saturate( ( ( v.ase_color.g - _VertexOcclusionMinValue ) / ( _VertexOcclusionMaxValue - _VertexOcclusionMinValue ) ) );
				o.ase_texcoord10.xyz = ase_worldPos;
				o.ase_texcoord11.xyz = pos_base;

				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord12.xyz = ase_worldNormal;
				//o.ase_texcoord12.xyz = TransformObjectToWorldNormal(v.vertex.xyz);

				o.ase_texcoord8.z = lerp( 1.0 , saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - TVE_CameraFadeStart ) / ( TVE_CameraFadeEnd - TVE_CameraFadeStart ) ) ) , _FadeCameraValue);
				
				o.ase_texcoord9 = v.texcoord;
				//o.ase_color = v.ase_color;
				o.ase_color = float4(1,0,0,1);
				//o.ase_normal = v.ase_normal;
				o.ase_normal = TransformObjectToWorldNormal(v.vertex.xyz);
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord8.w = 0;
				o.ase_texcoord10.w = 0;
				o.ase_texcoord11.w = 0;
				o.ase_texcoord12.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = lerp(v.vertex.xyz, Motion_mask5 * Motion_mask6, TVE_Enabled) + _DisableSRPBatcher;
				#else
					v.vertex.xyz += lerp(v.vertex.xyz, Motion_mask5 * Motion_mask6, TVE_Enabled) + _DisableSRPBatcher;
				#endif
				//v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );
				//VertexNormalInputs normalInput = GetVertexNormalInputs( v.vertex.xyz);

				//o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				//o.tSpace0 = float4( TransformObjectToWorld(v.vertex.xyz).xyz, positionWS.x);
				o.tSpace0 = float4( v.vertex.xyz, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );

				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif

				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;

				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(positionCS);
				#endif

				return o;
			}
			
			#if defined(TESSELLATION_ON)
				struct VertexControl
				{
					float4 vertex : INTERNALTESSPOS;
					float3 ase_normal : NORMAL;
					float4 ase_tangent : TANGENT;
					float4 texcoord : TEXCOORD0;
					float4 texcoord1 : TEXCOORD1;
					float4 texcoord2 : TEXCOORD2;
					float4 ase_texcoord3 : TEXCOORD3;
					float4 ase_color : COLOR;

					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct TessellationFactors
				{
					float edge[3] : SV_TessFactor;
					float inside : SV_InsideTessFactor;
				};

				VertexControl vert ( VertexInput v )
				{
					VertexControl o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.vertex = v.vertex;
					o.ase_normal = v.ase_normal;
					o.ase_tangent = v.ase_tangent;
					o.texcoord = v.texcoord;
					o.texcoord1 = v.texcoord1;
					o.texcoord2 = v.texcoord2;
					o.texcoord = v.texcoord;
					o.ase_texcoord3 = v.ase_texcoord3;
					o.ase_color = v.ase_color;
					return o;
				}

				TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
				{
					TessellationFactors o;
					float4 tf = 1;
					float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
					float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
					#if defined(ASE_FIXED_TESSELLATION)
						tf = FixedTess( tessValue );
					#elif defined(ASE_DISTANCE_TESSELLATION)
						tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
					#elif defined(ASE_LENGTH_TESSELLATION)
						tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
					#elif defined(ASE_LENGTH_CULL_TESSELLATION)
						tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
					#endif
					o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
					return o;
				}

				[domain("tri")]
				[partitioning("fractional_odd")]
				[outputtopology("triangle_cw")]
				[patchconstantfunc("TessellationFunction")]
				[outputcontrolpoints(3)]
				VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
				{
					return patch[id];
				}

				[domain("tri")]
				VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
				{
					VertexInput o = (VertexInput) 0;
					o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
					o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
					o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
					o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
					o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
					o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
					o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
					o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
					o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
					#if defined(ASE_PHONG_TESSELLATION)
						float3 pp[3];
						for (int i = 0; i < 3; ++i)
						pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
						float phongStrength = _TessPhongStrength;
						o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
					#endif
					UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
					return VertexFunction(o);
				}
			#else
				VertexOutput vert ( VertexInput v )
				{
					return VertexFunction( v );
				}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag ( VertexOutput IN 
			#ifdef ASE_DEPTH_WRITE_ON
				,out float outputDepth : ASE_SV_DEPTH
			#endif
			, FRONT_FACE_TYPE ase_vface : FRONT_FACE_SEMANTIC ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
				InputData inputData = (InputData)0;

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = TransformObjectToWorldNormal(normalize( IN.tSpace0.xyz ));
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
				
				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float3 GradientColor = lerp( (_GradientColorTwo).rgb , (_GradientColorOne).rgb , IN.ase_texcoord8.x);
				half2 MainUV = ( ( IN.ase_texcoord9.xy * (_MainUVs).xy ) + (_MainUVs).zw );
				float4 MainTex = tex2D( _MainAlbedoTex, MainUV );
				half3 Albedo = ( (_MainColor).rgb * (MainTex).rgb );
				float3 VertexOcclusion = lerp( (_VertexOcclusionColor).rgb , 1.0 , IN.ase_texcoord8.y);
				half3 AlbedoBlend = ( ( GradientColor * float3(1,1,1) * float3(1,1,1) ) * Albedo * VertexOcclusion );

				#ifdef TVE_FEATURE_BATCHING
					float3 ObjectPos = IN.ase_texcoord10.xyz;
				#else
					float3 ObjectPos = IN.ase_texcoord11.xyz;
				#endif

				float3 ColorPos = lerp( IN.ase_texcoord10.xyz , ObjectPos , _ColorsPositionMode);
				half2 ColorUV = TVE_ColorsCoords.zw + TVE_ColorsCoords.xy * ColorPos.xz;
				float4 ColorParams = lerp( TVE_ColorsParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_ColorsTex, sampler_linear_clamp, ColorUV, _LayerColorsValue, 0.0 ) , TVE_ColorsUsage[(int)_LayerColorsValue]);
				float3 AlbedoBlend2 = lerp( AlbedoBlend , (dot( AlbedoBlend , float3(0.2126,0.7152,0.0722) )).xxx , saturate( (ColorParams).a ));

				#ifdef UNITY_COLORSPACE_GAMMA
					half3 ColorGlobal = ColorParams.rgb * 2;
				#else
					half3 ColorGlobal = ColorParams.rgb * 4.594794;
				#endif
				
				#ifdef TVE_FEATURE_BATCHING
					float MeshVariation = IN.ase_color.r;
				#else
					float MeshVariation = frac( ( ( ( ObjectPos.x + ObjectPos.y + ObjectPos.z + 0.001275 ) * ( 1.0 - _VertexDynamicMode ) ) + IN.ase_color.r ) );
				#endif

				MeshVariation = clamp( MeshVariation , 0.01 , 0.99 );
				float ColorVariation = lerp( 1.0 , ( MeshVariation * MeshVariation ) , _ColorsVariationValue);
				float4 Mask = tex2D( _MainMaskTex, MainUV );
				half ColorsMask = saturate( ( ( clamp( Mask.b , 0.01 , 0.99 ) - _ColorsMaskMinValue ) / ( _ColorsMaskMaxValue - _ColorsMaskMinValue ) ) );

				AlbedoBlend = lerp( AlbedoBlend , ( AlbedoBlend2 * ColorGlobal ) , lerp( 0.0 , ( _GlobalColors * ColorVariation * ColorsMask ) , TVE_Enabled));
				float VertexDynamic = lerp( 0.5 , 1.0 , lerp( IN.ase_texcoord12.y , IN.ase_normal.y , _VertexDynamicMode));
				half2 ExtraUV = ( (TVE_ExtrasCoords).zw + ( (TVE_ExtrasCoords).xy * (lerp( IN.ase_texcoord10.xyz , ObjectPos , _ExtrasPositionMode)).xz ) );
				float4 ExtraParams = lerp( TVE_ExtrasParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_ExtrasTex, sampler_linear_clamp, ExtraUV, _LayerExtrasValue, 0.0 ) , TVE_ExtrasUsage[(int)_LayerExtrasValue]);
				half OverlayMask = ( VertexDynamic * 0.5 + Albedo.y ) * _GlobalOverlay * ExtraParams.b * lerp( 1.0 , MeshVariation , _OverlayVariationValue);
				OverlayMask = saturate( ( ( OverlayMask - _OverlayMaskMinValue ) / ( _OverlayMaskMaxValue - _OverlayMaskMinValue ) ) );
				
				// Normal
				float3 NormalTex = UnpackNormalScale( tex2D( _MainNormalTex, MainUV ), _MainNormalValue );
				NormalTex.z = lerp( 1, NormalTex.z, saturate(_MainNormalValue) );
				float3 Normal = ase_vface > 0 ? NormalTex : NormalTex * _render_normals; 

				// Base Color
				float3 BaseColor = lerp( AlbedoBlend , TVE_OverlayColor.rgb , OverlayMask);
				
				//Emission
				half2 EmissiveUV = ( ( IN.ase_texcoord9.xy * (_EmissiveUVs).xy ) + (_EmissiveUVs).zw );
				float3 Emission = (_EmissiveColor * _EmissiveIntensityParams.x * tex2D( _EmissiveTex, EmissiveUV)).rgb * lerp( 1.0 , ExtraParams.r , _GlobalEmissive);
				
				//Smoothness
				half Smoothness = Mask.a * _MainSmoothnessValue;
				Smoothness = lerp( Smoothness , TVE_OverlaySmoothness , OverlayMask);
				Smoothness = saturate(Smoothness + lerp(0.0, ExtraParams.g, _GlobalWetness));

				//Alpha
				float AlphaVariation = lerp( 0.1 , MeshVariation , _AlphaVariationValue);
				AlphaVariation = lerp( 1.0 , ( ( saturate( ExtraParams.a ) - AlphaVariation ) + ( saturate( ExtraParams.a ) * 0.5 ) ) , _GlobalAlpha );
				AlphaVariation = lerp( 1.0 , AlphaVariation , TVE_Enabled) + _AlphaClipValue;
				float NdotV = dot( normalize( WorldViewDirection ) , normalize( cross( ddy( WorldPosition ) , ddx( WorldPosition ) ) ) );
				float Glancing = lerp( 1.0 , saturate( abs( NdotV ) ) , _FadeGlancingValue);
				Glancing = lerp( 1.0 , Glancing * IN.ase_texcoord8.z , 1);
				Glancing = ( saturate( ( Glancing + ( Glancing * tex3D( TVE_ScreenTex3D, ( TVE_ScreenTexCoord * IN.ase_texcoord10.xyz ) ).r ) ) ) - 0.5 + _AlphaClipValue );
				float Alpha = _MainColor.a * MainTex.a * AlphaVariation * Glancing;
				Alpha = saturate(( Alpha - _AlphaClipValue ) / ( max( fwidth( Alpha ) , 0.001 ) + _AlphaFeatherValue ) + _AlphaClipValue);
				
				#if defined (TVE_FEATURE_CLIP)
					#if defined (TVE_IS_HD_PIPELINE)
						#if !defined (SHADERPASS_FORWARD_BYPASS_ALPHA_TEST)
							clip(Alpha - _AlphaClipValue);
						#endif
						#if !defined (SHADERPASS_GBUFFER_BYPASS_ALPHA_TEST)
							clip(Alpha - _AlphaClipValue);
						#endif
					#else
						clip(Alpha - _AlphaClipValue);
					#endif
				#endif

				//Subsurface & Translucency
				float3 SubsurfaceColor = lerp( _SubsurfaceColor.rgb , dot( _SubsurfaceColor.rgb , float3(0.2126,0.7152,0.0722) ).xxx , saturate( (ColorParams).a ));
				SubsurfaceColor = lerp( _SubsurfaceColor.rgb , ( SubsurfaceColor * ColorGlobal ) , ( _GlobalColors * ColorVariation * ColorsMask ));
				half SubsurfaceMask = saturate( ( ( 1 - _SubsurfaceMaskMinValue ) / ( _SubsurfaceMaskMaxValue - _SubsurfaceMaskMinValue ) ) );
				float3 Translucency = SubsurfaceColor * _SubsurfaceValue * TVE_SubsurfaceValue * SubsurfaceMask;

				float3 Specular = ( 0.04 * _RenderSpecular ).xxx;
				float Metallic = 0;
				float Occlusion=1;// = lerp( 1.0 , Mask.g , _MainOcclusionValue);
				
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;


				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif
				
				#ifdef _CLEARCOAT
					float CoatMask = 0;
					float CoatSmoothness = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;

				// #ifdef _NORMALMAP
				// 	#if _NORMAL_DROPOFF_TS
				// 		inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));
				// 	#elif _NORMAL_DROPOFF_OS
				// 		inputData.normalWS = TransformObjectToWorldNormal(Normal);
				// 	#elif _NORMAL_DROPOFF_WS
				// 		inputData.normalWS = Normal;
				// 	#endif
				// 	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				// #else

				float3 normalTexture = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, IN.ase_texcoord12.xyz)); 
				// ase_texcoord12为模型本身法线				
				// WorldNormal为模型空间position计算的法线（即伪球形法线）
				// Normal为法线贴图中采出的法线

				inputData.normalWS = lerp(normalTexture.xyz, WorldNormal, 0.7);
				//inputData.normalWS = inputData.normalWS * 0.5 + 0.5;

				// #endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = ShadowCoords;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif
				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
				#endif

				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
					#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = input.staticLightmapUV;
					#else
						inputData.vertexSH = input.sh;
					#endif
				#endif

				// Light light1 = GetMainLight();
				// float NdotL = dot(WorldNormal, light1.direction);
				// //BaseColor *= max(NdotL,0);
				// BaseColor *= NdotL * 0.5 + 0.5;

				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;

				#ifdef _CLEARCOAT
					surfaceData.clearCoatMask       = saturate(CoatMask);
					surfaceData.clearCoatSmoothness = saturate(CoatSmoothness);
				#endif

				#ifdef _DBUFFER
					ApplyDecalToSurfaceData(IN.clipPos, surfaceData, inputData);
				#endif

				half4 color = UniversalFragmentPBR( inputData, surfaceData);

				#ifdef _TRANSMISSION_ASE
					{
						float shadow = _TransmissionShadow;

						Light mainLight = GetMainLight( inputData.shadowCoord );
						float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
						mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
						half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
						color.rgb += BaseColor * mainTransmission;

						#ifdef _ADDITIONAL_LIGHTS
							int transPixelLightCount = GetAdditionalLightsCount();
							for (int i = 0; i < transPixelLightCount; ++i)
							{
								Light light = GetAdditionalLight(i, inputData.positionWS);
								float3 atten = light.color * light.distanceAttenuation;
								atten = lerp( atten, atten * light.shadowAttenuation, shadow );

								half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
								color.rgb += BaseColor * transmission;
							}
						#endif
					}
				#endif

				#ifdef _TRANSLUCENCY_ASE
					{
						float shadow = _TransShadow; // 0.5
						float normal = _TransNormal; // 0.5
						float scattering = _TransScattering; // 2
						float direct = _TransDirect; // 0.9
						float ambient = _TransAmbient; // 0.1
						float strength = _TransStrength; // 1

						Light mainLight = GetMainLight( inputData.shadowCoord );
						float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
						mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
						mainAtten = mainAtten + mainAtten * 0.5;

						//half3 mainLightDir = normalize(mainLight.direction + inputData.normalWS * normal);
						half3 mainLightDir = normalize(mainLight.direction + IN.ase_texcoord12.xyz * normal);
						
						//half3 mainLightDir = mainLight.direction;
						half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering ); // 计算背光时的透射范围
						half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
						color.rgb += BaseColor * mainTranslucency * strength;
						color.rgb *= (dot(WorldNormal.xyz, mainLightDir)*0.5+0.5);
						//color.rgb = mainAtten;// * mainLight.shadowAttenuation;
						#ifdef _ADDITIONAL_LIGHTS
							int transPixelLightCount = GetAdditionalLightsCount();
							for (int i = 0; i < transPixelLightCount; ++i)
							{
								Light light = GetAdditionalLight(i, inputData.positionWS);
								float3 atten = light.color * light.distanceAttenuation;
								atten = lerp( atten, atten * light.shadowAttenuation, shadow );

								half3 lightDir = light.direction + inputData.normalWS * normal;
								half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
								half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
								color.rgb += BaseColor * translucency * strength;
							}
						#endif
					}
				#endif

				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal,0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				
				//color.xyz = BaseColor;
				return color;
			}

			ENDHLSL
		}
		//-------------------------------------------------------------------------------------
		// END_PASS UNIVERSALFORWARD
		//-------------------------------------------------------------------------------------

		//-------------------------------------------------------------------------------------
		// BEGIN_PASS SHADOWCASTER
		//-------------------------------------------------------------------------------------
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			HLSLPROGRAM
			
			#define _SPECULAR_SETUP 1
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#pragma multi_compile _ DOTS_INSTANCING_ON
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _TRANSLUCENCY_ASE 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120100

			
			#pragma vertex vert
			#pragma fragment frag

			//-----------------------------------------------------------------------------
			// DEFINES - (Unity defined keywords) api 12.1.0 thru 14.0.3
			//-----------------------------------------------------------------------------
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			//-----------------------------------------------------------------------------
			// DEFINES - (Set by User)
			//-----------------------------------------------------------------------------

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local TVE_FEATURE_CLIP
			#pragma shader_feature_local TVE_FEATURE_BATCHING
			//TVE Pipeline Defines
			#define THE_VEGETATION_ENGINE
			#define TVE_IS_UNIVERSAL_PIPELINE
			//TVE Injection Defines
			//SHADER INJECTION POINT BEGIN
			//SHADER INJECTION POINT END
			//TVE Shader Type Defines
			#define TVE_IS_VEGETATION_SHADER


			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//-------------------------------------------------------------------------------------
			// BEGIN_CBUFFER
			//-------------------------------------------------------------------------------------

			CBUFFER_START(UnityPerMaterial)
				half4 _ColorsMaskRemap;
				half4 _VertexOcclusionRemap;
				half4 _DetailBlendRemap;
				half4 _SubsurfaceMaskRemap;
				float4 _GradientMaskRemap;
				half4 _GradientColorTwo;
				float4 _MaxBoundsInfo;
				half4 _GradientColorOne;
				half4 _MainColor;
				half4 _MainUVs;
				float4 _Color;
				float4 _SubsurfaceDiffusion_Asset;
				half4 _AlphaMaskRemap;
				half4 _EmissiveColor;
				float4 _EmissiveIntensityParams;
				half4 _VertexOcclusionColor;
				float4 _SubsurfaceDiffusion_asset;
				half4 _OverlayMaskRemap;
				float4 _NoiseMaskRemap;
				half4 _SubsurfaceColor;
				half4 _EmissiveUVs;
				half3 _render_normals;
				half _MotionNormalValue;
				half _MotionValue_30;
				half _MotionAmplitude_32;
				half _FadeGlancingValue;
				float _MotionSpeed_32;
				half _FadeCameraValue;
				float _MotionVariation_32;
				float _MotionScale_32;
				half _MotionAmplitude_22;
				half _MotionAmplitude_20;
				half _MotionValue_20;
				half _MotionSpeed_20;
				half _MotionVariation_20;
				half _MotionScale_20;
				half _InteractionMaskValue;
				half _InteractionAmplitude;
				half _SubsurfaceValue;
				half _VertexDynamicMode;
				half _MotionVariation_10;
				float _MotionSpeed_10;
				float _MotionScale_10;
				half _MotionAmplitude_10;
				half _LayerMotionValue;
				half _MotionFacingValue;
				half _VertexDataMode;
				half _GlobalSize;
				half _GlobalAlpha;
				half _GlobalEmissive;
				half _RenderSpecular;
				half _MainNormalValue;
				half _OverlayMaskMaxValue;
				half _OverlayMaskMinValue;
				half _MainSmoothnessValue;
				half _OverlayVariationValue;
				half _LayerExtrasValue;
				half _ExtrasPositionMode;
				half _GlobalOverlay;
				half _ColorsMaskMaxValue;
				half _LayerVertexValue;
				half _ColorsMaskMinValue;
				half _GlobalWetness;
				half _GlobalColors;
				half _LayerColorsValue;
				half _ColorsPositionMode;
				half _VertexOcclusionMaxValue;
				half _VertexOcclusionMinValue;
				half _VertexPivotMode;
				half _MainOcclusionValue;
				half _GradientMaxValue;
				half _GradientMinValue;
				half _AlphaVariationValue;
				half _ColorsVariationValue;
				half _render_zw;
				half _IsLeafShader;
				half _render_coverage;
				half _CategoryOcclusion;
				half _CategoryMain;
				half _CategorySizeFade;
				half _SpaceMotionLocals;
				half _IsVersion;
				half _RenderCoverage;
				half _LayerReactValue;
				half _RenderMode;
				half _RenderPriority;
				half _CategoryMotion;
				half _RenderClip;
				half _RenderAmbient;
				half _CategoryDetail;
				half _CategoryEmissive;
				half _VertexVariationMode;
				half _SpaceGlobalPosition;
				half _MessageSizeFade;
				half _SubsurfaceAngleValue;
				half _HasGradient;
				half _SpaceRenderFade;
				half _HasEmissive;
				half _SpaceGlobalLocals;
				half _DetailMode;
				half _DetailTypeMode;
				half _CategorySubsurface;
				half _VertexMasksMode;
				half _RenderShadow;
				half _SpaceMotionGlobals;
				half _IsTVEShader;
				half _RenderNormals;
				half _CategoryGradient;
				half _SpaceGlobalLayers;
				half _render_dst;
				half _render_cull;
				half _render_src;
				half _SubsurfaceMaskMinValue;
				half _SubsurfaceNormalValue;
				half _MessageMotionVariation;
				half _RenderSSR;
				half _CategoryGlobal;
				half _SubsurfaceScatteringValue;
				half _SubsurfaceShadowValue;
				half _RenderZWrite;
				half _MessageGlobalsVariation;
				half _RenderDirect;
				half _RenderDecals;
				half _AlphaFeatherValue;
				half _EmissiveFlagMode;
				half _CategoryNoise;
				half _CategoryPerspective;
				float _SubsurfaceDiffusion;
				half _CategoryRender;
				half _RenderQueue;
				half _DetailBlendMode;
				half _SubsurfaceDirectValue;
				half _SubsurfaceAmbientValue;
				half _RenderCull;
				half _HasOcclusion;
				half _Cutoff;
				half _AlphaClipValue;
				half _VertexRollingMode;
				half _IsSubsurfaceShader;
				half _SubsurfaceMaskMaxValue;
				#ifdef _TRANSMISSION_ASE
					float _TransmissionShadow;
				#endif
				#ifdef _TRANSLUCENCY_ASE
					float _TransStrength;
					float _TransNormal;
					float _TransScattering;
					float _TransDirect;
					float _TransAmbient;
					float _TransShadow;
				#endif
				#ifdef TESSELLATION_ON
					float _TessPhongStrength;
					float _TessValue;
					float _TessMin;
					float _TessMax;
					float _TessEdgeLength;
					float _TessMaxDisp;
				#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			//-------------------------------------------------------------------------------------
			// END_CBUFFER
			//-------------------------------------------------------------------------------------

			sampler2D _BumpMap;
			half TVE_Enabled;
			sampler2D _MainTex;
			half4 TVE_MotionParams;
			TEXTURE2D_ARRAY(TVE_MotionTex);
			half4 TVE_MotionCoords;
			SAMPLER(sampler_linear_clamp);
			float TVE_MotionUsage[10];
			sampler2D TVE_NoiseTex;
			half4 TVE_NoiseParams;
			half4 TVE_FlutterParams;
			half TVE_MotionFadeEnd;
			half TVE_MotionFadeStart;
			half4 TVE_VertexParams;
			TEXTURE2D_ARRAY(TVE_VertexTex);
			half4 TVE_VertexCoords;
			float TVE_VertexUsage[10];
			half _DisableSRPBatcher;
			sampler2D _MainAlbedoTex;
			half4 TVE_ExtrasParams;
			TEXTURE2D_ARRAY(TVE_ExtrasTex);
			half4 TVE_ExtrasCoords;
			float TVE_ExtrasUsage[10];
			half TVE_CameraFadeStart;
			half TVE_CameraFadeEnd;
			sampler3D TVE_ScreenTex3D;
			half TVE_ScreenTexCoord;


			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			float2 DecodeFloatToVector2( float enc )
			{
				float2 result ;
				result.y = enc % 2048;
				result.x = floor(enc / 2048);
				return result / (2048 - 1);
			}
			

			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 VertexPosRotationAxis = (float3(v.vertex.x , 0.0 , 0.0));
				//half3 VertexPosRotationAxis = VertexPosRotationAxis;
				//float3 v.vertex = v.vertex;
				float3 VertexPosOtherAxis = (float3(0.0 , v.vertex.y , v.vertex.z));
				// half3 VertexPosOtherAxis = VertexPosOtherAxis;
				// float4 TVE_MotionCoords = TVE_MotionCoords;
				// float4x4 GetObjectToWorldMatrix() = GetObjectToWorldMatrix();
				float3 WorldMov = (float3(GetObjectToWorldMatrix()[ 0 ][ 3 ] , GetObjectToWorldMatrix()[ 1 ][ 3 ] , GetObjectToWorldMatrix()[ 2 ][ 3 ]));
				float3 Mesh_PivotsData = (float3(v.ase_texcoord3.x , v.ase_texcoord3.z , v.ase_texcoord3.y))* _VertexPivotMode;
				//float3 Mesh_PivotsData2831_g74029 = Mesh_PivotsData2831_g74029;
				float3 PivotsOnly = (mul( GetObjectToWorldMatrix(), float4( Mesh_PivotsData , 0.0 ) ).xyz).xyz;
				half3 ObjectData = ( WorldMov + PivotsOnly );
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				//half3 ase_worldPos = ase_worldPos;
				#ifdef TVE_FEATURE_BATCHING
					float3 posWSVertToFrag = ase_worldPos;
				#else
					float3 posWSVertToFrag = WorldMov + PivotsOnly;
				#endif
				// float3 posWSVertToFrag = posWSVertToFrag;
				// float3 posWSVertToFrag = posWSVertToFrag;
				// half3 posWSVertToFrag = posWSVertToFrag;
				// float3 ase_worldPos = ase_worldPos;
				// half3 ase_worldPos = ase_worldPos;
				#ifdef TVE_FEATURE_BATCHING
					float3 ObjectPosition = ase_worldPos;
				#else
					float3 ObjectPosition = posWSVertToFrag;
				#endif
				//float3 ObjectPosition = ObjectPosition;
				half2 UV_Motion = ( (TVE_MotionCoords).zw + ( (TVE_MotionCoords).xy * (ObjectPosition).xz ) );
				//float _LayerMotionValue = _LayerMotionValue;
				float4 Global_Motion_Params = lerp( TVE_MotionParams , saturate( SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_MotionTex, sampler_linear_clamp, UV_Motion,_LayerMotionValue, 0.0 ) ) , TVE_MotionUsage[(int)_LayerMotionValue]);
				// half4 Global_Motion_Params3909_g74029 = Global_Motion_Params;
				// float4 Global_Motion_Params = Global_Motion_Params3909_g74029;
				float3 Global_Motion_Params_xy = (float3(Global_Motion_Params.x , 0.0 , Global_Motion_Params.y));
				Global_Motion_Params_xy = Global_Motion_Params_xy * 2.0 - 1.0;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				half2 Global_MotionDirectionOS = (( mul( GetWorldToObjectMatrix(), float4( Global_Motion_Params_xy , 0.0 ) ).xyz * ase_parentObjectScale )).xz;
				// half2 Global_MotionDirectionOS = Global_MotionDirectionOS;
				// half Wind_Power369_g74034 = Global_Motion_Params.z;
				// half Global_Motion_Params.z = Wind_Power369_g74034;
				// half3 ObjectPosition = ObjectPosition;
				// float _MotionScale_10 + 1.0 = ( _MotionScale_10 + 1.0 );
				// half TVE_NoiseParams.x = TVE_NoiseParams.x;
				float2 MotionPosOS = (( ObjectPosition * _MotionScale_10 + 1.0 * TVE_NoiseParams.x * 0.0075 )).xz;
				//half2 Global_MotionDirectionWS4683_g74029 = (Global_Motion_Params_xy).xz;
				// half2 (Global_Motion_Params_xy).xz = Global_MotionDirectionWS4683_g74029;
				// half _MotionSpeed_10 = _MotionSpeed_10;
				// half TVE_NoiseParams.y = TVE_NoiseParams.y;
				// half _MotionVariation_10 = _MotionVariation_10;
				// float3 ObjectPosition = ObjectPosition;
				// half Global_DynamicMode5112_g74029 = _VertexDynamicMode;
				// half _VertexDynamicMode = Global_DynamicMode5112_g74029;
				// float Mesh_Variation16_g74029 = v.ase_color.r;
				// half v.ase_color.r = Mesh_Variation16_g74029;
				//half ObjectData20_g74047 = frac( ( ( ( ObjectPosition.x + ObjectPosition.y + ObjectPosition.z + 0.001275 ) * ( 1.0 - _VertexDynamicMode ) ) + v.ase_color.r ) );
				//half v.ase_color.r = v.ase_color.r;
				#ifdef TVE_FEATURE_BATCHING
					float Global_MeshVariation = v.ase_color.r;
				#else
					float Global_MeshVariation = frac( ( ( ( ObjectPosition.x + ObjectPosition.y + ObjectPosition.z + 0.001275 ) * ( 1.0 - _VertexDynamicMode ) ) + v.ase_color.r ) );
				#endif
				Global_MeshVariation = clamp( Global_MeshVariation , 0.01 , 0.99 );
				// half Global_MeshVariation = Global_MeshVariation;
				// half Global_MeshVariation = Global_MeshVariation;
				float Motion_10_TimeParam = ( ( ( _TimeParameters.x * _MotionSpeed_10 * TVE_NoiseParams.y ) + ( _MotionVariation_10 * Global_MeshVariation ) ) * 0.03 );
				//float frac( Motion_10_TimeParam ) = frac( Motion_10_TimeParam );
				float3 Motion_10_Result = lerp( tex2Dlod( TVE_NoiseTex, float4( ( MotionPosOS + ( -(Global_Motion_Params_xy).xz * frac( Motion_10_TimeParam ) ) ), 0, 0.0) ) , 
													tex2Dlod( TVE_NoiseTex, float4( ( MotionPosOS + ( -(Global_Motion_Params_xy).xz * frac( ( Motion_10_TimeParam + 0.5 ) ) ) ), 0, 0.0) ) , 
													( abs( ( frac( Motion_10_TimeParam ) - 0.5 ) ) / 0.5 )).xyz;
				//half Global_Motion_Params.z = Global_Motion_Params.z;
				//float lerpResult612_g74097 = lerp( 1.4 , 0.4 , Global_Motion_Params.z);
				//float3 temp_cast_7 = (lerpResult612_g74097).xxx;
				Motion_10_Result = (pow( ( abs( (Motion_10_Result).rgb ) + 0.2 ) , lerp( 1.4 , 0.4 , Global_Motion_Params.z) )*1.4 + -0.2);
				//half Motion_10_Result.x = Motion_10_Result.x;
				half Motion_10_Amplitude = ( _MotionAmplitude_10 * Global_Motion_Params.z * Motion_10_Result.x );
				// half Motion_10_Amplitude = Motion_10_Amplitude;
				// half Mesh_Height1524_g74029 = v.ase_color.a;
				// half v.ase_color.a = Mesh_Height1524_g74029;
				// half v.ase_color.a * 2.0 = ( v.ase_color.a * 2.0 );
				// float v.ase_texcoord.w = v.ase_texcoord.w;
				//float2 localDecodeFloatToVector262_g74048 = DecodeFloatToVector2( v.ase_texcoord.w );
				float2 Bounds_Height = ( DecodeFloatToVector2( v.ase_texcoord.w ) * 100.0 );
				// float Bounds_Height5230_g74029 = Bounds_Height.x;
				// half Bounds_Height.x = Bounds_Height5230_g74029;
				//half ( v.ase_color.a * v.ase_color.a ) * Bounds_Height.x * 2.0 = ( ( v.ase_color.a * v.ase_color.a ) * Bounds_Height.x * 2.0 );
				#ifdef TVE_FEATURE_BATCHING
					float Mask_Motion = ( v.ase_color.a * v.ase_color.a ) * Bounds_Height.x * 2.0;
				#else
					float Mask_Motion = v.ase_color.a * 2.0;
				#endif
				// half Mask_Motion = Mask_Motion;
				// half _InteractionAmplitude = _InteractionAmplitude;
				// half _InteractionMaskValue = _InteractionMaskValue;
				//float lerpResult371_g74030 = lerp( 2.0 , Mask_Motion , _InteractionMaskValue);
				// half lerpResult371_g74030 = lerpResult371_g74030;
				// half Mask_Motion = Mask_Motion;
				#ifdef TVE_FEATURE_BATCHING
					float Mask_Interaction = Mask_Motion;
				#else
					float Mask_Interaction = lerp( 2.0 , Mask_Motion , _InteractionMaskValue);
				#endif
				Mask_Interaction = ( _InteractionAmplitude * Mask_Interaction );
				//half Global_Motion_Params.w * Global_Motion_Params.w = ( Global_Motion_Params.w * Global_Motion_Params.w );
				//float Global_Motion_Params.w * Global_Motion_Params.w = Global_Motion_Params.w * Global_Motion_Params.w;
				float Motion_10_Mask = lerp( ( Motion_10_Amplitude * Mask_Motion ) , Mask_Interaction , saturate( ( _InteractionAmplitude * Global_Motion_Params.w * Global_Motion_Params.w ) ));
				float2 Motion_10_Direction = ( Global_MotionDirectionOS * Motion_10_Mask );
				// half Motion_10_Direction.y = Motion_10_Direction.y;
				// half Motion_10_Direction.y = Motion_10_Direction.y;
				half3 VertexPos = ( VertexPosRotationAxis + ( VertexPosOtherAxis * cos( Motion_10_Direction.y ) ) + ( cross( float3(1,0,0) , VertexPosOtherAxis ) * sin( Motion_10_Direction.y ) ) );
				VertexPosRotationAxis = (float3(0.0 , 0.0 , VertexPos.z));
				// half3 VertexPosRotationAxis = VertexPosRotationAxis;
				// float3 VertexPos = VertexPos;
				VertexPosOtherAxis = (float3(VertexPos.x , VertexPos.y , 0.0));
				// half3 VertexPosOtherAxis = VertexPosOtherAxis;
				// half Motion_10_Direction.x = Motion_10_Direction.x;
				// half -Motion_10_Direction.x = -Motion_10_Direction.x;
				// half _MotionScale_20 = _MotionScale_20;
				// half _MotionVariation_20 = _MotionVariation_20;
				// half Global_MeshVariation = Global_MeshVariation;
				// half _MotionSpeed_20 = _MotionSpeed_20;
				half Motion_20_Sine = sin( ( ( ( ase_worldPos.x + ase_worldPos.y + ase_worldPos.z ) * _MotionScale_20 ) + ( _MotionVariation_20 * Global_MeshVariation ) + ( _TimeParameters.x * _MotionSpeed_20 ) ) );
				// half3 Input_Position419_g74111 = v.vertex.xyz;
				// float3 v.vertex.xyz = normalize( Input_Position419_g74111 );
				// half2 Input_DirectionOS423_g74111 = Global_MotionDirectionOS;
				// float2 -Global_MotionDirectionOS = -Input_DirectionOS423_g74111;
				float3 appendResult522_g74111 = (float3(-Global_MotionDirectionOS.x , 0.0 , -Global_MotionDirectionOS.y));
				float dotResult519_g74111 = dot( v.vertex.xyz , appendResult522_g74111 );
				//half _MotionFacingValue = _MotionFacingValue;
				float lerpResult524_g74111 = lerp( 1.0 , (dotResult519_g74111*0.5 + 0.5) , _MotionFacingValue);
				//half max( lerpResult524_g74111 , 0.001 ) = max( lerpResult524_g74111 , 0.001 );
				//half 1.0 = 1.0;
				#ifdef TVE_FEATURE_BATCHING
					float staticSwitch14_g74112 = 1.0;
				#else
					float staticSwitch14_g74112 = max( lerpResult524_g74111 , 0.001 );
				#endif
				//half staticSwitch14_g74112 = staticSwitch14_g74112;
				half Motion_20_Amplitude= ( _MotionValue_20 * Global_Motion_Params.z * Motion_10_Result.x * staticSwitch14_g74112 );
				// half Motion_20_Amplitude= = Motion_20_Amplitude=;
				// half _MotionAmplitude_20 = _MotionAmplitude_20;
				// float v.ase_texcoord.z = v.ase_texcoord.z;
				float2 ase_texcoord_Vector2 = DecodeFloatToVector2( v.ase_texcoord.z );
				// float2 break61_g74048 = ase_texcoord_Vector2;
				// half Mesh_Motion_2060_g74029 = break61_g74048.x;
				// half ase_texcoord_Vector2.x = Mesh_Motion_2060_g74029;
				// float Bounds_Radius5231_g74029 = Bounds_Height.y;
				// half Bounds_Height.y = Bounds_Radius5231_g74029;
				// half2 Input_DirectionOS366_g74065 = Global_MotionDirectionOS;
				// float2 Global_MotionDirectionOS = Input_DirectionOS366_g74065;
				float3 Motion_20_Squash = (float3(Global_MotionDirectionOS.x , ( Motion_20_Sine * 0.1 ) , Global_MotionDirectionOS.y));
				Motion_20_Squash = ( ( (Motion_20_Sine*0.2 + 1.0) * Motion_20_Amplitude * _MotionAmplitude_20 * ase_texcoord_Vector2.x * Bounds_Height.y ) * Motion_20_Squash );

				VertexPos = ( ( VertexPosRotationAxis + ( VertexPosOtherAxis * cos( -Motion_10_Direction.x ) ) + ( cross( float3(0,0,1) , VertexPosOtherAxis ) * sin( -Motion_10_Direction.x ) ) ) + Motion_20_Squash );
				VertexPosRotationAxis = (float3(0.0 , VertexPos.y , 0.0));
				// float3 VertexPosRotationAxis = VertexPosRotationAxis;
				// float3 VertexPos = VertexPos;
				VertexPosOtherAxis = (float3(VertexPos.x , 0.0 , VertexPos.z));
				// float3 VertexPosOtherAxis = VertexPosOtherAxis;
				// half _MotionAmplitude_22 = _MotionAmplitude_22;
				half Motion_20_Rolling = ( Motion_20_Sine * Motion_20_Amplitude * _MotionAmplitude_22 * ase_texcoord_Vector2.x );
				// half Motion_20_Rolling = Motion_20_Rolling;
				// half _MotionScale_32 = _MotionScale_32;
				// half _MotionVariation_32 = _MotionVariation_32;
				// half Global_MeshVariation = Global_MeshVariation;
				// half _MotionSpeed_32 = _MotionSpeed_32;
				// half TVE_FlutterParams.y = TVE_FlutterParams.y;
				// float TVE_MotionFadeEnd = TVE_MotionFadeEnd;
				half Motion_FadeOut = saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - TVE_MotionFadeEnd ) / ( TVE_MotionFadeStart - TVE_MotionFadeEnd ) ) );
				half Motion_30_Amplitude = ( _MotionAmplitude_32 * _MotionValue_30 * Global_Motion_Params.z * Motion_10_Result.x * staticSwitch14_g74112 * Motion_FadeOut );
				// half Motion_30_Amplitude = Motion_30_Amplitude;
				// half TVE_FlutterParams.x = TVE_FlutterParams.x;
				// half Mesh_Motion_30144_g74029 = break61_g74048.y;
				// half ase_texcoord_Vector2.y = Mesh_Motion_30144_g74029;
				// half _MotionNormalValue = _MotionNormalValue;
				//float3 lerp( float3( 1,1,1 ) , v.ase_normal , _MotionNormalValue) = lerp( float3( 1,1,1 ) , v.ase_normal , _MotionNormalValue);

				half3 Motion_30_Details = ( ( sin( ( ( ( ase_worldPos.x + ase_worldPos.y + ase_worldPos.z ) * _MotionScale_32 ) + ( _MotionVariation_32 * Global_MeshVariation ) + 
												( _TimeParameters.x * _MotionSpeed_32 * TVE_FlutterParams.y ) ) ) * Motion_30_Amplitude * TVE_FlutterParams.x * 
												ase_texcoord_Vector2.y * 0.4 ) * lerp( float3( 1,1,1 ) , v.ase_normal , _MotionNormalValue) );

				float3 Vertex_Motion_Object = ( ( VertexPosRotationAxis + ( VertexPosOtherAxis * cos( Motion_20_Rolling ) ) + ( cross( float3(0,1,0) , VertexPosOtherAxis ) * sin( Motion_20_Rolling ) ) ) + Motion_30_Details );
				//float3 v.vertex.xyz = ( v.vertex.xyz - 0 );
				float3 Motion_10_Axis = (float3(Motion_10_Direction.x , 0.0 , Motion_10_Direction.y));
				float3 Vertex_Motion_World = ( ( ( v.vertex.xyz + Motion_10_Axis ) + Motion_20_Squash ) + Motion_30_Details );
				#ifdef TVE_FEATURE_BATCHING
					float3 Vertex_Motion = Vertex_Motion_World;
				#else
					float3 Vertex_Motion = Vertex_Motion_Object;
				#endif
				// half3 0 = half3(0,0,0);
				// float4 TVE_VertexCoords = TVE_VertexCoords;
				half2 UV_ObjectPosition = ( (TVE_VertexCoords).zw + ( (TVE_VertexCoords).xy * (ObjectPosition).xz ) );
				//float _LayerVertexValue = _LayerVertexValue;
				float4 Global_Object_Params = lerp( TVE_VertexParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_VertexTex, sampler_linear_clamp, UV_ObjectPosition,_LayerVertexValue, 0.0 ) , TVE_VertexUsage[(int)_LayerVertexValue]);
				//half4 Global_Object_Params = Global_Object_Params;
				half Global_VertexSize = saturate( Global_Object_Params.w );
				Global_VertexSize = lerp( 1.0 , Global_VertexSize , _GlobalSize);
				//float3 appendResult3480_g74029 = (float3(Global_VertexSize , Global_VertexSize , Global_VertexSize));
				// half3 appendResult3480_g74029 = appendResult3480_g74029;
				// half3 _Vector11 = half3(1,1,1);
				// half3 _Vector11 = _Vector11;
				#ifdef TVE_FEATURE_BATCHING
					float3 Vertex_Size = half3(1,1,1);
				#else
					float3 Vertex_Size = float3(Global_VertexSize , Global_VertexSize , Global_VertexSize);
				#endif
				// half3 Vertex_Size = Vertex_Size;
				// half3 _Vector5 = half3(1,1,1);
				// float3 1 = _Vector5;
				//float3 lerpResult16_g74042 = lerp( v.vertex.xyz , Vertex_Motion * Vertex_Size , TVE_Enabled);
				//float3 Final_VertexPosition890_g74029 = ( lerp( v.vertex.xyz , Vertex_Motion * Vertex_Size , TVE_Enabled) + _DisableSRPBatcher );
				
				o.ase_texcoord3.xyz = ase_worldPos;
				o.ase_texcoord4.xyz = posWSVertToFrag;
				float temp_output_7_0_g74058 = TVE_CameraFadeStart;
				//float lerpResult4755_g74029 = lerp( 1.0 , saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - temp_output_7_0_g74058 ) / ( TVE_CameraFadeEnd - temp_output_7_0_g74058 ) ) ) , _FadeCameraValue);
				//float vertexToFrag11_g74057 = lerpResult4755_g74029;
				o.ase_texcoord3.w = lerp( 1.0 , saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - temp_output_7_0_g74058 ) / ( TVE_CameraFadeEnd - temp_output_7_0_g74058 ) ) ) , _FadeCameraValue);
				
				o.ase_texcoord2 = v.ase_texcoord;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = lerp( v.vertex.xyz , Vertex_Motion * Vertex_Size , TVE_Enabled) + _DisableSRPBatcher;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = clipPos;

				return o;
			}

			#if defined(TESSELLATION_ON)
				struct VertexControl
				{
					float4 vertex : INTERNALTESSPOS;
					float3 ase_normal : NORMAL;
					float4 ase_texcoord3 : TEXCOORD3;
					float4 ase_color : COLOR;
					float4 ase_texcoord : TEXCOORD0;

					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct TessellationFactors
				{
					float edge[3] : SV_TessFactor;
					float inside : SV_InsideTessFactor;
				};

				VertexControl vert ( VertexInput v )
				{
					VertexControl o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.vertex = v.vertex;
					o.ase_normal = v.ase_normal;
					o.ase_texcoord3 = v.ase_texcoord3;
					o.ase_color = v.ase_color;
					o.ase_texcoord = v.ase_texcoord;
					return o;
				}

				TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
				{
					TessellationFactors o;
					float4 tf = 1;
					float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
					float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
					#if defined(ASE_FIXED_TESSELLATION)
						tf = FixedTess( tessValue );
					#elif defined(ASE_DISTANCE_TESSELLATION)
						tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
					#elif defined(ASE_LENGTH_TESSELLATION)
						tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
					#elif defined(ASE_LENGTH_CULL_TESSELLATION)
						tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
					#endif
					o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
					return o;
				}

				[domain("tri")]
				[partitioning("fractional_odd")]
				[outputtopology("triangle_cw")]
				[patchconstantfunc("TessellationFunction")]
				[outputcontrolpoints(3)]
				VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
				{
					return patch[id];
				}

				[domain("tri")]
				VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
				{
					VertexInput o = (VertexInput) 0;
					o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
					o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
					o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
					o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
					o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
					#if defined(ASE_PHONG_TESSELLATION)
						float3 pp[3];
						for (int i = 0; i < 3; ++i)
						pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
						float phongStrength = _TessPhongStrength;
						o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
					#endif
					UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
					return VertexFunction(o);
				}
			#else
				VertexOutput vert ( VertexInput v )
				{
					return VertexFunction( v );
				}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN 
			#ifdef ASE_DEPTH_WRITE_ON
				,out float outputDepth : ASE_SV_DEPTH
			#endif
			) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float localCustomAlphaClip19_g74061 = ( 0.0 );
				half2 Main_UVs15_g74029 = ( ( IN.ase_texcoord2.xy * (_MainUVs).xy ) + (_MainUVs).zw );
				float4 tex2DNode29_g74029 = tex2D( _MainAlbedoTex, Main_UVs15_g74029 );
				float Main_Alpha316_g74029 = ( _MainColor.a * tex2DNode29_g74029.a );
				float4 temp_output_93_19_g74035 = TVE_ExtrasCoords;
				float3 vertexToFrag3890_g74029 = IN.ase_texcoord3.xyz;
				float3 WorldPosition3905_g74029 = vertexToFrag3890_g74029;
				float3 vertexToFrag4224_g74029 = IN.ase_texcoord4.xyz;
				half3 ObjectData20_g74082 = vertexToFrag4224_g74029;
				half3 WorldData19_g74082 = vertexToFrag3890_g74029;
				#ifdef TVE_FEATURE_BATCHING
				float3 staticSwitch14_g74082 = WorldData19_g74082;
				#else
				float3 staticSwitch14_g74082 = ObjectData20_g74082;
				#endif
				float3 ObjectPosition4223_g74029 = staticSwitch14_g74082;
				float3 lerpResult4827_g74029 = lerp( WorldPosition3905_g74029 , ObjectPosition4223_g74029 , _ExtrasPositionMode);
				half2 UV96_g74035 = ( (temp_output_93_19_g74035).zw + ( (temp_output_93_19_g74035).xy * (lerpResult4827_g74029).xz ) );
				float temp_output_84_0_g74035 = _LayerExtrasValue;
				float4 lerpResult109_g74035 = lerp( TVE_ExtrasParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_ExtrasTex, sampler_linear_clamp, UV96_g74035,temp_output_84_0_g74035, 0.0 ) , TVE_ExtrasUsage[(int)temp_output_84_0_g74035]);
				float4 break89_g74035 = lerpResult109_g74035;
				half Global_Extras_Alpha1033_g74029 = saturate( break89_g74035.a );
				float3 break111_g74046 = ObjectPosition4223_g74029;
				half Global_DynamicMode5112_g74029 = _VertexDynamicMode;
				half Input_DynamicMode120_g74046 = Global_DynamicMode5112_g74029;
				float Mesh_Variation16_g74029 = IN.ase_color.r;
				half Input_Variation124_g74046 = Mesh_Variation16_g74029;
				half ObjectData20_g74047 = frac( ( ( ( break111_g74046.x + break111_g74046.y + break111_g74046.z + 0.001275 ) * ( 1.0 - Input_DynamicMode120_g74046 ) ) + Input_Variation124_g74046 ) );
				half WorldData19_g74047 = Input_Variation124_g74046;
				#ifdef TVE_FEATURE_BATCHING
				float staticSwitch14_g74047 = WorldData19_g74047;
				#else
				float staticSwitch14_g74047 = ObjectData20_g74047;
				#endif
				float clampResult129_g74046 = clamp( staticSwitch14_g74047 , 0.01 , 0.99 );
				half Global_MeshVariation5104_g74029 = clampResult129_g74046;
				float lerpResult5154_g74029 = lerp( 0.1 , Global_MeshVariation5104_g74029 , _AlphaVariationValue);
				half Global_Alpha_Variation5158_g74029 = lerpResult5154_g74029;
				half Global_Alpha_Mask4546_g74029 = 1.0;
				float lerpResult5203_g74029 = lerp( 1.0 , ( ( Global_Extras_Alpha1033_g74029 - Global_Alpha_Variation5158_g74029 ) + ( Global_Extras_Alpha1033_g74029 * 0.5 ) ) , ( Global_Alpha_Mask4546_g74029 * _GlobalAlpha ));
				float lerpResult16_g74059 = lerp( 1.0 , lerpResult5203_g74029 , TVE_Enabled);
				half AlphaTreshold2132_g74029 = _AlphaClipValue;
				half Global_Alpha315_g74029 = ( lerpResult16_g74059 + AlphaTreshold2132_g74029 );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult2169_g74029 = normalize( ase_worldViewDir );
				float3 ViewDir_Normalized3963_g74029 = normalizeResult2169_g74029;
				float3 normalizeResult3971_g74029 = normalize( cross( ddy( WorldPosition ) , ddx( WorldPosition ) ) );
				float3 NormalsWS_Derivates3972_g74029 = normalizeResult3971_g74029;
				float dotResult3851_g74029 = dot( ViewDir_Normalized3963_g74029 , NormalsWS_Derivates3972_g74029 );
				float lerpResult3993_g74029 = lerp( 1.0 , saturate( abs( dotResult3851_g74029 ) ) , _FadeGlancingValue);
				half Fade_Glancing3853_g74029 = lerpResult3993_g74029;
				float vertexToFrag11_g74057 = IN.ase_texcoord3.w;
				half Fade_Camera3743_g74029 = vertexToFrag11_g74057;
				half Fade_Mask5149_g74029 = 1.0;
				float lerpResult5141_g74029 = lerp( 1.0 , ( Fade_Glancing3853_g74029 * Fade_Camera3743_g74029 ) , Fade_Mask5149_g74029);
				half Fade_Effects5360_g74029 = lerpResult5141_g74029;
				float temp_output_41_0_g74054 = Fade_Effects5360_g74029;
				float temp_output_5361_0_g74029 = ( saturate( ( temp_output_41_0_g74054 + ( temp_output_41_0_g74054 * tex3D( TVE_ScreenTex3D, ( TVE_ScreenTexCoord * WorldPosition3905_g74029 ) ).r ) ) ) + -0.5 + AlphaTreshold2132_g74029 );
				half Fade_Alpha3727_g74029 = temp_output_5361_0_g74029;
				float temp_output_661_0_g74029 = ( Main_Alpha316_g74029 * Global_Alpha315_g74029 * Fade_Alpha3727_g74029 );
				half Alpha34_g74056 = temp_output_661_0_g74029;
				half Offest27_g74056 = AlphaTreshold2132_g74029;
				half AlphaFeather5305_g74029 = _AlphaFeatherValue;
				half Feather30_g74056 = AlphaFeather5305_g74029;
				float temp_output_25_0_g74056 = ( ( ( Alpha34_g74056 - Offest27_g74056 ) / ( max( fwidth( Alpha34_g74056 ) , 0.001 ) + Feather30_g74056 ) ) + Offest27_g74056 );
				float temp_output_3_0_g74061 = temp_output_25_0_g74056;
				float Alpha19_g74061 = temp_output_3_0_g74061;
				float temp_output_15_0_g74061 = AlphaTreshold2132_g74029;
				float Treshold19_g74061 = temp_output_15_0_g74061;
				{
				#if defined (TVE_FEATURE_CLIP)
				#if defined (TVE_IS_HD_PIPELINE)
				#if !defined (SHADERPASS_FORWARD_BYPASS_ALPHA_TEST)
				clip(Alpha19_g74061 - Treshold19_g74061);
				#endif
				#if !defined (SHADERPASS_GBUFFER_BYPASS_ALPHA_TEST)
				clip(Alpha19_g74061 - Treshold19_g74061);
				#endif
				#else
				clip(Alpha19_g74061 - Treshold19_g74061);
				#endif
				#endif
				}
				half Final_Alpha914_g74029 = saturate( Alpha19_g74061 );
				

				float Alpha = Final_Alpha914_g74029;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}
		//-------------------------------------------------------------------------------------
		// END_PASS SHADOWCASTER
		//-------------------------------------------------------------------------------------

		
		//-------------------------------------------------------------------------------------
		// BEGIN_PASS DEPTHONLY
		//-------------------------------------------------------------------------------------
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			HLSLPROGRAM
			
			#define _SPECULAR_SETUP 1
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#pragma multi_compile _ DOTS_INSTANCING_ON
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _TRANSLUCENCY_ASE 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120100

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			//-----------------------------------------------------------------------------
			// DEFINES - (Set by User)
			//-----------------------------------------------------------------------------

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local TVE_FEATURE_CLIP
			#pragma shader_feature_local TVE_FEATURE_BATCHING
			//TVE Pipeline Defines
			#define THE_VEGETATION_ENGINE
			#define TVE_IS_UNIVERSAL_PIPELINE
			//TVE Injection Defines
			//SHADER INJECTION POINT BEGIN
			//SHADER INJECTION POINT END
			//TVE Shader Type Defines
			#define TVE_IS_VEGETATION_SHADER


			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//-------------------------------------------------------------------------------------
			// BEGIN_CBUFFER
			//-------------------------------------------------------------------------------------

			CBUFFER_START(UnityPerMaterial)
				half4 _ColorsMaskRemap;
				half4 _VertexOcclusionRemap;
				half4 _DetailBlendRemap;
				half4 _SubsurfaceMaskRemap;
				float4 _GradientMaskRemap;
				half4 _GradientColorTwo;
				float4 _MaxBoundsInfo;
				half4 _GradientColorOne;
				half4 _MainColor;
				half4 _MainUVs;
				float4 _Color;
				float4 _SubsurfaceDiffusion_Asset;
				half4 _AlphaMaskRemap;
				half4 _EmissiveColor;
				float4 _EmissiveIntensityParams;
				half4 _VertexOcclusionColor;
				float4 _SubsurfaceDiffusion_asset;
				half4 _OverlayMaskRemap;
				float4 _NoiseMaskRemap;
				half4 _SubsurfaceColor;
				half4 _EmissiveUVs;
				half3 _render_normals;
				half _MotionNormalValue;
				half _MotionValue_30;
				half _MotionAmplitude_32;
				half _FadeGlancingValue;
				float _MotionSpeed_32;
				half _FadeCameraValue;
				float _MotionVariation_32;
				float _MotionScale_32;
				half _MotionAmplitude_22;
				half _MotionAmplitude_20;
				half _MotionValue_20;
				half _MotionSpeed_20;
				half _MotionVariation_20;
				half _MotionScale_20;
				half _InteractionMaskValue;
				half _InteractionAmplitude;
				half _SubsurfaceValue;
				half _VertexDynamicMode;
				half _MotionVariation_10;
				float _MotionSpeed_10;
				float _MotionScale_10;
				half _MotionAmplitude_10;
				half _LayerMotionValue;
				half _MotionFacingValue;
				half _VertexDataMode;
				half _GlobalSize;
				half _GlobalAlpha;
				half _GlobalEmissive;
				half _RenderSpecular;
				half _MainNormalValue;
				half _OverlayMaskMaxValue;
				half _OverlayMaskMinValue;
				half _MainSmoothnessValue;
				half _OverlayVariationValue;
				half _LayerExtrasValue;
				half _ExtrasPositionMode;
				half _GlobalOverlay;
				half _ColorsMaskMaxValue;
				half _LayerVertexValue;
				half _ColorsMaskMinValue;
				half _GlobalWetness;
				half _GlobalColors;
				half _LayerColorsValue;
				half _ColorsPositionMode;
				half _VertexOcclusionMaxValue;
				half _VertexOcclusionMinValue;
				half _VertexPivotMode;
				half _MainOcclusionValue;
				half _GradientMaxValue;
				half _GradientMinValue;
				half _AlphaVariationValue;
				half _ColorsVariationValue;
				half _render_zw;
				half _IsLeafShader;
				half _render_coverage;
				half _CategoryOcclusion;
				half _CategoryMain;
				half _CategorySizeFade;
				half _SpaceMotionLocals;
				half _IsVersion;
				half _RenderCoverage;
				half _LayerReactValue;
				half _RenderMode;
				half _RenderPriority;
				half _CategoryMotion;
				half _RenderClip;
				half _RenderAmbient;
				half _CategoryDetail;
				half _CategoryEmissive;
				half _VertexVariationMode;
				half _SpaceGlobalPosition;
				half _MessageSizeFade;
				half _SubsurfaceAngleValue;
				half _HasGradient;
				half _SpaceRenderFade;
				half _HasEmissive;
				half _SpaceGlobalLocals;
				half _DetailMode;
				half _DetailTypeMode;
				half _CategorySubsurface;
				half _VertexMasksMode;
				half _RenderShadow;
				half _SpaceMotionGlobals;
				half _IsTVEShader;
				half _RenderNormals;
				half _CategoryGradient;
				half _SpaceGlobalLayers;
				half _render_dst;
				half _render_cull;
				half _render_src;
				half _SubsurfaceMaskMinValue;
				half _SubsurfaceNormalValue;
				half _MessageMotionVariation;
				half _RenderSSR;
				half _CategoryGlobal;
				half _SubsurfaceScatteringValue;
				half _SubsurfaceShadowValue;
				half _RenderZWrite;
				half _MessageGlobalsVariation;
				half _RenderDirect;
				half _RenderDecals;
				half _AlphaFeatherValue;
				half _EmissiveFlagMode;
				half _CategoryNoise;
				half _CategoryPerspective;
				float _SubsurfaceDiffusion;
				half _CategoryRender;
				half _RenderQueue;
				half _DetailBlendMode;
				half _SubsurfaceDirectValue;
				half _SubsurfaceAmbientValue;
				half _RenderCull;
				half _HasOcclusion;
				half _Cutoff;
				half _AlphaClipValue;
				half _VertexRollingMode;
				half _IsSubsurfaceShader;
				half _SubsurfaceMaskMaxValue;
				#ifdef _TRANSMISSION_ASE
					float _TransmissionShadow;
				#endif
				#ifdef _TRANSLUCENCY_ASE
					float _TransStrength;
					float _TransNormal;
					float _TransScattering;
					float _TransDirect;
					float _TransAmbient;
					float _TransShadow;
				#endif
				#ifdef TESSELLATION_ON
					float _TessPhongStrength;
					float _TessValue;
					float _TessMin;
					float _TessMax;
					float _TessEdgeLength;
					float _TessMaxDisp;
				#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			//-------------------------------------------------------------------------------------
			// END_CBUFFER
			//-------------------------------------------------------------------------------------

			sampler2D _BumpMap;
			half TVE_Enabled;
			sampler2D _MainTex;
			half4 TVE_MotionParams;
			TEXTURE2D_ARRAY(TVE_MotionTex);
			half4 TVE_MotionCoords;
			SAMPLER(sampler_linear_clamp);
			float TVE_MotionUsage[10];
			sampler2D TVE_NoiseTex;
			half4 TVE_NoiseParams;
			half4 TVE_FlutterParams;
			half TVE_MotionFadeEnd;
			half TVE_MotionFadeStart;
			half4 TVE_VertexParams;
			TEXTURE2D_ARRAY(TVE_VertexTex);
			half4 TVE_VertexCoords;
			float TVE_VertexUsage[10];
			half _DisableSRPBatcher;
			sampler2D _MainAlbedoTex;
			half4 TVE_ExtrasParams;
			TEXTURE2D_ARRAY(TVE_ExtrasTex);
			half4 TVE_ExtrasCoords;
			float TVE_ExtrasUsage[10];
			half TVE_CameraFadeStart;
			half TVE_CameraFadeEnd;
			sampler3D TVE_ScreenTex3D;
			half TVE_ScreenTexCoord;


			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			float2 DecodeFloatToVector2( float enc )
			{
				float2 result ;
				result.y = enc % 2048;
				result.x = floor(enc / 2048);
				return result / (2048 - 1);
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexPosRotationAxis = (float3(v.vertex.x , 0.0 , 0.0));
				float3 VertexPosOtherAxis = (float3(0.0 , v.vertex.y , v.vertex.z));
				float3 ObjectData = (float3(GetObjectToWorldMatrix()[ 0 ][ 3 ] , GetObjectToWorldMatrix()[ 1 ][ 3 ] , GetObjectToWorldMatrix()[ 2 ][ 3 ]));
				float3 MeshPivotsData = (float3(v.ase_texcoord3.x , v.ase_texcoord3.z , v.ase_texcoord3.y));
				float3 PivotsOnly = (mul( GetObjectToWorldMatrix(), float4( MeshPivotsData * _VertexPivotMode , 0.0 ) ).xyz).xyz;
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;

				#ifdef TVE_FEATURE_BATCHING
					float3 ObjectPos = ase_worldPos;
				#else
					float3 ObjectPos = ObjectData + PivotsOnly;
				#endif

				#ifdef TVE_FEATURE_BATCHING
					float3 ObjectPos_W = ase_worldPos;
				#else
					float3 ObjectPos_W = ObjectPos;
				#endif

				half2 UV_Motion = ( (TVE_MotionCoords).zw + ( (TVE_MotionCoords).xy * (ObjectPos_W).xz ) );
				float4 GlobalMotionParams = lerp( TVE_MotionParams , saturate( SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_MotionTex, sampler_linear_clamp, UV_Motion, _LayerMotionValue, 0.0 ) ) , TVE_MotionUsage[(int)_LayerMotionValue]);
				float3 Global_Motion_Params_xy = (float3(GlobalMotionParams.x , 0.0 , GlobalMotionParams.y));
				float3 GlobalMotionParams_xy = (Global_Motion_Params_xy*2.0 - 1.0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				half2 GlobalMotionDirection = (( mul( GetWorldToObjectMatrix(), float4( GlobalMotionParams_xy , 0.0 ) ).xyz * ase_parentObjectScale )).xz;
				float2 ObjectMotionPos = (( ObjectPos_W * (_MotionScale_10 + 1.0) * TVE_NoiseParams.x * 0.0075 )).xz;
				half2 DirectionWS = (GlobalMotionParams_xy).xz;

				#ifdef TVE_FEATURE_BATCHING
					float GlobalMeshVariation = v.ase_color.r;
				#else
					float GlobalMeshVariation = frac( ( ( ( ObjectPos_W.x + ObjectPos_W.y + ObjectPos_W.z + 0.001275 ) * ( 1.0 - _VertexDynamicMode ) ) + v.ase_color.r ) );
				#endif

				GlobalMeshVariation = clamp( GlobalMeshVariation , 0.01 , 0.99 );
				float MotionVariation = ( ( ( _TimeParameters.x * _MotionSpeed_10 * TVE_NoiseParams.y ) + ( _MotionVariation_10 * GlobalMeshVariation ) ) * 0.03 );
				float4 Noise_Sampled = lerp( tex2Dlod( TVE_NoiseTex, float4( ( ObjectMotionPos + ( -(GlobalMotionParams_xy).xz * frac( MotionVariation ) ) ), 0, 0.0) ) , 
				tex2Dlod( TVE_NoiseTex, float4( ( ObjectMotionPos + ( -(GlobalMotionParams_xy).xz * frac( ( MotionVariation + 0.5 ) ) ) ), 0, 0.0) ) , 
				( abs( ( frac( MotionVariation ) - 0.5 ) ) / 0.5 ));

				float GlobalWind = lerp( 1.4 , 0.4 , GlobalMotionParams.z);
				float3 GlobalNoise = (pow( ( abs( (Noise_Sampled).rgb ) + 0.2 ) , GlobalWind.xxx )*1.4 + -0.2);
				half MotionAmplitude_10 = ( _MotionAmplitude_10 * GlobalMotionParams.z * GlobalNoise.x );
				float2 BoundsHeight = DecodeFloatToVector2( v.ase_texcoord.w );
				BoundsHeight = ( BoundsHeight * 100.0 );

				#ifdef TVE_FEATURE_BATCHING
					float MaskMotion = v.ase_color.a * v.ase_color.a * BoundsHeight.x * 2.0;
				#else
					float MaskMotion = v.ase_color.a * 2.0;
				#endif

				#ifdef TVE_FEATURE_BATCHING
					float MaskInteraction = MaskMotion;
				#else
					float MaskInteraction = lerp( 2.0 , MaskMotion , _InteractionMaskValue);
				#endif
				MaskInteraction = ( _InteractionAmplitude * MaskInteraction );
				float MotionBending_10 = lerp( ( MotionAmplitude_10 * MaskMotion ) , MaskInteraction , saturate( ( _InteractionAmplitude * GlobalMotionParams.w * GlobalMotionParams.w ) ));
				float2 MotionBending_10_2 = ( GlobalMotionDirection * MotionBending_10 );

				half3 VertexPos = ( VertexPosRotationAxis + ( VertexPosOtherAxis * cos( MotionBending_10_2.y ) ) + ( cross( float3(1,0,0) , VertexPosOtherAxis ) * sin( MotionBending_10_2.y ) ) );
				VertexPosRotationAxis = (float3(0.0 , 0.0 , VertexPos.z));
				VertexPosOtherAxis = (float3(VertexPos.x , VertexPos.y , 0.0));
				half MotionSine_20 = sin( ( ( ( ase_worldPos.x + ase_worldPos.y + ase_worldPos.z ) * _MotionScale_20 ) + ( _MotionVariation_20 * GlobalMeshVariation ) + ( _TimeParameters.x * _MotionSpeed_20 ) ) );
				float VertexPosMotion = dot( normalize(v.vertex.xyz) , float3(GlobalMotionDirection.x , 0.0 , GlobalMotionDirection.y) );

				#ifdef TVE_FEATURE_BATCHING
					float MotionFacingMask = 1.0;
				#else
					float MotionFacingMask = max( lerp( 1.0 , (VertexPosMotion*0.5 + 0.5) , _MotionFacingValue) , 0.001 );
				#endif

				half MotionAmplitude_20 = ( _MotionValue_20 * GlobalMotionParams.z * GlobalNoise.x * MotionFacingMask );
				float2 MeshMotion = DecodeFloatToVector2( v.ase_texcoord.z );
				float3 GlobalMotionDirection_xy = (float3(GlobalMotionDirection.x , ( MotionSine_20 * 0.1 ) , GlobalMotionDirection.y));
				half3 MotionSquash_20 = ( ( (MotionSine_20*0.2 + 1.0) * MotionAmplitude_20 * _MotionAmplitude_20 * MeshMotion.x *  BoundsHeight.y ) * GlobalMotionDirection_xy );
				
				VertexPos = ( ( VertexPosRotationAxis + ( VertexPosOtherAxis * cos( -MotionBending_10.x ) ) + ( cross( float3(0,0,1) , VertexPosOtherAxis ) * sin( -MotionBending_10.x ) ) ) + MotionSquash_20 );
				VertexPosRotationAxis = (float3(0.0 , VertexPos.y , 0.0));
				VertexPosOtherAxis = (float3(VertexPos.x , 0.0 , VertexPos.z));
				half MotionRolling_20 = ( MotionSine_20 * MotionAmplitude_20 * _MotionAmplitude_22 * MeshMotion.x );
				half MotionFadeOut = saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - TVE_MotionFadeEnd ) / ( TVE_MotionFadeStart - TVE_MotionFadeEnd ) ) );
				half MotionAmplitude_30 = ( _MotionAmplitude_32 * _MotionValue_30 * GlobalMotionParams.z * GlobalNoise.x * MotionFacingMask * MotionFadeOut );
				float3 MotionNormal = lerp( float3( 1,1,1 ) , v.ase_normal , _MotionNormalValue);

				half3 MotionDetails_30 = ( ( sin( ( ( ( ase_worldPos.x + ase_worldPos.y + ase_worldPos.z ) * _MotionScale_32 ) + ( _MotionVariation_32 * GlobalMeshVariation ) + ( _TimeParameters.x * _MotionSpeed_32 * TVE_FlutterParams.y ) ) ) *
				MotionAmplitude_30 * TVE_FlutterParams.x * MeshMotion.y * 0.4 ) * MotionNormal );

				#ifdef TVE_FEATURE_BATCHING
					float3 MotionBlend = v.vertex.xyz + float3(MotionBending_10_2.x , 0.0 , MotionBending_10_2.y) + MotionSquash_20 + MotionDetails_30;
				#else
					float3 MotionBlend = ( VertexPosRotationAxis + ( VertexPosOtherAxis * cos( MotionRolling_20 ) ) + ( cross( float3(0,1,0) , VertexPosOtherAxis ) * sin( MotionRolling_20 ) ) ) + MotionDetails_30;
				#endif

				half2 UV_Vertex = ( (TVE_VertexCoords).zw + ( (TVE_VertexCoords).xy * (ObjectPos_W).xz ) );
				float4 GlobalObjectParams = lerp( TVE_VertexParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_VertexTex, sampler_linear_clamp, UV_Vertex, _LayerVertexValue, 0.0 ) , TVE_VertexUsage[(int)_LayerVertexValue]);
				half Global_VertexSize = saturate( GlobalObjectParams.w );
				float Size = lerp( 1.0 , Global_VertexSize , _GlobalSize);

				#ifdef TVE_FEATURE_BATCHING
					float3 VertexSize = half3(1,1,1);
				#else
					float3 VertexSize = float3(Size , Size , Size);
				#endif

				float3 FinalVertexPosition = lerp( v.vertex.xyz , MotionBlend * VertexSize , TVE_Enabled);
				
				o.ase_texcoord3.xyz = ase_worldPos;
				o.ase_texcoord4.xyz = ObjectPos;
				o.ase_texcoord3.w = lerp( 1.0 , saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - TVE_CameraFadeStart ) / ( TVE_CameraFadeEnd - TVE_CameraFadeStart ) ) ) , _FadeCameraValue);
				
				o.ase_texcoord2 = v.ase_texcoord;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = FinalVertexPosition + _DisableSRPBatcher;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(TESSELLATION_ON)
				struct VertexControl
				{
					float4 vertex : INTERNALTESSPOS;
					float3 ase_normal : NORMAL;
					float4 ase_texcoord3 : TEXCOORD3;
					float4 ase_color : COLOR;
					float4 ase_texcoord : TEXCOORD0;

					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct TessellationFactors
				{
					float edge[3] : SV_TessFactor;
					float inside : SV_InsideTessFactor;
				};

				VertexControl vert ( VertexInput v )
				{
					VertexControl o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.vertex = v.vertex;
					o.ase_normal = v.ase_normal;
					o.ase_texcoord3 = v.ase_texcoord3;
					o.ase_color = v.ase_color;
					o.ase_texcoord = v.ase_texcoord;
					return o;
				}

				TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
				{
					TessellationFactors o;
					float4 tf = 1;
					float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
					float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
					#if defined(ASE_FIXED_TESSELLATION)
						tf = FixedTess( tessValue );
					#elif defined(ASE_DISTANCE_TESSELLATION)
						tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
					#elif defined(ASE_LENGTH_TESSELLATION)
						tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
					#elif defined(ASE_LENGTH_CULL_TESSELLATION)
						tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
					#endif
					o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
					return o;
				}

				[domain("tri")]
				[partitioning("fractional_odd")]
				[outputtopology("triangle_cw")]
				[patchconstantfunc("TessellationFunction")]
				[outputcontrolpoints(3)]
				VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
				{
					return patch[id];
				}

				[domain("tri")]
				VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
				{
					VertexInput o = (VertexInput) 0;
					o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
					o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
					o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
					o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
					o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
					#if defined(ASE_PHONG_TESSELLATION)
						float3 pp[3];
						for (int i = 0; i < 3; ++i)
						pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
						float phongStrength = _TessPhongStrength;
						o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
					#endif
					UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
					return VertexFunction(o);
				}
			#else
				VertexOutput vert ( VertexInput v )
				{
					return VertexFunction( v );
				}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN 
			#ifdef ASE_DEPTH_WRITE_ON
				,out float outputDepth : ASE_SV_DEPTH
			#endif
			) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				half2 MainUVs = ( ( IN.ase_texcoord2.xy * (_MainUVs).xy ) + (_MainUVs).zw );
				float4 AlbedoTex = tex2D( _MainAlbedoTex, MainUVs );
				float MainAlpha = ( _MainColor.a * AlbedoTex.a );

				#ifdef TVE_FEATURE_BATCHING
					float3 ObjectPos_W = IN.ase_texcoord3.xyz;
				#else
					float3 ObjectPos_W = IN.ase_texcoord4.xyz;
				#endif
				float3 ExtrasPosition = lerp( IN.ase_texcoord3.xyz , ObjectPos_W , _ExtrasPositionMode);
				half2 UV_Extras = ( (TVE_ExtrasCoords).zw + ( (TVE_ExtrasCoords).xy * (ExtrasPosition).xz ) );
				float4 Albedo_Extras = lerp( TVE_ExtrasParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_ExtrasTex, sampler_linear_clamp, UV_Extras, _LayerExtrasValue, 0.0 ) , TVE_ExtrasUsage[(int)_LayerExtrasValue]);

				#ifdef TVE_FEATURE_BATCHING
					float GlobalMeshVariation = IN.ase_color.r;
				#else
					float GlobalMeshVariation = frac( ( ( ( ObjectPos_W.x + ObjectPos_W.y + ObjectPos_W.z + 0.001275 ) * ( 1.0 - _VertexDynamicMode ) ) + IN.ase_color.r ) );
				#endif
				GlobalMeshVariation = clamp( GlobalMeshVariation , 0.01 , 0.99 );
				float GlobalAlphaVariation = lerp( 0.1 , GlobalMeshVariation , _AlphaVariationValue);
				float GlobalAlpha = lerp( 1.0 , ( ( saturate( Albedo_Extras.a ) - GlobalAlphaVariation ) + ( saturate( Albedo_Extras.a ) * 0.5 ) ) , _GlobalAlpha );
				float lerpResult16_g74059 = lerp( 1.0 , GlobalAlpha , TVE_Enabled);
				GlobalAlpha = lerp( 1.0 , GlobalAlpha , TVE_Enabled) + _AlphaClipValue;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 NormalsWSDerivates = normalize( cross( ddy( WorldPosition ) , ddx( WorldPosition ) ) );
				float FadeGlancing = lerp( 1.0 , saturate( abs( dot( ase_worldViewDir , NormalsWSDerivates ) ) ) , _FadeGlancingValue);
				FadeGlancing = FadeGlancing * IN.ase_texcoord3.w;
				FadeGlancing = ( saturate( ( FadeGlancing + ( FadeGlancing * tex3D( TVE_ScreenTex3D, ( TVE_ScreenTexCoord * IN.ase_texcoord3.xyz ) ).r ) ) ) + -0.5 + _AlphaClipValue );
				float Alpha = ( MainAlpha * GlobalAlpha * FadeGlancing );
				Alpha = ( ( ( Alpha - _AlphaClipValue ) / ( max( fwidth( Alpha ) , 0.001 ) + _AlphaFeatherValue ) ) + _AlphaClipValue );

				{
					#if defined (TVE_FEATURE_CLIP)
						#if defined (TVE_IS_HD_PIPELINE)
							#if !defined (SHADERPASS_FORWARD_BYPASS_ALPHA_TEST)
								clip(Alpha - _AlphaClipValue);
							#endif
							#if !defined (SHADERPASS_GBUFFER_BYPASS_ALPHA_TEST)
								clip(Alpha - _AlphaClipValue);
							#endif
						#else
							clip(Alpha - _AlphaClipValue);
						#endif
					#endif
				}

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(saturate( Alpha ) - 0.5);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}
		//-------------------------------------------------------------------------------------
		// END_PASS DEPTHONLY
		//-------------------------------------------------------------------------------------


		//-------------------------------------------------------------------------------------
		// BEGIN_PASS DEPTHNORMALS
		//-------------------------------------------------------------------------------------
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZWrite On
			Blend One Zero
			ZTest LEqual
			//ZWrite On

			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			HLSLPROGRAM

			#define _SPECULAR_SETUP 1
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#pragma multi_compile _ DOTS_INSTANCING_ON
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _TRANSLUCENCY_ASE 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120100


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			//-----------------------------------------------------------------------------
			// DEFINES - (Set by User)
			//-----------------------------------------------------------------------------

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local TVE_FEATURE_CLIP
			#pragma shader_feature_local TVE_FEATURE_BATCHING
			//TVE Pipeline Defines
			#define THE_VEGETATION_ENGINE
			#define TVE_IS_UNIVERSAL_PIPELINE
			//TVE Injection Defines
			//SHADER INJECTION POINT BEGIN
			//SHADER INJECTION POINT END
			//TVE Shader Type Defines
			#define TVE_IS_VEGETATION_SHADER


			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float3 worldNormal : TEXCOORD2;
				float4 worldTangent : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//-------------------------------------------------------------------------------------
			// BEGIN_CBUFFER
			//-------------------------------------------------------------------------------------

			CBUFFER_START(UnityPerMaterial)
				half4 _ColorsMaskRemap;
				half4 _VertexOcclusionRemap;
				half4 _DetailBlendRemap;
				half4 _SubsurfaceMaskRemap;
				float4 _GradientMaskRemap;
				half4 _GradientColorTwo;
				float4 _MaxBoundsInfo;
				half4 _GradientColorOne;
				half4 _MainColor;
				half4 _MainUVs;
				float4 _Color;
				float4 _SubsurfaceDiffusion_Asset;
				half4 _AlphaMaskRemap;
				half4 _EmissiveColor;
				float4 _EmissiveIntensityParams;
				half4 _VertexOcclusionColor;
				float4 _SubsurfaceDiffusion_asset;
				half4 _OverlayMaskRemap;
				float4 _NoiseMaskRemap;
				half4 _SubsurfaceColor;
				half4 _EmissiveUVs;
				half3 _render_normals;
				half _MotionNormalValue;
				half _MotionValue_30;
				half _MotionAmplitude_32;
				half _FadeGlancingValue;
				float _MotionSpeed_32;
				half _FadeCameraValue;
				float _MotionVariation_32;
				float _MotionScale_32;
				half _MotionAmplitude_22;
				half _MotionAmplitude_20;
				half _MotionValue_20;
				half _MotionSpeed_20;
				half _MotionVariation_20;
				half _MotionScale_20;
				half _InteractionMaskValue;
				half _InteractionAmplitude;
				half _SubsurfaceValue;
				half _VertexDynamicMode;
				half _MotionVariation_10;
				float _MotionSpeed_10;
				float _MotionScale_10;
				half _MotionAmplitude_10;
				half _LayerMotionValue;
				half _MotionFacingValue;
				half _VertexDataMode;
				half _GlobalSize;
				half _GlobalAlpha;
				half _GlobalEmissive;
				half _RenderSpecular;
				half _MainNormalValue;
				half _OverlayMaskMaxValue;
				half _OverlayMaskMinValue;
				half _MainSmoothnessValue;
				half _OverlayVariationValue;
				half _LayerExtrasValue;
				half _ExtrasPositionMode;
				half _GlobalOverlay;
				half _ColorsMaskMaxValue;
				half _LayerVertexValue;
				half _ColorsMaskMinValue;
				half _GlobalWetness;
				half _GlobalColors;
				half _LayerColorsValue;
				half _ColorsPositionMode;
				half _VertexOcclusionMaxValue;
				half _VertexOcclusionMinValue;
				half _VertexPivotMode;
				half _MainOcclusionValue;
				half _GradientMaxValue;
				half _GradientMinValue;
				half _AlphaVariationValue;
				half _ColorsVariationValue;
				half _render_zw;
				half _IsLeafShader;
				half _render_coverage;
				half _CategoryOcclusion;
				half _CategoryMain;
				half _CategorySizeFade;
				half _SpaceMotionLocals;
				half _IsVersion;
				half _RenderCoverage;
				half _LayerReactValue;
				half _RenderMode;
				half _RenderPriority;
				half _CategoryMotion;
				half _RenderClip;
				half _RenderAmbient;
				half _CategoryDetail;
				half _CategoryEmissive;
				half _VertexVariationMode;
				half _SpaceGlobalPosition;
				half _MessageSizeFade;
				half _SubsurfaceAngleValue;
				half _HasGradient;
				half _SpaceRenderFade;
				half _HasEmissive;
				half _SpaceGlobalLocals;
				half _DetailMode;
				half _DetailTypeMode;
				half _CategorySubsurface;
				half _VertexMasksMode;
				half _RenderShadow;
				half _SpaceMotionGlobals;
				half _IsTVEShader;
				half _RenderNormals;
				half _CategoryGradient;
				half _SpaceGlobalLayers;
				half _render_dst;
				half _render_cull;
				half _render_src;
				half _SubsurfaceMaskMinValue;
				half _SubsurfaceNormalValue;
				half _MessageMotionVariation;
				half _RenderSSR;
				half _CategoryGlobal;
				half _SubsurfaceScatteringValue;
				half _SubsurfaceShadowValue;
				half _RenderZWrite;
				half _MessageGlobalsVariation;
				half _RenderDirect;
				half _RenderDecals;
				half _AlphaFeatherValue;
				half _EmissiveFlagMode;
				half _CategoryNoise;
				half _CategoryPerspective;
				float _SubsurfaceDiffusion;
				half _CategoryRender;
				half _RenderQueue;
				half _DetailBlendMode;
				half _SubsurfaceDirectValue;
				half _SubsurfaceAmbientValue;
				half _RenderCull;
				half _HasOcclusion;
				half _Cutoff;
				half _AlphaClipValue;
				half _VertexRollingMode;
				half _IsSubsurfaceShader;
				half _SubsurfaceMaskMaxValue;
				#ifdef _TRANSMISSION_ASE
					float _TransmissionShadow;
				#endif
				#ifdef _TRANSLUCENCY_ASE
					float _TransStrength;
					float _TransNormal;
					float _TransScattering;
					float _TransDirect;
					float _TransAmbient;
					float _TransShadow;
				#endif
				#ifdef TESSELLATION_ON
					float _TessPhongStrength;
					float _TessValue;
					float _TessMin;
					float _TessMax;
					float _TessEdgeLength;
					float _TessMaxDisp;
				#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			//-------------------------------------------------------------------------------------
			// END_CBUFFER
			//-------------------------------------------------------------------------------------

			sampler2D _BumpMap;
			half TVE_Enabled;
			sampler2D _MainTex;
			half4 TVE_MotionParams;
			TEXTURE2D_ARRAY(TVE_MotionTex);
			half4 TVE_MotionCoords;
			SAMPLER(sampler_linear_clamp);
			float TVE_MotionUsage[10];
			sampler2D TVE_NoiseTex;
			half4 TVE_NoiseParams;
			half4 TVE_FlutterParams;
			half TVE_MotionFadeEnd;
			half TVE_MotionFadeStart;
			half4 TVE_VertexParams;
			TEXTURE2D_ARRAY(TVE_VertexTex);
			half4 TVE_VertexCoords;
			float TVE_VertexUsage[10];
			half _DisableSRPBatcher;
			sampler2D _MainNormalTex;
			sampler2D _MainAlbedoTex;
			half4 TVE_ExtrasParams;
			TEXTURE2D_ARRAY(TVE_ExtrasTex);
			half4 TVE_ExtrasCoords;
			float TVE_ExtrasUsage[10];
			half TVE_CameraFadeStart;
			half TVE_CameraFadeEnd;
			sampler3D TVE_ScreenTex3D;
			half TVE_ScreenTexCoord;


			//-------------------------------------------------------------------------------------
			// BEGIN_DEFINES
			//-------------------------------------------------------------------------------------

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			//-------------------------------------------------------------------------------------
			// END_DEFINES
			//-------------------------------------------------------------------------------------

			float2 DecodeFloatToVector2( float enc )
			{
				float2 result ;
				result.y = enc % 2048;
				result.x = floor(enc / 2048);
				return result / (2048 - 1);
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexPosition3588_g74029 = v.vertex.xyz;
				half3 Mesh_PivotsOS2291_g74029 = half3(0,0,0);
				float3 temp_output_2283_0_g74029 = ( VertexPosition3588_g74029 - Mesh_PivotsOS2291_g74029 );
				half3 VertexPos40_g74091 = temp_output_2283_0_g74029;
				float3 appendResult74_g74091 = (float3(VertexPos40_g74091.x , 0.0 , 0.0));
				half3 VertexPosRotationAxis50_g74091 = appendResult74_g74091;
				float3 break84_g74091 = VertexPos40_g74091;
				float3 appendResult81_g74091 = (float3(0.0 , break84_g74091.y , break84_g74091.z));
				half3 VertexPosOtherAxis82_g74091 = appendResult81_g74091;
				float4 temp_output_91_19_g74069 = TVE_MotionCoords;
				float4x4 break19_g74043 = GetObjectToWorldMatrix();
				float3 appendResult20_g74043 = (float3(break19_g74043[ 0 ][ 3 ] , break19_g74043[ 1 ][ 3 ] , break19_g74043[ 2 ][ 3 ]));
				float3 appendResult60_g74076 = (float3(v.ase_texcoord3.x , v.ase_texcoord3.z , v.ase_texcoord3.y));
				half3 Mesh_PivotsData2831_g74029 = ( appendResult60_g74076 * _VertexPivotMode );
				float3 temp_output_122_0_g74043 = Mesh_PivotsData2831_g74029;
				float3 PivotsOnly105_g74043 = (mul( GetObjectToWorldMatrix(), float4( temp_output_122_0_g74043 , 0.0 ) ).xyz).xyz;
				half3 ObjectData20_g74044 = ( appendResult20_g74043 + PivotsOnly105_g74043 );
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				half3 WorldData19_g74044 = ase_worldPos;
				#ifdef TVE_FEATURE_BATCHING
					float3 staticSwitch14_g74044 = WorldData19_g74044;
				#else
					float3 staticSwitch14_g74044 = ObjectData20_g74044;
				#endif
				float3 temp_output_114_0_g74043 = staticSwitch14_g74044;
				float3 vertexToFrag4224_g74029 = temp_output_114_0_g74043;
				half3 ObjectData20_g74082 = vertexToFrag4224_g74029;
				float3 vertexToFrag3890_g74029 = ase_worldPos;
				half3 WorldData19_g74082 = vertexToFrag3890_g74029;
				#ifdef TVE_FEATURE_BATCHING
					float3 staticSwitch14_g74082 = WorldData19_g74082;
				#else
					float3 staticSwitch14_g74082 = ObjectData20_g74082;
				#endif
				float3 ObjectPosition4223_g74029 = staticSwitch14_g74082;
				half2 UV94_g74069 = ( (temp_output_91_19_g74069).zw + ( (temp_output_91_19_g74069).xy * (ObjectPosition4223_g74029).xz ) );
				float temp_output_84_0_g74069 = _LayerMotionValue;
				float4 lerpResult107_g74069 = lerp( TVE_MotionParams , saturate( SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_MotionTex, sampler_linear_clamp, UV94_g74069,temp_output_84_0_g74069, 0.0 ) ) , TVE_MotionUsage[(int)temp_output_84_0_g74069]);
				half4 Global_Motion_Params3909_g74029 = lerpResult107_g74069;
				float4 break322_g74034 = Global_Motion_Params3909_g74029;
				float3 appendResult397_g74034 = (float3(break322_g74034.x , 0.0 , break322_g74034.y));
				float3 temp_output_398_0_g74034 = (appendResult397_g74034*2.0 + -1.0);
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				half2 Global_MotionDirectionOS39_g74029 = (( mul( GetWorldToObjectMatrix(), float4( temp_output_398_0_g74034 , 0.0 ) ).xyz * ase_parentObjectScale )).xz;
				half2 Input_DirectionOS358_g74030 = Global_MotionDirectionOS39_g74029;
				half Wind_Power369_g74034 = break322_g74034.z;
				half Global_WindPower2223_g74029 = Wind_Power369_g74034;
				half3 Input_Position419_g74097 = ObjectPosition4223_g74029;
				float Input_MotionScale287_g74097 = ( _MotionScale_10 + 1.0 );
				half Global_Scale448_g74097 = TVE_NoiseParams.x;
				float2 temp_output_597_0_g74097 = (( Input_Position419_g74097 * Input_MotionScale287_g74097 * Global_Scale448_g74097 * 0.0075 )).xz;
				half2 Global_MotionDirectionWS4683_g74029 = (temp_output_398_0_g74034).xz;
				half2 Input_DirectionWS423_g74097 = Global_MotionDirectionWS4683_g74029;
				half Input_MotionSpeed62_g74097 = _MotionSpeed_10;
				half Global_Speed449_g74097 = TVE_NoiseParams.y;
				half Input_MotionVariation284_g74097 = _MotionVariation_10;
				float3 break111_g74046 = ObjectPosition4223_g74029;
				half Global_DynamicMode5112_g74029 = _VertexDynamicMode;
				half Input_DynamicMode120_g74046 = Global_DynamicMode5112_g74029;
				float Mesh_Variation16_g74029 = v.ase_color.r;
				half Input_Variation124_g74046 = Mesh_Variation16_g74029;
				half ObjectData20_g74047 = frac( ( ( ( break111_g74046.x + break111_g74046.y + break111_g74046.z + 0.001275 ) * ( 1.0 - Input_DynamicMode120_g74046 ) ) + Input_Variation124_g74046 ) );
				half WorldData19_g74047 = Input_Variation124_g74046;
				#ifdef TVE_FEATURE_BATCHING
					float staticSwitch14_g74047 = WorldData19_g74047;
				#else
					float staticSwitch14_g74047 = ObjectData20_g74047;
				#endif
				float clampResult129_g74046 = clamp( staticSwitch14_g74047 , 0.01 , 0.99 );
				half Global_MeshVariation5104_g74029 = clampResult129_g74046;
				half Input_GlobalVariation569_g74097 = Global_MeshVariation5104_g74029;
				float temp_output_630_0_g74097 = ( ( ( _TimeParameters.x * Input_MotionSpeed62_g74097 * Global_Speed449_g74097 ) + ( Input_MotionVariation284_g74097 * Input_GlobalVariation569_g74097 ) ) * 0.03 );
				float temp_output_607_0_g74097 = frac( temp_output_630_0_g74097 );
				float4 lerpResult590_g74097 = lerp( tex2Dlod( TVE_NoiseTex, float4( ( temp_output_597_0_g74097 + ( -Input_DirectionWS423_g74097 * temp_output_607_0_g74097 ) ), 0, 0.0) ) , tex2Dlod( TVE_NoiseTex, float4( ( temp_output_597_0_g74097 + ( -Input_DirectionWS423_g74097 * frac( ( temp_output_630_0_g74097 + 0.5 ) ) ) ), 0, 0.0) ) , ( abs( ( temp_output_607_0_g74097 - 0.5 ) ) / 0.5 ));
				half Input_GlobalWind327_g74097 = Global_WindPower2223_g74029;
				float lerpResult612_g74097 = lerp( 1.4 , 0.4 , Input_GlobalWind327_g74097);
				float3 temp_cast_7 = (lerpResult612_g74097).xxx;
				float3 break638_g74097 = (pow( ( abs( (lerpResult590_g74097).rgb ) + 0.2 ) , temp_cast_7 )*1.4 + -0.2);
				half Global_NoiseTexR34_g74029 = break638_g74097.x;
				half Motion_10_Amplitude2258_g74029 = ( _MotionAmplitude_10 * Global_WindPower2223_g74029 * Global_NoiseTexR34_g74029 );
				half Input_BendingAmplitude376_g74030 = Motion_10_Amplitude2258_g74029;
				half Mesh_Height1524_g74029 = v.ase_color.a;
				half Input_MeshHeight388_g74030 = Mesh_Height1524_g74029;
				half ObjectData20_g74032 = ( Input_MeshHeight388_g74030 * 2.0 );
				float enc62_g74048 = v.ase_texcoord.w;
				float2 localDecodeFloatToVector262_g74048 = DecodeFloatToVector2( enc62_g74048 );
				float2 break63_g74048 = ( localDecodeFloatToVector262_g74048 * 100.0 );
				float Bounds_Height5230_g74029 = break63_g74048.x;
				half Input_BoundsHeight390_g74030 = Bounds_Height5230_g74029;
				half WorldData19_g74032 = ( ( Input_MeshHeight388_g74030 * Input_MeshHeight388_g74030 ) * Input_BoundsHeight390_g74030 * 2.0 );
				#ifdef TVE_FEATURE_BATCHING
					float staticSwitch14_g74032 = WorldData19_g74032;
				#else
					float staticSwitch14_g74032 = ObjectData20_g74032;
				#endif
				half Mask_Motion_10321_g74030 = staticSwitch14_g74032;
				half Input_InteractionAmplitude58_g74030 = _InteractionAmplitude;
				half Input_InteractionUseMask62_g74030 = _InteractionMaskValue;
				float lerpResult371_g74030 = lerp( 2.0 , Mask_Motion_10321_g74030 , Input_InteractionUseMask62_g74030);
				half ObjectData20_g74031 = lerpResult371_g74030;
				half WorldData19_g74031 = Mask_Motion_10321_g74030;
				#ifdef TVE_FEATURE_BATCHING
					float staticSwitch14_g74031 = WorldData19_g74031;
				#else
					float staticSwitch14_g74031 = ObjectData20_g74031;
				#endif
				half Mask_Interaction373_g74030 = ( Input_InteractionAmplitude58_g74030 * staticSwitch14_g74031 );
				half Global_InteractionMask66_g74029 = ( break322_g74034.w * break322_g74034.w );
				float Input_InteractionGlobalMask330_g74030 = Global_InteractionMask66_g74029;
				float lerpResult360_g74030 = lerp( ( Input_BendingAmplitude376_g74030 * Mask_Motion_10321_g74030 ) , Mask_Interaction373_g74030 , saturate( ( Input_InteractionAmplitude58_g74030 * Input_InteractionGlobalMask330_g74030 ) ));
				float2 break364_g74030 = ( Input_DirectionOS358_g74030 * lerpResult360_g74030 );
				half Motion_10_BendingZ190_g74029 = break364_g74030.y;
				half Angle44_g74091 = Motion_10_BendingZ190_g74029;
				half3 VertexPos40_g74083 = ( VertexPosRotationAxis50_g74091 + ( VertexPosOtherAxis82_g74091 * cos( Angle44_g74091 ) ) + ( cross( float3(1,0,0) , VertexPosOtherAxis82_g74091 ) * sin( Angle44_g74091 ) ) );
				float3 appendResult74_g74083 = (float3(0.0 , 0.0 , VertexPos40_g74083.z));
				half3 VertexPosRotationAxis50_g74083 = appendResult74_g74083;
				float3 break84_g74083 = VertexPos40_g74083;
				float3 appendResult81_g74083 = (float3(break84_g74083.x , break84_g74083.y , 0.0));
				half3 VertexPosOtherAxis82_g74083 = appendResult81_g74083;
				half Motion_10_BendingX216_g74029 = break364_g74030.x;
				half Angle44_g74083 = -Motion_10_BendingX216_g74029;
				half Input_MotionScale321_g74065 = _MotionScale_20;
				half Input_MotionVariation330_g74065 = _MotionVariation_20;
				half Input_GlobalVariation400_g74065 = Global_MeshVariation5104_g74029;
				half Input_MotionSpeed62_g74065 = _MotionSpeed_20;
				half Motion_20_Sine395_g74065 = sin( ( ( ( ase_worldPos.x + ase_worldPos.y + ase_worldPos.z ) * Input_MotionScale321_g74065 ) + ( Input_MotionVariation330_g74065 * Input_GlobalVariation400_g74065 ) + ( _TimeParameters.x * Input_MotionSpeed62_g74065 ) ) );
				half3 Input_Position419_g74111 = VertexPosition3588_g74029;
				float3 normalizeResult518_g74111 = normalize( Input_Position419_g74111 );
				half2 Input_DirectionOS423_g74111 = Global_MotionDirectionOS39_g74029;
				float2 break521_g74111 = -Input_DirectionOS423_g74111;
				float3 appendResult522_g74111 = (float3(break521_g74111.x , 0.0 , break521_g74111.y));
				float dotResult519_g74111 = dot( normalizeResult518_g74111 , appendResult522_g74111 );
				half Input_Mask62_g74111 = _MotionFacingValue;
				float lerpResult524_g74111 = lerp( 1.0 , (dotResult519_g74111*0.5 + 0.5) , Input_Mask62_g74111);
				half ObjectData20_g74112 = max( lerpResult524_g74111 , 0.001 );
				half WorldData19_g74112 = 1.0;
				#ifdef TVE_FEATURE_BATCHING
					float staticSwitch14_g74112 = WorldData19_g74112;
				#else
					float staticSwitch14_g74112 = ObjectData20_g74112;
				#endif
				half Motion_FacingMask5214_g74029 = staticSwitch14_g74112;
				half Motion_20_Amplitude4381_g74029 = ( _MotionValue_20 * Global_WindPower2223_g74029 * Global_NoiseTexR34_g74029 * Motion_FacingMask5214_g74029 );
				half Input_MotionAmplitude384_g74065 = Motion_20_Amplitude4381_g74029;
				half Input_Squash58_g74065 = _MotionAmplitude_20;
				float enc59_g74048 = v.ase_texcoord.z;
				float2 localDecodeFloatToVector259_g74048 = DecodeFloatToVector2( enc59_g74048 );
				float2 break61_g74048 = localDecodeFloatToVector259_g74048;
				half Mesh_Motion_2060_g74029 = break61_g74048.x;
				half Input_MeshMotion_20388_g74065 = Mesh_Motion_2060_g74029;
				float Bounds_Radius5231_g74029 = break63_g74048.y;
				half Input_BoundsRadius390_g74065 = Bounds_Radius5231_g74029;
				half2 Input_DirectionOS366_g74065 = Global_MotionDirectionOS39_g74029;
				float2 break371_g74065 = Input_DirectionOS366_g74065;
				float3 appendResult372_g74065 = (float3(break371_g74065.x , ( Motion_20_Sine395_g74065 * 0.1 ) , break371_g74065.y));
				half3 Motion_20_Squash4418_g74029 = ( ( (Motion_20_Sine395_g74065*0.2 + 1.0) * Input_MotionAmplitude384_g74065 * Input_Squash58_g74065 * Input_MeshMotion_20388_g74065 * Input_BoundsRadius390_g74065 ) * appendResult372_g74065 );
				half3 VertexPos40_g74102 = ( ( VertexPosRotationAxis50_g74083 + ( VertexPosOtherAxis82_g74083 * cos( Angle44_g74083 ) ) + ( cross( float3(0,0,1) , VertexPosOtherAxis82_g74083 ) * sin( Angle44_g74083 ) ) ) + Motion_20_Squash4418_g74029 );
				float3 appendResult74_g74102 = (float3(0.0 , VertexPos40_g74102.y , 0.0));
				float3 VertexPosRotationAxis50_g74102 = appendResult74_g74102;
				float3 break84_g74102 = VertexPos40_g74102;
				float3 appendResult81_g74102 = (float3(break84_g74102.x , 0.0 , break84_g74102.z));
				float3 VertexPosOtherAxis82_g74102 = appendResult81_g74102;
				half Input_Rolling379_g74065 = _MotionAmplitude_22;
				half Motion_20_Rolling5257_g74029 = ( Motion_20_Sine395_g74065 * Input_MotionAmplitude384_g74065 * Input_Rolling379_g74065 * Input_MeshMotion_20388_g74065 );
				half Angle44_g74102 = Motion_20_Rolling5257_g74029;
				half Input_MotionScale321_g74106 = _MotionScale_32;
				half Input_MotionVariation330_g74106 = _MotionVariation_32;
				half Input_GlobalVariation372_g74106 = Global_MeshVariation5104_g74029;
				half Input_MotionSpeed62_g74106 = _MotionSpeed_32;
				half Global_Speed350_g74106 = TVE_FlutterParams.y;
				float temp_output_7_0_g74052 = TVE_MotionFadeEnd;
				half Motion_FadeOut4005_g74029 = saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - temp_output_7_0_g74052 ) / ( TVE_MotionFadeStart - temp_output_7_0_g74052 ) ) );
				half Motion_30_Amplitude4960_g74029 = ( _MotionAmplitude_32 * _MotionValue_30 * Global_WindPower2223_g74029 * Global_NoiseTexR34_g74029 * Motion_FacingMask5214_g74029 * Motion_FadeOut4005_g74029 );
				half Input_MotionAmplitude58_g74106 = Motion_30_Amplitude4960_g74029;
				half Global_Power354_g74106 = TVE_FlutterParams.x;
				half Mesh_Motion_30144_g74029 = break61_g74048.y;
				half Input_MeshMotion_30374_g74106 = Mesh_Motion_30144_g74029;
				half Input_MotionNormal364_g74106 = _MotionNormalValue;
				float3 lerpResult370_g74106 = lerp( float3( 1,1,1 ) , v.ase_normal , Input_MotionNormal364_g74106);
				half3 Motion_30_Details263_g74029 = ( ( sin( ( ( ( ase_worldPos.x + ase_worldPos.y + ase_worldPos.z ) * Input_MotionScale321_g74106 ) + ( Input_MotionVariation330_g74106 * Input_GlobalVariation372_g74106 ) + ( _TimeParameters.x * Input_MotionSpeed62_g74106 * Global_Speed350_g74106 ) ) ) * Input_MotionAmplitude58_g74106 * Global_Power354_g74106 * Input_MeshMotion_30374_g74106 * 0.4 ) * lerpResult370_g74106 );
				float3 Vertex_Motion_Object833_g74029 = ( ( VertexPosRotationAxis50_g74102 + ( VertexPosOtherAxis82_g74102 * cos( Angle44_g74102 ) ) + ( cross( float3(0,1,0) , VertexPosOtherAxis82_g74102 ) * sin( Angle44_g74102 ) ) ) + Motion_30_Details263_g74029 );
				float3 temp_output_3474_0_g74029 = ( VertexPosition3588_g74029 - Mesh_PivotsOS2291_g74029 );
				float3 appendResult2043_g74029 = (float3(Motion_10_BendingX216_g74029 , 0.0 , Motion_10_BendingZ190_g74029));
				float3 Vertex_Motion_World1118_g74029 = ( ( ( temp_output_3474_0_g74029 + appendResult2043_g74029 ) + Motion_20_Squash4418_g74029 ) + Motion_30_Details263_g74029 );
				#ifdef TVE_FEATURE_BATCHING
					float3 staticSwitch4976_g74029 = Vertex_Motion_World1118_g74029;
				#else
					float3 staticSwitch4976_g74029 = ( Vertex_Motion_Object833_g74029 + ( _VertexDataMode * 0.0 ) );
				#endif
				half3 Grass_Perspective2661_g74029 = half3(0,0,0);
				float4 temp_output_94_19_g74093 = TVE_VertexCoords;
				half2 UV97_g74093 = ( (temp_output_94_19_g74093).zw + ( (temp_output_94_19_g74093).xy * (ObjectPosition4223_g74029).xz ) );
				float temp_output_84_0_g74093 = _LayerVertexValue;
				float4 lerpResult109_g74093 = lerp( TVE_VertexParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_VertexTex, sampler_linear_clamp, UV97_g74093,temp_output_84_0_g74093, 0.0 ) , TVE_VertexUsage[(int)temp_output_84_0_g74093]);
				half4 Global_Object_Params4173_g74029 = lerpResult109_g74093;
				half Global_VertexSize174_g74029 = saturate( Global_Object_Params4173_g74029.w );
				float lerpResult346_g74029 = lerp( 1.0 , Global_VertexSize174_g74029 , _GlobalSize);
				float3 appendResult3480_g74029 = (float3(lerpResult346_g74029 , lerpResult346_g74029 , lerpResult346_g74029));
				half3 ObjectData20_g74033 = appendResult3480_g74029;
				half3 _Vector11 = half3(1,1,1);
				half3 WorldData19_g74033 = _Vector11;
				#ifdef TVE_FEATURE_BATCHING
					float3 staticSwitch14_g74033 = WorldData19_g74033;
				#else
					float3 staticSwitch14_g74033 = ObjectData20_g74033;
				#endif
				half3 Vertex_Size1741_g74029 = staticSwitch14_g74033;
				half3 _Vector5 = half3(1,1,1);
				float3 Vertex_SizeFade1740_g74029 = _Vector5;
				float3 lerpResult16_g74042 = lerp( VertexPosition3588_g74029 , ( ( ( staticSwitch4976_g74029 + Grass_Perspective2661_g74029 ) * Vertex_Size1741_g74029 * Vertex_SizeFade1740_g74029 ) + Mesh_PivotsOS2291_g74029 ) , TVE_Enabled);
				float3 Final_VertexPosition890_g74029 = ( lerpResult16_g74042 + _DisableSRPBatcher );
				
				o.ase_texcoord5.xyz = vertexToFrag3890_g74029;
				o.ase_texcoord6.xyz = vertexToFrag4224_g74029;
				float temp_output_7_0_g74058 = TVE_CameraFadeStart;
				float lerpResult4755_g74029 = lerp( 1.0 , saturate( ( ( distance( ase_worldPos , _WorldSpaceCameraPos ) - temp_output_7_0_g74058 ) / ( TVE_CameraFadeEnd - temp_output_7_0_g74058 ) ) ) , _FadeCameraValue);
				float vertexToFrag11_g74057 = lerpResult4755_g74029;
				o.ase_texcoord5.w = vertexToFrag11_g74057;
				
				o.ase_texcoord4 = v.ase_texcoord;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord6.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = Final_VertexPosition890_g74029;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal( v.ase_normal );
				float4 tangentWS = float4(TransformObjectToWorldDir( v.ase_tangent.xyz), v.ase_tangent.w);
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.worldNormal = TransformObjectToWorldNormal(v.vertex.xyz);//normalWS;
				o.worldTangent = tangentWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(TESSELLATION_ON)
				struct VertexControl
				{
					float4 vertex : INTERNALTESSPOS;
					float3 ase_normal : NORMAL;
					float4 ase_tangent : TANGENT;
					float4 ase_texcoord3 : TEXCOORD3;
					float4 ase_color : COLOR;
					float4 ase_texcoord : TEXCOORD0;

					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct TessellationFactors
				{
					float edge[3] : SV_TessFactor;
					float inside : SV_InsideTessFactor;
				};

				VertexControl vert ( VertexInput v )
				{
					VertexControl o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					o.vertex = v.vertex;
					o.ase_normal = v.ase_normal;
					o.ase_tangent = v.ase_tangent;
					o.ase_texcoord3 = v.ase_texcoord3;
					o.ase_color = v.ase_color;
					o.ase_texcoord = v.ase_texcoord;
					return o;
				}

				TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
				{
					TessellationFactors o;
					float4 tf = 1;
					float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
					float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
					#if defined(ASE_FIXED_TESSELLATION)
						tf = FixedTess( tessValue );
					#elif defined(ASE_DISTANCE_TESSELLATION)
						tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
					#elif defined(ASE_LENGTH_TESSELLATION)
						tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
					#elif defined(ASE_LENGTH_CULL_TESSELLATION)
						tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
					#endif
					o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
					return o;
				}

				[domain("tri")]
				[partitioning("fractional_odd")]
				[outputtopology("triangle_cw")]
				[patchconstantfunc("TessellationFunction")]
				[outputcontrolpoints(3)]
				VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
				{
					return patch[id];
				}

				[domain("tri")]
				VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
				{
					VertexInput o = (VertexInput) 0;
					o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
					o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
					o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
					o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
					o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
					o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
					#if defined(ASE_PHONG_TESSELLATION)
						float3 pp[3];
						for (int i = 0; i < 3; ++i)
						pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
						float phongStrength = _TessPhongStrength;
						o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
					#endif
					UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
					return VertexFunction(o);
				}
			#else
				VertexOutput vert ( VertexInput v )
				{
					return VertexFunction( v );
				}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN 
			#ifdef ASE_DEPTH_WRITE_ON
				,out float outputDepth : ASE_SV_DEPTH
			#endif
			, FRONT_FACE_TYPE ase_vface : FRONT_FACE_SEMANTIC ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float3 WorldNormal = IN.worldNormal;
				float4 WorldTangent = IN.worldTangent;

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				half2 Main_UVs15_g74029 = ( ( IN.ase_texcoord4.xy * (_MainUVs).xy ) + (_MainUVs).zw );
				float3 unpack4112_g74029 = UnpackNormalScale( tex2D( _MainNormalTex, Main_UVs15_g74029 ), _MainNormalValue );
				unpack4112_g74029.z = lerp( 1, unpack4112_g74029.z, saturate(_MainNormalValue) );
				half3 Main_Normal137_g74029 = unpack4112_g74029;
				float3 temp_output_13_0_g74110 = Main_Normal137_g74029;
				float3 switchResult12_g74110 = (((ase_vface>0)?(temp_output_13_0_g74110):(( temp_output_13_0_g74110 * _render_normals ))));
				half3 Blend_Normal312_g74029 = switchResult12_g74110;
				half3 Final_Normal366_g74029 = Blend_Normal312_g74029;
				
				float localCustomAlphaClip19_g74061 = ( 0.0 );
				float4 tex2DNode29_g74029 = tex2D( _MainAlbedoTex, Main_UVs15_g74029 );
				float Main_Alpha316_g74029 = ( _MainColor.a * tex2DNode29_g74029.a );
				float4 temp_output_93_19_g74035 = TVE_ExtrasCoords;
				float3 vertexToFrag3890_g74029 = IN.ase_texcoord5.xyz;
				float3 WorldPosition3905_g74029 = vertexToFrag3890_g74029;
				float3 vertexToFrag4224_g74029 = IN.ase_texcoord6.xyz;
				half3 ObjectData20_g74082 = vertexToFrag4224_g74029;
				half3 WorldData19_g74082 = vertexToFrag3890_g74029;
				#ifdef TVE_FEATURE_BATCHING
					float3 staticSwitch14_g74082 = WorldData19_g74082;
				#else
					float3 staticSwitch14_g74082 = ObjectData20_g74082;
				#endif
				float3 ObjectPosition4223_g74029 = staticSwitch14_g74082;
				float3 lerpResult4827_g74029 = lerp( WorldPosition3905_g74029 , ObjectPosition4223_g74029 , _ExtrasPositionMode);
				half2 UV96_g74035 = ( (temp_output_93_19_g74035).zw + ( (temp_output_93_19_g74035).xy * (lerpResult4827_g74029).xz ) );
				float temp_output_84_0_g74035 = _LayerExtrasValue;
				float4 lerpResult109_g74035 = lerp( TVE_ExtrasParams , SAMPLE_TEXTURE2D_ARRAY_LOD( TVE_ExtrasTex, sampler_linear_clamp, UV96_g74035,temp_output_84_0_g74035, 0.0 ) , TVE_ExtrasUsage[(int)temp_output_84_0_g74035]);
				float4 break89_g74035 = lerpResult109_g74035;
				half Global_Extras_Alpha1033_g74029 = saturate( break89_g74035.a );
				float3 break111_g74046 = ObjectPosition4223_g74029;
				half Global_DynamicMode5112_g74029 = _VertexDynamicMode;
				half Input_DynamicMode120_g74046 = Global_DynamicMode5112_g74029;
				float Mesh_Variation16_g74029 = IN.ase_color.r;
				half Input_Variation124_g74046 = Mesh_Variation16_g74029;
				half ObjectData20_g74047 = frac( ( ( ( break111_g74046.x + break111_g74046.y + break111_g74046.z + 0.001275 ) * ( 1.0 - Input_DynamicMode120_g74046 ) ) + Input_Variation124_g74046 ) );
				half WorldData19_g74047 = Input_Variation124_g74046;
				#ifdef TVE_FEATURE_BATCHING
					float staticSwitch14_g74047 = WorldData19_g74047;
				#else
					float staticSwitch14_g74047 = ObjectData20_g74047;
				#endif
				float clampResult129_g74046 = clamp( staticSwitch14_g74047 , 0.01 , 0.99 );
				half Global_MeshVariation5104_g74029 = clampResult129_g74046;
				float lerpResult5154_g74029 = lerp( 0.1 , Global_MeshVariation5104_g74029 , _AlphaVariationValue);
				half Global_Alpha_Variation5158_g74029 = lerpResult5154_g74029;
				half Global_Alpha_Mask4546_g74029 = 1.0;
				float lerpResult5203_g74029 = lerp( 1.0 , ( ( Global_Extras_Alpha1033_g74029 - Global_Alpha_Variation5158_g74029 ) + ( Global_Extras_Alpha1033_g74029 * 0.5 ) ) , ( Global_Alpha_Mask4546_g74029 * _GlobalAlpha ));
				float lerpResult16_g74059 = lerp( 1.0 , lerpResult5203_g74029 , TVE_Enabled);
				half AlphaTreshold2132_g74029 = _AlphaClipValue;
				half Global_Alpha315_g74029 = ( lerpResult16_g74059 + AlphaTreshold2132_g74029 );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult2169_g74029 = normalize( ase_worldViewDir );
				float3 ViewDir_Normalized3963_g74029 = normalizeResult2169_g74029;
				float3 normalizeResult3971_g74029 = normalize( cross( ddy( WorldPosition ) , ddx( WorldPosition ) ) );
				float3 NormalsWS_Derivates3972_g74029 = normalizeResult3971_g74029;
				float dotResult3851_g74029 = dot( ViewDir_Normalized3963_g74029 , NormalsWS_Derivates3972_g74029 );
				float lerpResult3993_g74029 = lerp( 1.0 , saturate( abs( dotResult3851_g74029 ) ) , _FadeGlancingValue);
				half Fade_Glancing3853_g74029 = lerpResult3993_g74029;
				float vertexToFrag11_g74057 = IN.ase_texcoord5.w;
				half Fade_Camera3743_g74029 = vertexToFrag11_g74057;
				half Fade_Mask5149_g74029 = 1.0;
				float lerpResult5141_g74029 = lerp( 1.0 , ( Fade_Glancing3853_g74029 * Fade_Camera3743_g74029 ) , Fade_Mask5149_g74029);
				half Fade_Effects5360_g74029 = lerpResult5141_g74029;
				float temp_output_41_0_g74054 = Fade_Effects5360_g74029;
				float temp_output_5361_0_g74029 = ( saturate( ( temp_output_41_0_g74054 + ( temp_output_41_0_g74054 * tex3D( TVE_ScreenTex3D, ( TVE_ScreenTexCoord * WorldPosition3905_g74029 ) ).r ) ) ) + -0.5 + AlphaTreshold2132_g74029 );
				half Fade_Alpha3727_g74029 = temp_output_5361_0_g74029;
				float temp_output_661_0_g74029 = ( Main_Alpha316_g74029 * Global_Alpha315_g74029 * Fade_Alpha3727_g74029 );
				half Alpha34_g74056 = temp_output_661_0_g74029;
				half Offest27_g74056 = AlphaTreshold2132_g74029;
				half AlphaFeather5305_g74029 = _AlphaFeatherValue;
				half Feather30_g74056 = AlphaFeather5305_g74029;
				float temp_output_25_0_g74056 = ( ( ( Alpha34_g74056 - Offest27_g74056 ) / ( max( fwidth( Alpha34_g74056 ) , 0.001 ) + Feather30_g74056 ) ) + Offest27_g74056 );
				float temp_output_3_0_g74061 = temp_output_25_0_g74056;
				float Alpha19_g74061 = temp_output_3_0_g74061;
				float temp_output_15_0_g74061 = AlphaTreshold2132_g74029;
				float Treshold19_g74061 = temp_output_15_0_g74061;
				{
					#if defined (TVE_FEATURE_CLIP)
						#if defined (TVE_IS_HD_PIPELINE)
							#if !defined (SHADERPASS_FORWARD_BYPASS_ALPHA_TEST)
								clip(Alpha19_g74061 - Treshold19_g74061-0.1);
							#endif
							#if !defined (SHADERPASS_GBUFFER_BYPASS_ALPHA_TEST)
								clip(Alpha19_g74061 - Treshold19_g74061-0.1);
							#endif
						#else
							clip(Alpha19_g74061 - Treshold19_g74061-0.1);
						#endif
					#endif
				}
				half Final_Alpha914_g74029 = saturate( Alpha19_g74061 );
				

				float3 Normal = Final_Normal366_g74029;
				float Alpha = Final_Alpha914_g74029;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				
				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				
				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(WorldNormal);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					return half4(packedNormalWS, 0.0);
				#else					
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float crossSign = (WorldTangent.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
							float3 bitangent = crossSign * cross(WorldNormal.xyz, WorldTangent.xyz);
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent.xyz, bitangent, WorldNormal.xyz));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = WorldNormal;
					#endif
					return half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif
			}
			ENDHLSL
		}
		//-------------------------------------------------------------------------------------
		// END_PASS DEPTHNORMALS
		//-------------------------------------------------------------------------------------
		
	}
	
	CustomEditor "TVEShaderCoreGUI"
	Fallback "Hidden/BOXOPHOBIC/The Vegetation Engine/Fallback"
	
}
