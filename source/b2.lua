@include args
@include codeutils
@include fsutils
@include logging

local apipath = _G.APIPATH or ".:apis:lib:/apis:/lib"
local apiext = _G.APIEXT or ".lua"

local args = args.parse({...})

if args.i then args.input = args.i end
if args.o then args.output = args.o end
if args.r then args.run = args.r end

if args.input then args.input = fsutils.resolve(args.input,shell.dir()) end
if args.output then args.output = fsutils.resolve(args.output,shell.dir()) end

if not fs.exists(args.input) then
	logging.log("cannot find input file",logging.levels.error)
	return
end

if not args.input then
	logging.log("no input specified",logging.levels.error)
	return
end

if not (args.output or args.run) then
	logging.log("no output action specified",logging.levels.warning)
end

logging.log(string.format("building '%s'",args.input),logging.levels.info)

local to_pack = {}

local function locateAPI(apiname, base)
	local found
	for search in apipath:gmatch("([^:]+)") do
		for ext in apiext:gmatch("([^:]+)") do
			local path = fs.combine(fsutils.resolve(search,base),apiname..ext)
			if fs.exists(path) then
				found = path
				break
			end
		end
		if not found then
			local path = fs.combine(fsutils.resolve(search,base),apiname)
			if fs.exists(path) then
				found = path
				break
			end
		else
			break
		end
	end
	return found
end

local function parseTree(file)
	local incpaths = {}
	local missing = {}
	local f = fs.open(file,"r")
	local fd = f.readAll()
	f.close()
	for inc in fd:gmatch("@include%s+(%w+)") do
		local found = locateAPI(inc,fs.getDir(file))
		if found then
			incpaths[inc] = found
		else
			table.insert(missing,inc)
		end
	end
	for k,v in pairs(incpaths) do
		local r,m = parseTree(v)
		for k,v in pairs(r) do
			incpaths[k] = v
		end
		for i,v in ipairs(m) do
			table.insert(m,v)
		end
	end
	return incpaths, missing
end