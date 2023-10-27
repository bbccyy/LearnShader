

一些思考：


1）关于shadow
	由Instance绘制gameObj时，目前没有考虑到shadow distance的影响，既对于那些需要接收shadow的实例化对象而言，绘制shadow将是必然选项，而不是条件触发选项，这会导致额外的（不必要的）阴影纹理采样和渲染逻辑执行。

