local PreventGC = { __gc = false }
PreventGC._values = {}
setmetatable(PreventGC, PreventGC)

function PreventGC:__call(value)
    table.insert(PreventGC._values, value)
end

return PreventGC