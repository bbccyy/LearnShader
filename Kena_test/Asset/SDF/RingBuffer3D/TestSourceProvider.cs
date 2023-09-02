using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Rendering.RuntimeTools.RingBuffer;
using System;
using Random = UnityEngine.Random;

public class TestSourceProvider : ISourceProvider
{
    public class MockLoadingUnit
    {
        public Action<UnityEngine.Object, bool> action;
        public UnityEngine.Object obj;
        public int restTime;

        public bool Due()
        {
            restTime--;
            return restTime < 0;
        }

        public void Fullfill()
        {
            if (action != null)
            {
                action(obj, true);
                action = null;
            }
            obj = null;
        }

        public void Dump()
        {
            action = null;
            GameObject.DestroyImmediate(obj);
        }
    }

    public Dictionary<string, MockLoadingUnit> map;
    private List<string> toBeDump;


    public TestSourceProvider()
    {
        map = new Dictionary<string, MockLoadingUnit>();
        toBeDump = new List<string>();
    }


    public void OnDestroy()
    {
        foreach(var pair in map)
        {
            pair.Value.Dump();
        }
        map.Clear();
    }


    public void UpdateMockDelay()
    {
        foreach (var pair in map)
        {
            if (pair.Value.Due())
            {
                pair.Value.Fullfill();
                toBeDump.Add(pair.Key);
            }
        }

        foreach(var key in toBeDump)
        {
            map.Remove(key);
        }

        toBeDump.Clear();
    }

    public void AyncLoad(Action<UnityEngine.Object, bool> aCallback, string aPath)
    {
        if (string.IsNullOrEmpty(aPath))
        {
            aCallback?.Invoke(null, false);
            return;
        }

        var go = Resources.Load(aPath);
        if (map.ContainsKey(aPath))
        {
            map[aPath].Fullfill();
        }

        var mock = new MockLoadingUnit();
        mock.action = aCallback;
        mock.obj = go;
        mock.restTime = Random.Range(0, 3); //0 ~ 3 frames delay
        map[aPath] = mock;
    }

    public UnityEngine.Object SyncLoad(string aPath)
    {
        return Resources.Load(aPath);
    }

}
