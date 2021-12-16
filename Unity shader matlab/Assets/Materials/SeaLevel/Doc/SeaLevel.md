# SeaLevel
## 基本描述：

​	PJ项目需求的流动海水平面。
## 贴图：

​	_MainTex：固定的贴图，水的基本样式。

​	_NormalTex：法线贴图，用以计算高光。

​	_NoiseTex：噪音贴图，用于扰乱流动的时序。（只用到了R通道，可以与FlowTex合并）

​	_FlowTex：每个顶点处的水流流速矢量图。（只用到了RG通道）

## 液体流动的分步实现过程：

首先以一个采样MainTex值，直接作为最终结果的shader为基础。

首先以一个采样MainTex值，直接作为最终结果的shader为基础。

1、贴图随时间发生变化。

​	在采样的MainTex的uv值中加入时间变化： uv = uv + _Time.y;

<img src="DocPicture/1_TimeFlow.gif" style="zoom:50%;" />

2、每个点以不同的方向和速度流动

​	添加时间以后，贴图流动了起来，但是每个点的流动都是一致的。为了增加流动的随机性，通过一个FlowMap来给每一个位置一个不同的流速和方向。添加贴图_FlowMap，并且采样，用采样结果影响MainTex的采样uv。

​	float2 flowVector = 对_FlowMap采样；

​	uv = uv + _Time.y * flowVector;

​	flowMap的意义就是每个点的uv流动速度矢量。

<img src="DocPicture/2_DiffSpeedFlow.gif" style="zoom:50%;" />

3、重置流动状态

​	沿着flowmap给出的方向移动一段时间之后，会陷入非常扭曲的显示效果。随着时间流逝这种扭曲会越来越严重，因此需要在某个时间点对扭曲状态进行重置。常用的重置方式就是让时间按照周期性变化，也就是将time变成锯齿波。

​	float progress = frac(time); // 0-1之间变化的锯齿波

​	uv = uv + progress * flowVector;

<img src="DocPicture/3_ResetFlow.gif" style="zoom:50%;" />

4、隐藏重置造成的突变

​	在锯齿波从1变为0的时刻，水的流动是反常规的突变状态（这与逻辑上水流动的连续性是不符的）。但是只要存在重置，就没有办法避免这个突变过程，只能尝试隐藏这一过程。在接近最大扭曲（也就是锯齿波接近1的时候）让纹理淡出为黑色，然后从最小扭曲的时候再从黑色淡入。

​	float3 uvw

​	uvw.xy = uv + progress * flowVector;

​	uvw.z = 某种波形，要求在0-1之间周期性变化，0-1时值最小，0.5时值最大。

​	符合要求的波形有很多种，实践中多用三角波，也就是说uvw.z = 1 - abs(1- 2 * progress);

<img src="DocPicture/4_FadeInOut.gif" style="zoom:50%;" />

5、破坏每个点的时间一致性

​	技术上来说突变被掩盖了，但是淡入淡出又十分不自然和明显，因此需要让水面上的每一个点，处于不同的时间，即处于不同的淡入淡出状态中（A点处于淡入的0.5，与此同时B点处于淡入的0.7）。因此需要对每个点的时间做一定的偏移。此处采用某种方式添加噪音，可以将噪音放在_FlowMap的其他通道里，也可以加入新的NoiseMap。

​	添加新的贴图_NoiseMap来提供时间偏移。

​	float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv).x;

​	float progress = frac(time + noise);

<img src="DocPicture/5_TimeNoise.gif" style="zoom:50%;" />

6、结合不同的扭曲

​	破坏了时间的连续性以后，可以考虑不一定非要淡入淡出为黑色，而是改为两种不同扭曲的淡入淡出，这样增强波动性并且不容易被看出周期性变化。

​	计算两次FlowUVW,其中一次增加一个0.5的偏移，就获得了两个三角形的锯齿波，两个波的Z值关系刚好符合Z1+Z2 = 1。然后用两个不同的uv采样MainTex，获得两个采样值，最终结果是两个采样值的加和。

<img src="DocPicture/6_FadeWave.gif" style="zoom:50%;" />

7、UV跳跃（搞不明白，保留参考文档）

​	目前看来uv的变化周期性还是太强，选择让UV的偏移不再一直局限于0-1的区间内。添加一个UV的Jump变量来偏移uv变量。

​	uvw.xy += (_Time.y - progress) * jump; // 利用时间的整数部分进行阶段跳跃

​	参考文档：https://mp.weixin.qq.com/s/xmQdoICG-BCcQ4yD2N91rw 2.5部分

<img src="DocPicture/7_UVJump.gif" style="zoom:50%;" />

8、动画效果微调

​	添加可以调控的平铺、速度、扭曲强度、流量偏移用于更多显示效果的调整。

​	例：扭曲强度逐渐增大

<img src="DocPicture/8_AnimFinetune.gif" style="zoom:50%;" />

9、添加法线贴图

​	增加法线贴图，加入高光。

<img src="DocPicture/9_Specular.gif" style="zoom:50%;" />

10、添加Mesh变化造成的波浪

​		在以上步骤完成之后，如果还需要起伏更加明显的海面效果，那就需要对每个顶点的位置进行改动。

* ​		**最直接的做法，顶点的xz保持不动，y变成与z值（或者x）相关的正弦波。**

​		v.positionOS.y = **sin**(v.positionOS.z);

* ​		此时就会产生一个正弦波形状的海面。正弦波的默认振幅是1，那么可以通过**添加一个变量_Amplitude来控制波的振幅大小**，即：

​		v.positionOS.y = **_Amplitude** * sin(v.positionOS.z);

* ​		为了调整波形的频率，再**添加变量_WaveLength调整波形的波长**。

​		**float k = 2 * PI / _WaveLength;**

​		v.positionOS.y = _Amplitude * sin(**k** * v.positionOS.z);

* ​		波浪需要移动，因此再**加入一个_Speed变量在波形上添加相位偏移**。

​		float k = 2 * PI / _WaveLength;

​		v.positionOS.y = _Amplitude * sin(k * (v.positionOS.z **- _Speed * _Time.y**));

* ​		至此，正弦波的调整就结束了。但是正弦波的波形与实际海浪的波形并不匹配，最匹配的海浪波形模拟Stokes波函数又过于复杂，因此**通常用于模拟海浪的波形是Gerstner波（摆线波）**。变换之后的顶点坐标关系(x, a * sin f, z + a * conf)。

​		float k = 2 * PI / _WaveLength;

​		float f = k * (v.positionOS.z - _Speed * _Time.y);

​		**v.positionOS.y = _Amplitude * sin(f);**

​		**v.positionOS.z += _Amplitude * cos(f);**

* ​		此时的波长和振幅之间是没有关联性的，但是在实际物理模型中**波长和振幅之间具备一定的相关性**。我们将这种相关性用一个变量_Steepness（波浪的陡峭程度）来表示，则振幅a = _Steepness / k；振幅变量去掉。

​		修改坐标的计算公式为：

​		float k = 2 * PI / _WaveLength;

​		float f = k * (v.positionOS.z - _Speed * _Time.y);

​		**float a = _Steepness / k;**

​		v.positionOS.y = **a** * sin(f);

​		v.positionOS.z += **a** * cos(f);

* ​		另一个问题，**波浪是没有相位速度的**，物理意义上的相位速度与波的数量有关，也就是与波长有关。具体关系为

​		float k = 2 * PI / _WaveLength;

​		**float c = sqrt(9.8 / k); // 此处9.8指的是重力加速度**

​		速度变量可以去掉，计算方式改为：

​		float f = k * (v.positionOS.z - **c** * _Time.y);

* ​		目前波浪的移动方向只在Z轴，为了解除这种限制，添加方向变量_Direction用来控制xz方向上的波浪移动

​		float k = 2 * PI / _WaveLength;

​		float c = sqrt(9.8 / k);

​		**float2 d = normalize(_Direction);**

​		float f = k * (**dot(d, v.positionOS.xz)** - c * _Time.y);

​		float a = _Steepness / k;

​		v.positionOS.y = a * sin(f);

​		v.positionOS.z += **d.y * a * cos(f);**

​		**v.positionOS.x += d.x * a * cons(f);**

* ​		至此单个波形的变换就完成了，为了丰富海面的形式，可以以同样的计算方式添加多个波形。

<img src="DocPicture/10_MeshWave.gif" style="zoom:50%;" />

