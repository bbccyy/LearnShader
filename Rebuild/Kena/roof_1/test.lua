

--衣服=0.65882 
--墙+屋顶+木头+远处树叶=0.64912
--草=0.65098
--天空=0
local data = {0.65882, 0.66275, 0.6549, 0.64706, 0.69412, 0.65098, 0}
local names = {"衣服", "眼睛","头发", "皮肤", "木墙","草","天空"}

for key, val in ipairs(data) do
	local tmp = math.floor(val * 255 + 0.5)
	local tmp1 = tmp & 15
	local tmp2 = (tmp & 16) == 16
	local and32 = tmp & 32
	local and64 = tmp & 64
	print(names[key] .. "\t\t\t" .. val .. "\t->\t" .. tmp .. "\t" .. tmp1 .. "\t" .. tostring(tmp2) .. "\tand32=" .. and32 .. "\tand64=" .. and64)
end

local v1 = {-0.09869, -0.98193, 0.1026}
local v2 = {0.40088, 0.46729, 0.01075}
local s = math.sqrt(v1[1]^2 + v1[2]^2 + v1[3]^2)
print((0x1FBD1DF5))
print(2^(16))
print(s)
print("DONE")

local saturate = function(a)
	if a > 1 then
		return 1
	end
	if a <= 0 then
		return 0
	end
	return a
end

local R = 6.6
local d = 3.1
local d1 = 1.12
local D = d + d1
local OF = saturate(R/D - 1)
print(OF)

local bi = 0xFF
bi = 0x80000000
print(bi)

local r0 = 0.11888
print(math.sqrt(r0))

--for (int planeIndex = 0; planeIndex < 6; ++planeIndex)
--{
--    ref DPlane plane = ref planes[planeIndex];
--    distRadius.x = math.dot(plane.normalDist.xyz, box.center) + plane.normalDist.w;
--    distRadius.y = math.dot(math.abs(plane.normalDist.xyz), box.extents);
--    visible = math.select(visible,0,  distRadius.x + distRadius.y < 0);
--}