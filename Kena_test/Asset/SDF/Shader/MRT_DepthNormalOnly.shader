Shader "Test/MRT_DepthNormalOnly"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "GBufferDepthNormalOnly"
            Tags {"LightMode"="UniversalGBuffer"}

            ZWrite On
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Deferred.hlsl"

            struct mrtOut
            {
                float4 o0_BaseColor_AO :    SV_Target0;     //RGBA32          Albedo_RGB_AO_A
                float4 o1_Comp :            SV_Target1;     //RGBA32          Comp_M_D_R_F
                float4 o2_Normal_Flag :     SV_Target2;     //RGB10A2         NormalWS_RGB 
                float4 o3_Emission :        SV_Target3;     //RGBA32          ColorAttachment  
                float  o4_Depth : SV_Target4;               //R32             Depth 
                float4 o5_CustomData :      SV_Target5;     //RGBA32          Comp_Custom_F_R_X_I 
            };

            struct Attribute
            {
                float4 positionOS   : POSITION;
                float4 normal       : NORMAL;
                float2 uv           : TEXCOORD0;
            };

            struct Varying
            {
                float2 uv           : TEXCOORD0;
                float4 vertex       : SV_POSITION;
                float3 normal       : TEXCOORD1;
                //float3 posOSxyz     : TEXCOORD3; 
            };

            SAMPLER(_MainTex); 

            CBUFFER_START(UnityPerMaterial)

                float4 _MainTex_ST;

            CBUFFER_END

            Varying vert (Attribute v)
            {
                Varying o;
                o.vertex = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                o.normal = TransformObjectToWorldNormal(v.normal.xyz);
                return o;
            }

            mrtOut frag(Varying i) : SV_Target
            {
                mrtOut mrt = (mrtOut)0;

                mrt.o0_BaseColor_AO.a = 1;
                mrt.o0_BaseColor_AO.rgb = half3(0.5,0.5,0.5);
                mrt.o3_Emission.rgba = 0;   
                mrt.o2_Normal_Flag.rgb = (i.normal + 1.0f) * 0.5f;  //Encode normal to maintain negative values. Any better idea?
                mrt.o2_Normal_Flag.a = 0; 
                mrt.o1_Comp.rgba = 0;
                mrt.o5_CustomData.rgba = 0;

                mrt.o4_Depth.r = i.vertex.z; // Linear01Depth(i.vertex.z, _ZBufferParams);

                return mrt;
            }

            ENDHLSL
        }
    }
}
