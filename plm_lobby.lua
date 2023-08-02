package.prepend_path("plugins/plm")
local plm_protocol = Proto("plm_lobby",  "plm lobby protocol")

local json = require "json"
local TableHelper = require "TableHelper"
require "PrintTable"

local packet_id       = ProtoField.int32 ("plm.packet_id"       , "packet_id"         , base.DEC)
local packet_length   = ProtoField.int32 ("plm.packet_length"   , "packet_length"     , base.DEC)
local packet_data     = ProtoField.string ("plm.packet_data"    , "packet_data"       , base.UNICODE)

plm_protocol.fields = {
    packet_id, packet_length, packet_data
}

function plm_protocol.dissector(buffer, pinfo, tree)
    local rawdata = buffer():raw()
    local length = string.len(rawdata)
    if length == 0 then return end

    pinfo.cols.protocol = plm_protocol.name
    local        subtree =    tree:add(plm_protocol, buffer(), "PLM Protocol Data")

    local index = 0
    local suffix = "\r\n\r\n"
    local packetdata = rawdata

    repeat
        local beginindex, endindex = string.find(packetdata, suffix, 1, true)
        if beginindex == nil then break end
        local currentdata = string.sub(packetdata, 0, beginindex - 1)
        packetdata = string.sub(packetdata, endindex + 1)
        local messagedata = json.decode(currentdata)
        local packetname = messagedata["ACTION"]
        local packetid = get_packet_id(packetname)
        local  protocolSubtree = subtree:add(plm_protocol, buffer(), "Protocal Data " .. index)
        index = index + 1
        protocolSubtree:add_le(packet_id,         packetid):append_text(" (" .. packetname .. ")")
        protocolSubtree:add_le(packet_length,     string.len(currentdata))
        if packetid ~= 1 then
            local data = json.decode(currentdata)
            local subtreedata = protocolSubtree:add(packet_data, buffer(), "")
            TableHelper:addtabletree(buffer(), data["DATA"], subtreedata)
            PrintTable(data)
        end
    until (string.len(packetdata) == 0)
end

function get_packet_id(packetname)
    local packetid = -1
    if packetname ==    "login" then packetid = 101
    elseif packetname == "heart" then packetid = 1
    elseif packetname == "global_data" then packetid = 0
    end
    return packetid
end

local tcp_port = DissectorTable.get("tcp.port")
tcp_port:add(9086, plm_protocol)
