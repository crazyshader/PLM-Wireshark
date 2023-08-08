package.prepend_path("plugins/plm")
local plm_protocol = Proto("plm_game",  "plm game protocol")

local plm_dissector = require "plm_dissector"
require "PrintTable"

local packet_id       = ProtoField.int32 ("plm.packet_id"       , "packet_id"         , base.DEC)
local packet_length   = ProtoField.int32 ("plm.packet_length"   , "packet_length"     , base.DEC)
local packet_data     = ProtoField.string ("plm.packet_data"    , "packet_data"       , base.UNICODE)

plm_protocol.fields = {
    packet_id, packet_length, packet_data
}

function get_packet_length(buffer, pinfo, tree)
    local rawdata = buffer():raw()
    local length = string.len(rawdata)
    local offset = 0
    while (offset < length)
    do
        offset = offset + 4
        local lengthBuffer = buffer(offset,4)
        offset = offset + 4
        local datalength = lengthBuffer:le_uint()
        offset = offset + datalength
    end
    return offset
end

function dissect_packet_pdu(buffer, pinfo, tree)

    plm_dissector:game_dissector(buffer, pinfo, tree, plm_protocol)
end

function plm_protocol.dissector(buffer, pinfo, tree)
    dissect_tcp_pdus(buffer, tree, 4, get_packet_length, dissect_packet_pdu)
    local bytes_length = buffer:len()
    return bytes_length
end

local tcp_port = DissectorTable.get("tcp.port")
tcp_port:add(9099, plm_protocol)
tcp_port:add(9032, plm_protocol)