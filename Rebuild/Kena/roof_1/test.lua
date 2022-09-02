
local data = {1.000001, 0.694118, 0.552941, 0.564706, 0.478431}

for key, val in ipairs(data) do
	local tmp = math.floor(val * 255 + 0.5)
	local tmp1 = tmp & 15
	local tmp2 = (tmp & 16) == 16
	print(val .. "\t->\t" .. tmp .. "\t" .. tmp1 .. "\t" .. tostring(tmp2))
end


print("DONE")