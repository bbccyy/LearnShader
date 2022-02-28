Shader "GammaUIFix"
{
    Properties
    {
        [HideInInspector] _MainTex ("UI Texture", 2D) = "white" {}
        //_UITex ("_UITex", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _CameraColorTexture;  //全局变量，URP会把main camera的输出存放此处 
            sampler2D _MainTex;             //Blit操作时，会把第一个入参附加给 _MainTex，存放的是UI Camera的输出RT 

            float4 frag (v2f i) : SV_Target
            {
                //第一步是采样UI Camera的输出，注意需要取消所有UI相关额贴图纹理的sRGB勾选项（有图集的要取消图集的相关设定）
                //所有UI将会在Gamma空间进行计算和混淆：rgb保持原样，混淆时使用原始a，这样可以保持和美术家在Photoshop中的叠加混合一致。
                float4 uicol = tex2D(_MainTex, i.uv); //ui in lighter color
                //对UI RT的alpha作Pow(alpha, 0.45)操作，借用了转换到Gamma空间的方法，其实是为了提高alpha的数值大小，使得UI的总体不透明度增加。
                //注意uicol.a是对多张UI纹理的alpha连乘后，取于1的差得到的，既a = 1- a1*a2*...an
                uicol.a = LinearToGammaSpace(uicol.a); //make ui alpha in lighter color

                //所有3D相机的内容都是基于Linear space进行渲染的，请确保ProjectSetting->Player->Other Render->col space的设置是Linear
                //此外请确保所有艺术家输出的纹理的sRGB勾选项是勾选的状态，这样Unity才会在采样时自动做remove gamma correction操作。
                float4 col = tex2D(_CameraColorTexture, i.uv); //3d in normal color
                //3D层的内容需要转换到Gamma空间，与UI输出的RT保持在一个空间里，此后才能做混淆。 
                col.rgb = LinearToGammaSpace(col.rgb); //make 3d in lighter color

                float4 result;
                //按alpha值混淆3D层和UI层输出，混淆是发生在Gamma空间里的。
                result.rgb = lerp(col.rgb,uicol.rgb,uicol.a); //do linear blending
                //最后转换到Linear空间，后续仍然会有计算（Post process?），需要继续保持Linear
                result.rgb = GammaToLinearSpace(result.rgb); //make result normal color
                result.a = 1;

                return result;  //输出到Blit方法的第二个入参上，既 renderer.cameraColorTarget 
            }
            ENDCG
        }
    }
}
