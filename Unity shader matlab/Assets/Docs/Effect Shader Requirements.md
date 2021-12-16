# 特效Shader需求说明

## 常用主Shader

### 路径：

​	Assets/Materials/Particle/Shader/ParticleMain.shader

### 整体需求：

1. 可调节的Blend，主要使用Additive和AlphaBlend效果。
2. 可调节Cull。
3. 可开关深度写入。
4. 关键帧动画。

### 详细需求：

1. 贴图1：MainTex。UV动画速度可控；Material可调节颜色。
2. 贴图2：Mask。UI动画速度可控。遮罩较长用的功能为限定或者更改模型的显示区域，避免产生模型硬边或者利用贴图的多样性改变呈现的效果。遮罩的流动可以使显示区域进行动态改变，可使表现形式略显丰富。（遮罩流动使用不多，但还是加上比较好。）
3. 贴图3：Noise。UI动画速度可控，Noise强度可控。主要扰乱主贴图，使其动态丰富，形成假扭曲效果。
4. 贴图4：溶解。可控溶解程度，溶解边缘宽度，边缘双色（颜色1和颜色2的Lerp，不使用MainTex的Color进行Lerp。主颜色保留），边缘软硬边切换，可选边透明边溶解效果。主要说明最后一点需求，溶解的同时透明化。这部分需求的原因是希望某些特效不完全生硬溶解消失，而是伴随透明化。比较典型的元素例如烟尘。

## 次要Shader

1. Fresnel效果

   路径：Assets/Materials/Fresnel/Shader/Fresnel.shader

   可调节的Blend，主要是用Additive和AlphaBlend效果。

   可调节Cull。

   可开关深度写入。

   贴图、贴图颜色、Fresnel颜色、Fresnel范围、Fresnel强度、粒子编辑器可控制贴图颜色、整体透明度。

2. 双面效果

   路径：Assets/Materials/DoubleFace/Shader/DoubleFace.shader

   贴图UV动画、A面颜色、A面Blend、B面颜色、B面Blend、Noise贴图、Noise强度、Noise UV动画（可加入Mask贴图）。功能实现：例如表现在爆炸的烟尘、龙卷风等技能时，外围的烟尘内部靠近爆炸主体的模拟光源，使内部看起来亮度高于外侧。

3. 折射（扭曲）效果

   路径：Assets/Materials/SpaceWarp/Shader/SpaceWarp.shader

   贴图、UV动画、Mask贴图、扭曲强度、显示贴图开关。功能实现：表现能量、火焰的扭曲背景效果

4. Billboard脚本

   路径：Assets/Materials/BillBoardScript/BillBoard.cs

   脚本实现 Billboard ，Billboard使用场景并不一定在某一个shader中。任何shader都可能需要使用。除非所有shader都加入Billboard。否则希望使用脚本实现。