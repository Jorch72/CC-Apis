@include colormix

local a = colormix(0xFF0000)
local b = colormix(0x0000FF)

local gradient = colormix.gradient(a,b)
for i = 0, 10 do
	local c = gradient.mix(i/10)
	print(c.hex())
end
