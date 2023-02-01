

--衣服=0.65882 
--墙+屋顶+木头+远处树叶=0.64912
--草=0.65098
--天空=0
local data = {0.65882, 0.64912, 0.65098, 0}
local names = {"衣服","木墙","草","天空"}

for key, val in ipairs(data) do
	local tmp = math.floor(val * 255 + 0.5)
	local tmp1 = tmp & 15
	local tmp2 = (tmp & 16) == 16
	local and32 = tmp & 32
	local and64 = tmp & 64
	print(names[key] .. "\t\t\t" .. val .. "\t->\t" .. and32 .. "\t" .. and64 .. "\t" .. tostring(tmp2))
end


print("DONE")