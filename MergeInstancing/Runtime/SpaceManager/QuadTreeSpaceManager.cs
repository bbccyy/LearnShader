using UnityEngine;

namespace Unity.MergeInstancingSystem.SpaceManager
{
    public class QuadTreeSpaceManager : ISpaceManager
    {
        private float preRelative;
        /// <summary>
        /// 根节点下相机的空间
        /// </summary>
        private Vector3 camPosition;
        public QuadTreeSpaceManager()
        {
        }
        /// <summary>
        /// 将相机转到根节点所在的空间中
        /// </summary>
        /// <param name="hlodTransform"></param>
        /// <param name="cam"></param>
        public void UpdateCamera(Transform hlodTransform, Camera cam)
        {
            if (cam.orthographic)
            {
                preRelative = 0.5f / cam.orthographicSize;
            }
            else
            {
                float halfAngle = Mathf.Tan(Mathf.Deg2Rad * cam.fieldOfView * 0.5F);
                preRelative = 0.5f / halfAngle;
            }
            preRelative = preRelative * QualitySettings.lodBias;
            camPosition = hlodTransform.worldToLocalMatrix.MultiplyPoint(cam.transform.position);
        }
        /// <summary>
        /// 判断是否为高等级显示
        /// </summary>
        /// <param name="lodDistance"></param>
        /// <param name="bounds"></param>
        /// <returns></returns>
        public bool IsHigh(float lodDistance, Bounds bounds)
        {
            //float distance = 1.0f;
            //if (cam.orthographic == false)
            
            float distance = GetDistance(bounds.center, camPosition);
            float relativeHeight = bounds.size.x * preRelative / distance;
            return relativeHeight > lodDistance;
        }
        /// <summary>
        /// 计算包围盒中心与相机的距离的平方
        /// </summary>
        /// <param name="bounds"></param>
        /// <returns></returns>
        public float GetDistanceSqure(Bounds bounds)
        {
            float x = bounds.center.x - camPosition.x;
            float z = bounds.center.z - camPosition.z;

            float square = x * x + z * z;
            return square;
        }
        /// <summary>
        /// 判断当前包围盒应不应该被剔除，包围盒距离相机有多远为依据，足够远就会被剔除
        /// </summary>
        /// <param name="cullDistance">小于这个值就会被剔除</param>
        /// <param name="bounds"></param>
        /// <returns></returns>
        public bool IsCull(float cullDistance, Bounds bounds)
        {
            float distance = GetDistance(bounds.center, camPosition);
            //bound.size是包围盒的长宽高，包围盒是个立方体
            // preRelative 是 视锥体一半的 0.5/tanΘ。
            // bounds.size.x * preRelative = y * 0.5 / tanΘ * bais
            //bais越大，越不容易被剔除。
            float relativeHeight = bounds.size.x * preRelative / distance;
            return relativeHeight < cullDistance;
        }
        /// <summary>
        /// 获取两个点的距离,只在XZ平面判断
        /// </summary>
        /// <param name="boundsPos"></param>
        /// <param name="camPos"></param>
        /// <returns></returns>
        private float GetDistance(Vector3 boundsPos, Vector3 camPos)
        {
            float x = boundsPos.x - camPos.x;
            float z = boundsPos.z - camPos.z;
            float square = x * x + z * z;
            return Mathf.Sqrt(square);
        }
    }
}