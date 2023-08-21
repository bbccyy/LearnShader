using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
using static TMPro.SpriteAssetUtilities.TexturePacker_JsonArray;

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
        public static readonly int MinimumPixelGroupSize = 8;

        //private Transform m_followee;       //������buffer���ĵ�����
        private Vector3 mRingBufferAABBExtension;       //Buffer��Ӧ���������ά����ߵ�һ��

        private Vector3 mRingBufferAABBSize;            //Buffer��Ӧ���������ά�����

        private Vector3 mRingBufferTextureSize;         //Texture3D pixel resolution

        private Vector3 mRingBufferAABBCenterPosition;  //Buffer���������ĵ�����(����ռ�)

        private Vector3 mDesiredBufferAABBCenterPosition;       //ÿ֡���µ�����λ��
        
        private Vector3 mOnWorkingBufferAABBCenterPosition;     //���ڴ����е�λ��

        private ERING_BUFFER_EXEC_STATE State;

        private ISourceProvider mSourceProvider;

        private ITileManager mTileMgr;

        private Vector3Int mMinimumCopyDeltaMultiply;  //��С���˳ߴ�,λ��С���������ֵ���ᴥ��Buffer����

        private Vector3 mMinimumCopyDeltaSize;

        private int AsyncLoadingCounter = 0;

        private Texture3D dummy;

        private Vector3 Epsilon;                          //����0.5��pixel������ռ��еĳ߶�

        public RingBufferBase(ISourceProvider aSourceProvider, ITileManager aTileMgr)
        {
            this.mSourceProvider = aSourceProvider;
            this.mTileMgr = aTileMgr;
            dummy = new Texture3D(1,1,1, TextureFormat.RFloat, false);
            dummy.SetPixel(0, 0, 0, Color.white);
            State = ERING_BUFFER_EXEC_STATE.InValid;
        }

        /// <summary>
        /// ��ʼ��RingBuffer
        /// </summary>
        /// <param name="aExtention">������ռ�����Buffer��������AABB��Χ�еİ�߳�</param>
        /// <param name="aCenterPos">��Χ������λ��</param>
        /// <param name="aMinCopyDeltaMultiply">֧�ֿ����Ͱ��˵���С���سߴ磬�����С�ڸóߴ�ʱ������Buffer�ĸ���</param>
        /// <param name="aBufferTexSize">Buffer��ӦTexture3D��width��height��depth</param>
        public void Init(Vector3 aExtention, Vector3 aCenterPos, Vector3Int aMinCopyDeltaMultiply, Vector3 aBufferTexSize)
        {
            mRingBufferAABBCenterPosition.Set(
                Mathf.Floor(aCenterPos.x),
                Mathf.Floor(aCenterPos.y),
                Mathf.Floor(aCenterPos.z)
                );
            mRingBufferAABBExtension = aExtention;
            mRingBufferAABBSize = mRingBufferAABBExtension * 2;
            mRingBufferTextureSize = aBufferTexSize;
            mMinimumCopyDeltaMultiply = aMinCopyDeltaMultiply;

            Epsilon = aExtention;
            Epsilon.Set(
                Epsilon.x / aBufferTexSize.x,
                Epsilon.y / aBufferTexSize.y,
                Epsilon.z / aBufferTexSize.z);

            mMinimumCopyDeltaSize = mMinimumCopyDeltaMultiply * MinimumPixelGroupSize;
            mMinimumCopyDeltaSize.x *= (Epsilon.x * 2);
            mMinimumCopyDeltaSize.y *= (Epsilon.y * 2);
            mMinimumCopyDeltaSize.z *= (Epsilon.z * 2);

            mPool = new ObjectPool<Work3D>(null, Work3D.OnReturnWork);

            State = ERING_BUFFER_EXEC_STATE.Init;
        }

        public void Setup(Vector3 aDesiredTargetCenter)
        {
            mDesiredBufferAABBCenterPosition = aDesiredTargetCenter;
            State |= ERING_BUFFER_EXEC_STATE.IsDirty;
        }

        public void Execute(CommandBuffer cmd = null)
        {
            if (State == ERING_BUFFER_EXEC_STATE.InValid || 
                State == ERING_BUFFER_EXEC_STATE.Normal)
                return;

            EBUILD_STRATEGY strategy = EBUILD_STRATEGY.INVALID;

            switch (State)
            {
                case ERING_BUFFER_EXEC_STATE.Init:
                    strategy = EBUILD_STRATEGY.PREPARE_FROM_GROUND;
                    break;
                case ERING_BUFFER_EXEC_STATE.IsDirty:
                    strategy = ConsideOnDistanceChange(ref mRingBufferAABBCenterPosition, ref mDesiredBufferAABBCenterPosition);
                    if (strategy == EBUILD_STRATEGY.DO_NOT_BUILD)
                    {
                        SubtractState(ERING_BUFFER_EXEC_STATE.IsDirty);  //��ǰ��Dirty����ִ��
                    }
                    break;
                case ERING_BUFFER_EXEC_STATE.Init | ERING_BUFFER_EXEC_STATE.IsDirty:
                    strategy = EBUILD_STRATEGY.PREPARE_FROM_GROUND;
                    break;
                case ERING_BUFFER_EXEC_STATE.Loading:
                    strategy = EBUILD_STRATEGY.DO_NOT_BUILD;
                    if (AsyncLoadingCounter == 0)
                    {
                        State = ERING_BUFFER_EXEC_STATE.Process;
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
                                SubtractState(ERING_BUFFER_EXEC_STATE.IsDirty); //��ǰ��Dirty����ִ�У�������һ��PrepareWork3D�ĺ����߼�
                                strategy = EBUILD_STRATEGY.DO_BUILD;
                            }
                            else
                            {
                                DumpWork3D(); //������һ��PrepareWork3D�Ľ��ȣ�ֱ�ӿ�����һ��Prepare
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
                    PrepareWork3D(strategy);
                    break;
                case EBUILD_STRATEGY.DO_BUILD:
                    TryProcessWork3D();
                    break;
                case EBUILD_STRATEGY.DO_NOT_BUILD:
                    break;
                default:
                    break;
            }

        }

        //��Ϊ��ʼ����Ҫ����λ���������� -> ����(����)׼��Work3D
        private void PrepareWork3D(EBUILD_STRATEGY aStrategy)
        {
            mOnWorkingBufferAABBCenterPosition = mDesiredBufferAABBCenterPosition;
            SubtractState(ERING_BUFFER_EXEC_STATE.IsDirty);

        }

        //ÿ�����PrepareWork3D��ִ��һ��
        private void PostWork3D()
        {

        }

        //Load��ɺ���Work3Dû�й��� -> ִ�б�����
        private void TryProcessWork3D()
        {

        }

        //��Work3D���ڣ�����ִ����Ϻ�ִ�б�����
        private void DumpWork3D()
        {
            
        }

        private void SubtractState(ERING_BUFFER_EXEC_STATE aState)
        {
            State &= (~aState);
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

            //8���㶼��Box�У���ӦΨһ����� -> Box ��ͬ����8����
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

            //4������Box�У���Ӧ6�в�ͬ���
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

            //2������Box�У���Ӧ12�ֲ�ͬ���
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

            //ֻ��1������Box�У���Ӧ8�в�ͬ�����
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

        protected List<Work3D> ExtractWork3DFrom(ref Box aShrinkedBox)
        {
            List<Work3D> output = new List<Work3D>();
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_LEFT_UP, output);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_RIGHT_UP, output);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_LEFT_UP, output);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_RIGHT_UP, output);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_LEFT_DOWN, output);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.FRONT_RIGHT_DOWN, output);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_LEFT_DOWN, output);
            CreateWork3D(ref aShrinkedBox, ECORNER_TYPE.BACK_RIGHT_DOWN, output);

            return output;
        }

        /// <summary>
        /// ����һ��Work3Dʵ������������Buffer�߽綥��������Ϣ�Թ���������ʹ��
        /// </summary>
        /// <param name="aShrinkedBox">����Ҫ��һ�㣬���ڻ�ȡTileIndex��Box�����뾭����ֵ��Epsilon����</param>
        /// <param name="aCorner">Buffer�ı߽綥������</param>
        /// <param name="aOutput">������</param>
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