using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class makeCameraMove : MonoBehaviour
{
    private Camera cam;

    public Vector3 deltaPos = new Vector3(0.1f, 0.1f, 0.1f);
    public Vector3 deltaRot = new Vector3(0.1f, 0.1f, 0.1f);

    // Start is called before the first frame update
    void Start()
    {
        cam = gameObject.GetComponent<Camera>();
    
    }

    // Update is called once per frame
    void Update()
    {
        var oldPos = cam.transform.position;
        var oldRot = cam.transform.rotation.eulerAngles;
        var oldRotQ = cam.transform.rotation;
        oldRotQ.eulerAngles = oldRot - deltaRot;

        cam.transform.position = oldPos - deltaPos;
        cam.transform.rotation = oldRotQ;
    }
}
