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

    local function save_protocol()

        local save_path = os.getenv("USERPROFILE") .. "\\Documents\\PLM_Protocol\\"
        if not Dir.exists(save_path) then
            Dir.make(save_path)
        end
        local save_filepath = save_path .. "PLM_Protocol_" .. os.date("%Y-%m-%d-%H-%M-%S")  .. ".txt"
        local file = assert(io.open(save_filepath, "w"))
        file:write(string.format("Protocol Count:%d\n\n", TableHelper:getTableLength(plm_dissector.protocoldata)))
        for number, protocoldata in TableHelper:pairsByKeys(plm_dissector.protocoldata) do
            local data = GetTableString(protocoldata)
            file:write(string.format("Frame:%d %s\n", number, data))
        end
        file:close()
        print("Save Path:" .. save_filepath)
    end

    -- Export Window
	local function export_protocol()

		if export_open then return end
		export_open = true

		local w = TextWindow.new("Export Protocol")
		w:add_button("Save", function() save_protocol() end)

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
                print(string.format("Frame:%d %s", number, data))
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
