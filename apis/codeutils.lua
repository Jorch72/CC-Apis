function escape(str, readable)
	str = str:gsub("\\","\\\\")
	str = str:gsub("\"","\\\"")
	if readable then
		str = str:gsub("\n","\\\n")
	else
		str = str:gsub("\n","\\n")
		str = str:gsub("\t","\\t")
	end
	return str
end

-- todo
function minify(str)
	return str
end