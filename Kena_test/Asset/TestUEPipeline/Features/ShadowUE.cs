using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ShadowUE : ScriptableRendererFeature
{
    class ShadowUEPass : ScriptableRenderPass
    {

        RTHandle shadowUE;
        private GraphicsFormat shadowUE_fmt;
        private string shadowUE_name;
        private RenderTargetIdentifier shadowUE_target_id;
        private RTHandle source;
        Material shadowUE_mat;
        static MaterialPropertyBlock shadow_PropertyBlock = new MaterialPropertyBlock();
        private ProfilingSampler shadow_profile_sampler;

        public ShadowUEPass(string name, Material mat, bool use_default_tex)
        {
            shadowUE_name = name;
            shadowUE_mat = mat;
            if (use_default_tex)
            {
                shadowUE_mat.EnableKeyword("USE_DEFAULT_TEX");
            }
            else
            {
                shadowUE_mat.DisableKeyword("USE_DEFAULT_TEX");
            }
            shadowUE_fmt = GraphicsFormat.B8G8R8A8_UNorm;
            shadowUE_target_id = Shader.PropertyToID(shadowUE_name);
            shadowUE = RTHandles.Alloc(shadowUE_target_id);

            shadow_profile_sampler = new ProfilingSampler("ShadowUE");

            shadow_PropertyBlock.SetFloat(Shader.PropertyToID("_BlitMipLevel"), 0);
            shadow_PropertyBlock.SetVector(Shader.PropertyToID("_BlitScaleBias"), Vector2.one);
        }


        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);

            var rtDesc = cameraTextureDescriptor;
            rtDesc.msaaSamples = 1;
            rtDesc.depthBufferBits = 0;
            rtDesc.stencilFormat = GraphicsFormat.None;
            rtDesc.graphicsFormat = shadowUE_fmt;
            RenderingUtils.ReAllocateIfNeeded(ref shadowUE, rtDesc, FilterMode.Point, TextureWrapMode.Clamp, name: shadowUE_name);
        }


        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            //source = renderingData.cameraData.renderer.cameraColorTargetHandle;
            if (shadowUE.rt == null)
            {
                var desc = renderingData.cameraData.cameraTargetDescriptor;
                desc.msaaSamples = 1;
                desc.depthBufferBits = 0;
                desc.stencilFormat = GraphicsFormat.None;
                desc.graphicsFormat = shadowUE_fmt;
                cmd.GetTemporaryRT(Shader.PropertyToID(shadowUE_name), desc, FilterMode.Point);
            }

            cmd.SetGlobalTexture(shadowUE.name, shadowUE.nameID);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(shadow_profile_sampler.name);
            cmd.Clear();

            {
                //Blitter.BlitCameraTexture(cmd, source, shadowUE, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, shadowUE_mat, 0);

                cmd.SetRenderTarget(shadowUE, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                cmd.DrawProcedural(Matrix4x4.identity, shadowUE_mat, 0, MeshTopology.Triangles, 3, 1, shadow_PropertyBlock);

                context.ExecuteCommandBuffer(cmd);
                cmd.EndSample(shadow_profile_sampler.name);
            }

            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    ShadowUEPass m_ScriptablePass;

    public string shadowUE_rt_name = "_ShadowTex";
    public string shadowUE_shader = "Custom/ShadowUE";
    public bool use_default_texture = false;
    public Texture2D shadowUE_tex;
    private Material shadowUE_mat;

    /// <inheritdoc/>
    public override void Create()
    {
        shadowUE_mat = CoreUtils.CreateEngineMaterial(Shader.Find(shadowUE_shader));
        if (shadowUE_tex != null)
        {
            shadowUE_mat.SetTexture(Shader.PropertyToID("_Tex"), shadowUE_tex);
        }


        m_ScriptablePass = new ShadowUEPass(shadowUE_rt_name, shadowUE_mat, use_default_texture);

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


