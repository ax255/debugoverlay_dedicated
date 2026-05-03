if not game.IsDedicated() then
	return
end

local debug_type = {
	["Axis"] = {"Vector", "Angle", "Float", "Float", "Bool"},
	["Box"] = {"Vector", "Vector", "Vector", "Float", "Color"},
	["BoxAngles"] = {"Vector", "Vector", "Vector", "Angle", "Float", "Color"},
	["Cross"] = {"Vector", "Float", "Float", "Color", "Bool"},
	["EntityTextAtPosition"] = {"Vector", "Float", "String", "Float", "Color"},
	["Grid"] = {"Vector"},
	["Line"] = {"Vector", "Vector", "Float", "Color", "Bool"},
	["ScreenText"] = {"Float", "Float", "String", "Float", "Color"},
	["Sphere"] = {"Vector", "Float", "Float", "Color", "Bool"},
	["SweptBox"] = {"Vector", "Vector", "Vector", "Vector", "Angle", "Float", "Color"},
	["Text"] = {"Vector", "String", "Float", "Bool"},
	["Triangle"] = {"Vector", "Vector", "Vector", "Float", "Color", "Bool"},
}

local dev_convar = GetConVar("developer")

if SERVER then
	util.AddNetworkString("debugoverlay_network")
	local debug_write = {}

	for name, types in pairs(debug_type) do
		debug_write[name] = function(...)
			local args = {...}

			for i, var in ipairs(args) do
				net["Write" .. types[i]](var)
			end
		end
	end

	for name, func in pairs(debugoverlay) do
		if debug_write[name] then
			debugoverlay[name] = function(...)
				if dev_convar:GetInt() < 1 then return end

				net.Start("debugoverlay_network")
				net.WriteString(name)
				debug_write[name](...)
				net.Broadcast()
			end
		end
	end
else
	local debug_read = {}

	for name, types in pairs(debug_type) do
		debug_read[name] = function()
			local args = {}

			for i, type_name in ipairs(types) do
				args[#args + 1] = net["Read" .. type_name]()
			end

			return unpack(args)
		end
	end

	net.Receive("debugoverlay_network", function()
		local name = net.ReadString()

		if debug_read[name] then
			debugoverlay[name](debug_read[name]())
		end
	end)
end