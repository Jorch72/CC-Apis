function escape(str)
	str = str:gsub("\\","\\\\")
	str = str:gsub("\"","\\\"")
	str = str:gsub("\n","\\n")
	str = str:gsub("\t","\\t")
	return str
end

-- todo
function minify(str)
	return str
end