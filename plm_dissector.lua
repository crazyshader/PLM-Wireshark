local json = require "json"
local TableHelper = require "TableHelper"
local plm_define = require "plm_define"
require "PrintTable"

local plm_dissector = {}
plm_dissector.protocoldata = {}
plm_dissector.protocoltype = {}

plm_dissector.dissectortype = { PLM_HTTP = 1, PLM_LOBBY = 2, PLM_GAME = 3 }

---- url decode (from www.lua.org guide)
local function unescape (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

---- convert string to hex string
local function string2hex (s)
    local hex = "";
    for i=1, #s, 1 do
        hex = hex .. string.format("%x", s:byte(i))
    end
    return hex
end

local function stringsplit(s, delimiter)
    local fields = {}
    local pattern = string.format("([^%s]+)", delimiter)
    string.gsub(s, pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local httpuri = Field.new("http.request.uri")
local httpdata = Field.new("http.file_data")

function plm_dissector:http_dissector(tvb, pinfo, tree, plm_http)

    local http_uri = httpuri()
    local http_data = httpdata()
    if not http_uri and not http_data then
        return
    end

    if plm_http ~= nil then
        pinfo.cols.protocol = plm_http.name
    end
    if http_uri ~= nil then
        local content = http_uri.value
        local idx = content:find("?")
        if not idx then
            if not http_data then
                return
            end
            idx = 0
            content = http_data.range():raw()
        end

        local tab = ByteArray.new(string2hex(content)):tvb("Decoded HTTP Request")
        local tab_range = tab()

        -- add proto item to tree
        local subtree
        if tree ~= nil then
            subtree = tree:add(plm_http, tab_range)
            -- add raw data to tree
            subtree:add(tab_range, "[HTTP Request] (" .. tab_range:len() .. " bytes)"):add(tab_range, content)
        end

        -- add param value pair to tree
        local pairs_tree
        if subtree ~= nil then
            pairs_tree = subtree:add(tab_range, "[Request Data]")
        end
        local si = 1
        local ei = idx
        local count = 0
        local datatable = {}
        if idx > 1 then
            datatable["ACTION"] = unescape(content:sub(2, idx-1))
            if pairs_tree ~= nil then
                pairs_tree:add(tab(2, idx-1), string.format("ACTION=%s", datatable["ACTION"]))
            end
        end
        while ei do
            si = ei + 1
            ei = string.find(content, "&", si)
            local xlen = (ei and (ei - si)) or (content:len() - si + 1)
            if xlen > 0 then
                local data = unescape(content:sub(si, si+xlen-1))
                local dataline = stringsplit(data, '=')
                datatable[dataline[1]] = dataline[2]
                if pairs_tree ~= nil then
                    pairs_tree:add(tab(si-1, xlen), data)
                end
                count = count + 1
            end
        end
        if pairs_tree ~= nil then
            pairs_tree:append_text(" (" .. count .. ")")
        end
        if plm_http ~= nil then
            plm_dissector.protocoltype[pinfo.number] = plm_dissector.dissectortype.PLM_HTTP
        else
            plm_dissector.protocoldata[pinfo.number] = datatable
        end
        PrintTable(datatable)
    elseif http_data ~= nil then
        local responsedata = http_data.range():raw()
        local tab = ByteArray.new(string2hex(responsedata)):tvb("Decoded HTTP Response")
        local tab_range = tab()

        -- add proto item to tree
        local subtree
        if tree ~= nil then
            subtree = tree:add(plm_http, tab_range)
            -- add raw data to tree
            subtree:add(tab_range, "[HTTP Response] (" .. tab_range:len() .. " bytes)"):add(tab_range, responsedata)
        end

        -- add param value pair to tree
        local pairs_tree
        if subtree ~= nil then
            pairs_tree = subtree:add(tab_range, "[Response Data]")
        end
        local data = json.decode(responsedata)
        if pairs_tree ~= nil then
            TableHelper:addtabletree(tab_range, data, pairs_tree)
        end
        if plm_http ~= nil then
            plm_dissector.protocoltype[pinfo.number] = plm_dissector.dissectortype.PLM_HTTP
        else
            plm_dissector.protocoldata[pinfo.number] = data
        end
        PrintTable(data)
    end
end

function plm_dissector:lobby_dissector(buffer, pinfo, tree, plm_protocol)

    local rawdata = buffer():raw()
    local length = string.len(rawdata)
    if length == 0 then return end
    if plm_protocol ~= nil then
        pinfo.cols.protocol = plm_protocol.name
    end

    local subtree
    if tree ~= nil then
        subtree =    tree:add(plm_protocol, buffer(), "PLM Protocol Data")
    end

    local index = 1
    local suffix = "\r\n\r\n"
    local packetdata = rawdata
    repeat
        local beginindex, endindex = string.find(packetdata, suffix, 1, true)
        if beginindex == nil then break end
        local currentdata = string.sub(packetdata, 0, beginindex - 1)
        packetdata = string.sub(packetdata, endindex + 1)
        local messagedata = json.decode(currentdata)
        local packetname = messagedata["ACTION"]
        local packetid = plm_define:get_lobby_packet_id(packetname)
        local  protocolSubtree
        if subtree ~= nil then
            protocolSubtree = subtree:add(plm_protocol, buffer(), "Protocal Data " .. index)
            protocolSubtree:add_le(plm_protocol.fields[1],         packetid):append_text(" (" .. packetname .. ")")
            protocolSubtree:add_le(plm_protocol.fields[2],     string.len(currentdata))
            index = index + 1
        end
        if packetid ~= 1 then
            local data = json.decode(currentdata)
            local subtreedata
            if protocolSubtree ~= nil then
                subtreedata = protocolSubtree:add(plm_protocol.fields[3], buffer(), "")
                TableHelper:addtabletree(buffer(), data["DATA"], subtreedata)
            end

            if data["ACTION"] ~= nil then
                data["ACTION"] = tostring(packetid) .. " (" .. data["ACTION"] .. ")"
            end
            if plm_protocol ~= nil then
                plm_dissector.protocoltype[pinfo.number] = plm_dissector.dissectortype.PLM_LOBBY
            else
                if plm_dissector.protocoldata[pinfo.number] ~= nil then
                    table.insert(plm_dissector.protocoldata[pinfo.number], data)
                else
                    plm_dissector.protocoldata[pinfo.number] = { data }
                end
            end
            PrintTable(data)
        end
    until (string.len(packetdata) == 0)
end

function plm_dissector:game_dissector(buffer, pinfo, tree, plm_protocol)

    local tvb = buffer():tvb()
    local rawdata = buffer():raw()
    local length = string.len(rawdata)
    if length == 0 then return end

    if plm_protocol ~= nil then
        pinfo.cols.protocol = plm_protocol.name
    end

    local subtree
    if tree ~= nil then
        subtree =    tree:add(plm_protocol, buffer(), "PLM Protocol Data")
    end

    local index = 1
    local offset = 0
    while (offset < length)
    do
        if offset + 4 > length then break end
        local idBuffer = tvb(offset,4)
        local packetid = idBuffer:le_uint()
        offset = offset + 4
        if offset + 4 > length then break end
        local lengthBuffer = tvb(offset,4)
        local packetlength = lengthBuffer:le_uint()
        offset = offset + 4
        if offset + packetlength > length then break end
        local dataBuffer = tvb(offset,packetlength):raw()
        offset = offset + packetlength
        local packetname = plm_define:get_packet_name(packetid);
        local  protocolSubtree
        if subtree ~= nil then
            protocolSubtree = subtree:add(plm_protocol, tvb(), "Protocal Data " .. index)
            protocolSubtree:add_le(plm_protocol.fields[1],         idBuffer):append_text(" (" .. packetname .. ")")
            protocolSubtree:add_le(plm_protocol.fields[2],     lengthBuffer)
            index = index + 1
        end
        if packetid ~= 1 then
            local data = json.decode(dataBuffer)
            local subtreedata
            if protocolSubtree ~= nil then
                subtreedata = protocolSubtree:add(plm_protocol.fields[3], tvb(), "")
                if type(data["DATA"]) == "table" then
                    TableHelper:addtabletree(buffer(), data["DATA"], subtreedata)
                else
                    subtreedata:add(tvb(), string.format("Data = %s", data["DATA"]))
                end
            end
            if data["MSG_ID"] ~= nil then
                data["MSG_ID"] = data["MSG_ID"] .. " (" .. packetname .. ")"
            end
            if plm_protocol ~= nil then
                plm_dissector.protocoltype[pinfo.number] = plm_dissector.dissectortype.PLM_GAME
            else
                if plm_dissector.protocoldata[pinfo.number] ~= nil then
                    table.insert(plm_dissector.protocoldata[pinfo.number], data)
                else
                    plm_dissector.protocoldata[pinfo.number] = { data }
                end
            end
            PrintTable(data)
        end
    end
end

return plm_dissector