using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.VFX;
using UnityEngine.VFX.SDF;

public class BakeTool : EditorWindow
{
    [MenuItem("Tools/BakeSDF")]
    private static void OnCreateWindow()
    {
        var window = EditorWindow.GetWindow<BakeTool>();
        window.titleContent = new GUIContent("Bake SDF Batch");
        window.position = new Rect(500, 300, 620, 300);
        window.Show();
    }

    private void OnGUI()
    {
        HandleOnGUI();
    }

    private void OnDestroy()
    {
        ReleaseBaker();
    }

    private void ReleaseBaker()
    {
        publicBaker?.Dispose();
        publicBaker = null;
    }

    public GameObject SDFTargetPrefab;
    public Transform CenterTrans;
    public Vector2Int Extent;
    public string OutPath;

    private MeshToSDFBaker publicBaker;

    private void HandleOnGUI()
    {
        EditorGUILayout.BeginVertical();
        var scene = EditorGUILayout.ObjectField("Scene Prefab", SDFTargetPrefab, typeof(GameObject), false) as GameObject;//待烘焙场景
        if (scene != null) SDFTargetPrefab = scene;
        GUILayout.Space(5);
        var center = EditorGUILayout.ObjectField("Bake Center", CenterTrans, typeof(Transform), false) as Transform;//烘焙中心点和半径
        if (center != null) CenterTrans = center;
        GUILayout.Space(5);
        var extent = EditorGUILayout.Vector2IntField("Extents XY", Extent);//X和Z轴方向重复次数
        if (extent != null) Extent = extent;
        GUILayout.Space(5);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.TextField(OutPath, GUILayout.Width(500));
        GUILayout.FlexibleSpace();
        if (GUILayout.Button("Browser...", GUILayout.Width(100)))
        {
            OutPath = EditorUtility.OpenFolderPanel("Select an output path", OutPath, "");
            OutPath = GetAssetPathByFullName(OutPath);
        }
        EditorGUILayout.EndHorizontal();
        GUILayout.Space(20);
        EditorGUILayout.EndVertical();

        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        if (GUILayout.Button("Bake", GUILayout.Width(100))
            && scene != null && center != null)
        {
            
            DoBake(scene, center, extent);
        }
        EditorGUILayout.EndHorizontal();

    }

    private void DoBake(GameObject scene, Transform center, Vector2Int ext)
    {
        var mrs = scene.GetComponentsInChildren<MeshFilter>();
        List<Mesh> allMeshs = new List<Mesh>();
        List<Matrix4x4> allTrans = new List<Matrix4x4>();
        foreach (var m in mrs)
        {
            allMeshs.Add(m.sharedMesh);
            allTrans.Add(m.gameObject.transform.localToWorldMatrix);
        }

        Vector3 size = center.localScale;
        Vector3 baseCenter = center.position;

        Debug.Log($"Start Bake! Size = {size}, BaseCenterPosition = {baseCenter}");

        for (int z = -ext.y; z <= ext.y; ++z)
        {
            for (int x = -ext.x; x <= ext.x; ++x)
            {
                Vector3 currentCenter = baseCenter + new Vector3(x * size.x, 0, z * size.z);

                if (publicBaker != null)
                {
                    publicBaker.Reinit(size, currentCenter, 128, allMeshs, allTrans);
                }
                else
                {
                    publicBaker = new MeshToSDFBaker(size, currentCenter, 128, allMeshs, allTrans);
                }

                publicBaker.BakeSDF();

                var name = GetAssetName(size.x, currentCenter);

                Debug.Log($"Handle:{name}");

                publicBaker.SaveToAsset("", $"{OutPath}/{name}.asset");
            }
        }

    }

    private string GetAssetName(float Size, Vector3 Center)
    {
        return string.Format($"{(int)Center.x}_{(int)Center.y}_{(int)Center.z}_{Size}");
    }

    private string GetAssetPathByFullName(string fullName)
    {
        fullName = fullName.Replace("\\", "/");
        var dataPath_prefix = Application.dataPath.Replace("Assets", "");
        dataPath_prefix = dataPath_prefix.Replace(dataPath_prefix + "/", "");
        var mi_path = fullName.Replace(dataPath_prefix, "");
        return mi_path;
    }

    Texture3D Convert2Tex3D(RenderTexture rt)
    {
        Texture3D tex = new Texture3D(rt.width, rt.height, rt.depth, TextureFormat.RFloat, false);
        tex.filterMode = FilterMode.Point;
        tex.wrapMode = TextureWrapMode.Clamp;
        RenderTexture.active = rt;
        //todo...
        return tex;
    }

}
