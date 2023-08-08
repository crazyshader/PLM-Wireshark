local TableHelper = {}

function TableHelper:addtabletree(range, table, tree)
    if table == nil then return end
    for key, value in pairs(table) do
        if type(value) ~= "table" then
            tree:add(range, string.format("%s = %s", key, value))
        else
            local subtree = tree:add(range, key)
            TableHelper:addtabletree(range, value, subtree)
        end
    end
end

function TableHelper:mergetable(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == 'table' then
            if type(t1[k] or false) == 'table' then
                TableHelper:mergetable(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

function TableHelper:addtable(t1, t2)
    local length = TableHelper:getTableLength(t1)
    t1[length+1] = t2
    return t1
end

function TableHelper:getTableLength(table)
    local length = 0
    for _ in pairs(table) do
        length = length + 1
    end
    return length
end

function TableHelper:pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

return TableHelper