package.prepend_path("plugins/plm")
local plm_protocol = Proto("plm_lobby",  "plm lobby protocol")

local plm_dissector = require "plm_dissector"

local packet_id       = ProtoField.int32 ("plm.packet_id"       , "packet_id"         , base.DEC)
local packet_length   = ProtoField.int32 ("plm.packet_length"   , "packet_length"     , base.DEC)
local packet_data     = ProtoField.string ("plm.packet_data"    , "packet_data"       , base.UNICODE)

plm_protocol.fields = {
    packet_id, packet_length, packet_data
}

function plm_protocol.dissector(buffer, pinfo, tree)

    plm_dissector:lobby_dissector(buffer, pinfo, tree, plm_protocol)
end

local tcp_port = DissectorTable.get("tcp.port")
tcp_port:add(9086, plm_protocol)
tcp_port:add(9082, plm_protocol)