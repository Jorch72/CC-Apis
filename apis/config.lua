function init(file)
	local data
	if fs.exists(file) and not fs.isDir(file) then
		local f = fs.open(file,"r")
		data = textutils.unserialize(f.readAll()) or {}
		f.close()
	else
		data = {}
		if fs.exists(file) then fs.delete(file) end
	end
	local out = {}
	function out.get(key, default)
		if data[key] ~= nil then return data[key] end
		return default
	end
	function out.set(key,value)
		data[key] = value
		local f = fs.open(file,"w")
		f.write(textutils.serialize(data))
		f.close()
	end
	return out
end