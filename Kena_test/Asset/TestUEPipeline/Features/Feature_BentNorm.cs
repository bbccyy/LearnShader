//#define ENABLE_DEBUG

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.Xml.Linq;
using Unity.Mathematics;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


namespace BentNormalImplemnt
{
    public class SDF
    {
        public Texture3D SDF_TEX3D_LOD0;       //SignedDistField Tex3D Lod0
        public Texture3D SDF_TEX3D_LOD1;       //SignedDistField Tex3D Lod1 
        public Vector4 SDFVolumeCenterAndExtentLod0;
        public Vector4 SDFVolumeCenterAndExtentLod1;

        public void Load(string Lod0, string Lod1)
        {
            if (!string.IsNullOrEmpty(Lod0))
            {
                SDF_TEX3D_LOD0 = Resources.Load<Texture3D>(Lod0);
            }
            if (!string.IsNullOrEmpty(Lod1))
            {
                SDF_TEX3D_LOD1 = Resources.Load<Texture3D>(Lod1);
            }
        }

        //TODO 拓展以支持大世界地图动态加载和管理 
        //方案1: OctTree + RingBuffer + Streaming -> runtime效率好，但是资源提及巨大 
        //方案2: UE4 -> runtime效率低，但是存储资源占用极少 
    }
    public class BentNormData
    {
        public static RTHandle motionTex;

        private int m_LastUpdateFrameIndex;

        public int FrameIndex
        {
            get { return m_LastUpdateFrameIndex; }
            set { m_LastUpdateFrameIndex = value; }
        }

        //RWBuffer<uint> RWScreenGridConeVisibility; 
        public ComputeBuffer ScreenGridConeVisibility;

        public int[] ScreenGridConeVisibilitySize;         //[213, 120] Grid的数目(对应屏幕空间的横向和纵向)
        public Vector4 ScreenGridBufferAndTexelSize;       //[213, 120, 1/213, 1/120]
        public float[] JitterOffset;                       //[0, 2]
        public Vector2 DistanceFieldGBufferJitterOffset;   //JitterOffset *  BaseLevelSizeAndTexelSize.zw 
        public Vector4 BaseLevelSizeAndTexelSize;          //[854, 480, 1/854, 1/480] 
        public Vector4 View_BufferSizeAndInvSize;	       //[1708, 960, 1/1708, 1/960] 
        public Vector4 View_ScreenPositionScaleBias;       //[0.5, +-0.5, 0.5, 0.5]  其中y值在OpenGL下为+，在DX模式下为-，对应纹理UV原点在Tex的左下还是左上 
        public Vector4[] GlobalVolumeCenterAndExtent;      //[0]=[-17,35,-12, 25], [1]=[-17,35,-12, 50];
        public Vector4[] GlobalVolumeWorldToUVAddAndMul;   //  
                                                           //  VolumeCetner -> VC;  Extent -> ET;
                                                           //  Scale = 1/(2*ET); Add = 1 - VC/(2*ET) 
        public Vector4 AOGlobalMaxOcclusionDistanceAndInv; //[10, 0.1] 单位米 
        public float GlobalVolumeTexelSize;                //50/128 每个SDF cell的边长 

        //说明: 如下朝向需经TBN矩阵变换到世界空间，当前数值对应切线空间，特别的x分量对应Tangent，y分量对应Bitengent，z分量对应Normal 
        //举个例子，如果xy分量=0，z分量=1，则经过TBN矩阵变换后，得到的朝向与Normal完全一致
        public static readonly Vector4[] AOSamples2_SampleDirections = new Vector4[NUM_CONE_DIRECTIONS]
        {
            new Vector4(-0.46761f, 0.73942f, 0.48435f, 1.00f),
            new Vector4(0.51746f, -0.70544f, 0.48435f, 1.00f),
            new Vector4(-0.41985f, -0.76755f, 0.48435f, 1.00f),
            new Vector4(0.34308f, 0.8048f, 0.48435f, 1.00f),
            new Vector4(0.36424f, 0.24429f, 0.89869f, 1.00f),
            new Vector4(-0.38155f, 0.18582f, 0.90548f, 1.00f),
            new Vector4(-0.87018f, -0.09056f, 0.48435f, 1.00f),
            new Vector4(0.87445f, 0.02739f, 0.48435f, 1.00f),
            new Vector4(0.03297f, -0.43562f, 0.89952f, 1.00f)

        };

        public float TanConeHalfAngle;                     //0.51539 

        Vector2 FullScreenPixelXY;
        float AODownSampleFactor;                           //2 
        float ConeTracingDownSampleFactor;                  //4 

        static readonly float SDF_BAKE_SIZE = 128;
        const int NUM_CONE_DIRECTIONS = 9;

        public RenderTextureDescriptor DFBentNormDesc;
        public RenderTextureDescriptor DFBentNormConeTracingDesc;

        public BentNormData(int FullScreenPixelX, int FullScreenPixelY, float AODownSampleFactor, float ConeTracingDownSampleFactor)
        {
            m_LastUpdateFrameIndex = 0;

            FullScreenPixelXY = new Vector2((float)FullScreenPixelX, (float)FullScreenPixelY);
            this.AODownSampleFactor = AODownSampleFactor;
            this.ConeTracingDownSampleFactor = ConeTracingDownSampleFactor;

            View_BufferSizeAndInvSize = new Vector4(
                FullScreenPixelXY.x, FullScreenPixelXY.y,
                1f / FullScreenPixelXY.x, 1f / FullScreenPixelXY.y);

            BaseLevelSizeAndTexelSize = new Vector4(
                Mathf.Floor(FullScreenPixelXY.x / this.AODownSampleFactor),
                Mathf.Floor(FullScreenPixelXY.y / this.AODownSampleFactor),
                1f / Mathf.Floor(FullScreenPixelXY.x / this.AODownSampleFactor),
                1f / Mathf.Floor(FullScreenPixelXY.y / this.AODownSampleFactor)
                );

            ScreenGridConeVisibilitySize = new int[]
            {
                (int)Mathf.Floor(BaseLevelSizeAndTexelSize.x / this.ConeTracingDownSampleFactor),
                (int)Mathf.Floor(BaseLevelSizeAndTexelSize.y / this.ConeTracingDownSampleFactor)
            };

            ScreenGridBufferAndTexelSize = new Vector4(
                (float)ScreenGridConeVisibilitySize[0],
                (float)ScreenGridConeVisibilitySize[1],
                1.0f / (float)ScreenGridConeVisibilitySize[0],
                1.0f / (float)ScreenGridConeVisibilitySize[1]
            );
        }

        public void Init(SDF SdfData, float MaxOcclusionDist, RenderTextureDescriptor CameraRTDesc)
        {
            const int GVCount = 2;  //todo... 
            GlobalVolumeCenterAndExtent = new Vector4[GVCount];
            GlobalVolumeWorldToUVAddAndMul = new Vector4[GVCount];
            GlobalVolumeCenterAndExtent[0] = SdfData.SDFVolumeCenterAndExtentLod0;
            GlobalVolumeCenterAndExtent[1] = SdfData.SDFVolumeCenterAndExtentLod1;

            var gtype = SystemInfo.graphicsDeviceType;
            float deviceY = 0.5f;
            if (gtype == GraphicsDeviceType.Direct3D11 || gtype == GraphicsDeviceType.Direct3D12)
            {
                deviceY = -0.5f;
            }
            View_ScreenPositionScaleBias = new Vector4(0.5f, deviceY, 0.5f, 0.5f);  //TODO: 视Graphics API 不同，做相应调整 

            JitterOffset = new float[2] { 0f, 2f };  //TODO: 是否每帧变动?
            DistanceFieldGBufferJitterOffset = new Vector2();
            DistanceFieldGBufferJitterOffset[0] = JitterOffset[0] * BaseLevelSizeAndTexelSize.z;
            DistanceFieldGBufferJitterOffset[1] = JitterOffset[1] * BaseLevelSizeAndTexelSize.w;

            //  VolumeCetner -> VC;  Extent -> ET;
            //  Scale = 1/(2*ET); Add = 1 - VC/(2*ET) 
            for (int i = 0; i < GVCount; i++)
            {
                float ET2 = GlobalVolumeCenterAndExtent[i].w * 2f;
                GlobalVolumeWorldToUVAddAndMul[i] = new Vector4(
                    0.5f - GlobalVolumeCenterAndExtent[i].x / ET2,
                    0.5f - GlobalVolumeCenterAndExtent[i].y / ET2,
                    0.5f - GlobalVolumeCenterAndExtent[i].z / ET2,
                    1f / ET2
                    );
            }

            AOGlobalMaxOcclusionDistanceAndInv = new Vector4(
                MaxOcclusionDist,
                1f / MaxOcclusionDist,
                1,
                1
                );

            GlobalVolumeTexelSize = SdfData.SDFVolumeCenterAndExtentLod0.w * 2f / SDF_BAKE_SIZE;
            TanConeHalfAngle = 0.51539f;

            ScreenGridConeVisibility?.Release();
            ScreenGridConeVisibility = new ComputeBuffer(
                ScreenGridConeVisibilitySize[0] * ScreenGridConeVisibilitySize[1] * NUM_CONE_DIRECTIONS,
                sizeof(uint), ComputeBufferType.Raw, ComputeBufferMode.Dynamic
                );

            //ScreenGridConeVisibility.SetData<float>(new List<float>() { 1 });

            DFBentNormDesc = CameraRTDesc;
            DFBentNormDesc.height = (int)BaseLevelSizeAndTexelSize.y;      //半分辨率 bentnormal最终输出纹理 
            DFBentNormDesc.width = (int)BaseLevelSizeAndTexelSize.x;
            DFBentNormDesc.msaaSamples = 1;
            DFBentNormDesc.depthBufferBits = 0;
            DFBentNormDesc.stencilFormat = GraphicsFormat.None;
            DFBentNormDesc.graphicsFormat = GraphicsFormat.R16G16B16A16_SFloat;

            DFBentNormConeTracingDesc = DFBentNormDesc;
            DFBentNormConeTracingDesc.width = ScreenGridConeVisibilitySize[0];
            DFBentNormConeTracingDesc.height = ScreenGridConeVisibilitySize[1];
            DFBentNormConeTracingDesc.enableRandomWrite = true;
        }

        public void Dispose()
        {
            ScreenGridConeVisibility?.Dispose();
            ScreenGridConeVisibility = null;
        }
    }
    class BentNormPass : ScriptableRenderPass
    {
        private RTHandle BentNormRTA;   // stands for bentnormal final output 
        private RTHandle BentNormRTB;   // swap between A and B 

        private RTHandle NormDepthRT;   // rgb=normalWS, a=deviceZ 

        private RTHandle CombinedDFBentNormal;  //created out of nine Cone Traced DFAO in different direction

#if ENABLE_DEBUG
        //private RTHandle DebugRT;
        private RTHandle DebugRT3X3;
#endif

        private string BentNormTexNameCurrent;       //name of final output -> _BentNorm
        private string BentNormTexNameLast;          //name of final output -> _BentNorm_History

        private SDF SDFData;

        private ComputeShader DFLightingMainCS;
        private Material DFLightingHelperMat;

        private const string NormDepthTexName = "_NormalDepth";
        private const string CombinedDFBentNormalName = "_CombinedDFBentNormal";

        private const int DownSampleFactor = 2;
        private const int ConeTraceSampleFactor = 4;
        private const float MaxOcclusionDist = 10f;
        private const float HistoryWeight = 0.85f;

        private BentNormData BNData;

        private static readonly ProfilingSampler BNCombineNormalDepthProfileSampler = new ProfilingSampler("BentNormalCombineNormDepth");
        private static readonly ProfilingSampler BNConeTraceGlobalProfileSampler = new ProfilingSampler("BentNormalConeTraceGlobal");
#if ENABLE_DEBUG
        private static readonly ProfilingSampler BNDebugProfileSampler = new ProfilingSampler("BentNormalDebug");
#endif
        private static readonly ProfilingSampler BNCombineConeTracingResultSampler = new ProfilingSampler("BentNormalCombineConeTracingResult");
        private static readonly ProfilingSampler BNUpdateHistoryDepthRejectionSamper = new ProfilingSampler("BentNormalUpdateHistoryDepthRejection");
        private static readonly ProfilingSampler BNFilterHistorySamper = new ProfilingSampler("BentNormalFilterHistory");

        public static readonly int BN_PreScreenToWorld = Shader.PropertyToID("BN_PreScreenToWorld");
        Matrix4x4 m_ScreenToWorld = Matrix4x4.identity;
        Matrix4x4 m_PreScreenToWorld = Matrix4x4.identity;

        private bool SwapFlag = false;

        private RTHandle GetSource() => SwapFlag ? BentNormRTA : BentNormRTB;
        private RTHandle GetDestination() => SwapFlag ? BentNormRTB : BentNormRTA;

        private void Swap()
        {
            SwapFlag = !SwapFlag;
        }

        public void Dispose()
        {
            BNData?.Dispose();
            BentNormRTA?.Release();
            BentNormRTB?.Release();
            NormDepthRT?.Release();
            CombinedDFBentNormal?.Release();

#if ENABLE_DEBUG
            //DebugRT?.Release();
            DebugRT3X3?.Release();
            //DebugRT = null;
            DebugRT3X3 = null;
#endif

            BentNormRTA = null;
            BentNormRTB = null;
            NormDepthRT = null;
            CombinedDFBentNormal = null;
        }

        public void InitDebugRT(int width, int height, GraphicsFormat g_fmt)
        {
#if ENABLE_DEBUG
            RenderTextureDescriptor desc = new RenderTextureDescriptor(width, height, g_fmt, GraphicsFormat.None, 1);
            desc.enableRandomWrite = true;

            //desc.msaaSamples = 1;
            //desc.depthBufferBits = 0;
            //RenderingUtils.ReAllocateIfNeeded(ref DebugRT, desc, FilterMode.Point, TextureWrapMode.Clamp, name: "_DebugTexture");

            RenderTextureDescriptor desc3x3 = desc;
            desc3x3.width = 3 * desc.width;
            desc3x3.height = 3 * desc.height;
            RenderingUtils.ReAllocateIfNeeded(ref DebugRT3X3, desc3x3, FilterMode.Point, TextureWrapMode.Clamp, name: "_DebugTexture3X3");
#endif
        }

        public BentNormPass(string BentNormTexName, SDF sdf, Material DFLightingHelper, ComputeShader DFLightingMainCS)
        {
            this.BentNormTexNameCurrent = BentNormTexName; //_BentNorm
            this.BentNormTexNameLast = string.Format($"{BentNormTexName}_History");  //_BentNorm_History
            this.DFLightingMainCS = DFLightingMainCS;
            BNData = null;
            SDFData = sdf;
            DFLightingHelperMat = DFLightingHelper;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            var bnDesc = cameraTextureDescriptor;

            if (BNData == null ||
                BNData.View_BufferSizeAndInvSize.x != bnDesc.width ||
                BNData.View_BufferSizeAndInvSize.y != bnDesc.height)
            {
                if (BNData != null)
                    BNData.Dispose();
                BNData = new BentNormData(bnDesc.width, bnDesc.height, DownSampleFactor, ConeTraceSampleFactor);
                BNData.Init(SDFData, MaxOcclusionDist, cameraTextureDescriptor);
                InitDebugRT(BNData.ScreenGridConeVisibilitySize[0], BNData.ScreenGridConeVisibilitySize[1], GraphicsFormat.R16G16B16A16_SFloat);
            }

            RenderingUtils.ReAllocateIfNeeded(ref BentNormRTA, BNData.DFBentNormDesc, FilterMode.Point, TextureWrapMode.Clamp, false, name: "_BentNorm_A");
            RenderingUtils.ReAllocateIfNeeded(ref BentNormRTB, BNData.DFBentNormDesc, FilterMode.Point, TextureWrapMode.Clamp, false, name: "_BentNorm_B");

            RenderingUtils.ReAllocateIfNeeded(ref NormDepthRT, BNData.DFBentNormDesc, FilterMode.Point, TextureWrapMode.Clamp, false, name: NormDepthTexName);
            RenderingUtils.ReAllocateIfNeeded(ref CombinedDFBentNormal, BNData.DFBentNormConeTracingDesc, FilterMode.Point, TextureWrapMode.Clamp, false, name: CombinedDFBentNormalName);

            ConfigureTarget(GetDestination());
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            bool isNewFrame = BNData.FrameIndex != Time.frameCount;

            CommandBuffer cmd = CommandBufferPool.Get(); 
            cmd.Clear();

            if (!isNewFrame)
            {
                using (new ProfilingScope(cmd, BNFilterHistorySamper))  //in case of GPU Capturing -> will see the current working BentNormal
                {
                    cmd.SetGlobalTexture(Shader.PropertyToID(BentNormTexNameCurrent), GetSource());
                    Blitter.BlitCameraTexture(cmd, GetDestination(), GetDestination(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, DFLightingHelperMat, 2);
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
                return;
            }

            //Combine NormalWS and DeviceDepth into one RT with half resolution 
            using (new ProfilingScope(cmd, BNCombineNormalDepthProfileSampler))
            {
                cmd.SetRenderTarget(NormDepthRT, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                Blitter.BlitCameraTexture(cmd, NormDepthRT, NormDepthRT, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, DFLightingHelperMat, 0);
            }

            //ConeTraceGlobalOcclusionCS 
            using (new ProfilingScope(cmd, BNConeTraceGlobalProfileSampler)) 
            {
                //cmd.SetComputeTextureParam(DFLightingMainCS, 0, Shader.PropertyToID("_DebugTexture"), DebugRT);  //debug only 

                cmd.SetComputeBufferParam(DFLightingMainCS, 0, Shader.PropertyToID("RWScreenGridConeVisibility"), BNData.ScreenGridConeVisibility);
                cmd.SetComputeTextureParam(DFLightingMainCS, 0, Shader.PropertyToID("_GlobalDistanceFieldTexture0"), SDFData.SDF_TEX3D_LOD0);
                cmd.SetComputeTextureParam(DFLightingMainCS, 0, Shader.PropertyToID("_GlobalDistanceFieldTexture1"), SDFData.SDF_TEX3D_LOD1);
                cmd.SetComputeTextureParam(DFLightingMainCS, 0, Shader.PropertyToID(NormDepthTexName), NormDepthRT);

                cmd.SetComputeVectorParam(DFLightingMainCS, Shader.PropertyToID("View_BufferSizeAndInvSize"), BNData.View_BufferSizeAndInvSize);
                cmd.SetComputeVectorParam(DFLightingMainCS, Shader.PropertyToID("View_ScreenPositionScaleBias"), BNData.View_ScreenPositionScaleBias);
                cmd.SetComputeIntParams(DFLightingMainCS, Shader.PropertyToID("ScreenGridConeVisibilitySize"), BNData.ScreenGridConeVisibilitySize);
                cmd.SetComputeFloatParams(DFLightingMainCS, Shader.PropertyToID("JitterOffset"), BNData.JitterOffset);
                cmd.SetComputeVectorParam(DFLightingMainCS, Shader.PropertyToID("BaseLevelSizeAndTexelSize"), BNData.BaseLevelSizeAndTexelSize);
                cmd.SetComputeVectorArrayParam(DFLightingMainCS, Shader.PropertyToID("GlobalVolumeCenterAndExtent"), BNData.GlobalVolumeCenterAndExtent);
                cmd.SetComputeVectorArrayParam(DFLightingMainCS, Shader.PropertyToID("GlobalVolumeWorldToUVAddAndMul"), BNData.GlobalVolumeWorldToUVAddAndMul);
                cmd.SetComputeVectorArrayParam(DFLightingMainCS, Shader.PropertyToID("AOSamples2_SampleDirections"), BentNormData.AOSamples2_SampleDirections);
                cmd.SetComputeFloatParams(DFLightingMainCS, Shader.PropertyToID("AOGlobalMaxOcclusionDistanceAndInv"),
                    BNData.AOGlobalMaxOcclusionDistanceAndInv.x, BNData.AOGlobalMaxOcclusionDistanceAndInv.y);
                cmd.SetComputeFloatParam(DFLightingMainCS, Shader.PropertyToID("GlobalVolumeTexelSize"), BNData.GlobalVolumeTexelSize);
                cmd.SetComputeFloatParam(DFLightingMainCS, Shader.PropertyToID("TanConeHalfAngle"), BNData.TanConeHalfAngle);

                DispatchCompute(DFLightingMainCS, cmd, 0, BNData.ScreenGridConeVisibilitySize[0], BNData.ScreenGridConeVisibilitySize[1], 1);
            }

#if ENABLE_DEBUG
            using (new ProfilingScope(cmd, BNDebugProfileSampler))
            {
                cmd.SetComputeBufferParam(DFLightingMainCS, 1, Shader.PropertyToID("RWScreenGridConeVisibility"), BNData.ScreenGridConeVisibility);  //debug only
                cmd.SetComputeTextureParam(DFLightingMainCS, 1, Shader.PropertyToID("_DebugTexture3X3"), DebugRT3X3);
                DispatchCompute(DFLightingMainCS, cmd, 1, BNData.ScreenGridConeVisibilitySize[0], BNData.ScreenGridConeVisibilitySize[1], 1);
            }
#endif
            using (new ProfilingScope(cmd, BNCombineConeTracingResultSampler))
            {
                cmd.SetComputeBufferParam(DFLightingMainCS, 2, Shader.PropertyToID("RWScreenGridConeVisibility"), BNData.ScreenGridConeVisibility);
                cmd.SetComputeTextureParam(DFLightingMainCS, 2, Shader.PropertyToID("RWCombinedDFBentNormal"), CombinedDFBentNormal);
                cmd.SetComputeFloatParam(DFLightingMainCS, Shader.PropertyToID("BentNormalNormalizeFactor"), 1.0f);
                cmd.SetComputeTextureParam(DFLightingMainCS, 2, Shader.PropertyToID(NormDepthTexName), NormDepthRT);
                DispatchCompute(DFLightingMainCS, cmd, 2, BNData.ScreenGridConeVisibilitySize[0], BNData.ScreenGridConeVisibilitySize[1], 1);
            }


            using (new ProfilingScope(cmd, BNUpdateHistoryDepthRejectionSamper))  
            {
                cmd.SetGlobalTexture(Shader.PropertyToID(BentNormTexNameLast), GetSource());
                cmd.SetGlobalFloat(Shader.PropertyToID("HistoryWeight"), HistoryWeight); //0.85 

                //获取到来自MotionVectorPass产出的_MotionVectorTexture句柄，根据实际情况在blackTex和MotionVectorTex之间切换
                cmd.SetGlobalTexture(Shader.PropertyToID("_BentNormalMotionVectorTexture"), isNewFrame ? Shader.GetGlobalTexture("_MotionVectorTexture") : Texture2D.blackTexture);

                DFLightingHelperMat.SetTexture(Shader.PropertyToID(CombinedDFBentNormalName), CombinedDFBentNormal);
                DFLightingHelperMat.SetTexture(Shader.PropertyToID(NormDepthTexName), NormDepthRT);
                DFLightingHelperMat.SetVector(Shader.PropertyToID("DistanceFieldGBufferJitterOffset"), BNData.DistanceFieldGBufferJitterOffset);
                DFLightingHelperMat.SetVector(Shader.PropertyToID("ScreenGridBufferAndTexelSize"), BNData.ScreenGridBufferAndTexelSize);
                DFLightingHelperMat.SetVector(Shader.PropertyToID("View_BufferSizeAndInvSize"), BNData.View_BufferSizeAndInvSize);

                Blitter.BlitCameraTexture(cmd, GetDestination(), GetDestination(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, DFLightingHelperMat, 1);
                Swap();
            }

            using (new ProfilingScope(cmd, BNFilterHistorySamper))
            {
                cmd.SetGlobalTexture(Shader.PropertyToID(BentNormTexNameCurrent), GetSource());
                cmd.SetGlobalVector(Shader.PropertyToID("BaseLevelSizeAndTexelSize"), BNData.BaseLevelSizeAndTexelSize);
                Blitter.BlitCameraTexture(cmd, GetDestination(), GetDestination(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, DFLightingHelperMat, 2);
                Swap();
            }

            if (isNewFrame)
            {
                BNData.FrameIndex = Time.frameCount;
            }

            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
        }

        static void DispatchCompute(ComputeShader targetCS, CommandBuffer cmd, int kernel, int width, int height, int depth = 1)
        {
            // If any issue occur on mac / intel GPU devices regarding the probe subdivision, it's likely to be
            // the GetKernelThreadGroupSizes returning wrong values.
            targetCS.GetKernelThreadGroupSizes(kernel, out uint x, out uint y, out uint z);
            cmd.DispatchCompute(
                targetCS,
                kernel,
                Mathf.Max(1, Mathf.CeilToInt(width / (float)x)),
                Mathf.Max(1, Mathf.CeilToInt(height / (float)y)),
                Mathf.Max(1, Mathf.CeilToInt(depth / (float)z)));
        }
    }


    public class Feature_BentNorm : ScriptableRendererFeature
    {

        #region FakeBentNorml
        class BentNormPassFake : ScriptableRenderPass
        {

            RTHandle bn;
            private GraphicsFormat bn_fmt;
            private string bn_name;
            private RenderTargetIdentifier bn_target_id;
            private RTHandle source;
            Material bn_mat;

            static MaterialPropertyBlock bn_PropertyBlock = new MaterialPropertyBlock();
            private ProfilingSampler bn_profile_sampler;

            public BentNormPassFake(string name, Material mat, bool use_default_tex)
            {
                bn_name = name;
                bn_mat = mat;
                if (use_default_tex)
                {
                    bn_mat.EnableKeyword("USE_DEFAULT_TEX");
                }
                else
                {
                    bn_mat.DisableKeyword("USE_DEFAULT_TEX");
                }
                bn_fmt = GraphicsFormat.R16G16B16A16_SFloat;
                bn_target_id = Shader.PropertyToID(bn_name);
                bn = RTHandles.Alloc(bn_target_id);

                bn_profile_sampler = new ProfilingSampler("BentNormalFake");

                bn_PropertyBlock.SetFloat(Shader.PropertyToID("_BlitMipLevel"), 0);
                bn_PropertyBlock.SetVector(Shader.PropertyToID("_BlitScaleBias"), Vector2.one);
            }

            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                var rtDesc = cameraTextureDescriptor;
                rtDesc.msaaSamples = 1;
                rtDesc.depthBufferBits = 0;
                rtDesc.stencilFormat = GraphicsFormat.None;
                rtDesc.graphicsFormat = bn_fmt;
                RenderingUtils.ReAllocateIfNeeded(ref bn, rtDesc, FilterMode.Point, TextureWrapMode.Clamp, name: bn_name);

                //ConfigureTarget(bn);
            }

            // This method is called before executing the render pass.
            // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
            // When empty this render pass will render to the active camera render target.
            // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
            // The render pipeline will ensure target setup and clearing happens in a performant manner.
            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                //source = renderingData.cameraData.renderer.cameraColorTargetHandle;
                if (bn.rt == null)
                {
                    var desc = renderingData.cameraData.cameraTargetDescriptor;
                    desc.msaaSamples = 1;
                    desc.depthBufferBits = 0;
                    desc.stencilFormat = GraphicsFormat.None;
                    desc.graphicsFormat = bn_fmt;
                    cmd.GetTemporaryRT(Shader.PropertyToID(bn_name), desc, FilterMode.Point);
                }

                cmd.SetGlobalTexture(bn.name, bn.nameID);
            }

            // Here you can implement the rendering logic.
            // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
            // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
            // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get(bn_profile_sampler.name);
                cmd.Clear();
                {
                    //Blitter.BlitCameraTexture(cmd, source, bn, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, bn_mat, 0);
                    cmd.SetRenderTarget(bn, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                    cmd.DrawProcedural(Matrix4x4.identity, bn_mat, 0, MeshTopology.Triangles, 3, 1, bn_PropertyBlock);

                    context.ExecuteCommandBuffer(cmd);
                    cmd.EndSample(bn_profile_sampler.name);


                }

                CommandBufferPool.Release(cmd);
            }

            // Cleanup any allocated resources that were created during the execution of this render pass.
            public override void OnCameraCleanup(CommandBuffer cmd)
            {
            }
        }

        BentNormPassFake m_ScriptablePass;
        public string bn_shader = "Custom/BentNorm";
        private Material bn_mat;
        public Texture2D bent_norm_tex;
        public bool use_default_tex;
        #endregion


        BentNormPass m_BentNormPass;
        public readonly string BentNoramlRTName = "_BentNorm";  //这个名字不能修改，因为必须和shader中一致，这里暴露给外面看到而已

        public string SDFLod0AssetPath = "Assets/SDF/SDF_LOD0.asset";
        public Vector4 SDFLod0CenterExtent;
        public string SDFLod1AssetPath = "Assets/SDF/SDF_LOD1.asset";
        public Vector4 SDFLod1CenterExtent;

        public ComputeShader BentNormalCS;
        public string BNHelperShaderPath = "Test/DistanceFieldLightingHelper";

        /// <inheritdoc/>
        public override void Create()
        {
            #region FakeBentNorml
            bn_mat = CoreUtils.CreateEngineMaterial(Shader.Find(bn_shader));
            if (bent_norm_tex != null)
            {
                bn_mat.SetTexture(Shader.PropertyToID("_Tex"), bent_norm_tex);
            }

            m_ScriptablePass = new BentNormPassFake(BentNoramlRTName, bn_mat, use_default_tex);

            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingGbuffer;
            #endregion

            #region BentNorml
            SDF Sdf = new SDF();
            Sdf.Load(SDFLod0AssetPath, SDFLod1AssetPath);
            Sdf.SDFVolumeCenterAndExtentLod0 = SDFLod0CenterExtent;
            Sdf.SDFVolumeCenterAndExtentLod1 = SDFLod1CenterExtent;

            var DFLightingHelper = CoreUtils.CreateEngineMaterial(BNHelperShaderPath);

            m_BentNormPass = new BentNormPass(BentNoramlRTName, Sdf, DFLightingHelper, BentNormalCS);

            m_BentNormPass.renderPassEvent = RenderPassEvent.AfterRenderingGbuffer;

            m_BentNormPass.ConfigureInput(ScriptableRenderPassInput.Motion);
            #endregion
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (BentNormalCS != null)
            {
                renderer.EnqueuePass(m_BentNormPass); 
            }
            else
            {
                renderer.EnqueuePass(m_ScriptablePass);
            }
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            m_BentNormPass?.Dispose();
        }
    }



}

