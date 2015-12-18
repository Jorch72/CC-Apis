function init(file)
	local out = {}
	local data = {}
	if fs.exists(file) then
		local f = fs.open(file,"r")
		local d = f.readAll()
		f.close()
		if textutils.unserialize(d) then
			data = textutils.unserialize(d)
		end
	end
	local function save()
		local f = fs.open(file,"w")
		f.write(textutils.serialize(data))
		f.close()
	end
	function out.get(key, default)
		return data[key] or default
	end
	function out.set(key, value)
		data[key] = value
		save()
	end
	return out
end