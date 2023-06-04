
struct FDeferredLightData
{
	float3 Direction;
	float4 Color;
	float3 Tangent;
	float ContactShadowLength;
	float4 ShadowMapChannelMask;
	uint ShadowedBits;
	float SourceLength;
	float SourceRadius;
	float SoftSourceRadius;
	bool bInverseSquared;
	float SpecularScale;
};


static float FrameId = 3;
static int View_StateFrameIndexMod8 = 3;
static bool bSubsurfacePostprocessEnabled = true;
static uint bCheckerboardSubsurfaceProfileRendering = 1;
static FDeferredLightData kena_LightData = (FDeferredLightData)0;

static float4 View_ViewRectMin = float4(0, 0, 0, 0);
static float4 View_BufferSizeAndInvSize = float4(1708.00, 960.00, 0.00059, 0.00104);
static float4 View_ViewSizeAndInvSize = float4(1708.00, 960.00, 0.00059, 0.00104);
static float4 View_SkyLightColor = float4(4.95, 4.19202, 3.12225, 0.00);
static float4 OcclusionTintAndMinOcclusion = float4(0.04519, 0.05127, 0.02956, 0.00);
static float4 ContrastAndNormalizeMulAdd = float4(0.01, 40.00843, -19.50422, 0.70);

static float4 AmbientCubemapColor = float4(0.14722, 0.17128, 0.2, 0.2);

static float4 ReflectionStruct_SkyLightParameters = float4(7.00, 1.00, 1.00, 0.00);

static float4 AmbientCubemapMipAdjust = float4(0.33333, 1.66667, 2.00, 6.00);

//SH irradiance map 
static float4 View_SkyIrradianceEnvironmentMap[] = {
	float4(0.00226, -0.06811, 0.24557, 0.34246),
	float4(0.00125, -0.05614, 0.2917, 0.4208),
	float4(0.00028, -0.03233, 0.36868, 0.53767),
	float4(-0.01405, -0.01719, -0.07034, 0.00444),
	float4(-0.01044, -0.01305, -0.07727, 0.00333),
	float4(-0.00504, -0.00213, -0.07663, 0.00164),
	float4(-0.01606, -0.01079, -0.0033, 1.00),
};

static float4 InvDeviceZToWorldZTransform = float4(0.00, 0.00, 0.10, -1.00000E-08); //CB0[65] 对应Unity的zBufferParams  
static float4 ScreenPositionScaleBias = float4(0.49971, -0.50, 0.50, 0.49971); //CB0[66] 从NDC变换到UV空间 
static float4 CameraPosWS = float4(-58625.35547, 27567.39453, -6383.71826, 0); //世界空间中摄像机的坐标值 

static float view_minRoughness = 0.02; //cb0[219].y 

static float4x4 Matrix_VP = float4x4(
    float4(0.9252,		-0.61489,	-0.00021,	0.00),
    float4(0.46399,		0.69752,	1.78886,	0.00),
    float4(0.00,		0.00,		0.00,		10.00),
    float4(-0.50162,	-0.75408,	0.42396,	0.00)
);

static float4x4 Matrix_Inv_P = float4x4(			//CB0[36] ~ CB0[39]
    float4(0.90018, 0,			0,		0.00045	),
    float4(0,	    0.50625,	0,		0.00017	),
    float4(0,		0,			0,		1		),
    float4(0,		0,			0.10,	0		)
);

static float4x4 Matrix_P = float4x4(				//CB0[32] ~ CB0[35]
    float4(1.11089,		0,			0,		0),
    float4(0,			1.97531,	0,		0),
    float4(0,			0,			0,		10),
    float4(0,			0,			1,		0)
);

//cb1_v48 ~ cb1_v51
static float4x4 Matrix_Inv_VP = float4x4(
	float4(0.7495,			0.11887,	-0.5012,		-58625.35547),
	float4(-0.49857,		0.1787,		-0.75428,		27567.39453),
	float4(-2.68273E-08,	0.4585,		0.42411,		-6383.71826),
	float4(0,				0,			0,				1.00)
);


