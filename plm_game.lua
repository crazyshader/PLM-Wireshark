package.prepend_path("plugins/plm")
local plm_protocol = Proto("plm_game",  "plm game protocol")

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
    local offset = 0
    while (offset < length)
    do
        if offset + 4 > length then break end
        local idBuffer = buffer(offset,4)
        local packetid = idBuffer:le_uint()
        offset = offset + 4
        if offset + 4 > length then break end
        local lengthBuffer = buffer(offset,4)
        local packetlength = lengthBuffer:le_uint()
        offset = offset + 4
        if offset + packetlength > length then break end
        local dataBuffer = buffer(offset,packetlength):raw()
        offset = offset + packetlength
        index = index + 1
        local packetname = get_packet_name(packetid);
        local  protocolSubtree = subtree:add(plm_protocol, buffer(), "Protocal Data " .. index)
        protocolSubtree:add_le(packet_id,         idBuffer):append_text(" (" .. packetname .. ")")
        protocolSubtree:add_le(packet_length,     lengthBuffer)
        if packetid ~= 1 then
            local data = json.decode(dataBuffer)
            local subtreedata = protocolSubtree:add(packet_data, buffer(), "")
            TableHelper:addtabletree(buffer(), data["DATA"], subtreedata)
            PrintTable(data)
        end
    end
end

function get_packet_name(packetid)
    local packetname = "Unknown"

	if packetid ==    1 then packetname = "心跳"
	elseif packetid == 2 then packetname = "登陆游戏"
    elseif packetid == 102 then packetname = "进入房间"
    elseif packetid == 105 then packetname = "离开房间"
    elseif packetid == 4098 then packetname = "进桌广播"
    elseif packetid == 4097 then packetname = "获取玩家列表"
    elseif packetid == 4133 then packetname = "获取房间规则"
    elseif packetid == 4129 then packetname = "重连恢复游戏"
    elseif packetid == 4099 then packetname = "游戏准备开始"
    elseif packetid == 4109 then packetname = "发牌"
    elseif packetid == 5010 then packetname = "换牌"
    elseif packetid == 5011 then packetname = "换牌广播"
    elseif packetid == 5001 then packetname = "定缺"
    elseif packetid == 4132 then packetname = "买马"
    elseif packetid == 4112 then packetname = "打牌"
    elseif packetid == 4110 then packetname = "摸牌"
    elseif packetid == 5000 then packetname = "碰杠胡过"
    elseif packetid == 4127 then packetname = "一局结束"
    elseif packetid == 6050 then packetname = "发送表情"
    elseif packetid == 4137 then packetname = "断线重连计分表"
    elseif packetid == 4136 then packetname = "整局结束"
    elseif packetid == 5002 then packetname = "游戏状态改变"
    elseif packetid == 5049 then packetname = "发起解散投票"
    elseif packetid == 5050 then packetname = "解散投票"
    elseif packetid == 5051 then packetname = "解散投票结果"
    elseif packetid == 5053 then packetname = "解散投票取消"
    elseif packetid == 651 then packetname = "创建桌子"
    elseif packetid == 652 then packetname = "关闭桌子"

    elseif packetid == 5068 then packetname = "暂离"
    elseif packetid == 4138 then packetname = "玩家掉线"
    elseif packetid == 4139 then packetname = "玩家掉线重回"
    elseif packetid == 4140 then packetname = "玩家离开房间"
    elseif packetid == 5012 then packetname = "叫牌成功"
    elseif packetid == 4142 then packetname = "更换房主"


    elseif packetid == 5053 then packetname = "解散投票取消"
    elseif packetid == 4141 then packetname = "更新金币信息"
    elseif packetid == 5010 then packetname = "换牌" end

    return packetname
end

local tcp_port = DissectorTable.get("tcp.port")
tcp_port:add(9099, plm_protocol)
