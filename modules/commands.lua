local command_table = {}

function addCommand(command, f)
	command_table[string.lower(command)] = f
end

function runCommand(args)
	local command = string.lower(args[1])

	if command_table[command] then
		command_table[command](args)
		return true
	end

	return false
end

function init(_, _)
end
