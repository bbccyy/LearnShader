using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[CreateAssetMenu]
public class GammaUIFix : ScriptableRendererFeature
{
    public Material material;
    
	public GammaUIFix()
	{
	}

	public override void Create()
	{
	}

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var cameraColorTarget = renderer.cameraColorTarget;
        var DrawUIIntoRTPass = new DrawUIIntoRTPass(RenderPassEvent.BeforeRenderingTransparents, cameraColorTarget);
        var BlitRenderPassesToScreen = new BlitPass(RenderPassEvent.AfterRenderingTransparents, cameraColorTarget,material);

        renderer.EnqueuePass(DrawUIIntoRTPass);
        renderer.EnqueuePass(BlitRenderPassesToScreen);
    }

    //-------------------------------------------------------------------------

	class DrawUIIntoRTPass : ScriptableRenderPass
	{
        private RenderTargetIdentifier colorHandle;

        //The temporary UI texture
        public static int m_uiRTid = Shader.PropertyToID("_UITexture");
        public static RenderTargetIdentifier m_uiRT = new RenderTargetIdentifier(m_uiRTid);

        public DrawUIIntoRTPass(RenderPassEvent renderPassEvent, RenderTargetIdentifier colorHandle)
        {
            this.colorHandle = colorHandle;
            this.renderPassEvent = renderPassEvent;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescripor)
        {
            RenderTextureDescriptor descriptor = cameraTextureDescripor;
            descriptor.colorFormat = RenderTextureFormat.Default;
            cmd.GetTemporaryRT(m_uiRTid, descriptor);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
			CommandBuffer cmd = CommandBufferPool.Get("Draw UI Into RT Pass");

            cmd.SetRenderTarget(m_uiRT);
            cmd.ClearRenderTarget(true,true,Color.clear);

            context.ExecuteCommandBuffer(cmd);
			CommandBufferPool.Release(cmd);
		}

		public override void FrameCleanup(CommandBuffer cmd)
		{
			if (cmd == null)
				throw new ArgumentNullException("cmd");

			base.FrameCleanup(cmd);
		}
	}

    //-------------------------------------------------------------------------

	class BlitPass : ScriptableRenderPass
	{
        private RenderTargetIdentifier colorHandle;
        Material material;

        public BlitPass(RenderPassEvent renderPassEvent, RenderTargetIdentifier colorHandle, Material mat)
        {
            this.colorHandle = colorHandle;
            this.renderPassEvent = renderPassEvent;
            this.material = mat;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
			CommandBuffer cmd = CommandBufferPool.Get("Blit Pass");
            
            cmd.Blit(DrawUIIntoRTPass.m_uiRT,colorHandle,material);

            context.ExecuteCommandBuffer(cmd);
			CommandBufferPool.Release(cmd);
		}

		public override void FrameCleanup(CommandBuffer cmd)
		{
			if (cmd == null)
				throw new ArgumentNullException("cmd");

            cmd.ReleaseTemporaryRT(DrawUIIntoRTPass.m_uiRTid);

			base.FrameCleanup(cmd);
		}
	}

    //-------------------------------------------------------------------------
}