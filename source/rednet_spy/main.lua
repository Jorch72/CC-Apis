@include args
@include logging
@include resources

local args = args.parse({...})

local modem = peripheral.find("modem")
assert(modem,resources.no_modem)

-- initialize logging
local logfile = logging.nextAvailableFile("logs/rednet_spy_%d.log")
logging.setFileOut(logfile)

logging.setTermFormat("[{{running}}] {{msg}}")
logging.setFileFormat("[{{running}}] {{msg}}")

logging.log(resources.start, logging.levels.info)

modem.open(resources.channel)

local function parse(data)
	if type(data) == table then
		return textutils.serialize(data)
	else
		return tostring(data)
	end
end

while true do
	local e = {os.pullEvent()}
	if e[1] == "modem_message" and e[3] == resources.channel then
		logging.log(resources.message_format:gsub("{{id}}",e[4]):gsub("{{msg}}",parse(e[5])),logging.levels.fine)
	end
end