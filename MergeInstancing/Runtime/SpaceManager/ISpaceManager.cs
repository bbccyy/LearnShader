using UnityEngine;

namespace Unity.MergeInstancingSystem.SpaceManager
{
    public interface ISpaceManager
    {
        void UpdateCamera(Transform instanceTransform, Camera cam);
        bool IsHigh(float lodDistance, Bounds bounds);
        /// <summary>
        /// 判断一个包围盒是否要被剔除
        /// </summary>
        /// <param name="cullDistance"></param>
        /// <param name="bounds"></param>
        /// <returns></returns>
        bool IsCull(float cullDistance, Bounds bounds);
        /// <summary>
        /// 获取两个点的距离的平方，在XZ平面上
        /// </summary>
        /// <param name="bounds"></param>
        /// <returns></returns>
        float GetDistanceSqure(Bounds bounds);
    }
}