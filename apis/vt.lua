-- virtual turtle api

local df = {
	[0] = {		-- South
		dx = 0,
		dz = 1,
		name = "South"
	},
	[1] = {		-- West
		dx = -1,
		dz = 0,
		name = "West"
	},
	[2] = {		-- North
		dx = 0,
		dz = -1,
		name = "North"
	},
	[3] = {		-- East
		dx = 1,
		dz = 0,
		name = "East"
	}
}

local blocks = {
	grass = {name="minecraft:grass",metadata=0},
	dirt = {name="minecraft:dirt",metadata=0},
	stone = {name="minecraft:stone",metadata=0},
	cobble = {name="minecraft:cobblestone",metadata=0},
	bedrock = {name="minecraft:bedrock",metadata=0},
	coalore = {name="minecraft:coal_ore",metadata=0},
	coal = {name="minecraft:coal",metadata=0},
	ironore = {name="minecraft:iron_ore",metadata=0},
	goldore = {name="minecraft:gold_ore",metadata=0},
	diamondore = {name="minecraft:diamond_ore",metadata=0},
	diamond = {name="minecraft:diamond",metadata=0}
}

local function breakBlock(block)
	-- 'breaks' a block, converting it into an item
	-- special cases first, like ores and cobblestone
	if block.name == blocks.coalore.name then
		return {name=blocks.coal.name,damage=0,count=1}
	elseif block.name == blocks.diamondore.name then
		return {name=blocks.diamond.name,damage=0,count=1}
	elseif block.name == blocks.stone.name then
		return {name=blocks.cobble.name,damage=0,count=1}
	elseif block.name == blocks.grass.name then
		return {name=blocks.dirt.name,damage=0,count=1}
	end
	return {name=block.name,damage=block.metadata,count=1}
end

local function placeItem(item)
	-- 'places' an item, converting it to a block if possible.
	if item.name == blocks.coal or item.name == blocks.diamond then
		return false
	end
	return {name=item.name,metadata=item.damage}
end

local fuels = {
	-- format: itemid = fuelamount
	["minecraft:coal"] = 80
}

local errors = {
	-- errors that can be returned by various turtle functions
	noFuel = "Out of fuel",
	blocked = "Movement obstructed",
	nothingToDig = "Nothing to dig here",
	unbreakable = "Unbreakable block detected",
	tooHigh = "Too high to move",
	tooLow = "Too low to move",
	noToolDig = "No tool to dig with",
	noToolAttack = "No tool to attack with",
	invalidRecipe = "No matching recipes",
	cantSuck = "No items to take",
	cantDrop = "No items to drop",
	cantInspect = "No block to inspect",
	notEnoughItems = "Not enough items"
}

local function delay(seconds)
	-- fail-safe version of 'sleep' - will requeue dropped events
	if seconds == 0 then return end
	local timer = os.startTimer(seconds)
	local q = {}
	while true do
		local data = {os.pullEvent()}
		if data[1] == "timer" and data[2] == timer then
			break
		else
			table.insert(q, data)
		end
	end
	for i,v in ipairs(q) do
		os.queueEvent(unpack(v))
	end
end

local function genBlock(x, y, z, seed)
	if (y >= 64) then return {} end
	if (y == 63) then return blocks.grass end
	if (y < 63 and y >= 60) then return blocks.dirt end
	if (y < 60 and y > 1) then
		-- ore generation
		if y < 55 and math.random(1,150) <= 1 then
			return blocks.ironore
		elseif math.random(1,25) <= 1 then
			return blocks.coalore
		else
			return blocks.stone
		end
	end
	if (y == 1) then return blocks.bedrock end
end

local function genWorld(x, z)
	-- generates a world as a table
	local x = x or 99
	local z = z or 99
	local data = {}
	local startx = math.floor(0-x/2)
	local endx = x + startx
	local startz = math.floor(0-z/2)
	local endz = z + startz
	for i = startx, endx do
		data[i] = {}
		for j = 1, 255 do
			data[i][j] = {}
			for k = startz, endz do
				if (i == startx or i == endx) or (k == startz or k == endz) then
					data[i][j][k] = blocks.bedrock
				else
					data[i][j][k] = genBlock(i, j, k)
				end
			end
		end
	end
	return data
end

function posDisplay(data)
	-- onUpdate function to display the virtual turtle's position
	local x,y = term.getCursorPos()
	term.setCursorPos(1,1)
	term.clearLine()
	term.write("X:"..data.x.." Y:"..data.y.." Z:"..data.z.." F:"..df[data.f].name.." Fuel:"..data.fuel)
	term.setCursorPos(x,y)
end

function new(isMining, fuel, timescale, onUpdate)
	local e = {}
	local timescale = timescale or 1
	local moveTime, actTime = 0.5 * timescale, 0.05 * timescale
	setmetatable(e, {__index=_G})
	local x, y, z, f = 0, 64, 0, 0
	local fuel = fuel or 200
	local maxfuel = 100000
	local inv = {}
	for i = 1, 16 do
		inv[i] = {}
	end
	local selected = 1 -- selected slot in inventory
	local world = genWorld(49,49)
	local onUpdate = onUpdate or function(turtledata) end
	local function update()
		onUpdate({x = x,
			y = y,
			z = z,
			f = f,
			fuel = fuel,
			inv = inv,
			world = world,
			mining = isMining,
			selected = selected})
	end
	e.gps = {}
	e.gps.locate = function()
		return x,
		 y, z
	end
	e.turtle = {}
	e.turtle.forward = function()
		if world[x + df[f].dx][y][z + df[f].dz].name then return false, errors.blocked end
		if fuel < 1 then return false, errors.noFuel end
		fuel = fuel - 1
		delay(moveTime)
		x = x + df[f].dx
		z = z + df[f].dz
		update()
		return true
	end
	e.turtle.back = function()
		if world[x - df[f].dx][y][z - df[f].dz].name then return false, errors.blocked end
		if fuel < 1 then return false, errors.noFuel end
		fuel = fuel - 1
		delay(moveTime)
		x = x - df[f].dx
		z = z - df[f].dz
		update()
		return true
	end
	e.turtle.up = function()
		if y >= 255 then return false, errors.tooHigh end
		if world[x][y + 1][z].name then return false, errors.blocked end
		if fuel < 1 then return false, errors.noFuel end
		fuel = fuel - 1
		delay(moveTime)
		y = y + 1
		update()
		return true
	end
	e.turtle.down = function()
		if world[x][y - 1][z].name then return false, errors.blocked end
		if fuel < 1 then return false, errors.noFuel end
		if y > 1 then
			fuel = fuel - 1
			delay(moveTime)
			y = y - 1
			update()
			return true
		end
		return false, errors.tooLow
	end
	e.turtle.turnRight = function()
		delay(moveTime)
		f = f + 1
		if f > 3 then f = 0 end
		update()
		return true
	end
	e.turtle.turnLeft = function()
		delay(moveTime)
		f = f - 1
		if f < 0 then f = 3 end
		update()
		return true
	end
	e.turtle.getFuelLevel = function()
		return fuel
	end
	e.turtle.getFuelLimit = function()
		return maxfuel
	end
	e.turtle.select = function(slot)
		if slot < 1 or slot > 16 then
			error("Slot number "..slot.." out of range")
		end
		update()
		return true
	end
	e.turtle.getSelectedSlot = function()
		return selected
	end
	e.turtle.getItemCount = function(slot)
		local slot = slot or selected
		if slot < 1 or slot > 16 then
			error("Slot number "..slot.." out of range")
		end
		return inv[slot].count or 0
	end
	e.turtle.getItemSpace = function(slot)
		local slot = slot or selected
		if slot < 1 or slot > 16 then
			error("Slot number "..slot.." out of range")
		end
		return (inv[slot].count and 64 - inv[slot].count) or 64
	end
	e.turtle.getItemDetail = function(slot)
		local slot = slot or selected
		if slot < 1 or slot > 16 then
			error("Slot number "..slot.." out of range")
		end
		if inv[slot].name then return inv[slot] else return end
	end
	e.turtle.equipLeft = function()
		-- nyi
		return false
	end
	e.turtle.equipRight = function()
		-- nyi
		return false
	end
	e.turtle.attack = function()
		-- nyi
		return false
	end
	e.turtle.attackUp = function()
		-- nyi
		return false
	end
	e.turtle.attackDown = function()
		-- nyi
		return false
	end
	local fitItem = function(itemdata)
		-- tries to fit item(s) into turtle's inventory
		for slot = 1, 16 do
			if itemdata.count > 0 then
				if inv[slot].name then
					if inv[slot].name == itemdata.name and inv[slot].damage == itemdata.damage then
						if inv[slot].count + itemdata.count > 64 then
							itemdata.count = inv[slot].count + itemdata.count - 64
							inv[slot].count = 64
						else
							inv[slot].count = inv[slot].count + itemdata.count
							itemdata.count = 0
						end
					end
				else
					inv[slot].name = itemdata.name
					inv[slot].damage = itemdata.damage
					inv[slot].count = itemdata.count
					if inv[slot].count > 64 then
						itemdata.count = itemdata.count - 64
						inv[slot].count = 64
					else
						itemdata.count = 0
					end
				end
			end
		end
	end
	e.turtle.dig = function()
		if not isMining then return false, errors.noToolDig end
		if world[x + df[f].dx][y][z + df[f].dz].name == blocks.bedrock.name then return false, errors.unbreakable end
		if world[x + df[f].dx][y][z + df[f].dz].name then
			fitItem(breakBlock(world[x + df[f].dx][y][z + df[f].dz]))
			world[x + df[f].dx][y][z + df[f].dz] = {}
			delay(moveTime)
			return true
		else
			return false, errors.nothingToDig
		end
	end
	e.turtle.digUp = function()
		if not isMining then return false, errors.noToolDig end
		if world[x][y+1][z].name == blocks.bedrock.name then return false, errors.unbreakable end
		if world[x][y+1][z].name then
			fitItem(breakBlock(world[x][y+1][z]))
			world[x][y+1][z] = {}
			delay(moveTime)
			return true
		else
			return false, errors.nothingToDig
		end
	end
	e.turtle.digDown = function()
		if not isMining then return false, errors.noToolDig end
		if world[x][y-1][z].name == blocks.bedrock.name then return false, errors.unbreakable end
		if world[x][y-1][z].name then
			fitItem(breakBlock(world[x][y-1][z]))
			world[x][y-1][z] = {}
			delay(moveTime)
			return true
		else
			return false, errors.nothingToDig
		end
	end
	e.turtle.detect = function()
		if world[x + df[f].dx][y][z + df[f].dz].name then
			return true
		else
			return false
		end
	end
	e.turtle.detectUp = function()
		if world[x][y+1][z].name then
			return true
		else
			return false
		end
	end
	e.turtle.detectDown = function()
		if world[x][y-1][z].name then
			return true
		else
			return false
		end
	end
	e.turtle.refuel = function(amt)
		if fuels[inv[selected].name] then
			if amt > inv[selected].count then return false, errors.notEnoughItems end
			fuel = fuel + (fuels[inv[selected].name] * amt)
			inv[selected].count = inv[selected].count - amt
			if inv[selected].count == 0 then inv[selected] = {} end
			return true
		else
			return false
		end
	end
	e.turtle.drop = function(amt)
		if inv[selected].name then
			local amt = amt or inv[selected].count
			if amt <= inv[selected].count then
				inv[selected].count = inv[selected].count - amt
				if inv[selected].count == 0 then
					inv[selected] = {}
				end
				return true
			else
				return false
			end
		else
			return false, errors.cantDrop
		end
	end
	e.turtle.place = function()
		if inv[selected].name then
			if not world[x + df[f].dx][y][z + df[f].dz].name then
				if placeItem(inv[selected]) then
					world[x + df[f].dx][y][z + df[f].dz] = placeItem(inv[selected])
					inv[selected].count = inv[selected].count - 1
					if inv[selected].count == 0 then
						inv[selected] = {}
					end
					return true
				end
				return false
			else
				return false
			end
		else
			return false, errors.notEnoughItems
		end
	end
	e.turtle.placeDown = function()
		if inv[selected].name then
			if not world[x][y-1][z].name then
				if placeItem(inv[selected]) then
					world[x][y-1][z] = placeItem(inv[selected])
					inv[selected].count = inv[selected].count - 1
					if inv[selected].count == 0 then
						inv[selected] = {}
					end
					return true
				end
				return false
			else
				return false
			end
		else
			return false, errors.notEnoughItems
		end
	end
	e.turtle.placeUp = function()
		if inv[selected].name then
			if not world[x][y+1][z].name then
				if placeItem(inv[selected]) then
					world[x][y+1][z] = placeItem(inv[selected])
					inv[selected].count = inv[selected].count - 1
					if inv[selected].count == 0 then
						inv[selected] = {}
					end
					return true
				end
				return false
			else
				return false
			end
		else
			return false, errors.notEnoughItems
		end
	end
	e.turtle.dropUp = e.turtle.drop
	e.turtle.dropDown = e.turtle.drop
	-- DEBUG
	e.addItem = fitItem

	return e
end

function run(prog, args, ...)
	local e = new(...)
	if prog then
		if setfenv then
			local data = loadfile(prog)
			setfenv(data, e)(unpack(args))
		else
			loadfile(prog, "t", e)(unpack(args))
		end
	end
end