
local data = {1.00000, 0.694118, 0.552941}

for key, val in ipairs(data) do
	local tmp = math.floor(val * 255 + 0.5)
	local tmp1 = tmp & 15
	local tmp2 = (tmp & 16) == 16
	print(val .. "\t->\t" .. tmp .. "\t" .. tmp1 .. "\t" .. tostring(tmp2))
end


print("DONE")