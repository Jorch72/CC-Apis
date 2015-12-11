function resolve(path, base)
	local s = string.sub( path, 1, 1 )
	if s == "/" or s == "\\" then
		return fs.combine( "", path )
	else
		return fs.combine( base, path )
	end
end