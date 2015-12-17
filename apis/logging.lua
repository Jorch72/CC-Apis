levels = {}
levels.fine = -1
levels[-1] = "FINE"
levels.info = 0
levels[0] = "INFO"
levels.warning = 1
levels[1] = "WARNING"
levels.error = 2
levels[2] = "ERROR"
levels.success = 3
levels[3] = "SUCCESS"

local start = os.clock()
local fileout
local termout = true
local colored = true

-- symbols
-- {{msg}} message
-- {{time}} os.clock value
-- {{running}} time since program started
-- {{level}} logging level
local termformat = "{{msg}}"
local fileformat = "[{{level}}] {{running}}: {{msg}}"

function setTermOutput(bool)
	termout = bool
end

function setFileOut(file)
	fileout = file
end

function setTermFormat(str)
	termformat = str
end

function setFileFormat(str)
	fileformat = str
end

function setColored(bool)
	colored = bool
end


local function format(str, msg, lvl)
	str = str:gsub("{{msg}}",msg):gsub("{{time}}",os.clock()):gsub("{{running}}",os.clock() - start):gsub("{{level}}",levels[lvl])
	return str
end

function log(msg, level)
	level = level or levels.info
	if termout then
		local old = term.getTextColor()
		if colored then
			if level == levels.fine then
				term.setTextColor(colors.lightGray)
			elseif level == levels.warning and term.isColor() then
				term.setTextColor(colors.yellow)
			elseif level == levels.error and term.isColor() then
				term.setTextColor(colors.red)
			elseif level == levels.success and term.isColor() then
				term.setTextColor(colors.green)
			else
				term.setTextColor(colors.white)
			end
		end
		print(format(termformat,msg,level))
		term.setTextColor(old)
	end
	if fileout then
		local f = fs.open(fileout,"a")
		f.write(format(fileformat,msg,level).."\n")
		f.close()
	end
end