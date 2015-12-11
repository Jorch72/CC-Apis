function parse(args)
	local out = {}
	out.paths = {}
	for n,arg in ipairs(args) do
		if arg:sub(1,1) == '-' then
			local name, value = arg:match("%-([^:]+):([^:]+)")
			if name and value then
				out[name] = value
			else
				local name = arg:match("%-([^:]+)")
				if args[n+1] then
					local value = args[n+1]
					if not (value:sub(1,1) == "-") then
						out[name] = value
					else
						out[name] = true
					end
				else
					out[name] = true
				end
			end
		else
			if n == 1 then
				out.input = arg
			else
				table.insert(out.paths, arg)
			end
		end
	end
	return out
end