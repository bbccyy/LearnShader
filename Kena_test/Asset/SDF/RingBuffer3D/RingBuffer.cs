using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.RuntimeTools.RingBuffer
{
    public interface ISourceProvider //todo 
    {
        public UnityEngine.Object SyncLoad(string aPath);

        //public Texture3D SyncLoad(Vector3 aPosWS);

        public void AyncLoad(Action<UnityEngine.Object, bool> aCallback, string aPath);

        //public void AyncLoad(Action<Texture3D, bool> aCallback, Vector3 aPosWS);

    }

    public interface ITileManager
    {
        public int GetTileIndexFromOnePointInWorldSpace(Vector3 aPosWS);

        public Bounds GetBoundingBoxOfGivenTileIndex(int aTileIndex);

        public string GetAssetPathFromTileIndex(int aTileIndex);
    }
    

    public class RingBufferBase
    {
        public static readonly int MinimumPixelGroupSizeBase = 8;

        private Vector3 mRingBufferAABBSize;            //Buffer对应立方体的三维长宽高

        private Vector3 mRingBufferAABBExtension;       //Buffer对应立方体的三维长宽高的一半

        private Vector3 mRingBufferTextureSize;         //Texture3D pixel resolution

        private Vector3 mRingBufferTextureInvSize;      //1 over resolution

        private Vector3 mRingBufferAABBCenterPosition;  //Buffer立方体中心点坐标(世界空间)

        private Vector3 mRingBufferBaselineCenterPosition;      //烘焙时确定的基准中心点

        private Vector3 mDesiredBufferAABBCenterPosition;       //每帧更新的期望位置
        
        private Vector3 mOnWorkingBufferAABBCenterPosition;     //正在处理中的位置

        private Vector3 mShiftBaseAABBCenterPosition;   //用于计算AABB偏移的基准,与Init Buffer绑定

        private ERING_BUFFER_EXEC_STATE State;

        private ISourceProvider mSourceProvider;

        private ITileManager mTileMgr;

        private Vector3Int mMinimumCopyDeltaMultiply;  //最小搬运尺寸,位移小于这个像素值不会触发Buffer更新

        private Vector3 mMinimumCopyDeltaSize;

        private int AsyncLoadingCounter = 0;

        private Texture3D dummy;

        private Vector3 HalfTexelSize;                  //代表0.5个pixel在世界空间中的尺度

        private Vector3 FullTexelSize;                  //代表1个pixel在世界空间中的尺度

        private List<Work3D> works;

        public RTHandle mRingBuffer;

        private int TargetRWTexture3D_PropertyId = Shader.PropertyToID("_RingBuffer");

        private int SrcTexture3D_PropertyId = Shader.PropertyToID("_SrcVolumeTex");

        private int AreaOfIntresetingSize_PropertyId = Shader.PropertyToID("_AreaOfIntresetingSize");

        private int SrcVolumeTex_InvTexelSize_PropertyId = Shader.PropertyToID("_SrcVolumeTex_InvTexelSize");

        private int SrcVolumeTex_MinTexelOffset_PropertyId = Shader.PropertyToID("_SrcVolumeTex_MinTexelOffset");

        private int RingBufferSize_PropertyId = Shader.PropertyToID("_RingBufferSize");

        private int MovementTexelDelta_PropertyId = Shader.PropertyToID("_MovementTexelDelta");

        private int RingBuffer_MinTexelOffset_PropertyId = Shader.PropertyToID("_RingBuffer_MinTexelOffset");

        private ComputeShader Tex3DBlitterCS;

        public RingBufferBase(ISourceProvider aSourceProvider, ITileManager aTileMgr, ComputeShader computeShader)
        {
            this.mSourceProvider = aSourceProvider;
            this.mTileMgr = aTileMgr;
            this.Tex3DBlitterCS = computeShader;

            dummy = new Texture3D(1, 1, 1, TextureFormat.RFloat, false);
            dummy.SetPixel(0, 0, 0, Color.white);
            works = new List<Work3D>();

            State = ERING_BUFFER_EXEC_STATE.InValid;
        }

        /// <summary>
        /// 初始化RingBuffer
        /// </summary>
        /// <param name="aBaseBounding">一个被选出来当做位置基准的世界空间包围盒，对应烘焙插件的某个输出</param>
        /// <param name="aDesiredCenterPos">初始化时期望的Buffer中心位置</param>
        /// <param name="aMinCopyDeltaMultiply">支持拷贝和搬运的最小像素尺寸，当差距小于该尺寸时不触发Buffer的更新</param>
        /// <param name="aBufferTexResolution">Buffer对应Texture3D的width，height和depth。为加速计算，推荐分辨率为8的倍数。不推荐奇数个数的分辨率，因为可能造成计算误差</param>
        public void Init(Bounds aBaseBounding, Vector3 aDesiredCenterPos, Vector3Int aMinCopyDeltaMultiply, Vector3 aBufferTexResolution)
        {
            mRingBufferBaselineCenterPosition = aBaseBounding.center;
            mRingBufferAABBExtension = aBaseBounding.extents;
            mRingBufferAABBSize = aBaseBounding.extents * 2;

            mRingBufferTextureSize = aBufferTexResolution;
            mRingBufferTextureInvSize = new Vector3(
                1.0f / mRingBufferTextureSize.x,
                1.0f / mRingBufferTextureSize.y,
                1.0f / mRingBufferTextureSize.z);
            mMinimumCopyDeltaMultiply = aMinCopyDeltaMultiply;

            HalfTexelSize = aBaseBounding.extents;   //Half Pixel Size
            HalfTexelSize.Set(
                HalfTexelSize.x / aBufferTexResolution.x,
                HalfTexelSize.y / aBufferTexResolution.y,
                HalfTexelSize.z / aBufferTexResolution.z);

            mMinimumCopyDeltaSize = mMinimumCopyDeltaMultiply * MinimumPixelGroupSizeBase;
            FullTexelSize = HalfTexelSize * 2;
            mMinimumCopyDeltaSize.x *= FullTexelSize.x;
            mMinimumCopyDeltaSize.y *= FullTexelSize.y;
            mMinimumCopyDeltaSize.z *= FullTexelSize.z;

            var checkOddEven = new Vector3Int((int)aBufferTexResolution.x % 2, (int)aBufferTexResolution.y % 2, (int)aBufferTexResolution.z % 2);
            if (checkOddEven.x + checkOddEven.y + checkOddEven.z > 0)
            {
                Debug.LogWarning("Not recomand Odd number resolution");
                mRingBufferBaselineCenterPosition.x += checkOddEven.x > 0 ? HalfTexelSize.x : 0;
                mRingBufferBaselineCenterPosition.y += checkOddEven.y > 0 ? HalfTexelSize.y : 0;
                mRingBufferBaselineCenterPosition.z += checkOddEven.z > 0 ? HalfTexelSize.z : 0; //让中心点始终对齐像素的某个角
            }

            mRingBufferAABBCenterPosition = QuantizeWithMinCopyDelta(mRingBufferBaselineCenterPosition, aDesiredCenterPos);
            mDesiredBufferAABBCenterPosition = mRingBufferAABBCenterPosition;

            mPool = new ObjectPool<Work3D>(null, Work3D.OnReturnWork);

            var desc = new RenderTextureDescriptor((int)mRingBufferTextureSize.x, (int)mRingBufferTextureSize.y, RenderTextureFormat.R16, 0, 1);
            desc.enableRandomWrite = true;
            desc.volumeDepth = (int)mRingBufferTextureSize.z;
            desc.dimension = TextureDimension.Tex3D;
            desc.stencilFormat = UnityEngine.Experimental.Rendering.GraphicsFormat.None;
            desc.msaaSamples = 1;

            RenderingUtils.ReAllocateIfNeeded(ref mRingBuffer, desc, FilterMode.Point, TextureWrapMode.Repeat, false, name: "RingBufferVolume");
            

            State = ERING_BUFFER_EXEC_STATE.Init;
        }

        public void OnDestroy()
        {
            mRingBuffer?.Release();
            mRingBuffer = null;

            mSourceProvider = null;
            mTileMgr = null;

            GameObject.DestroyImmediate(dummy); 

            DumpWork3D();
        }

        /// <summary>
        /// 由外界在关联摄像机产生位移后视情况调用
        /// </summary>
        /// <param name="aDesiredTargetCenterWS">期望的Buffer中心点世界坐标</param>
        public void Setup(Vector3 aDesiredTargetCenterWS)
        {
            if (aDesiredTargetCenterWS == mDesiredBufferAABBCenterPosition)
            {
                return;
            }
            if (ContainsState(ERING_BUFFER_EXEC_STATE.Init))
            {
                return;
            }
            mDesiredBufferAABBCenterPosition = aDesiredTargetCenterWS;
            State |= ERING_BUFFER_EXEC_STATE.IsDirty;
        }

        public Vector3 GetUVW()
        {
            var delta =  mRingBufferAABBCenterPosition - mShiftBaseAABBCenterPosition;
            delta.Set(
                (delta.x % mRingBufferAABBSize.x) / mRingBufferAABBSize.x,
                (delta.y % mRingBufferAABBSize.y) / mRingBufferAABBSize.y,
                (delta.z % mRingBufferAABBSize.z) / mRingBufferAABBSize.z);
            return delta;
        }

        public RTHandle GetRingBuffer()
        {
            return mRingBuffer;
        }

        public int GetRingBufferShaderPropertyId()
        {
            return TargetRWTexture3D_PropertyId;
        }

        /// <summary>
        /// 每帧执行一次，依据状态驱动RingBuffer逻辑
        /// </summary>
        /// <param name="cmd"></param>
        public void Execute(CommandBuffer cmd = null)
        {
            if (State == ERING_BUFFER_EXEC_STATE.InValid)
                return;

            EBUILD_STRATEGY strategy = EBUILD_STRATEGY.INVALID;

            switch (State)
            {
                case ERING_BUFFER_EXEC_STATE.Normal:
                    strategy = EBUILD_STRATEGY.DO_NOT_BUILD;
                    break;
                case ERING_BUFFER_EXEC_STATE.Init:
                    strategy = EBUILD_STRATEGY.PREPARE_FROM_GROUND;
                    break;
                case ERING_BUFFER_EXEC_STATE.IsDirty:
                    strategy = ConsideOnDistanceChange(ref mRingBufferAABBCenterPosition, ref mDesiredBufferAABBCenterPosition);
                    if (strategy == EBUILD_STRATEGY.DO_NOT_BUILD)
                    {
                        SubtractState(ERING_BUFFER_EXEC_STATE.IsDirty);  //当前的Dirty不予执行
                    }
                    break;
                case ERING_BUFFER_EXEC_STATE.Loading:
                case ERING_BUFFER_EXEC_STATE.Init | ERING_BUFFER_EXEC_STATE.Loading:
                    strategy = EBUILD_STRATEGY.DO_NOT_BUILD;
                    if (AsyncLoadingCounter == 0)
                    {
                        SubtractState(ERING_BUFFER_EXEC_STATE.Loading);
                        strategy = EBUILD_STRATEGY.DO_BUILD;
                    }
                    break;
                case ERING_BUFFER_EXEC_STATE.Loading | ERING_BUFFER_EXEC_STATE.IsDirty:
                    strategy = EBUILD_STRATEGY.DO_NOT_BUILD;
                    if (AsyncLoadingCounter == 0)
                    {
                        SubtractState(ERING_BUFFER_EXEC_STATE.Loading);
                        strategy = ConsideOnDistanceChange(ref mRingBufferAABBCenterPosition, ref mDesiredBufferAABBCenterPosition);
                        if (strategy == EBUILD_STRATEGY.DO_NOT_BUILD)
                        {
                            SubtractState(ERING_BUFFER_EXEC_STATE.IsDirty);
                            DumpWork3D();
                        }
                        else
                        {
                            strategy = ConsideOnDistanceChange(ref mOnWorkingBufferAABBCenterPosition, ref mDesiredBufferAABBCenterPosition);
                            if (strategy == EBUILD_STRATEGY.DO_NOT_BUILD)
                            {
                                SubtractState(ERING_BUFFER_EXEC_STATE.IsDirty); //当前的Dirty不予执行，继续上一次PrepareWork3D的后续逻辑
                                strategy = EBUILD_STRATEGY.DO_BUILD;
                            }
                            else
                            {
                                DumpWork3D(); //放弃上一次PrepareWork3D的进度，直接开启下一轮Prepare
                            }
                        }
                    }
                    break;
                default:
                    strategy = EBUILD_STRATEGY.INVALID;
                    break;
            }

            if (strategy == EBUILD_STRATEGY.INVALID)
            {
                Debug.LogWarning("Get Invalid Build Type");
                return;
            }

            switch(strategy)
            {
                case EBUILD_STRATEGY.PREPARE_ON_DELTA:
                case EBUILD_STRATEGY.PREPARE_FROM_GROUND:
                    PrepareWork3D(strategy, cmd);
                    break;
                case EBUILD_STRATEGY.DO_BUILD:
                    TryProcessWork3D(cmd);
                    break;
                case EBUILD_STRATEGY.DO_NOT_BUILD:
                    break;
                default:
                    break;
            }

        }

        //因为初始化需要或者位移满足条件 -> 必须(重新)准备Work3D
        private void PrepareWork3D(EBUILD_STRATEGY aStrategy, CommandBuffer cmd)
        {
            mDesiredBufferAABBCenterPosition = QuantizeWithMinCopyDelta(mRingBufferAABBCenterPosition, mDesiredBufferAABBCenterPosition);
            mOnWorkingBufferAABBCenterPosition = mDesiredBufferAABBCenterPosition;
            
            SubtractState(ERING_BUFFER_EXEC_STATE.IsDirty); //Clean up Dirty flag once starts to prepare work3D

            DumpWork3D();

            switch (aStrategy)
            {
                case EBUILD_STRATEGY.PREPARE_FROM_GROUND:
                    {
                        State |= ERING_BUFFER_EXEC_STATE.Init;
                        Box shrinkedTargetBox = Box.Convert2Box(mOnWorkingBufferAABBCenterPosition, mRingBufferAABBExtension, HalfTexelSize);
                        shrinkedTargetBox.MoveDir = Vector3.zero;
                        var listOfWorks = ExtractWork3DFrom(ref shrinkedTargetBox);
                        works.AddRange(listOfWorks);
                    }
                    break;
                case EBUILD_STRATEGY.PREPARE_ON_DELTA:
                    {
                        var listOfWorks = ExtractWork3DFromDelta();
                        works.AddRange(listOfWorks);
                    }
                    break;
                default:
                    Debug.LogError("Invalid PrepareWork3d Strategy");
                    break;
            }

            PostPrepareWork3D(cmd);
        }

        //每次完成PrepareWork3D后执行一次
        private void PostPrepareWork3D(CommandBuffer cmd)
        {
            if (AsyncLoadingCounter == 0) //所有资源当即就准备完毕了
            {
                TryProcessWork3D(cmd);
            }
            else
            {
                //Debug.Log($"Before loading, current ERING_BUFFER_EXEC_STATE is {State}");
                State |= ERING_BUFFER_EXEC_STATE.Loading;
            }
        }

        public void TestRenderEveryFrame(CommandBuffer cmd)
        {
            var MovementTexelDelta = QuantizeWithFullTexelSize(mOnWorkingBufferAABBCenterPosition - mShiftBaseAABBCenterPosition, HalfTexelSize);
            MovementTexelDelta.Set(
                (int)MovementTexelDelta.x % (int)mRingBufferTextureSize.x,
                (int)MovementTexelDelta.y % (int)mRingBufferTextureSize.y,
                (int)MovementTexelDelta.z % (int)mRingBufferTextureSize.z);
            var OnWorkingBox = Box.Convert2Box(mOnWorkingBufferAABBCenterPosition, mRingBufferAABBExtension, Vector3.zero);

            if (cmd != null)
                cmd.SetComputeTextureParam(Tex3DBlitterCS, 0, TargetRWTexture3D_PropertyId, mRingBuffer);

            foreach (var work in works)
            {
                var SrcVolumeTex_MinTexelOffset = QuantizeWithFullTexelSize(
                    work.AreaOfIntreseting.Min - work.SrcBoxWorldSpace.Min, Vector3.zero);
                var TarVolumeBuffer_MinTexelOffset = QuantizeWithFullTexelSize(
                    work.AreaOfIntreseting.Min - OnWorkingBox.Min, Vector3.zero);
                var AreaOfIntresetingSize = QuantizeWithFullTexelSize(work.AreaOfIntreseting.Max + FullTexelSize - work.AreaOfIntreseting.Min, HalfTexelSize);

                if (cmd != null)
                {
                    cmd.SetComputeTextureParam(Tex3DBlitterCS, 0, SrcTexture3D_PropertyId, work.SrcTexture3D);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, AreaOfIntresetingSize_PropertyId, AreaOfIntresetingSize);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, SrcVolumeTex_InvTexelSize_PropertyId, mRingBufferTextureInvSize);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, SrcVolumeTex_MinTexelOffset_PropertyId, SrcVolumeTex_MinTexelOffset);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, RingBufferSize_PropertyId, mRingBufferTextureSize);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, MovementTexelDelta_PropertyId, MovementTexelDelta);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, RingBuffer_MinTexelOffset_PropertyId, TarVolumeBuffer_MinTexelOffset);
                    DispatchCompute(Tex3DBlitterCS, cmd, 0,
                        (int)AreaOfIntresetingSize.x, (int)AreaOfIntresetingSize.y, (int)AreaOfIntresetingSize.z);
                }
            }
        }


        //Load完成后，且Work3D没有过期 -> 执行本方法
        private void TryProcessWork3D(CommandBuffer cmd)
        {
            if (ContainsState(ERING_BUFFER_EXEC_STATE.Init))
            {
                mShiftBaseAABBCenterPosition = mOnWorkingBufferAABBCenterPosition;
            }
            
            State = ERING_BUFFER_EXEC_STATE.Process;

            var MovementTexelDelta = QuantizeWithFullTexelSize(mOnWorkingBufferAABBCenterPosition - mShiftBaseAABBCenterPosition, HalfTexelSize);
            MovementTexelDelta.Set(
                (int)MovementTexelDelta.x % (int)mRingBufferTextureSize.x,
                (int)MovementTexelDelta.y % (int)mRingBufferTextureSize.y,
                (int)MovementTexelDelta.z % (int)mRingBufferTextureSize.z);
            var OnWorkingBox = Box.Convert2Box(mOnWorkingBufferAABBCenterPosition, mRingBufferAABBExtension, Vector3.zero);

            if (cmd != null)
                cmd.SetComputeTextureParam(Tex3DBlitterCS, 0, TargetRWTexture3D_PropertyId, mRingBuffer);
            else
                Tex3DBlitterCS.SetTexture(0, TargetRWTexture3D_PropertyId, mRingBuffer);

            foreach (var work in works)
            {
                var SrcVolumeTex_MinTexelOffset = QuantizeWithFullTexelSize(
                    work.AreaOfIntreseting.Min - work.SrcBoxWorldSpace.Min, Vector3.zero);
                var TarVolumeBuffer_MinTexelOffset = QuantizeWithFullTexelSize(
                    work.AreaOfIntreseting.Min - OnWorkingBox.Min, Vector3.zero);
                var AreaOfIntresetingSize = QuantizeWithFullTexelSize(work.AreaOfIntreseting.Max + FullTexelSize - work.AreaOfIntreseting.Min, HalfTexelSize);

                if (cmd != null)
                {
                    cmd.SetComputeTextureParam(Tex3DBlitterCS, 0, SrcTexture3D_PropertyId, work.SrcTexture3D);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, AreaOfIntresetingSize_PropertyId, AreaOfIntresetingSize);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, SrcVolumeTex_InvTexelSize_PropertyId, mRingBufferTextureInvSize);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, SrcVolumeTex_MinTexelOffset_PropertyId, SrcVolumeTex_MinTexelOffset);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, RingBufferSize_PropertyId, mRingBufferTextureSize);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, MovementTexelDelta_PropertyId, MovementTexelDelta);
                    cmd.SetComputeVectorParam(Tex3DBlitterCS, RingBuffer_MinTexelOffset_PropertyId, TarVolumeBuffer_MinTexelOffset);
                    DispatchCompute(Tex3DBlitterCS, cmd, 0, 
                        (int)AreaOfIntresetingSize.x, (int)AreaOfIntresetingSize.y, (int)AreaOfIntresetingSize.z);
                }
                else
                {
                    Tex3DBlitterCS.SetTexture(0, SrcTexture3D_PropertyId, work.SrcTexture3D);
                    Tex3DBlitterCS.SetVector(AreaOfIntresetingSize_PropertyId, AreaOfIntresetingSize);
                    Tex3DBlitterCS.SetVector(SrcVolumeTex_InvTexelSize_PropertyId, mRingBufferTextureInvSize);
                    Tex3DBlitterCS.SetVector(SrcVolumeTex_MinTexelOffset_PropertyId, SrcVolumeTex_MinTexelOffset);
                    Tex3DBlitterCS.SetVector(RingBufferSize_PropertyId, mRingBufferTextureSize);
                    Tex3DBlitterCS.SetVector(MovementTexelDelta_PropertyId, MovementTexelDelta);
                    Tex3DBlitterCS.SetVector(RingBuffer_MinTexelOffset_PropertyId, TarVolumeBuffer_MinTexelOffset);
                    DispatchCompute(Tex3DBlitterCS, null, 0,
                        (int)AreaOfIntresetingSize.x, (int)AreaOfIntresetingSize.y, (int)AreaOfIntresetingSize.z);
                }
            }

            PostProcess();
        }

        private void PostProcess()
        {
            State = ERING_BUFFER_EXEC_STATE.Normal;
            mRingBufferAABBCenterPosition = mOnWorkingBufferAABBCenterPosition;
        }

        //当Work3D过期，或者执行完毕后执行本方法
        private void DumpWork3D()
        {
            works.ForEach((a) => { mPool.Release(a);});
            works.Clear();
        }

        private bool ContainsState(ERING_BUFFER_EXEC_STATE aState)
        {
            return (State & aState) == aState;
        }

        private void SubtractState(ERING_BUFFER_EXEC_STATE aState)
        {
            State &= (~aState);
        }

        private Vector3 QuantizeWithFullTexelSize(Vector3 aVector, Vector3 Epsilon)
        {
            var result = aVector;
            result.Set(Mathf.Abs(result.x), Mathf.Abs(result.y), Mathf.Abs(result.z));
            result.Set(
                Mathf.Floor((result.x + Epsilon.x) / FullTexelSize.x) * (aVector.x >= 0 ? 1 : -1),
                Mathf.Floor((result.y + Epsilon.y) / FullTexelSize.y) * (aVector.y >= 0 ? 1 : -1),
                Mathf.Floor((result.z + Epsilon.z) / FullTexelSize.z) * (aVector.z >= 0 ? 1 : -1));
            return result;
        }

        private Vector3 QuantizeWithMinCopyDelta(Vector3 aBase, Vector3 aDesired)
        {
            var cur2desiredDelta = aDesired - aBase;
            cur2desiredDelta.x = Mathf.Floor((Mathf.Abs(cur2desiredDelta.x) + HalfTexelSize.x) / mMinimumCopyDeltaSize.x)
                * mMinimumCopyDeltaSize.x * (cur2desiredDelta.x >= 0 ? 1 : -1);
            cur2desiredDelta.y = Mathf.Floor((Mathf.Abs(cur2desiredDelta.y) + HalfTexelSize.y) / mMinimumCopyDeltaSize.y)
                * mMinimumCopyDeltaSize.y * (cur2desiredDelta.y >= 0 ? 1 : -1);
            cur2desiredDelta.z = Mathf.Floor((Mathf.Abs(cur2desiredDelta.z) + HalfTexelSize.z) / mMinimumCopyDeltaSize.z)
                * mMinimumCopyDeltaSize.z * (cur2desiredDelta.z >= 0 ? 1 : -1);
            return cur2desiredDelta + aBase;
        }

        static void DispatchCompute(ComputeShader targetCS, CommandBuffer cmd, int kernel, int width, int height, int depth = 1)
        {
            // If any issue occur on mac / intel GPU devices regarding the probe subdivision, it's likely to be
            // the GetKernelThreadGroupSizes returning wrong values.
            targetCS.GetKernelThreadGroupSizes(kernel, out uint x, out uint y, out uint z);
            if (cmd != null)
                cmd.DispatchCompute(
                    targetCS,
                    kernel,
                    Mathf.Max(1, Mathf.CeilToInt(width / (float)x)),
                    Mathf.Max(1, Mathf.CeilToInt(height / (float)y)),
                    Mathf.Max(1, Mathf.CeilToInt(depth / (float)z)));
            else
                targetCS.Dispatch(
                    kernel, 
                    Mathf.Max(1, Mathf.CeilToInt(width / (float)x)),
                    Mathf.Max(1, Mathf.CeilToInt(height / (float)y)),
                    Mathf.Max(1, Mathf.CeilToInt(depth / (float)z)));
        }

        private EBUILD_STRATEGY ConsideOnDistanceChange(ref Vector3 aOrigPos, ref Vector3 aTargetPos)
        {
            var Delta = aOrigPos - aTargetPos;
            Delta.Set(Mathf.Abs(Delta.x), Mathf.Abs(Delta.y), Mathf.Abs(Delta.z));
            if (Delta.x < mMinimumCopyDeltaSize.x && Delta.y < mMinimumCopyDeltaSize.y && Delta.z < mMinimumCopyDeltaSize.z)
            {
                return EBUILD_STRATEGY.DO_NOT_BUILD;
            }
            if (Delta.x >= mRingBufferAABBSize.x || Delta.y >= mRingBufferAABBSize.y || Delta.z >= mRingBufferAABBSize.z)
            {
                return EBUILD_STRATEGY.PREPARE_FROM_GROUND;
            }
            return EBUILD_STRATEGY.PREPARE_ON_DELTA;
        }


        private enum EBUILD_STRATEGY
        {
            INVALID = 0,
            PREPARE_FROM_GROUND = 1,
            PREPARE_ON_DELTA = 2,
            DO_BUILD = 3,
            DO_NOT_BUILD = 4,
        }

        private enum ERING_BUFFER_EXEC_STATE
        {
            Normal  = 0,
            Init    = 1 << 1,
            IsDirty = 1 << 2,
            Loading = 1 << 3,
            Process = 1 << 4,
            InValid = 1 << 5,
        }

        protected enum ECORNER_PRIMITIVE
        {
            FRONT   =   1 << 0,
            LEFT    =   1 << 1,
            UP      =   1 << 2,
            BACK    =   1 << 3,
            RIGHT   =   1 << 4,
            DOWN    =   1 << 5,
        }

        protected enum EDIR_TYPE
        {
            FRONT_LEFT_UP       =   ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.LEFT | ECORNER_PRIMITIVE.UP,
            FRONT_RIGHT_UP      =   ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.RIGHT | ECORNER_PRIMITIVE.UP,
            BACK_LEFT_UP        =   ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.LEFT | ECORNER_PRIMITIVE.UP,
            BACK_RIGHT_UP       =   ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.RIGHT | ECORNER_PRIMITIVE.UP,
            FRONT_LEFT_DOWN     =   ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.LEFT | ECORNER_PRIMITIVE.DOWN,
            FRONT_RIGHT_DOWN    =   ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.RIGHT | ECORNER_PRIMITIVE.DOWN,
            BACK_LEFT_DOWN      =   ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.LEFT | ECORNER_PRIMITIVE.DOWN,
            BACK_RIGHT_DOWN     =   ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.RIGHT | ECORNER_PRIMITIVE.DOWN,

            _INVALID            = -1,
            _MERGED             = -2,
        }


        protected struct Box
        {
            public Vector3 Min;
            public Vector3 Max;
            public Vector3 MoveDir;

            public static Box Convert2Box(Bounds aBound, Vector3 Epsilon)
            {
                Box box = new Box();
                box.Min = aBound.min;
                box.Max = aBound.max;
                box.Min += Epsilon;
                box.Max -= Epsilon;
                box.MoveDir = Vector3.zero;
                return box;
            }

            public static Box Convert2Box(Vector3 aCenter, Vector3 aExtent, Vector3 Epsilon)
            {
                Box box = new Box();
                box.Min = aCenter - aExtent;
                box.Max = aCenter + aExtent;
                box.Min += Epsilon;
                box.Max -= Epsilon;
                box.MoveDir = Vector3.zero;
                return box;
            }

            public static Box CreateBox(Vector3 aMin, Vector3 aMax, Vector3 Epsilon)
            {
                Box box = new Box();
                box.Min = aMin + Epsilon;
                box.Max = aMax - Epsilon;
                box.MoveDir = Vector3.zero;
                return box;
            }
        }

        private ObjectPool<Work3D> mPool = null;

        protected sealed class Work3D
        {
            public EDIR_TYPE RingBufferBoxDirType;
            public Texture3D SrcTexture3D;
            public int TileIndex;

            public Box SrcBoxWorldSpace;        //Unshrinked Box of src tex3d from where data will be sampled
            public Box TarBoxWorldSpace;        //Unshrinked Box of target area in world space defined by current AABB center and extents
            public Box AreaOfIntreseting;       //Shrinked Box refs to the intreseted area

            public Vector3 BoxDirAssociatedPos; //Shrinked Position
            public Vector3 Epsilon;
            public Vector3 MoveDir;

            public bool MyCornerTypeHasFeature(int aFlag)
            {
                return ((int)RingBufferBoxDirType & aFlag) == aFlag;
            }

            //8个点都在Box中，对应唯一的情况 -> Box 等同于这8个点
            public void Merge(Work3D aA, Work3D aB, Work3D aC, Work3D aD, Work3D aE, Work3D aF, Work3D aG)
            {
                Vector3 _Min = new Vector3(
                    Mathf.Min(Mathf.Min(Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Min(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)), aD.BoxDirAssociatedPos.x),
                    Mathf.Min(Mathf.Min(Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Min(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)), aD.BoxDirAssociatedPos.y),
                    Mathf.Min(Mathf.Min(Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Min(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)), aD.BoxDirAssociatedPos.z));
                Vector3 _Max = new Vector3(
                    Mathf.Max(Mathf.Max(Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Max(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)), aD.BoxDirAssociatedPos.x),
                    Mathf.Max(Mathf.Max(Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Max(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)), aD.BoxDirAssociatedPos.y),
                    Mathf.Max(Mathf.Max(Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Max(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)), aD.BoxDirAssociatedPos.z));

                AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                RingBufferBoxDirType = EDIR_TYPE._MERGED;
            }

            //4个点在Box中，对应6中不同情况
            public void Merge(Work3D aA, Work3D aB, Work3D aC)
            {
                uint aFlag = (uint)RingBufferBoxDirType & 
                    (uint)aA.RingBufferBoxDirType &
                    (uint)aB.RingBufferBoxDirType &
                    (uint)aC.RingBufferBoxDirType;

                Vector3 _Min;
                Vector3 _Max;

                switch(aFlag)
                {
                    case (uint)ECORNER_PRIMITIVE.FRONT:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),Mathf.Min(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),Mathf.Min(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z),Mathf.Min(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Max(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Max(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case (uint)ECORNER_PRIMITIVE.BACK:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Min(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Min(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Max(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Max(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Max(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.LEFT:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Min(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Min(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Min(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Max(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Max(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.RIGHT:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Min(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Min(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Max(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Max(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Max(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.UP:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Min(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Min(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Max(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Max(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Max(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.DOWN:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Min(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y), Mathf.Min(aB.BoxDirAssociatedPos.y, aC.BoxDirAssociatedPos.y)),
                            Mathf.Min(Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Min(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x), Mathf.Max(aB.BoxDirAssociatedPos.x, aC.BoxDirAssociatedPos.x)),
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            Mathf.Max(Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z), Mathf.Max(aB.BoxDirAssociatedPos.z, aC.BoxDirAssociatedPos.z)));
                        break;
                    default:
                        _Min = new Vector3();
                        _Max = new Vector3();
                        break;
                }

                AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                RingBufferBoxDirType = EDIR_TYPE._MERGED;
            }

            //2个点在Box中，对应12种不同情况
            public void Merge(Work3D aA)
            {
                Vector3 dir = this.BoxDirAssociatedPos - aA.BoxDirAssociatedPos;
                if (dir.x != 0) //direction: U -> Left2Right
                {
                    if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.UP)))
                    {
                        Vector3 _Min = new Vector3(
                            Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            BoxDirAssociatedPos.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                            BoxDirAssociatedPos.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.UP)))
                    {
                        Vector3 _Min = new Vector3(
                            Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                            BoxDirAssociatedPos.y,
                            BoxDirAssociatedPos.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if(MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.DOWN)))
                    {
                        Vector3 _Min = new Vector3(
                           Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                           BoxDirAssociatedPos.y,
                           BoxDirAssociatedPos.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if(MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.DOWN)))
                    {
                        Vector3 _Min = new Vector3(
                           Mathf.Min(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                           BoxDirAssociatedPos.y,
                           SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(BoxDirAssociatedPos.x, aA.BoxDirAssociatedPos.x),
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            BoxDirAssociatedPos.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else
                    {
                        Debug.LogWarning("Invalid State U");
                    }
                }
                else if(dir.y != 0)//direction: W
                {
                    if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            BoxDirAssociatedPos.z);

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            BoxDirAssociatedPos.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            BoxDirAssociatedPos.z);

                        Vector3 _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            Mathf.Min(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            Mathf.Max(BoxDirAssociatedPos.y, aA.BoxDirAssociatedPos.y),
                            BoxDirAssociatedPos.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else
                    {
                        Debug.LogWarning("Invalid State W");
                    }
                }
                else if(dir.z != 0) //direction: V
                {
                    if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.UP | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            BoxDirAssociatedPos.y,
                            Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.DOWN | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            BoxDirAssociatedPos.y,
                            Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.UP | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        Vector3 _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            BoxDirAssociatedPos.y,
                            Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((int)(ECORNER_PRIMITIVE.DOWN | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            BoxDirAssociatedPos.y,
                            Mathf.Min(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        Vector3 _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            Mathf.Max(BoxDirAssociatedPos.z, aA.BoxDirAssociatedPos.z));

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else
                    {
                        Debug.LogWarning("Invalid State V");
                    }
                }
                else
                {
                    Debug.LogWarning("Invalid State for 2 Point");
                }
                RingBufferBoxDirType = EDIR_TYPE._MERGED;
            }

            //只有1个点在Box中，对应8种不同的情况
            public void Merge()
            {
                Vector3 _Min;
                Vector3 _Max;
                switch(RingBufferBoxDirType)
                {
                    case EDIR_TYPE.FRONT_LEFT_UP:
                        _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            BoxDirAssociatedPos.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            BoxDirAssociatedPos.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case EDIR_TYPE.FRONT_RIGHT_UP:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            BoxDirAssociatedPos.z);
                        _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            BoxDirAssociatedPos.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case EDIR_TYPE.BACK_LEFT_UP:
                        _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            BoxDirAssociatedPos.y,
                            BoxDirAssociatedPos.z);
                        break;
                    case EDIR_TYPE.BACK_RIGHT_UP:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            BoxDirAssociatedPos.y,
                            BoxDirAssociatedPos.z);
                        break;
                    case EDIR_TYPE.FRONT_LEFT_DOWN:
                        _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            BoxDirAssociatedPos.y,
                            BoxDirAssociatedPos.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case EDIR_TYPE.FRONT_RIGHT_DOWN:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            BoxDirAssociatedPos.y,
                            BoxDirAssociatedPos.z);
                        _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case EDIR_TYPE.BACK_LEFT_DOWN:
                        _Min = new Vector3(
                            BoxDirAssociatedPos.x,
                            BoxDirAssociatedPos.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            BoxDirAssociatedPos.z);
                        break;
                    case EDIR_TYPE.BACK_RIGHT_DOWN:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            BoxDirAssociatedPos.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            BoxDirAssociatedPos.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            BoxDirAssociatedPos.z);
                        break;
                    default:
                        _Min = new Vector3();
                        _Max = new Vector3();
                        Debug.LogWarning("Invalid State for 1 Point");
                        break;
                }

                AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                RingBufferBoxDirType = EDIR_TYPE._MERGED;
            }

            public void Reset()
            {
                SrcTexture3D = null; //要的是释放引用
                TileIndex = 0;
                RingBufferBoxDirType = EDIR_TYPE._INVALID; //状态归位
            }

            public static void OnReturnWork(Work3D aWork)
            {
                aWork.Reset();
            }
        }


        private List<Work3D> ExtractWork3DFromDelta()
        {
            List<Work3D> output = new List<Work3D>();
            var MoveDir = mOnWorkingBufferAABBCenterPosition - mRingBufferAABBCenterPosition;
            Box CurrentBox = Box.Convert2Box(mRingBufferAABBCenterPosition, mRingBufferAABBExtension, Vector3.zero);
            Box DynamicBox = Box.Convert2Box(mOnWorkingBufferAABBCenterPosition, mRingBufferAABBExtension, Vector3.zero);

            //direction U (or x-axis)
            if(MoveDir.x < 0)
            {
                var _Min = DynamicBox.Min;
                var _Max = new Vector3(CurrentBox.Min.x, DynamicBox.Max.y, DynamicBox.Max.z);
                Box ShrinkedSearchingBox = Box.CreateBox(_Min, _Max, HalfTexelSize);
                var _works = ExtractWork3DFrom(ref ShrinkedSearchingBox);
                output.AddRange(_works);
                DynamicBox.Min.x = CurrentBox.Min.x;  //shrink the box accordingly
            }
            else if (MoveDir.x > 0)
            {
                
                var _Min = new Vector3(CurrentBox.Max.x, DynamicBox.Min.y, DynamicBox.Min.z);
                var _Max = DynamicBox.Max;
                Box ShrinkedSearchingBox = Box.CreateBox(_Min, _Max, HalfTexelSize);
                var _works = ExtractWork3DFrom(ref ShrinkedSearchingBox);
                output.AddRange(_works);
                DynamicBox.Max.x = CurrentBox.Max.x;  //shrink the box accordingly
            }
            
            //direction V (or z-axis)
            if(MoveDir.z < 0)
            {
                var _Min = DynamicBox.Min;
                var _Max = new Vector3(DynamicBox.Max.x, DynamicBox.Max.y, CurrentBox.Min.z);
                Box ShrinkedSearchingBox = Box.CreateBox(_Min, _Max, HalfTexelSize);
                var _works = ExtractWork3DFrom(ref ShrinkedSearchingBox);
                output.AddRange(_works);
                DynamicBox.Min.z = CurrentBox.Min.z;
            }
            else if (MoveDir.z > 0)
            {
                var _Min = new Vector3(DynamicBox.Min.x, DynamicBox.Min.y, CurrentBox.Max.z);
                var _Max = DynamicBox.Max;
                Box ShrinkedSearchingBox = Box.CreateBox(_Min, _Max, HalfTexelSize);
                var _works = ExtractWork3DFrom(ref ShrinkedSearchingBox);
                output.AddRange(_works);
                DynamicBox.Max.z = CurrentBox.Max.z;
            }

            //direction W (or y-axis)
            if (MoveDir.y < 0)
            {
                var _Min = DynamicBox.Min;
                var _Max = new Vector3(DynamicBox.Max.x, CurrentBox.Min.y, DynamicBox.Max.z);
                Box ShrinkedSearchingBox = Box.CreateBox(_Min, _Max, HalfTexelSize);
                var _works = ExtractWork3DFrom(ref ShrinkedSearchingBox);
                output.AddRange(_works);
                //DynamicBox.Min.y = CurrentBox.Min.y;
            }
            else if(MoveDir.y > 0)
            {
                var _Min = new Vector3(DynamicBox.Min.x, CurrentBox.Max.y, DynamicBox.Min.z);
                var _Max = DynamicBox.Max;
                Box ShrinkedSearchingBox = Box.CreateBox(_Min, _Max, HalfTexelSize);
                var _works = ExtractWork3DFrom(ref ShrinkedSearchingBox);
                output.AddRange(_works);
                //DynamicBox.Max.y = CurrentBox.Max.y;
            }

            try
            {
                output.Sort((a, b) => { return a.TileIndex.CompareTo(b.TileIndex); });
            }
            catch(Exception e)
            {
                Debug.Log("has exception"); 
                throw e;
            }
            

            return output;
        }


        protected List<Work3D> ExtractWork3DFrom(ref Box aShrinkedBox)
        {
            List<Work3D> output = new List<Work3D>();

            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.FRONT_LEFT_UP, output);
            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.FRONT_RIGHT_UP, output);
            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.BACK_LEFT_UP, output);
            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.BACK_RIGHT_UP, output);
            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.FRONT_LEFT_DOWN, output);
            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.FRONT_RIGHT_DOWN, output);
            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.BACK_LEFT_DOWN, output);
            CreateWork3D(ref aShrinkedBox, EDIR_TYPE.BACK_RIGHT_DOWN, output);

            output.Sort((a,b) => { return a.TileIndex.CompareTo(b.TileIndex); });

            int p = 0;
            for (int i = 0, j = 1; i < output.Count; )
            {
                while(j < output.Count && output[i].TileIndex == output[j].TileIndex)
                {
                    j++;
                }
                if (p != i)
                {
                    output[p] = output[i];
                    output[i] = null;
                }
                switch(j - i)
                {
                    case 1:
                        output[p].Merge();
                        break;
                    case 2:
                        output[p].Merge(output[i+1]);
                        break;
                    case 4:
                        output[p].Merge(output[i + 1], output[i + 2], output[i + 3]);
                        break;
                    case 8:
                        output[p].Merge(output[i + 1], output[i + 2], output[i + 3], output[i + 4], 
                            output[i + 5], output[i + 6], output[i + 7]);
                        break;
                    default:
                        Debug.LogError("Invalid Merge Number");
                        break;
                }

                i++;
                p++;
                
                for (; i < j; ++i)
                {
                    mPool.Release(output[i]);
                    output[i] = null;
                }
                i = j;
                j++;
            }

            if (p < output.Count)
                output.RemoveRange(p, output.Count - p);

            return output;
        }

        /// <summary>
        /// 创建一个Work3D实例，里面存放有Buffer边界顶点和相关信息以供后续计算使用
        /// </summary>
        /// <param name="aShrinkedBox">很重要的一点，用于获取TileIndex的Box，必须经过有值的Epsilon修正</param>
        /// <param name="aCorner">Buffer的边界顶点类型</param>
        /// <param name="aOutput">输出结果</param>
        protected void CreateWork3D(ref Box aShrinkedBox, EDIR_TYPE aCorner, in List<Work3D> aOutput)
        {
            var _work = mPool.Get();
            _work.Epsilon = this.HalfTexelSize;
            _work.RingBufferBoxDirType = aCorner;
            _work.MoveDir = aShrinkedBox.MoveDir;
            _work.TarBoxWorldSpace = Box.Convert2Box(mOnWorkingBufferAABBCenterPosition, mRingBufferAABBExtension, Vector3.zero);
            _work.BoxDirAssociatedPos = ConvertBoxCornerToPosition(ref aShrinkedBox, aCorner);
            _work.TileIndex = mTileMgr.GetTileIndexFromOnePointInWorldSpace(_work.BoxDirAssociatedPos);
            var bounding = mTileMgr.GetBoundingBoxOfGivenTileIndex(_work.TileIndex);
            _work.SrcBoxWorldSpace = Box.Convert2Box(bounding, Vector3.zero); //clean box(not shrinked)

            string assetPath = mTileMgr.GetAssetPathFromTileIndex(_work.TileIndex);

            AsyncLoadingCounter++;
            mSourceProvider.AyncLoad((texGo, suc) =>
            {
                AsyncLoadingCounter--;
                if (_work.RingBufferBoxDirType == EDIR_TYPE._INVALID)
                {
                    return; //此Work3D已经被合并销毁了
                }
                if (!suc)
                {
                    _work.SrcTexture3D = dummy;
                }
                else
                {
                    if (texGo is Texture3D)
                    {
                        _work.SrcTexture3D = texGo as Texture3D;
                        //Debug.Log($"SrcTexture3D.isReadable = {_work.SrcTexture3D.isReadable}");  //做个测试，我需要它是 unreadable
                    }
                    else
                    {
                        _work.SrcTexture3D = dummy;
                    }
                }
            }, assetPath);

            aOutput.Add(_work);
        }

        protected Vector3 ConvertBoxCornerToPosition(ref Box aBox, EDIR_TYPE aCorner)
        {
            var ret = new Vector3();
            switch(aCorner)
            {
                case EDIR_TYPE.FRONT_LEFT_UP:
                    ret.Set(aBox.Min.x, aBox.Max.y, aBox.Min.z);
                    break;
                case EDIR_TYPE.FRONT_RIGHT_UP:
                    ret.Set(aBox.Max.x, aBox.Max.y, aBox.Min.z);
                    break;
                case EDIR_TYPE.BACK_LEFT_UP:
                    ret.Set(aBox.Min.x, aBox.Max.y, aBox.Max.z);
                    break;
                case EDIR_TYPE.BACK_RIGHT_UP:
                    ret.Set(aBox.Max.x, aBox.Max.y, aBox.Max.z);
                    break;
                case EDIR_TYPE.FRONT_LEFT_DOWN:
                    ret.Set(aBox.Min.x, aBox.Min.y, aBox.Min.z);
                    break;
                case EDIR_TYPE.FRONT_RIGHT_DOWN:
                    ret.Set(aBox.Max.x, aBox.Min.y, aBox.Min.z);
                    break;
                case EDIR_TYPE.BACK_LEFT_DOWN:
                    ret.Set(aBox.Min.x, aBox.Min.y, aBox.Max.z);
                    break;
                case EDIR_TYPE.BACK_RIGHT_DOWN:
                    ret.Set(aBox.Max.x, aBox.Min.y, aBox.Max.z);
                    break;
                default:
                    Debug.LogError("Invalid Corner Type");
                    break;
            }

            return ret;
        }

    }

}