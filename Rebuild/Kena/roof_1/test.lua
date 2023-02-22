

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

local s = math.sqrt(0.51555^2 + 0.29836^2 + 0.80324^2)
print((0x1FBD1DF5))

print("DONE")