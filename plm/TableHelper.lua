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

return TableHelper