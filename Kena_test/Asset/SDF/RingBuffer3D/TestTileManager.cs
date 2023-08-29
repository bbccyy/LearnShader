using Rendering.RuntimeTools.RingBuffer;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestTileManager : ITileManager
{

    public string BasePath = "SDF/";

    public Bounds BaseBound;

    private Vector3 AABBSize;

    private Dictionary<int, Vector3Int> TileTable = new Dictionary<int, Vector3Int>();

    public TestTileManager(Bounds aBaseBound, string aBasePath)
    {
        BaseBound = aBaseBound;
        if (!string.IsNullOrEmpty(aBasePath))
            BasePath = aBasePath;

        AABBSize.Set(
            BaseBound.extents.x * 2,
            BaseBound.extents.y * 2,
            BaseBound.extents.z * 2);
    }


    public void OnDestroy()
    {
        TileTable.Clear();
    }


    public string ConvertIndexXYZ2AssetName(Vector3Int aIndexXYZ)
    {
        Vector3 center = new Vector3();
        center.x = aIndexXYZ.x * AABBSize.x + BaseBound.extents.x;
        center.y = aIndexXYZ.y * AABBSize.y + BaseBound.extents.y;
        center.z = aIndexXYZ.z * AABBSize.z + BaseBound.extents.z;

        return string.Format($"{(int)center.x}_{(int)center.y}_{(int)center.z}_{(int)AABBSize.x}");
    }

    public Vector3Int ConvertPosWS2IndexXYZ(Vector3 aPosWS)
    {
        Vector3Int idx3 = new Vector3Int();

        var localPos = aPosWS - BaseBound.min;

        idx3.Set(
            Mathf.FloorToInt(localPos.x / AABBSize.x),
            Mathf.FloorToInt(localPos.y / AABBSize.y),
            Mathf.FloorToInt(localPos.z / AABBSize.z));  //无需转换为向0取整，保持向下取整是正确的

        return idx3;
    }


    public int ConvertIndexXYZ2Index(Vector3Int aIndexXYZ)
    {
        int key = aIndexXYZ.GetHashCode();
        if (!TileTable.ContainsKey(key))
        {
            TileTable.Add(key, aIndexXYZ);
        }
        return key;
    }

    public string GetAssetPathFromTileIndex(int aTileIndex)
    {
        if (TileTable.ContainsKey(aTileIndex))
        {
            return BasePath + ConvertIndexXYZ2AssetName(TileTable[aTileIndex]);
        }
        else
        {
            return null;
        }
    }

    public Bounds GetBoundingBoxOfGivenTileIndex(int aTileIndex)
    {
        if (TileTable.ContainsKey(aTileIndex))
        {
            var IndexXYZ = TileTable[aTileIndex];
            Vector3 center = new Vector3();
            center.x = IndexXYZ.x * AABBSize.x + BaseBound.extents.x;
            center.y = IndexXYZ.y * AABBSize.y + BaseBound.extents.y;
            center.z = IndexXYZ.z * AABBSize.z + BaseBound.extents.z;
            return new Bounds(center, AABBSize); ;
        }
        else
        {
            Debug.LogError("Invalid Input TileIndex");
            return new Bounds();
        }
    }

    public int GetTileIndexFromOnePointInWorldSpace(Vector3 aPosWS)
    {
        return ConvertIndexXYZ2Index(ConvertPosWS2IndexXYZ(aPosWS));
    }

}
