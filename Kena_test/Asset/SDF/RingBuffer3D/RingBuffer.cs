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

        private Vector3 mRingBufferTextureSize;         //in pixel

        private Vector3 mRingBufferAABBCenterPosition;  //Buffer立方体中心点坐标(世界空间)

        private Vector3 mDesiredBufferAABBCenterPosition;       //每帧更新的期望位置
        
        private Vector3 mOnWorkingBufferAABBCenterPosition;     //正在处理中的位置

        private ERINB_BUFFER_EXEC_STATE State;

        private ISourceProvider mSourceProvider;

        private ITileManager mTileMgr;

        private Vector3Int mMinimumDeltaUnitSizeInPixel;  //最小搬运尺寸,位移小于这个像素值不会触发Buffer更新

        private int AsyncLoadingCounter = 0;

        private Texture3D dummy;

        private Vector3 Epsilon;                          //代表0.5个pixel在世界空间中的尺度

        public RingBufferBase(ISourceProvider aSourceProvider, ITileManager aTileMgr)
        {
            this.mSourceProvider = aSourceProvider;
            this.mTileMgr = aTileMgr;
            dummy = new Texture3D(1,1,1, TextureFormat.RFloat, false);
            dummy.SetPixel(0, 0, 0, Color.white);
            State = ERINB_BUFFER_EXEC_STATE.InValid;
        }

        /// <summary>
        /// 初始化RingBuffer
        /// </summary>
        /// <param name="aExtention">在世界空间中由Buffer数据填充的AABB包围盒的半边长</param>
        /// <param name="aCenterPos">包围盒中心位置</param>
        /// <param name="aMinDeltaSize">支持拷贝和搬运的最小像素尺寸，当差距小于该尺寸时不触发Buffer的更新</param>
        /// <param name="aBufferTexSize">Buffer对应Texture3D的width，height和depth</param>
        public void Init(Vector3 aExtention, Vector3 aCenterPos, Vector3Int aMinDeltaSize, Vector3 aBufferTexSize)
        {
            mRingBufferAABBCenterPosition.Set(
                Mathf.Floor(aCenterPos.x),
                Mathf.Floor(aCenterPos.y),
                Mathf.Floor(aCenterPos.z)
                );
            mRingBufferAABBExtension = aExtention;
            mRingBufferTextureSize = aBufferTexSize;
            mMinimumDeltaUnitSizeInPixel = aMinDeltaSize;

            Epsilon = aExtention;
            Epsilon.Set(
                Epsilon.x / aBufferTexSize.x,
                Epsilon.y / aBufferTexSize.y,
                Epsilon.z / aBufferTexSize.z);


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

        private void BuildBufferFronGround()
        {

        }

        private enum ERINB_BUFFER_EXEC_STATE
        {
            WAIT    = 0,
            Init    = 1 << 1,
            IsDirty = 1 << 2,
            InValid = 1 << 3,
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

        protected enum ECORNER_TYPE
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
        }

        protected struct Box
        {
            public Vector3 Min;
            public Vector3 Max;

            public static Box Convert2Box(Bounds aBound, Vector3 Epsilon)
            {
                Box box = new Box();
                box.Min = aBound.min;
                box.Max = aBound.max;
                box.Min += Epsilon;
                box.Max -= Epsilon;
                return box;
            }

            public static Box Convert2Box(Vector3 aCenter, Vector3 aExtent, Vector3 Epsilon)
            {
                Box box = new Box();
                box.Min = aCenter - aExtent;
                box.Max = aCenter + aExtent;
                box.Min += Epsilon;
                box.Max -= Epsilon;
                return box;
            }

            public static Box CreateBox(Vector3 aMin, Vector3 aMax, Vector3 Epsilon)
            {
                Box box = new Box();
                box.Min = aMin + Epsilon;
                box.Max = aMax - Epsilon;
                return box;
            }
        }

        private ObjectPool<Work3D> mPool = null;

        protected sealed class Work3D
        {
            public ECORNER_TYPE RingBufferCornerPositionType;
            public Texture3D SrcTexture3D;
            public int TileIndex;
            public Box SrcBoxWorldSpace;
            public Box AreaOfIntreseting;
            public Vector3 CornerPositionWS;    //Shrinked Position
            public Vector3 Epsilon;

            public bool MyCornerTypeHasFeature(uint aFlag)
            {
                return ((uint)RingBufferCornerPositionType & aFlag) == aFlag;
            }

            //8个点都在Box中，对应唯一的情况 -> Box 等同于这8个点
            public void Merge(Work3D aA, Work3D aB, Work3D aC, Work3D aD, Work3D aE, Work3D aF, Work3D aG)
            {
                Vector3 _Min = new Vector3(
                    Mathf.Min(Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Min(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                    Mathf.Min(Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Min(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                    Mathf.Min(Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Min(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                Vector3 _Max = new Vector3(
                    Mathf.Max(Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Max(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                    Mathf.Max(Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Max(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                    Mathf.Max(Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Max(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));

                AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
            }

            //4个点在Box中，对应6中不同情况
            public void Merge(Work3D aA, Work3D aB, Work3D aC)
            {
                uint aFlag = (uint)RingBufferCornerPositionType & 
                    (uint)aA.RingBufferCornerPositionType &
                    (uint)aB.RingBufferCornerPositionType &
                    (uint)aC.RingBufferCornerPositionType;

                Vector3 _Min;
                Vector3 _Max;

                switch(aFlag)
                {
                    case (uint)ECORNER_PRIMITIVE.FRONT:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x),Mathf.Min(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y),Mathf.Min(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z),Mathf.Min(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Max(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Max(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case (uint)ECORNER_PRIMITIVE.BACK:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Min(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Min(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Max(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Max(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Max(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.LEFT:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Min(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Min(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Min(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            Mathf.Max(Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Max(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Max(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.RIGHT:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            Mathf.Min(Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Min(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Min(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Max(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Max(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Max(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.UP:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Min(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            Mathf.Min(Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Min(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Max(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Max(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Max(Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Max(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        break;
                    case (uint)ECORNER_PRIMITIVE.DOWN:
                        _Min = new Vector3(
                            Mathf.Min(Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Min(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y), Mathf.Min(aB.CornerPositionWS.y, aC.CornerPositionWS.y)),
                            Mathf.Min(Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Min(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        _Max = new Vector3(
                            Mathf.Max(Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x), Mathf.Max(aB.CornerPositionWS.x, aC.CornerPositionWS.x)),
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            Mathf.Max(Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z), Mathf.Max(aB.CornerPositionWS.z, aC.CornerPositionWS.z)));
                        break;
                    default:
                        _Min = new Vector3();
                        _Max = new Vector3();
                        break;
                }

                AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
            }

            //2个点在Box中，对应12种不同情况
            public void Merge(Work3D aA)
            {
                Vector3 dir = this.CornerPositionWS - aA.CornerPositionWS;
                if (dir.x != 0) //direction: U -> Left2Right
                {
                    if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.UP)))
                    {
                        Vector3 _Min = new Vector3(
                            Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x),
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            CornerPositionWS.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x),
                            CornerPositionWS.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.UP)))
                    {
                        Vector3 _Min = new Vector3(
                            Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x),
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x),
                            CornerPositionWS.y,
                            CornerPositionWS.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if(MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.DOWN)))
                    {
                        Vector3 _Min = new Vector3(
                           Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x),
                           CornerPositionWS.y,
                           CornerPositionWS.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x),
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if(MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.DOWN)))
                    {
                        Vector3 _Min = new Vector3(
                           Mathf.Min(CornerPositionWS.x, aA.CornerPositionWS.x),
                           CornerPositionWS.y,
                           SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            Mathf.Max(CornerPositionWS.x, aA.CornerPositionWS.x),
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            CornerPositionWS.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else
                    {
                        Debug.LogWarning("Invalid State U");
                    }
                }
                else if(dir.y != 0)//direction: W
                {
                    if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            CornerPositionWS.x,
                            Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y),
                            CornerPositionWS.z);

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y),
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            CornerPositionWS.x,
                            Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y),
                            SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y),
                            CornerPositionWS.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.FRONT | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y),
                            CornerPositionWS.z);

                        Vector3 _Max = new Vector3(
                            CornerPositionWS.x,
                            Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y),
                            SrcBoxWorldSpace.Max.z - Epsilon.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.BACK | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            Mathf.Min(CornerPositionWS.y, aA.CornerPositionWS.y),
                            SrcBoxWorldSpace.Min.z + Epsilon.z);

                        Vector3 _Max = new Vector3(
                            CornerPositionWS.x,
                            Mathf.Max(CornerPositionWS.y, aA.CornerPositionWS.y),
                            CornerPositionWS.z);

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else
                    {
                        Debug.LogWarning("Invalid State W");
                    }
                }
                else if(dir.z != 0) //direction: V
                {
                    if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.UP | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            CornerPositionWS.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z));

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            CornerPositionWS.y,
                            Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z));

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.DOWN | ECORNER_PRIMITIVE.LEFT)))
                    {
                        Vector3 _Min = new Vector3(
                            CornerPositionWS.x,
                            CornerPositionWS.y,
                            Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z));

                        Vector3 _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z));

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.UP | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z));

                        Vector3 _Max = new Vector3(
                            CornerPositionWS.x,
                            CornerPositionWS.y,
                            Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z));

                        AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
                    }
                    else if (MyCornerTypeHasFeature((uint)(ECORNER_PRIMITIVE.DOWN | ECORNER_PRIMITIVE.RIGHT)))
                    {
                        Vector3 _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            CornerPositionWS.y,
                            Mathf.Min(CornerPositionWS.z, aA.CornerPositionWS.z));

                        Vector3 _Max = new Vector3(
                            CornerPositionWS.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            Mathf.Max(CornerPositionWS.z, aA.CornerPositionWS.z));

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
            }

            //只有1个点在Box中，对应8中不同的情况
            public void Merge()
            {
                Vector3 _Min;
                Vector3 _Max;
                switch(RingBufferCornerPositionType)
                {
                    case ECORNER_TYPE.FRONT_LEFT_UP:
                        _Min = new Vector3(
                            CornerPositionWS.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            CornerPositionWS.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            CornerPositionWS.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case ECORNER_TYPE.FRONT_RIGHT_UP:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            CornerPositionWS.z);
                        _Max = new Vector3(
                            CornerPositionWS.x,
                            CornerPositionWS.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case ECORNER_TYPE.BACK_LEFT_UP:
                        _Min = new Vector3(
                            CornerPositionWS.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            CornerPositionWS.y,
                            CornerPositionWS.z);
                        break;
                    case ECORNER_TYPE.BACK_RIGHT_UP:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            SrcBoxWorldSpace.Min.y + Epsilon.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            CornerPositionWS.x,
                            CornerPositionWS.y,
                            CornerPositionWS.z);
                        break;
                    case ECORNER_TYPE.FRONT_LEFT_DOWN:
                        _Min = new Vector3(
                            CornerPositionWS.x,
                            CornerPositionWS.y,
                            CornerPositionWS.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case ECORNER_TYPE.FRONT_RIGHT_DOWN:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            CornerPositionWS.y,
                            CornerPositionWS.z);
                        _Max = new Vector3(
                            CornerPositionWS.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            SrcBoxWorldSpace.Max.z - Epsilon.z);
                        break;
                    case ECORNER_TYPE.BACK_LEFT_DOWN:
                        _Min = new Vector3(
                            CornerPositionWS.x,
                            CornerPositionWS.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            SrcBoxWorldSpace.Max.x - Epsilon.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            CornerPositionWS.z);
                        break;
                    case ECORNER_TYPE.BACK_RIGHT_DOWN:
                        _Min = new Vector3(
                            SrcBoxWorldSpace.Min.x + Epsilon.x,
                            CornerPositionWS.y,
                            SrcBoxWorldSpace.Min.z + Epsilon.z);
                        _Max = new Vector3(
                            CornerPositionWS.x,
                            SrcBoxWorldSpace.Max.y - Epsilon.y,
                            CornerPositionWS.z);
                        break;
                    default:
                        _Min = new Vector3();
                        _Max = new Vector3();
                        Debug.LogWarning("Invalid State for 1 Point");
                        break;
                }

                AreaOfIntreseting = Box.CreateBox(_Min, _Max, Vector3.zero);
            }

            public void Reset()
            {
                SrcTexture3D = null;
                TileIndex = 0;
                RingBufferCornerPositionType = ECORNER_TYPE._INVALID;
            }

            public static void OnReturnWork(Work3D aWork)
            {
                aWork.Reset();
            }
        }

        protected void ExtractWork3DFrom(ref Box aShrinkedBox, in List<Work3D> aOutput)
        {
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_LEFT_UP, aOutput);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_RIGHT_UP, aOutput);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_LEFT_UP, aOutput);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_RIGHT_UP, aOutput);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_LEFT_DOWN, aOutput);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_RIGHT_DOWN, aOutput);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_LEFT_DOWN, aOutput);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_RIGHT_DOWN, aOutput);
        }

        /// <summary>
        /// 创建一个Work3D实例，里面存放有一个Buffer边界顶点和相关信息以供后续计算使用
        /// </summary>
        /// <param name="aShrinkedBox">很重要的一点，用于获取TileIndex的Box，必须经过有值的Epsilon修正</param>
        /// <param name="aCorner">Buffer的边界顶点类型</param>
        /// <param name="aOutput">输出结果</param>
        protected void CreateWork3D(ref Box aShrinkedBox, ECORNER_TYPE aCorner, in List<Work3D> aOutput)
        {
            var _work = mPool.Get();
            _work.Epsilon = this.Epsilon;
            _work.RingBufferCornerPositionType = aCorner;
            _work.CornerPositionWS = ConvertBoxCornerToPosition(ref aShrinkedBox, aCorner);
            _work.TileIndex = mTileMgr.GetTileIndexFromOnePointInWorldSpace(_work.CornerPositionWS);
            var bounding = mTileMgr.GetBoundingBoxOfGivenTileIndex(_work.TileIndex);
            _work.SrcBoxWorldSpace = Box.Convert2Box(bounding, Vector3.zero); //clean box(not shrinked)

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
            }, _work.TileIndex);

            aOutput.Add(_work);
        }

        protected Vector3 ConvertBoxCornerToPosition(ref Box aBox, ECORNER_TYPE aCorner)
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