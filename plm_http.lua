package.prepend_path("plugins/plm")
local plm_http = Proto("plm_http", "plm http protocol")

local plm_dissector = require "plm_dissector"

function plm_http.dissector(tvb, pinfo, tree)

    plm_dissector:http_dissector(tvb, pinfo, tree, plm_http)
end

-- register this dissector
register_postdissector(plm_http)

return plm_http