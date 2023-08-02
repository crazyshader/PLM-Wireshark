package.prepend_path("plugins/plm")
local plm_http = Proto("plm_http", "plm http protocol")

local json = require "json"
local TableHelper = require "TableHelper"
require "PrintTable"

---- url decode (from www.lua.org guide)
function unescape (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

---- convert string to hex string
function string2hex (s)
    local hex = "";
    for i=1, #s, 1 do
        hex = hex .. string.format("%x", s:byte(i))
    end
    return hex
end

function stringsplit(s, delimiter)
    local fields = {}
    local pattern = string.format("([^%s]+)", delimiter)
    string.gsub(s, pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local httpuri = Field.new("http.request.uri")
local httpdata = Field.new("http.file_data")

function plm_http.dissector(tvb, pinfo, tree)
    local http_uri = httpuri()
    local http_data = httpdata()
    if not http_uri and not http_data then
        return
    end

    pinfo.cols.protocol = plm_http.name
    if http_uri ~= nil then
        local content = http_uri.value
        local idx = content:find("?")
        if not idx then return end -- not include query string, so stop parsing

        local tab = ByteArray.new(string2hex(content)):tvb("Decoded HTTP Request")
        local tab_range = tab()

        -- add proto item to tree
        local subtree = tree:add(plm_http, tab_range)

        -- add raw data to tree
        subtree:add(tab_range, "[HTTP Request] (" .. tab_range:len() .. " bytes)"):add(tab_range, content)

        -- add param value pair to tree
        local pairs_tree = subtree:add(tab_range, "[Request Data]")
        local si = 1
        local ei = idx
        local count = 0
        local datatable = {}
        datatable["ACTION"] = unescape(content:sub(2, idx-1))
        pairs_tree:add(tab(2, idx-1), string.format("ACTION=%s", datatable["ACTION"]))

        while ei do
            si = ei + 1
            ei = string.find(content, "&", si)
            local xlen = (ei and (ei - si)) or (content:len() - si + 1)
            if xlen > 0 then
                local data = unescape(content:sub(si, si+xlen-1))
                local dataline = stringsplit(data, '=')
                datatable[dataline[1]] = dataline[2]
                pairs_tree:add(tab(si-1, xlen), data)
                count = count + 1
            end
        end
        pairs_tree:append_text(" (" .. count .. ")") 
        PrintTable(datatable)
    elseif http_data ~= nil then
        local responsedata = http_data.range():raw()
        local tab = ByteArray.new(string2hex(responsedata)):tvb("Decoded HTTP Response")
        local tab_range = tab()

        -- add proto item to tree
        local subtree = tree:add(plm_http, tab_range)

        -- add raw data to tree
        subtree:add(tab_range, "[HTTP Response] (" .. tab_range:len() .. " bytes)"):add(tab_range, responsedata)

        -- add param value pair to tree
        local pairs_tree = subtree:add(tab_range, "[Response Data]")
        local data = json.decode(responsedata)
        --for key, value in pairs(data) do
        --    if type(value) ~= "table" then
        --        pairs_tree:add(tab_range, string.format("%s = %s", key, value))
        --    end
        --end
        TableHelper:addtabletree(tab_range, data, pairs_tree)
        PrintTable(data)
    end
end

-- register this dissector
register_postdissector(plm_http)