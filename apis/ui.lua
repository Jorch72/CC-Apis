local function tblToString(tbl)
	local s = ""
	for i,v in ipairs(tbl) do
		s = s .. v
	end
	return s
end

local function colorToHex(color)
	return string.format("%.1x",math.log(color) / math.log(2))
end

function read(width, maxlen, placeholder, bg, fg, placeholdercolor)
	local x, y = term.getCursorPos()
	local sx, sy = term.getSize()
	width = width or sx - x
	maxlen = maxlen or -1
	placeholder = placeholder or ""
	bg = bg or term.getBackgroundColor()
	fg = fg or term.getTextColor()
	placeholdercolor = placeholdercolor or fg
	local scroll = 0
	local pos = 0
	local text = {}
	local function draw()
		term.setCursorPos(x,y)
		local str = tblToString(text)
		local s = str:sub(scroll + 1, scroll + width)
		if #s < width then
			s = s .. (" "):rep(width - #s)
		end
		term.blit(s, colorToHex(fg):rep(#s), colorToHex(bg):rep(#s))
		term.setCursorPos(x + pos - scroll,y)
		term.setCursorBlink(true)
	end
	draw()
	while true do
		local e = {os.pullEvent()}
		if e[1] == "char" then
			if maxlen <= 0 or #text < maxlen then 
				pos = pos + 1
				if pos >= width then
					scroll = scroll + 1
				end
				table.insert(text, pos, e[2])
			end
		end
		if e[1] == "key" then
			if e[2] == keys.backspace then
				if #text > 0 then
					table.remove(text,pos)
					if pos > 0 then
						pos = pos - 1
					end
					if scroll > #text - width and scroll > 0 then
						scroll = scroll - 1
					end
				end
			end
			if e[2] == keys.right then
				if pos < #text then
					pos = pos + 1
					if pos - scroll >= width then
						scroll = scroll + 1
					end
				end
			end
			if e[2] == keys.left then
				if pos > 0 then
					pos = pos - 1
					if pos < scroll then
						scroll = scroll - 1
					end
				end
			end
			if e[2] == keys.enter or e[2] == keys.tab then
				return tblToString(text), e[2] == keys.tab
			end
		end
		draw()
	end
end