using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.RuntimeTools.RingBuffer
{
    public interface ISourceProvider
    {
        public Texture3D SyncLoad(int aTileIndex);

        //public Texture3D SyncLoad(Vector3 aPosWS);

        public void AyncLoad(Action<Texture3D, bool> aCallback, int aTileIndex);

        //public void AyncLoad(Action<Texture3D, bool> aCallback, Vector3 aPosWS);

    }

    public interface ITileManager
    {
        public int GetTileIndexFromOnePointInWorldSpace(Vector3 aPosWS);

        public Bounds GetBoundingBoxOfGivenTileIndex(int aTileIndex);
    }
    

    public class RingBufferBase
    {
        //private Transform m_followee;       //期望的buffer中心点坐标
        private Vector3 mRingBufferAABBExtension;       //Buffer对应立方体的三维长宽高

        private Vector3 mRingBufferAABBCenterPosition;  //Buffer立方体中心点坐标(世界空间)

        private Vector3 mDesiredBufferAABBCenterPosition;

        private ERINB_BUFFER_EXEC_STATE State;

        private ISourceProvider mSourceProvider;

        private ITileManager mTileMgr;

        private Vector3Int mMinimumDeltaUnitSizeInPixel;

        private int AsyncLoadingCounter = 0;

        private Texture3D dummy;

        public RingBufferBase(ISourceProvider aSourceProvider, ITileManager aTileMgr)
        {
            this.mSourceProvider = aSourceProvider;
            this.mTileMgr = aTileMgr;
            dummy = new Texture3D(1,1,1, TextureFormat.RFloat, false);
            dummy.SetPixel(0, 0, 0, Color.white);
            State = ERINB_BUFFER_EXEC_STATE.InValid;
        }

        public void Init(Vector3 aExtention, Vector3 aCenterPos, Vector3Int aMinDeltaSize)
        {
            mRingBufferAABBCenterPosition.Set(
                Mathf.Floor(aCenterPos.x),
                Mathf.Floor(aCenterPos.y),
                Mathf.Floor(aCenterPos.z)
                );
            mRingBufferAABBExtension = aExtention;
            mMinimumDeltaUnitSizeInPixel = aMinDeltaSize;

            mPool = new ObjectPool<Work3D>(null, Work3D.OnReturnWork);

            State = ERINB_BUFFER_EXEC_STATE.Init;
        }

        public void Setup(Vector3 aDesiredTargetCenter)
        {
            mDesiredBufferAABBCenterPosition = aDesiredTargetCenter;
            State |= ERINB_BUFFER_EXEC_STATE.IsDirty;
        }

        public void Execute(CommandBuffer cmd = null)
        {
            if (State == ERINB_BUFFER_EXEC_STATE.InValid || 
                State == ERINB_BUFFER_EXEC_STATE.WAIT) 
                return;

            switch (State)
            {
                case ERINB_BUFFER_EXEC_STATE.Init:
                    break;
                case ERINB_BUFFER_EXEC_STATE.IsDirty:
                    break;
                case ERINB_BUFFER_EXEC_STATE.Init | ERINB_BUFFER_EXEC_STATE.IsDirty:
                    break;
                default:
                    break;
            }
        }

        private enum ERINB_BUFFER_EXEC_STATE
        {
            WAIT = 0,
            Init = 1 << 1,
            IsDirty = 1 << 2,
            InValid = 1 << 3,
        }

        protected enum ECORNER_TYPE
        {
            FRONT_LEFT_UP       = 0,
            FRONT_RIGHT_UP,
            BACK_LEFT_UP,
            BACK_RIGHT_UP,
            FRONT_LEFT_DOWN,
            FRONT_RIGHT_DOWN,
            BACK_LEFT_DOWN,
            BACK_RIGHT_DOWN,

            _COUNT,
        }

        protected struct Box
        {
            public Vector3 Min;
            public Vector3 Max;

            public static Box Convert2Box(Vector3 aCenter, Vector3 aExtent)
            {
                Box box = new Box();
                box.Min = aCenter - aExtent;
                box.Max = aCenter + aExtent;
                return box;
            }

            public static Box CreateBox(Vector3 aMin, Vector3 aMax)
            {
                Box box = new Box();
                box.Min = aMin;
                box.Max = aMax;
                return box;
            }
        }

        private ObjectPool<Work3D> mPool = null;

        protected sealed class Work3D
        {
            public ECORNER_TYPE RingBufferCornerPositionType;
            public Texture3D SrcTexture3D;
            public Box SrcAABBWorldSpaceBox;
            public Vector3 CornerPositionWS;

            public void Reset()
            {
                SrcTexture3D = null;
                RingBufferCornerPositionType = ECORNER_TYPE._COUNT;
            }
            public static void OnReturnWork(Work3D aWork)
            {
                aWork.Reset();
            }
        }

        protected void ExtractWork3DFrom(ref Box aBox, in List<Work3D> aOutput)
        {
            CreateWord3D(ref aBox, ECORNER_TYPE.FRONT_LEFT_UP, aOutput);
            CreateWord3D(ref aBox, ECORNER_TYPE.FRONT_RIGHT_UP, aOutput);
            CreateWord3D(ref aBox, ECORNER_TYPE.BACK_LEFT_UP, aOutput);
            CreateWord3D(ref aBox, ECORNER_TYPE.BACK_RIGHT_UP, aOutput);
            CreateWord3D(ref aBox, ECORNER_TYPE.FRONT_LEFT_DOWN, aOutput);
            CreateWord3D(ref aBox, ECORNER_TYPE.FRONT_RIGHT_DOWN, aOutput);
            CreateWord3D(ref aBox, ECORNER_TYPE.BACK_LEFT_DOWN, aOutput);
            CreateWord3D(ref aBox, ECORNER_TYPE.BACK_RIGHT_DOWN, aOutput);
        }

        protected void CreateWord3D(ref Box aBox, ECORNER_TYPE aCorner, in List<Work3D> aOutput)
        {
            var _work = mPool.Get();
            _work.RingBufferCornerPositionType = aCorner;
            _work.CornerPositionWS = ConvertBoxCornerToPosition(aBox, aCorner);

            int tileIndex = mTileMgr.GetTileIndexFromOnePointInWorldSpace(_work.CornerPositionWS);

            AsyncLoadingCounter++;
            mSourceProvider.AyncLoad((tex, suc) =>
            {
                AsyncLoadingCounter--;
                if (!suc)
                {
                    _work.SrcTexture3D = dummy;
                }
                else
                {
                    _work.SrcTexture3D = tex;
                }
            }, tileIndex);

            aOutput.Add(_work);
        }

        protected static Vector3 ConvertBoxCornerToPosition(Box aBox, ECORNER_TYPE aCorner)
        {
            var ret = new Vector3();
            switch(aCorner)
            {
                case ECORNER_TYPE.FRONT_LEFT_UP:
                    ret.Set(aBox.Min.x, aBox.Max.y, aBox.Min.z);
                    break;
                case ECORNER_TYPE.FRONT_RIGHT_UP:
                    ret.Set(aBox.Max.x, aBox.Max.y, aBox.Min.z);
                    break;
                case ECORNER_TYPE.BACK_LEFT_UP:
                    ret.Set(aBox.Min.x, aBox.Max.y, aBox.Max.z);
                    break;
                case ECORNER_TYPE.BACK_RIGHT_UP:
                    ret.Set(aBox.Max.x, aBox.Max.y, aBox.Max.z);
                    break;
                case ECORNER_TYPE.FRONT_LEFT_DOWN:
                    ret.Set(aBox.Min.x, aBox.Min.y, aBox.Min.z);
                    break;
                case ECORNER_TYPE.FRONT_RIGHT_DOWN:
                    ret.Set(aBox.Max.x, aBox.Min.y, aBox.Min.z);
                    break;
                case ECORNER_TYPE.BACK_LEFT_DOWN:
                    ret.Set(aBox.Min.x, aBox.Min.y, aBox.Max.z);
                    break;
                case ECORNER_TYPE.BACK_RIGHT_DOWN:
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