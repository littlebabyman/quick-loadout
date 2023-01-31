local enabled = CreateConVar("codql_enable", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Enable Quick Loadout.", 0, 1)

util.AddNetworkString("codqloadout")

function CODQLoadout()
    if enabled then
    end
end

net.Receive("codqloadout", function(len, ply)
    local wtable = {}
end)