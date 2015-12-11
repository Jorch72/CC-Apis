local args = {...}

--[[
	subcommands
		launch <file>	downloads dependencies and runs program with apecore api
		prepare <file>	downloads dependencies, does not run program
		clear			clears dependency cache (removes all downloaded files)
		loadapi			loads the apecore api globally
		update			redownloads repository
	options
		-l				enable logging
		-o				offline mode (don't connect to the internet at all)
		-v				verbose mode
	metadata
		the following metadata is currently parsed and used by apecore:
		--@deps


]]

local installdir = "/.apecore"
local pkgdir = "/.apecore/packages"
local cache = "/.apecore/cache.txt"

local api = {}
local packagelist = {}

api.repo = "https://raw.githubusercontent.com/apemanzilla/apecore/master/repository"

if not fs.exists(installdir) then
	fs.makeDir(installdir)
end
if not fs.exists(pkgdir) then
	fs.makeDir(pkgdir)
end

function api.parseDep(depstring)
	-- parses a dependency string from a repository entry into package ids
	local deps = {}
	for dep in depstring:gmatch("([%w%-%.:]+)") do
		table.insert(deps, dep)
	end
	return deps
end

function api.parseEntry(entry)
	-- parses a line from a repository to get package data
	local name, version, url, dep
	name, version, url, dep = entry:match("^([%w%-%.]+):([%d%.]+):%[([^%[^%]]+)]:%[([^%[^%]]*)]$") -- ugly as hell pattern, but it
	if not (name and version and url) then
		return false
	end
	--return name, version, url, api.parseDep(dep)
	local pkg = {}
	pkg.url = url
	pkg.deps = api.parseDep(dep)
	return name, version, pkg
end

function api.loadRepo(url)
	local data
	if not url then
		if fs.exists(cache) then
			local f = fs.open(cache, "r")
			data = f.readAll()
			f.close()
		else
			return
		end
	else
		local h = http.get(url)
		if not h then return false end
		data = h.readAll()
		h.close()
	end
	for entry in data:gmatch("[^\n]+") do
		if entry ~= "" then
			local name, version, pkg = api.parseEntry(entry)
			local version = tonumber(version)
			if name then
				if not packagelist[name] then
					packagelist[name] = {}
				end
				if not packagelist[name][version] then
					packagelist[name][version] = pkg
				end
			end
		end
	end
	local f = fs.open(cache, "w")
	f.write(data)
	f.close()
end

function api.parseMeta(data)
	local tags = {}
	for name, value in data:gmatch("%-%-@(%w+):%s+([^\n]+)") do
		tags[name] = value
	end
	return tags
end

function api.getUrls(idlist, tbl)
	local urls = tbl or {}
	for _, id in pairs(idlist) do
		-- id should be formatted as such:
		-- example:1.0
		-- to download version 1.0 of package example, OR
		-- example
		-- to download the latest version of package example
		local name, version
		name, version = id:match("^([%w%-%.]+):([%d%.]+)$")
		if not name then
			name = id:match("^([%w%-%.]+)$")
		end
		assert(packagelist[name], "package not available: "..name)
		if version then version = tonumber(version) else
			for k,v in pairs(packagelist[name]) do
				if not version then version = k end
				if k > version then version = k end
			end
		end
		assert(packagelist[name][version], "package version not available: "..name.." v"..version)
		local add = true
		for _,v in pairs(urls) do
			if v == packagelist[name][version].url then
				add = false
				break
			end
		end
		if add then
			--table.insert(urls, packagelist[name][version].url)
			urls[name..":"..version] = packagelist[name][version].url
		end
		api.getUrls(packagelist[name][version].deps, urls)
	end
	return urls
end

local function findVal(tbl, value)
	for k,v in pairs(tbl) do
		if v == value then
			return k
		end
	end
end

function api.download(urls)
	-- downloads all listed urls into packages folder
	local tries = {}
	local pending = 0
	for _, url in pairs(urls) do
		tries[url] = 1
		http.request(url)
		pending = pending + 1
	end
	while pending > 0 do
		local e = {os.pullEvent()}
		if e[1] == "http_success" then
			if tries[e[2]] then
				pending = pending - 1
				local dat = findVal(urls, e[2])
				local name, version = dat:match("^([%w%-%.]+):([%d%.]+)$")
				if not fs.exists(pkgdir) then
					fs.makeDir(pkgdir)
				end
				local tempdir = fs.combine(pkgdir, name)
				if not fs.exists(tempdir) then
					fs.makeDir(tempdir)
				end
				local f = fs.open(fs.combine(tempdir, version), "w")
				f.write(e[3].readAll())
				f.close()
				e[3].close()
			end
		elseif e[1] == "http_failure" then
			if tries[e[2]] then
				if tries[e[2]] == 3 then
					error("failed to download packages")
				else
					tries[e[2]] = tries[e[2]] + 1
					http.request(e[2])
				end
			end
		end
	end
end

function api.resolve(package)
	-- gets a local path to a package or returns false if it is not present
	local name, version
	name, version = package:match("^([%w%-%.]+):([%d%.]+)$")
	if not name then
		name = package:match("^([%w%-%.]+)$")
	end
	if fs.exists(fs.combine(pkgdir, name)) then
		if version then
			version = tonumber(version)
			if fs.exists(fs.combine(pkgdir, fs.combine(name, tostring(version)))) then
				return fs.combine(pkgdir, fs.combine(name, tostring(version)))
			end
			return false
		else
			local versions = packagelist[name]
			local highest = 0
			for v,_ in ipairs(versions) do
				if tonumber(v) > highest then highest = tonumber(v) end
			end
			if fs.exists(fs.combine(pkgdir, fs.combine(name, tostring(highest)))) then
				return fs.combine(pkgdir, fs.combine(name, tostring(highest)))
			end
			return false
		end
	else
		return false
	end
end

function api.load(package)
	local e = {}
	-- add apecore api to environment
	e.apecore = api
	setmetatable(e, {__index = _G})
	local pkg = api.resolve(package)
	if pkg then
		--loadfile(pkg,"t",e)()
		local f = fs.open(pkg,"r")
		local data = f.readAll()
		f.close()
		local fn = load(data, "pkg_"..package, "t", e)
		local ok, err = pcall(fn)
		if ok then
			setmetatable(e, nil)
			return e
		else
			error(err, -1)
		end
	else
		error("package not present")
	end
end

return api