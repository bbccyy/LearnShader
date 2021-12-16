using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public enum LockType
{
    X_AXIS, Y_AXIS, Z_AXIS
}

public class BillBoard : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {

    }

    public LockType mLockAxis = LockType.Y_AXIS;
    // Update is called once per frame
    void Update()
    {
        // Vector3 lookPos = new Vector3(Camera.main.transform.position.x, 0, Camera.main.transform.position.z);
        // this.transform.LookAt(lookPos);

        Vector3 lookDir = Camera.main.transform.position - this.transform.position;

        switch(mLockAxis)
        {
            case LockType.X_AXIS:
                lookDir.x = 0;
                break;
            case LockType.Y_AXIS:
                lookDir.y = 0;
                break;
            case LockType.Z_AXIS:
                lookDir.z = 0;
                break;
        }
        this.transform.rotation = Quaternion.LookRotation(lookDir);
    }

    #if UNITY_EDITOR
        [CustomEditor(typeof(BillBoard))]
        public class BillBoardEditor : Editor
        {
            public override void OnInspectorGUI()
            {
                BillBoard gameObject = target as BillBoard;

                gameObject.mLockAxis = (LockType)EditorGUILayout.EnumPopup(gameObject.mLockAxis, new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(20f)});
            }
        }
    #endif
}

