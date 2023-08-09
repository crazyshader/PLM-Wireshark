local plm_define = {}

function plm_define:get_lobby_packet_name(packetid)

    local packetname = "Unknown"
    if packetid ==    1 then packetname = "心跳"
	elseif packetid == 101 then packetname = "登陆大厅"
    elseif packetid == 0 then packetname = "全局消息"
    else
        if packetid == 11 then packetname = "俱乐部在线人数"
        elseif packetid == 101 then packetname = "登陆大厅"
        elseif packetid == -2 then packetname = "获得房卡"
        elseif packetid == -3 then packetname = "更新Token"
        end
        packetname = packetname .. " Undefined"
    end
    return packetname
end

function plm_define:get_lobby_packet_id(packetname)

    local packetid = -1
    if packetname ==    "login" then packetid = 101
    elseif packetname == "heart" then packetid = 1
    elseif packetname == "circle_online_count" then packetid = 11
    elseif packetname == "addRoomCard" then packetid = -2
    elseif packetname == "token_update" then packetid = -3
    elseif packetname == "global_data" then packetid = 0
    end
    return packetid
end


function plm_define:get_packet_name(packetid)

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
    elseif packetid == 5053 then packetname = "解散投票取消"
    elseif packetid == 4141 then packetname = "更新金币信息"
    elseif packetid == 5010 then packetname = "换牌"
    else
        if packetid == 5068 then packetname = "暂离"
        elseif packetid == 4138 then packetname = "玩家掉线"
        elseif packetid == 4139 then packetname = "玩家掉线重回"
        elseif packetid == 4140 then packetname = "玩家离开房间"
        elseif packetid == 5012 then packetname = "叫牌成功"
        elseif packetid == 4142 then packetname = "更换房主"
        end
        packetname = packetname .. " Undefined"
    end

    return packetname
end

return plm_define