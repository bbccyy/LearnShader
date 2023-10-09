using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.UI;

public class Feature_SSR : ScriptableRendererFeature
{
    class SSRPass : ScriptableRenderPass
    {

        RTHandle ssr;
        private GraphicsFormat ssr_fmt;
        private string ssr_name;
        private RenderTargetIdentifier ssr_target_id;
        private RTHandle source;
        Material ssr_mat;
        static MaterialPropertyBlock ssr_PropertyBlock = new MaterialPropertyBlock();
        private ProfilingSampler ssr_profile_sampler;

        public SSRPass(string name, Material mat)
        {
            ssr_name = name;
            ssr_mat = mat;
            ssr_fmt = GraphicsFormat.B8G8R8A8_UNorm;
            ssr_target_id = Shader.PropertyToID(ssr_name);
            ssr = RTHandles.Alloc(ssr_target_id);

            ssr_profile_sampler = new ProfilingSampler("ShadowUE");

            ssr_PropertyBlock.SetFloat(Shader.PropertyToID("_BlitMipLevel"), 0);
            ssr_PropertyBlock.SetVector(Shader.PropertyToID("_BlitScaleBias"), Vector2.one);
        }


        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);

            var rtDesc = cameraTextureDescriptor;
            rtDesc.msaaSamples = 1;
            rtDesc.depthBufferBits = 0;
            rtDesc.stencilFormat = GraphicsFormat.None;
            rtDesc.graphicsFormat = ssr_fmt;
            RenderingUtils.ReAllocateIfNeeded(ref ssr, rtDesc, FilterMode.Point, TextureWrapMode.Clamp, name: ssr_name);
        }


        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            //source = renderingData.cameraData.renderer.cameraColorTargetHandle;
            if (ssr.rt == null)
            {
                var desc = renderingData.cameraData.cameraTargetDescriptor;
                desc.msaaSamples = 1;
                desc.depthBufferBits = 0;
                desc.stencilFormat = GraphicsFormat.None;
                desc.graphicsFormat = ssr_fmt;
                cmd.GetTemporaryRT(Shader.PropertyToID(ssr_name), desc, FilterMode.Point);
            }

            cmd.SetGlobalTexture(ssr.name, ssr.nameID);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(ssr_profile_sampler.name);
            cmd.Clear();

            {
                //Blitter.BlitCameraTexture(cmd, source, ssr, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, ssr_mat, 0);
                cmd.SetRenderTarget(ssr, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                cmd.DrawProcedural(Matrix4x4.identity, ssr_mat, 0, MeshTopology.Triangles, 3, 1, ssr_PropertyBlock);

                context.ExecuteCommandBuffer(cmd);
                cmd.EndSample(ssr_profile_sampler.name);
            }
            
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    SSRPass m_ScriptablePass;

    public string ssr_rt_name = "_SSR";
    public string ssr_shader = "Custom/SSR";
    public Texture2D ssr_tex;
    private Material ssr_mat;

    /// <inheritdoc/>
    public override void Create()
    {
        ssr_mat = CoreUtils.CreateEngineMaterial(Shader.Find(ssr_shader));
        if (ssr_tex != null)
        {
            ssr_mat.SetTexture(Shader.PropertyToID("_Tex"), ssr_tex);
        }


        m_ScriptablePass = new SSRPass(ssr_rt_name, ssr_mat);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingGbuffer;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


