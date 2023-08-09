local plm_dissector = require "plm_dissector"
local TableHelper = require "TableHelper"
require "PrintTable"

if (gui_enabled()) then 
	-- Note that everything is "local" to this "if then" 
	-- this way we don't add globals

	local export_open = false

	local date = rawget(os,"date") -- use rawget to avoid disabled's os.__index

	if type(date) ~= "function" then
		-- 'os' has been disabled, use a dummy function for date
		date = function() return "" end
	end

    local payload_field = Field.new("tcp.payload")
    local reassembled_in = Field.new("tcp.reassembled_in")
    local segment_count = Field.new("tcp.segment.count")

    local function get_save_path()
        local save_path = os.getenv("USERPROFILE") .. "\\Documents\\PLM_Protocol\\"
        if not Dir.exists(save_path) then
            Dir.make(save_path)
        end
        return save_path
    end

    local function remove_defined_protocol(protocoldata, packetdata, finddata, key)
        local beginindex, _ = string.find(packetdata, finddata)
        if beginindex == nil then
            protocoldata[key] = nil
        end
    end

    local function save_Undefined_protocol()

        local save_filepath = get_save_path() .. "PLM_Undefined_Protocol_" .. os.date("%Y-%m-%d-%H-%M-%S")  .. ".txt"
        local file = assert(io.open(save_filepath, "w"))
        local undefinedprotocoldata = TableHelper:deepcopytable(plm_dissector.protocoldata)
        for key, protocoldatas in pairs(undefinedprotocoldata) do
            if plm_dissector.protocoltype[key] == plm_dissector.dissectortype.PLM_HTTP then
                undefinedprotocoldata[key] = nil
            end
            for _, protocoldata in ipairs(protocoldatas) do
                if protocoldata["MSG_ID"] ~= nil then
                    remove_defined_protocol(undefinedprotocoldata, protocoldata["MSG_ID"], "Unknown", key)
                    remove_defined_protocol(undefinedprotocoldata, protocoldata["MSG_ID"], "Undefined", key)
                elseif protocoldata["ACTION"] ~= nil then
                    remove_defined_protocol(undefinedprotocoldata, protocoldata["ACTION"], "-1", key)
                end
            end
        end
        file:write(string.format("Undefined Protocol Count:%d\n\n", TableHelper:getTableLength(undefinedprotocoldata)))
        for number, protocoldata in TableHelper:pairsByKeys(undefinedprotocoldata) do
            local data = GetTableString(protocoldata)
            local type = plm_dissector:get_dissector_name(plm_dissector.protocoltype[number])
            file:write(string.format("Frame:%d Type:%s %s\n", number, type, data))
        end
        file:close()
        print("Save undefined protocol to path:" .. save_filepath)
    end

    local function save_all_protocol()

        local save_filepath = get_save_path() .. "PLM_Protocol_" .. os.date("%Y-%m-%d-%H-%M-%S")  .. ".txt"
        local file = assert(io.open(save_filepath, "w"))
        file:write(string.format("Protocol Count:%d\n\n", TableHelper:getTableLength(plm_dissector.protocoldata)))
        for number, protocoldata in TableHelper:pairsByKeys(plm_dissector.protocoldata) do
            local data = GetTableString(protocoldata)
            local type = plm_dissector:get_dissector_name(plm_dissector.protocoltype[number])
            file:write(string.format("Frame:%d Type:%s %s\n", number, type, data))
        end
        file:close()
        print("Save all protocol to path:" .. save_filepath)
    end

    -- Export Window
	local function export_protocol()

		if export_open then return end
		export_open = true

		local w = TextWindow.new("Export Protocol")
        w:add_button("Save Undefined", function() save_Undefined_protocol() end)
		w:add_button("Save All", function() save_all_protocol() end)

        plm_dissector.protocoldata = {}
        plm_dissector.protocoltype = {}

        local tap = Listener.new();
        local function remove()
            tap:remove();
        end

		-- save original logger functions
		local orig_print = print

		-- define new logger functions that append text to the window
		function print(...)
			local arg = {...}
			local n = #arg
			w:append(date() .. " ")
			for i=1, n do
				if i > 1 then w:append("\t") end
				w:append(tostring(arg[i]))
			end
			w:append("\n")
		end

		-- when the window gets closed restore the original logger functions
		local function at_close()
			print = orig_print
			export_open = false
            remove()
		end

		w:set_atclose(at_close)

        local reassembled = {}

        function tap.packet(pinfo,tvb)

            local payload = payload_field()
            local reassembledin = reassembled_in()
            local segmentcount = segment_count()
            if reassembledin ~= nil then
                table.insert(reassembled, { ["framenumber"] = reassembledin.value, ["framedata"] = payload() })
            end

            if plm_dissector.protocoltype[pinfo.number] == plm_dissector.dissectortype.PLM_LOBBY then
                plm_dissector:lobby_dissector(payload, pinfo, nil, nil)
            elseif plm_dissector.protocoltype[pinfo.number] == plm_dissector.dissectortype.PLM_GAME then
                if segmentcount ~= nil then
                    local reassemblecount = segmentcount.value
                    if reassemblecount == TableHelper:getTableLength(reassembled) +1 then
                        local reassembledata
                        for index, frame in ipairs(reassembled) do
                            if index == 1 then
                                reassembledata = frame["framedata"]
                            else
                                reassembledata:append(frame["framedata"])
                            end
                        end
                        reassembledata:append(payload())
                        plm_dissector:game_dissector(reassembledata:tvb(), pinfo, nil, nil)
                        reassembled = {}
                    end
                else
                    plm_dissector:game_dissector(payload, pinfo, nil, nil)
                    reassembled = {}
                end
            else
                plm_dissector:http_dissector(payload, pinfo, nil, nil)
            end
        end

        function tap.draw(t)

            w:clear()
            local last = 0
            print(string.format("Protocol Count:%d\n\n", TableHelper:getTableLength(plm_dissector.protocoldata)))
            for number, protocoldata in TableHelper:pairsByKeys(plm_dissector.protocoldata) do
                if number - last ~= 1 then
                    --print("Missing Protocol:" .. number)
                end
                local data = GetTableString(protocoldata)
                local type = plm_dissector:get_dissector_name(plm_dissector.protocoltype[number])
                print(string.format("Frame:%d Type:%s \n %s", number, type, data))
                last = number
            end
        end

        function tap.reset()
            w:clear()
            plm_dissector.protocoldata = {}
            plm_dissector.protocoltype = {}
        end

        retap_packets()
	end

    register_menu("Export Protocol", export_protocol, MENU_TOOLS_UNSORTED)
end
