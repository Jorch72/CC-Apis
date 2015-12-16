function contains(table, value)
	for k,v in pairs(table) do
		if v == value then return true end
	end
	return false
end

function count(table)
	local i = 0
	for _,_ in pairs(table) do
		i = i + 1
	end
	return i
end