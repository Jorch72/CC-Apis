function color(...)
	local args = {...}
	local r, g, b
	if #args == 1 and type(args[1]) == "number" then
		-- single hex number
		local hex = string.format("%.6x",args[1])
		hex = hex:sub(#hex - 5)
		r = tonumber(hex:sub(1,2),16)
		g = tonumber(hex:sub(3,4),16)
		b = tonumber(hex:sub(5,6),16)
		if not r and g and b then
			error("invalid color specified",2)
		end
	elseif #args == 3 and type(args[1]) == "number" and type(args[2]) == "number" and type(args[3]) == "number" then
		-- number RGB
		r, g, b = args[1], args[2], args[3]
	end
	r = r or 0
	g = g or 0
	b = b or 0
	local output = {}
	output.r = r
	output.g = g
	output.b = b
	output.hex = function()
		return string.format("%.2X%.2X%.2X",output.r,output.g,output.b)
	end
	output.hexn = function()
		return tonumber(output.hex(), 16)
	end
	return output
end

__const = color

function gradient(a, b)
	assert(type(a) == "table" and a.r and a.g and a.b, "invalid color #1; please create a color first")
	assert(type(b) == "table" and b.r and b.g and b.b, "invalid color #2; please create a color first")
	local output = {}
	output.first = function() return a end
	output.second = function() return b end
	function output.mix(f)
		local tr = math.floor(((1 - f) * a.r) + (f * b.r))
		local tg = math.floor(((1 - f) * a.g) + (f * b.g))
		local tb = math.floor(((1 - f) * a.b) + (f * b.b))
		return color(tr, tg, tb)
	end
	return output
end