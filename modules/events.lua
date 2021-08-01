local listeners = {}

function addEventListener(event, func)
	if not listeners[event] then
		listeners[event] = {}
	end
	table.insert(listeners[event], func)
end
function triggerEvent(...)
	local event = arg[1]
	table.remove(arg, 1)

	if listeners[event] then
		for _, l in listeners[event] do
			l(unpack(arg))
		end
	end

end
