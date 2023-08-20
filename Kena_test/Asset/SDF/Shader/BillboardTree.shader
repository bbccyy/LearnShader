Shader "Unlit/BillboardTree"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_MainNormalTex ("Texture", 2D) = "white" {}
        [HDR]_OverlayColor("Over Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        CULL Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                float4 vertex : SV_POSITION;
                //float3 normalOS : NORMAL;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 tangentWS : TEXCOORD4;
                float3 bitangentWS : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MainNormalTex;
            float4 _MainNormalTex_ST;
            half4 _OverlayColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogCoord = ComputeFogFactor(o.vertex.z);
                VertexNormalInputs tbn = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = tbn.normalWS;
                o.tangentWS = tbn.tangentWS;
                o.bitangentWS = tbn.bitangentWS;
                o.positionWS = TransformObjectToWorld(v.vertex);

                // 广告板自动面对摄像机
                // float3 newZ = TransformWorldToObject(_WorldSpaceCameraPos);
                // //float3 newX = abs(newZ.y)<0.99?cross(float3(0,1,0),newZ):cross(newZ,float3(0,0,1));
                // float3 newX = cross(float3(0,1,0),newZ);
                // float3 newY = cross(newZ, newX);
                // newZ = -normalize(newZ);
                // newX = normalize(newX);
                // newY = normalize(newY);

                // float3x3 toBillboard = {newX, newY, newZ};
                // //toBillboard = transpose(toBillboard);
                // float3 NewPos = mul(toBillboard, v.vertex);
                // o.vertex = TransformObjectToHClip(float4(NewPos, 1));


               
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);
                float3 NormalTex = UnpackNormalScale( tex2D( _MainNormalTex, i.uv ), 1 );
                float3 NormalWS = TransformTangentToWorld(NormalTex, half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz));
                clip(col.a - 0.5);

                Light mainlight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                float NdotL = dot(mainlight.direction, NormalWS)*0.5+0.5;

                col.xyz *= NdotL * _OverlayColor;
                // apply fog
                col.xyz = MixFog(col.xyz, i.fogCoord);
                return col;
            }
            ENDHLSL
        }
    }
}
