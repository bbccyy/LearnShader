
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
	float mask;
	float ambientStrength;
	float speed;
	float4 direction;
	float swinging;

	float randObject;
	float randVertex;
	float randObjectStrength;

	float gustStrength;
	float gustFrequency;
};

//Struct that holds both VertexPositionInputs and VertexNormalInputs
struct VertexHolder {
	//Positions
	float3 positionWS;	// World space position
	float3 positionVS;	// View space position
	float4 positionCS;	// Homogeneous clip space position
	float4 positionNDC;	// Homogeneous normalized device coordinates
	float3 viewDir;		// Homogeneous normalized device coordinates

	//Normals
#if defined(_NORMALMAP) 
	real4 tangentWS;
#endif
	float3 normalWS;
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

	//Random offset per vertex
	float f = length(positionOS.xz) * s.randVertex;
	float strength = s.ambientStrength * 0.5 * lerp(1, rand, s.randObjectStrength);
	//Combine
	float sine = sin(s.speed * (_TimeParameters.x + (rand * s.randObject) + f));
	//Remap from -1/1 to 0/1
	sine = lerp(sine * 0.5 + 0.5, sine, s.swinging);

	//Apply gusting
	float gust = SampleGustMapLOD(wPos, s);

	//Scale sine
	sine = sine * s.mask * strength;

	//Mask by direction vector + gusting push
	offset.xz = sine + gust * s.direction.xz;
	offset.y = s.mask;

	//Summed offset strength
	float windWeight = length(offset.xz) + 0.0001;
	//Slightly negate the triangle-shape curve
	windWeight = pow(windWeight, 1.5);
	offset.y *= windWeight;

	//Wind strength in alpha
	offset.a = sine + gust;

	return offset;
}


//Combination of GetVertexPositionInputs and GetVertexNormalInputs with bending
VertexHolder GetVertexOutput(in VertexInput input, float rand, WindSettings s)
{
	VertexHolder data = (VertexHolder)0;

	float3 wPos = TransformObjectToWorld(input.positionOS.xyz);

	float4 windVec = GetWindOffset(input.positionOS.xyz, wPos, rand, s);  //Less wind on shorter grass

	float3 offsets = windVec.xyz;

	//Perspective correction
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - wPos);
	float NdotV = dot(float3(0, 1, 0), viewDir);

	//Avoid pushing grass straight underneath the camera in a falloff of 4 units (1.0/4.0)
	float dist = saturate(distance(wPos.xz, _WorldSpaceCameraPos.xz) * 0.25);

	//Push grass away from camera position
	float2 pushVec = viewDir.xz;

	//This looks better, however during the shadow casting pass, the projection matrix is that of the light
	//pushVec = mul((float3x3)unity_CameraToWorld, float3(0,1,0)).xz;

	float perspMask = dist * NdotV;
	offsets.xz += pushVec.xy * perspMask;

	//Apply bend offset
	wPos.xz += offsets.xz;
	wPos.y -= offsets.y;

	//Vertex positions in various coordinate spaces
	data.positionWS = wPos;
	data.positionVS = TransformWorldToView(data.positionWS);
	data.positionCS = TransformWorldToHClip(data.positionWS);

	//Skip normal derivative during shadow and depth passes
#if !defined(SHADERPASS_SHADOWCASTER) && !defined(SHADERPASS_DEPTHONLY) 
	#if _ADVANCED_LIGHTING && defined(RECALC_NORMALS)
		float3 oPos = TransformWorldToObject(wPos); //object-space position after displacement in world-space
		float3 bentNormals = lerp(input.normalOS, normalize(oPos - input.positionOS.xyz), abs(offsets.x + offsets.z) * 0.5); //weight is length of wind/bend vector
	#else
		float3 bentNormals = input.normalOS;
	#endif

		data.normalWS = TransformObjectToWorldNormal(bentNormals);
	#ifdef _NORMALMAP
		data.tangentWS.xyz = TransformObjectToWorldDir(input.tangentOS.xyz);
		real sign = input.tangentOS.w * GetOddNegativeScale();
		data.tangentWS.w = sign;
	#endif
#endif

	return data;
}