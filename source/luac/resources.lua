version = {}
version.major = 4
version.minor = 0
version.patch = 0
version.meta = "alpha"

-- strings
usage = [[usage: luac <input> [output] [options]
OPTIONS
  -i, -input <path>: alternate way of specifying input file
  -o, -output <path>: alternate way of specifying output file
  -r, -run: run the output after building
  -I, -ignoreMissing: continue build even if some apis are not found
  -O, -overwrite: if output file exists, overwrite it
  -v, -version: show version information
  -?, -help: show this information]]
version_str = string.format("luac v%s.%s.%s %s",version.major,version.minor,version.patch,version.meta)
apipath = [[.:apis:lib:/apis:/lib:/rom/apis]]
apiext = [[.lua]]
no_input = [[no input specified]]
missing_input = [[input file non-existant]]
input_dir_no_main = [[cannot find main.lua in directory]]
usage_tip = [[use -help to show usage]]
building = [[building '%s']]
req_string = [[local %s = require("%s")]]
no_action = [[no action specified]]
missing_api = [[failed to find '%s' as requested by '%s']]
parsed = [[recursively found %i inclusion]]
assembling = [[assembling output...]]
syntax_err = [[syntax error in '%s']]
build_success = [[build successful]]
writing = [[saving output as file]]
overwrite_err = [[output file '%s' already exists]]
overwriting = [[output file '%s' already exists, overwriting]]
written = [[output written successfully]]

-- code
pre_load = [[assert(_CC_VERSION or _HOST, "CC 1.74+ required!")
local apis = {}
local loaded = {}
]]
load = [[apis["%s"] = "%s"
]]
loadf = [[local main = "%s"
local name = "%s"
]]
post_load = [[local function require(path)
	if loaded[path] then return loaded[path] end
	if not apis[path] then return {} end
	local e = {}
	e.require = require
	setmetatable(e,{__index = _ENV})
	load(apis[path],fs.getName(path),nil,e)()
	local out = {}
	for k,v in pairs(e) do
		if k == "__const" then
			setmetatable(out, {__call = function(_,...) return v(...) end})
		else
			out[k] = v
		end
	end
	if out.require and out.require == require then out.require = nil end
	loaded[path] = out
	return out
end
local e = {}
setmetatable(e,{__index=_ENV})
e.require = require
return load(main, name, nil, e)(...)]]