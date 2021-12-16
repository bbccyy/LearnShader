using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[System.Serializable]
public class Setting
{
    public string textureName = "_ScreenGrabTexture";
    public List<string> shaderTagIdList = new List<string>();
    [Range(0, 1)]public float sampleDown = 0.5f;
    public FilterMode filterMode = FilterMode.Point;
    public Setting()
    {
        shaderTagIdList.Add("UniversalForward");
        shaderTagIdList.Add("SRPDefaultUnlit");
    }
}

class BlitPass : ScriptableRenderPass
{
    Setting mSetting;
    RenderTargetIdentifier mSource;
    RenderTargetHandle mRT = RenderTargetHandle.CameraTarget;
    public List<ShaderTagId> shaderTagIdList = new List<ShaderTagId>();
    public BlitPass(Setting setting)
    {
        mSetting = setting;
        mRT.Init(setting.textureName);
        foreach (string tag in setting.shaderTagIdList)
        {
            shaderTagIdList.Add(new ShaderTagId(tag));
        }
    }

    public void Setup(RenderTargetIdentifier source)
    {
        mSource = source;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get("GrabPass");
        RenderTextureDescriptor cameraRTDesc = renderingData.cameraData.cameraTargetDescriptor;
        int width = (int)(cameraRTDesc.width * mSetting.sampleDown);
        int height = (int)(cameraRTDesc.height * mSetting.sampleDown);
        RenderTextureDescriptor desc = new RenderTextureDescriptor(width, height, cameraRTDesc.colorFormat);
        cmd.GetTemporaryRT(mRT.id, desc, mSetting.filterMode);
        cmd.SetGlobalTexture(mSetting.textureName, mRT.Identifier());
        Blit(cmd, mSource, mRT.Identifier());
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
    public override void FrameCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(mRT.id);
    }
}

public class GrabRenderFeature : ScriptableRendererFeature
{
    BlitPass mBlitPass;
    public Setting settings = new Setting();

    public override void Create()
    {
        mBlitPass = new BlitPass(settings);
        mBlitPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        mBlitPass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(mBlitPass);
    }
}