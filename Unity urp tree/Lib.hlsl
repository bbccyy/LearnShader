
//Properties
TEXTURE2D(_WindMap);       SAMPLER(sampler_WindMap);

//X: Strength
//W: (int bool) Wind zone present
float4 _GlobalWindParams;

//X: Gust dir X
//Y: Gust dir Y
//Z: Gust speed
//W: Gust strength
float4 GlobalWindDirectionAndStrength;

//X: Shiver speed
//Y: Shiver strength
float4 _GlobalShiver;


struct WindSettings
{
	float mask;				//独立于风的其他影响顶点动画的因素，主要指受压弯折Bending
	float ambientStrength;	//基础风强，影响柔和风的强度，所谓柔和风是指基础风
	float speed;			//控制基础风强度的变化频率(既风速)，同时也控制阵风计算过程中采样噪声贴图的频率(既阵风流速)
	float4 direction;		//主要负责控制风动偏移在x-z平面上的朝向，同时也影响采样阵风噪声纹理中的uv流动朝向 
	float swinging;			//调节基础风形成的顶点回摆幅度，从[0,1]区间到[-1,1]区间，swing值越接近1，来回摆动的程度越大

	float randObject;		//影响Obj级别的随机数大小，从而影响基础风的初始相位
	float randVertex;		//影响Vertex级别的计算量大小，从而也影响基础风的初始相位 
	float randObjectStrength;//控制关联Obj的随机数rand的影响程度，从而间接控制基础风强

	float gustStrength;		//调节阵风强度 
	float gustFrequency;	//调节阵风频率 
};

//Struct that holds both VertexPositionInputs and VertexNormalInputs
struct VertexHolder {
	//Positions
	float3 positionWS;	// World space position
	float3 positionVS;	// View space position
	float4 positionCS;	// Homogeneous clip space position
	float3 normalOS;
};

float2 DirectionalEquation(float _WindDirection)
{
	float d = _WindDirection * 0.0174532924;
	float xL = cos(d) + 1 / 2;
	float zL = sin(d) + 1 / 2;
	return float2(zL, xL);
}

float3 HandleLeaves(float3 vertexPos, float sinfunc, float depth, float windStrength, float angle, float globalWindTurbulence)
{
	//leaves
	float3 leavePos = float3(0, 0, 0);
	leavePos.x = vertexPos.x;
	leavePos.z = vertexPos.z;
	leavePos.y = vertexPos.y + sinfunc * depth * (windStrength / 200.0 + angle) * globalWindTurbulence;
	return leavePos;
}

float3 HSVToRGB(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float3 RGBToHSV(float3 c)
{
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
	float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//TODO: really need dither fadeout? 
inline float Dither8x8Bayer(int x, int y)
{
	const float dither[64] = {
		1, 49, 13, 61,  4, 52, 16, 64,
		33, 17, 45, 29, 36, 20, 48, 32,
		9, 57,  5, 53, 12, 60,  8, 56,
		41, 25, 37, 21, 44, 28, 40, 24,
		3, 51, 15, 63,  2, 50, 14, 62,
		35, 19, 47, 31, 34, 18, 46, 30,
		11, 59,  7, 55, 10, 58,  6, 54,
		43, 27, 39, 23, 42, 26, 38, 22
	};
	int r = y * 8 + x;
	return dither[r] / 64; // same # of instructions as pre-dividing due to compiler magic
}


//World-align UV moving in wind direction
float2 GetGustingUV(float3 wPos, WindSettings s) {
	return (wPos.xz * s.gustFrequency * 0.01) + (_TimeParameters.x * s.speed * s.gustFrequency * 0.01) * s.direction.xz;
}


float SampleGustMapLOD(float3 wPos, WindSettings s) {
	float2 gustUV = GetGustingUV(wPos, s);
	float gust = SAMPLE_TEXTURE2D_LOD(_WindMap, sampler_WindMap, gustUV, 0).r;

	gust *= s.gustStrength * s.mask;

	return gust;
}


//综合全局和局部变量，输出wind structure 
WindSettings PopulateWindSettings(in float strength, float speed, float4 direction, float swinging, float mask, float randObject, float randVertex, float randObjectStrength, float gustStrength, float gustFrequency)
{
	WindSettings s = (WindSettings)0;

	//Apply WindZone strength
	if (_GlobalWindParams.w > 0)
	{
		strength *= _GlobalWindParams.x;
		gustStrength *= _GlobalWindParams.x;
		//direction.xz += _WindDirection.xz;
	}

	//Nature renderer params
	if (_GlobalShiver.y > 0) {
		strength += _GlobalShiver.y;
		speed += _GlobalShiver.x;
	}
	if (GlobalWindDirectionAndStrength.w > 0) {
		gustStrength += GlobalWindDirectionAndStrength.w;
		direction.xz += GlobalWindDirectionAndStrength.xy;
	}

	s.ambientStrength = strength;
	s.speed = speed;
	s.direction = -direction; //Needs negating
	s.swinging = swinging;
	s.mask = mask;
	s.randObject = randObject;
	s.randVertex = randVertex;
	s.randObjectStrength = randObjectStrength;
	s.gustStrength = gustStrength;
	s.gustFrequency = gustFrequency;

	return s;
}


float ObjectPosRand01() {
	return frac(UNITY_MATRIX_M[0][3] + UNITY_MATRIX_M[1][3] + UNITY_MATRIX_M[2][3]);
}


float4 GetWindOffset(in float3 positionOS, in float3 wPos, float rand, WindSettings s)
{
	float4 offset;

	//第一部分ambientStrength是用户调节的振幅强度
	//第二部分中的rand是关联当前Obj(不是顶点)的一个随机数，不同Obj不同，相同Obj此数值相同
	//两部分合成的strength控制Obj级别的振幅强度
	float strength = s.ambientStrength * 0.5 * lerp(1, rand, s.randObjectStrength);

	//模型空间该点到中心的距离(水平面上) * 顶点扰动强度
	//f属于顶点级别的震动强度，且具有越远离模型中心，强度f越大的特点 
	float f = length(positionOS.xz) * s.randVertex;
	//生成随时间流动的正弦函数曲线，用以模拟柔和的风摆 
	//由(rand * s.randObject) + f控制初始相位，是一个既关联Obj，又关联顶点的随机数，调解randObject可控制关联Obj的比例 
	//由s.speed控制波动频率
	float sine = sin(s.speed * (_TimeParameters.x + (rand * s.randObject) + f));
	//调解震动范围，可以从[0,1]区间变化到[-1,1]区间震动
	//用户输入的swinging负责插值上述两个范围，swinging为0时震动范围最小 
	sine = lerp(sine * 0.5 + 0.5, sine, s.swinging);

	//计算阵风(突然增强的风)
	//为强度其随机性，gust强度需通过采样噪声贴图获取
	//首先是依据顶点属性，时间，用户控制的朝向dir，以及用户控制的gustFrequency(采样频率)来生成随机的采样UV 
	float2 gustUV = frac((wPos.xz * s.gustFrequency * 0.01) + (_TimeParameters.x * s.speed * s.gustFrequency * 0.01) * s.direction.xz);
	//采样噪声图，注意此图最好使用局部连续，整体离散的perlin noise，不要使用红粉噪声 
	float gust = SAMPLE_TEXTURE2D_LOD(_WindMap, sampler_WindMap, gustUV, 0).r;
	//对采样结果修正，gustStrength是用户控制的阵风强度，mask是弯折程度(bend intencity)，0代表完全弯折，1代表不受影响 
	gust *= s.gustStrength * s.mask;

	//对温和的风波进行修正，原理同上 
	sine = sine * s.mask * strength;

	//最终输出的风动偏移中的xz分量由下面公式计算获取
	//sine提供基础震动(可以理解为波的低频部分，或者底噪)
	//gust * s.direction.xz 计算沿着风向，由阵风引起的叠加振幅 
	offset.xz = sine + gust * s.direction.xz;
	//垂直方向先由mask站位，如果当前顶点受到完全的挤压(bending)，则y值为0，后续对y的缩放操作将不会输出变化 
	offset.y = s.mask;

	//windWeight用于缩放y轴的偏移(offset)
	//它的底子是正比于xz平面上的偏移程度的 
	float windWeight = length(offset.xz) + 0.0001;
	//同时为了避免这种线性偏移带来的生硬感，这里对windWeight做了次指数为1.5的乘方 
	windWeight = pow(windWeight, 1.5);
	offset.y *= windWeight;  //对y轴偏移进行缩放 

	//将合成风强(柔和风 + 阵风)保存到a通道一并输出 
	offset.a = sine + gust;

	return offset;
}


//Combination of GetVertexPositionInputs and GetVertexNormalInputs with bending
VertexHolder GetVertexOutput(in VertexInput input, float rand, WindSettings s)
{
	VertexHolder data = (VertexHolder)0;
	//获取世界坐标 
	float3 wPos = TransformObjectToWorld(input.positionOS.xyz);
	//计算风动偏移向量
	float4 windVec = GetWindOffset(input.positionOS.xyz, wPos, rand, s);  //Less wind on shorter grass

	//Perspective correction
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - wPos);
	float NdotV = dot(float3(0, 1, 0), viewDir);  //平视为0， 仰视为负，俯瞰为正 

	//Avoid pushing grass straight underneath the camera in a falloff of 4 units (1.0/4.0)
	//距离超过单位1时dist为0.25，距离越小越接近0
	float dist = saturate(distance(wPos.xz, _WorldSpaceCameraPos.xz) * 0.25);

	//使用此向量，将植被顶点推离(远离)摄像机一个单位距离
	float2 pushVec = viewDir.xz;

	//perspMask受到水平距离和摄像机俯仰视角的影响
	//水平距离越小(小于单位1时)，推力pushVec越小
	//俯瞰时(一般是看地上草的情况)，推力变大
	//其余视角(平视，仰视),推力为0或直接反向
	float perspMask = dist * NdotV;
	pushVec.xy = pushVec.xy * perspMask;

	//将水平推力作用到风动矢量的水平分量上 
	windVec.xz += pushVec.xy;

	//风动矢量作用到植被顶点的世界坐标上
	//也可以直接 wPos +=windVec; 区别不大
	wPos.xz += windVec.xz;
	wPos.y -= windVec.y;

	//Vertex positions in various coordinate spaces
	data.positionWS = wPos;
	data.positionVS = TransformWorldToView(data.positionWS);
	data.positionCS = TransformWorldToHClip(data.positionWS);

	//Skip normal derivative during shadow and depth passes
#if !defined(SHADERPASS_SHADOWCASTER) && !defined(SHADERPASS_DEPTHONLY) 
	#if _ADVANCED_LIGHTING && defined(RECALC_NORMALS)
		//重新计算法线，依据原始法线位置，朝向运动方向做偏移(lerp) 
		float3 oPos = TransformWorldToObject(wPos);
		float3 bentNormals = lerp(
			input.normalOS, 
			normalize(oPos - input.positionOS.xyz), 
			abs(windVec.x + windVec.z) * 0.5
		); //weight is length of wind/bend vector
	#else
		float3 bentNormals = input.normalOS;
	#endif
		data.normalOS = bentNormals;
#endif

	return data;
}