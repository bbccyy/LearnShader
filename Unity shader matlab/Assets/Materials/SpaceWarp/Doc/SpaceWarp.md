# SpaceWarp效果

​		在渲染需要扭曲的GameObject之前，获取除本物体之外的所有物体渲染完成的渲染结果，然后对中间渲染结果进行扭曲，扭曲后的结果渲染到对应GameObject。URP中不存在BuildIn中的GrabPass，因此需要添加一个RenderFeature用于实现将中间渲染结果保存到临时RT上的效果，然后再添加RenderObject来渲染对应的GameObject。此过程需要添加一个特殊的LayerMask（本工程中采用“GrabThing”）配合完成。

## 添加RenderFeature和RenderObject

代码路径：Assets/Scripts/GrabRenderFeature.cs

如何添加RenderFeature自行检索不加赘述，只强调某些关键点。

由于希望该效果渲染顺序靠后，因此Shader渲染的Queue是Transparent，在ForwardRenderer的设置中，需要将Transparent Layer Mask当中对GrabThing的渲染取消。（如果不取消，在正常的非透明渲染队列中，就会渲染出一个错误的空白对象）。

<img src="G:\MaterialProj\MaterialLib\Assets\Docs\Pictures\ForwardRendererSetting.jpg"  />

添加的RenderFeature中，对应的Texture Name也就是在Shader中使用到的RenderTexture名称。

<img src="G:\MaterialProj\MaterialLib\Assets\Docs\Pictures\RenderFeatureSetting.jpg"  />

添加的RenderObject中，可以选择渲染的时机，关键是需要选择对应需要渲染的LayerMask。

![image-20211201170852729](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20211201170852729.png)

### SpaceWarp.shader

对GrabTexture的应用如同普通的Texture，只需要注意名称跟RenderFeature一致。

​	TEXTURE2D(_ScreenGrabTexture);        SAMPLER(sampler_ScreenGrabTexture);

​	……

​	SAMPLE_TEXTURE2D(_ScreenGrabTexture, sampler_ScreenGrabTexture, screenPosition.xy);

**为了保证特效的粒子控制器能控制颜色和扭曲强度，计算颜色和扭曲偏移时都会乘顶点color的a值。**