@include resources
@include args
@include fsutils
@include codeutils
@include tblutils
@include logging

local args = args.parse({...})

if args.help or args["?"] then
	term.setTextColor(colors.white)
	print(resources.usage)
	return
end

if args.i then args.input = args.i end
if args.o then args.output = args.o end
if args.r then args.run = args.r end
if args.I then args.ignoreMissing = args.I end
if args.O then args.overwrite = args.O end

if args.output then
	args.output = fsutils.resolve(args.output, shell.dir())
end

local apipath = _G.APIPATH or resources.apipath
local apiext = _G.APIEXT or resources.apiext

if not args.input then
	logging.log(resources.no_input, logging.levels.error)
	logging.log(resources.usage_tip, logging.levels.error)
	return
end

local file = fsutils.resolve(args.input, shell.dir())
logging.log(string.format(resources.building,file),logging.levels.info)

if not (args.output or args.run) then
	logging.log(resources.no_action, logging.levels.warning)
end

local function locate(api, base)
	-- where base is the folder containing the requesting file
	local out
	for spath in apipath:gmatch("([^:]+)") do
		spath = fsutils.resolve(spath,base)
		for ext in apiext:gmatch("([^:]+)") do
			if fs.exists(fsutils.resolve(api..ext,spath)) then
				out = fsutils.resolve(api..ext,spath)
				break
			end
		end
		if not out then
			if fs.exists(fsutils.resolve(api,spath)) then
				out = fsutils.resolve(api,spath)
			end
		end
		if out then break end
	end
	return out
end

local function parseRecurse(file)
	local paths = {}
	local f = fs.open(file,"r")
	local fdata = f.readAll()
	if not fdata:sub(#fdata) == "\n" then fdata = fdata.."\n" end
	f.close()
	for inclusion in fdata:gmatch("@include (%w+)\n") do
		local p = locate(inclusion, fs.getDir(file))
		if p then
			fdata = fdata:gsub("@include "..inclusion.."\n",string.format(resources.req_string,inclusion,p).."\n")
			local fd, incpaths = parseRecurse(p)
			paths[p] = fd
			for k,v in pairs(incpaths) do
				if not paths[k] then paths[k] = v end
			end
		else
			if args.ignoreMissing then
				logging.log(string.format(resources.missing_api,inclusion,file),logging.levels.warning)
				fdata = fdata:gsub("@include (%w+)\n","\n")
			else
				logging.log(string.format(resources.missing_api,inclusion,file),logging.levels.error)
				error("",0)
			end
		end
	end
	return fdata, paths
end

local fdata, paths = parseRecurse(file)
logging.log(string.format(resources.parsed,tblutils.count(paths))..((tblutils.count(paths) ~= 1 and "s") or ""), logging.levels.fine)
logging.log(resources.assembling,logging.levels.fine)

local output = ""

output = output .. resources.pre_load
for k,v in pairs(paths) do
	local _, e = load(v)
	if e then
		logging.log(string.format(resources.syntax_err,k),logging.levels.error)
		logging.log(e,logging.levels.error)
		return
	end
	output = output .. string.format(resources.load, k, codeutils.escape(v,true))
end
local _, e  = load(fdata)
if e then
	logging.log(string.format(resources.syntax_err,file),logging.levels.error)
	logging.log(e,logging.levels.error)
	return
end
output = output .. string.format(resources.loadf, codeutils.escape(fdata, true), fs.getName(file))
output = output .. resources.post_load

logging.log(resources.build_success,logging.levels.success)

if args.output then
	logging.log(resources.writing, logging.levels.info)
	if fs.exists(args.output) then
		if not args.overwrite then
			logging.log(string.format(resources.overwrite_err, args.output), logging.levels.error)
			return
		else
			logging.log(string.format(resources.overwriting, args.output), logging.levels.warning)
		end
	end
	local f = fs.open(args.output,"w")
	f.write(output)
	f.close()
	logging.log(resources.written,logging.levels.success)
end

if args.run then
	logging.log()
end