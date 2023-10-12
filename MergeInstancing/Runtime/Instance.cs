﻿using System;
using System.Collections.Generic;
using UnityEngine;
using Object = UnityEngine.Object;
using Unity.MergeInstancingSystem.Controller;
namespace Unity.MergeInstancingSystem
{
    public class Instance : MonoBehaviour, ISerializationCallbackReceiver, IGeneratedResourceManager
    {
        public const string InstanceLayerStr = "MegreInstance";
        // ---------------- Build Setting ----------------------------------
        [SerializeField]
        private float m_ChunkSize = 30.0f;

        [SerializeField] 
        private bool m_UseMotionvector = false;
        
        [SerializeField]
        private float m_LODDistance = 0.3f;
        
        [SerializeField]
        private float m_CullDistance = 0.01f;
        
        [SerializeField]
        private float m_MinObjectSize = 0.0f;
        //----------------- 接口 --------------------------------------------
        [SerializeField]
        private string m_SpaceSplitterTypeStr;
        [SerializeField]
        private string m_MeshUtilsTypeStr;
        [SerializeField]
        private string m_BuildingTypeStr;
        
        private Type m_SpaceSplitterType;
        
        private Type m_MeshUtilsType;

        private Type m_BuildingType;
        
        

        [SerializeField]
        private SerializableDynamicObject m_SpaceSplitterOptions = new SerializableDynamicObject();
        
        [SerializeField]
        private SerializableDynamicObject m_MeshUtilsOptions = new SerializableDynamicObject();

        [SerializeField] 
        private SerializableDynamicObject m_BuildOptions = new SerializableDynamicObject();
        
        [SerializeField]
        private List<Object> m_generatedObjects = new List<Object>();
        
        [SerializeField]
        private List<GameObject> m_convertedPrefabObjects = new List<GameObject>();

        [SerializeField]
        public List<MeshRenderer> m_DisAbleComponent = new List<MeshRenderer>();
        
        [SerializeField]
        public List<GameObject> m_DestoryOBJ = new List<GameObject>();
        
        [SerializeField]
        public List<Mesh> m_DestoryMesh = new List<Mesh>();
        public float MinObjectSize
        {
            set { m_MinObjectSize = value; }
            get { return m_MinObjectSize; }
        }
        
        public float ChunkSize
        {
            get { return m_ChunkSize; }
        }

        public bool USEMOTIONVECTOR
        {
            get
            {
                return m_UseMotionvector;
            }
        }
        public float LODDistance
        {
            get { return m_LODDistance; }
        }
        
        public float CullDistance
        {
            set { m_CullDistance = value; }
            get { return m_CullDistance; }
        }
        
        
        public Type SpaceSplitterType
        {
            set { m_SpaceSplitterType = value; }
            get { return m_SpaceSplitterType; }
        }
        
        
        public Type MeshUtilsType
        {
            set { m_MeshUtilsType = value; }
            get { return m_MeshUtilsType; }
        }
        
        
        public Type BuildType
        {
            set { m_BuildingType = value; }
            get { return m_BuildingType; }
        }
        
        public SerializableDynamicObject SpaceSplitterOptions
        {
            get { return m_SpaceSplitterOptions; }
        }
        
        public SerializableDynamicObject MeshUtilsOptions
        {
            get { return m_MeshUtilsOptions; }
        }

        public SerializableDynamicObject BuildOptions
        {
            get { return m_BuildOptions; }
        }
        
        /// <summary>
        /// 在Instance对象被序列化之前调用
        /// </summary>
        public void OnBeforeSerialize()
        {
            //返回Type的命名空间和类名等属性
            if (m_SpaceSplitterType != null)
                m_SpaceSplitterTypeStr = m_SpaceSplitterType.AssemblyQualifiedName;
            if (m_MeshUtilsType != null)
                m_MeshUtilsTypeStr = m_MeshUtilsType.AssemblyQualifiedName;
            if (m_BuildingType != null)
                m_BuildingTypeStr = m_BuildingType.AssemblyQualifiedName;
        }

        /// <summary>
        /// 在对象被序列化之后调用
        /// </summary>
        public void OnAfterDeserialize()
        {
            if (string.IsNullOrEmpty(m_SpaceSplitterTypeStr))
            {
                m_SpaceSplitterType = null;
            }
            else
            {
                m_SpaceSplitterType = Type.GetType(m_SpaceSplitterTypeStr);
            }
            if (string.IsNullOrEmpty(m_MeshUtilsTypeStr))
            {
                m_MeshUtilsType = null;
            }
            else
            {
                m_MeshUtilsType = Type.GetType(m_MeshUtilsTypeStr);
            }
            if (string.IsNullOrEmpty(m_BuildingTypeStr))
            {
                m_BuildingType = null;
            }
            else
            {
                m_BuildingType = Type.GetType(m_BuildingTypeStr);
            }
        }
        
        public void AddGeneratedResource(Object obj)
        {
            m_generatedObjects.Add(obj);
        }

        public bool IsGeneratedResource(Object obj)
        {
            return m_generatedObjects.Contains(obj);
        }
        
        public void AddConvertedPrefabResource(GameObject obj)
        {
            m_convertedPrefabObjects.Add(obj);
        }
#if UNITY_EDITOR
        public List<Object> GeneratedObjects
        {
            get { return m_generatedObjects; }
        }

        public List<GameObject> ConvertedPrefabObjects
        {
            get { return m_convertedPrefabObjects; }
        }
        /// <summary>
        /// 找到HLOD所有ControerBase
        /// </summary>
        /// <returns></returns>
        public List<InstanceControllerBase> GetInstanceControllerBase()
        {
            List<InstanceControllerBase> controllerBases = new List<InstanceControllerBase>();

            foreach (Object obj in m_generatedObjects)
            {
                var controllerBase = obj as InstanceControllerBase;
                if ( controllerBase != null )
                    controllerBases.Add(controllerBase);
            }
            
            //if controller base doesn't exists in the generated objects, it was created from old version.
            //so adding controller base manually.
            if (controllerBases.Count == 0)
            {
                var controller = GetComponent<InstanceControllerBase>();
                if (controller != null)
                {
                    controllerBases.Add(controller);
                }
            }
            return controllerBases;
        }
#endif
        /// <summary>
        /// 以挂载这个脚本的OBJ为世界坐标原点，转换包围盒。
        /// </summary>
        /// <returns></returns>
        public Bounds GetBounds()
        {
            Bounds ret = new Bounds();
            var renderers = GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                ret.center = Vector3.zero;
                ret.size = Vector3.zero;
                return ret;
            }
            Bounds bounds = Utils.BoundsUtils.CalcLocalBounds(renderers[0], transform);
            //扩展包围盒使其包含所有的OBJ
            for (int i = 1; i < renderers.Length; ++i)
            {
                bounds.Encapsulate(Utils.BoundsUtils.CalcLocalBounds(renderers[i], transform));
            }

            ret.center = bounds.center;
            float max = Mathf.Max(bounds.size.x, bounds.size.y, bounds.size.z);
            ret.size = new Vector3(max, max, max);
            return ret;
        }
    }
}