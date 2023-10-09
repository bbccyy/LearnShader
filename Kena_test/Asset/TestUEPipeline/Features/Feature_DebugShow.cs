using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Rendering.RuntimeTools.RingBuffer;



public class DebugShow : ScriptableRenderPass
{

    public Material mBlitMat;  //通过置空这个对象来切换显示bentNorm与否

    //public Texture3D mTexture;

    public Transform mMoveable;

    private TestTileManager tileMgr;

    private TestSourceProvider srcProvider;

    private ComputeShader cs;

    private RingBufferBase ringbuffer;

    public DebugShow(Material aBlitMat, ComputeShader aCs)
    {
        this.mBlitMat = aBlitMat;

        this.cs = aCs; 

        //mTexture = Resources.Load<Texture3D>("SDF/-5_35_-32_50");
        //if (mTexture != null)
        //{
        //    Debug.Log($"Name of tex3d is {mTexture.name}, is readable = {mTexture.isReadable}"); //TODO: isReadable==false 
        //}

        //todo init tile mgr and src provider
        Bounds bakeOrigBounds = new Bounds(new Vector3(-5, 35, -32), new Vector3(50, 50, 50));
        tileMgr = new TestTileManager(bakeOrigBounds);
        srcProvider = new TestSourceProvider();

        ringbuffer = new RingBufferBase(srcProvider, tileMgr, cs);
        Bounds baselineBounds = new Bounds(new Vector3(-5, 35, -32), new Vector3(50, 50, 50));
        Vector3 delta = new Vector3(10, 5, -20);
        Vector3 desiredPostion = baselineBounds.center + delta;
        if (SingletonObj.Instance.obj != null)
        {
            desiredPostion = SingletonObj.Instance.obj.transform.position;
        }

        ringbuffer.Init(baselineBounds, desiredPostion, new Vector3Int(1, 1, 1), new Vector3(128, 128, 128));

    }

    private static readonly ProfilingSampler MyDebugSampler = new ProfilingSampler("MyDebugSampler");
    private static readonly ProfilingSampler TestRingBufferSampler = new ProfilingSampler("TestRingBufferSampler");

    RTHandle m_CameraColorTarget;
    RTHandle m_IntermediaRT;
    public void SetTarget(RTHandle colorHandle)
    {
        m_CameraColorTarget = colorHandle;

        var desc = colorHandle.rt.descriptor;
        desc.width /= 4;
        desc.height /= 4;
        RenderingUtils.ReAllocateIfNeeded(ref m_IntermediaRT, desc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "intermedia");

    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        base.OnCameraSetup(cmd, ref renderingData);
        ConfigureTarget(m_CameraColorTarget);
        srcProvider.UpdateMockDelay();
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get();
        cmd.Clear();


        if (SingletonObj.Instance.obj != null)
        {
            Vector3 desiredPostion = SingletonObj.Instance.obj.transform.position;
            //Debug.Log("Set pos to ringbuffer");
            ringbuffer.Setup(desiredPostion);
        }


        //Execute
        using (new ProfilingScope(cmd, TestRingBufferSampler))
        {
            ringbuffer.Execute(cmd);
            //ringbuffer.TestRenderEveryFrame(cmd);
        }


        var bentNormal = Shader.GetGlobalTexture("_BentNorm");

        using (new ProfilingScope(cmd, MyDebugSampler))
        {
            if (mBlitMat == null)
            {
                cmd.Blit(bentNormal, m_CameraColorTarget);
            }
            else
            {

                cmd.SetGlobalTexture(Shader.PropertyToID("_SDF"), ringbuffer.GetRingBuffer());
                cmd.SetGlobalVector(Shader.PropertyToID("_AABB_SIZE"), new Vector3(50,50,50));
                cmd.SetGlobalVector(Shader.PropertyToID("_AABB_MIN"), new Vector3(0,0,0));
                cmd.SetGlobalVector(Shader.PropertyToID("_uvw_delta"), ringbuffer.GetUVW());
                cmd.Blit(null, m_IntermediaRT, mBlitMat, 0);
                cmd.Blit(m_IntermediaRT, m_CameraColorTarget);
            }
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public void OnDispose()
    {
        m_IntermediaRT?.Release();
        m_IntermediaRT = null;
        m_CameraColorTarget = null;

        ringbuffer?.OnDestroy();
        tileMgr?.OnDestroy();
        srcProvider?.OnDestroy();
    }
}

public class Feature_DebugShow : ScriptableRendererFeature
{
    DebugShow ds;

    public Material BlitMat;

    public ComputeShader cs;

    public bool Enable;
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (Enable)
            renderer.EnqueuePass(ds);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        base.SetupRenderPasses(renderer, renderingData);
        ds.SetTarget(renderer.cameraColorTargetHandle);
        ds.ConfigureInput(ScriptableRenderPassInput.Color);
    }

    public override void Create()
    {
        ds = new DebugShow(BlitMat, cs);
        ds.renderPassEvent = RenderPassEvent.AfterRenderingSkybox; 
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        ds?.OnDispose();
    }
}
