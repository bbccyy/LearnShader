using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_SSAO : ScriptableRendererFeature
{
    class SSAOPass : ScriptableRenderPass
    {

        RTHandle ssao;
        private bool use_default_tex;
        private GraphicsFormat ssao_format { get; set; }
        private string ssao_name { get; set; }
        private RenderTargetIdentifier id {get;set;}

        private RTHandle source;

        Material ssao_mat;

        static MaterialPropertyBlock ssao_PropertyBlock = new MaterialPropertyBlock();

        static Mesh s_TriangleMesh;  //备用 

        private ProfilingSampler ssao_profile_sampler;

        public SSAOPass(string name, Material mat, bool useDefault)
        {
            use_default_tex = useDefault;
            ssao_name = name;
            ssao_format = GraphicsFormat.R16_SFloat; 
            id = Shader.PropertyToID(ssao_name);
            ssao_mat = mat;
            if (use_default_tex)
            {
                ssao_mat.EnableKeyword("USE_DEFAULT_TEX");
            }
            else
            {
                ssao_mat.DisableKeyword("USE_DEFAULT_TEX");
            }
            ssao = RTHandles.Alloc(id);

            ssao_profile_sampler = new ProfilingSampler("SSAO");

            ssao_PropertyBlock.SetFloat(Shader.PropertyToID("_BlitMipLevel"), 0);
            //如果不正确设置“_BlitScaleBias”此值，
            //那么在使用Unity自带Blit.hlsl中的Vert顶点着色逻辑时，uv会被乘以0，导致PS节点uv不可用 
            ssao_PropertyBlock.SetVector(Shader.PropertyToID("_BlitScaleBias"), Vector2.one);  

            if (!s_TriangleMesh)
            {
                float nearClipZ = -1;
                if (SystemInfo.usesReversedZBuffer)
                    nearClipZ = 1;

                s_TriangleMesh = new Mesh();
                s_TriangleMesh.vertices = GetFullScreenTriangleVertexPosition(nearClipZ);
                s_TriangleMesh.uv = GetFullScreenTriangleTexCoord();
                s_TriangleMesh.triangles = new int[3] { 0, 1, 2 };
            }
        }

        public void Setup(RTHandle source)
        {
            this.source = source;
        }

        /// <summary>
        /// This method is called by the renderer before executing the render pass.
        /// Override this method if you need to to configure render targets and their clear state, and to create temporary render target textures.
        /// If a render pass doesn't override this method, this render pass renders to the active Camera's render target.
        /// You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        /// </summary>
        /// <param name="cmd">CommandBuffer to enqueue rendering commands. This will be executed by the pipeline.</param>
        /// <param name="cameraTextureDescriptor">Render texture descriptor of the camera render target.</param>
        /// <seealso cref="ConfigureTarget"/>
        /// <seealso cref="ConfigureClear"/>
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            var rtDesc = cameraTextureDescriptor;
            rtDesc.msaaSamples = 1;
            rtDesc.depthBufferBits = 0;
            rtDesc.stencilFormat = GraphicsFormat.None;
            rtDesc.graphicsFormat = ssao_format;
            RenderingUtils.ReAllocateIfNeeded(ref ssao, rtDesc, FilterMode.Point, TextureWrapMode.Clamp, name: ssao_name);
            
            //ConfigureTarget(ssao);//RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (ssao.rt == null)
            {
                RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
                descriptor.msaaSamples = 1;
                descriptor.depthBufferBits = 0;
                descriptor.stencilFormat = GraphicsFormat.None;
                descriptor.graphicsFormat = ssao_format;
                cmd.GetTemporaryRT(Shader.PropertyToID(ssao_name), descriptor, FilterMode.Point);
            }

            cmd.SetGlobalTexture(ssao.name, ssao.nameID); 
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) 
        {
            CommandBuffer cmd = CommandBufferPool.Get(ssao_profile_sampler.name); 
            cmd.Clear();
            //using (new ProfilingScope(cmd, ProfilingSampler.Get(PSamplerE.SSAO_UE)))
            {
                //注意，如下方法需要shader的VS部分支持DrawNullGeometry，建议使用UnityPipCore/Utilities/Blit.hlsl中定义的Vert方法 
                //如果要自己些VS，建议使用DrawMesh替代Blitter 
                //Blitter.BlitCameraTexture(cmd, source, ssao, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, ssao_mat, 0);

                //对于完全离屏渲染，使用DrawMesh类型的接口,跳过source RT设置会比较好 
                cmd.SetRenderTarget(ssao, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                cmd.DrawProcedural(Matrix4x4.identity, ssao_mat, 0, MeshTopology.Triangles, 3, 1, ssao_PropertyBlock);
                //cmd.DrawMesh(s_TriangleMesh, Matrix4x4.identity, ssao_mat, 0, 0, ssao_PropertyBlock);  //备用，仅针对 SystemInfo.graphicsShaderLevel < 30

                context.ExecuteCommandBuffer(cmd);
                cmd.EndSample(ssao_profile_sampler.name);
            }
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }

        // Should match Common.hlsl
        static Vector3[] GetFullScreenTriangleVertexPosition(float z /*= UNITY_NEAR_CLIP_VALUE*/)
        {
            var r = new Vector3[3];
            for (int i = 0; i < 3; i++)
            {
                Vector2 uv = new Vector2((i << 1) & 2, i & 2);
                r[i] = new Vector3(uv.x * 2.0f - 1.0f, uv.y * 2.0f - 1.0f, z);
            }
            return r;
        }

        // Should match Common.hlsl
        static Vector2[] GetFullScreenTriangleTexCoord()
        {
            var r = new Vector2[3];
            for (int i = 0; i < 3; i++)
            {
                if (SystemInfo.graphicsUVStartsAtTop)
                    r[i] = new Vector2((i << 1) & 2, 1.0f - (i & 2));
                else
                    r[i] = new Vector2((i << 1) & 2, i & 2);
            }
            return r;
        }
    }

    SSAOPass m_ScriptablePass;

    public string ssao_rt_name = "_SSAO";

    public string ssao_shader = "Custom/SSAO";

    public Texture2D ssao_tex;

    public bool use_default_texture = false;

    private Material ssao_mat;

    /// <inheritdoc/>
    public override void Create()
    {
        ssao_mat = CoreUtils.CreateEngineMaterial(Shader.Find(ssao_shader));
        if (ssao_tex != null)
        {
            ssao_mat.SetTexture(Shader.PropertyToID("_Tex"), ssao_tex);
        }

        m_ScriptablePass = new SSAOPass(ssao_rt_name, ssao_mat, use_default_texture);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingGbuffer;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //m_ScriptablePass.Setup(renderer.cameraColorTargetHandle);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


