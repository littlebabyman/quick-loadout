local enabled = CreateConVar("codql_enable", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Enable Quick Loadout.", 0, 1)
local override = CreateConVar("codql_override", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Override default loadout.", 0, 1)
local maxslots = CreateConVar("codql_maxslots", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Override default loadout.", 0, 1)

util.AddNetworkString("codqloadout")

local weps = list.Get("Weapon")

net.Receive("codqloadout", function(len, ply)
    ply.codqloadout = net.ReadTable()
    if override:GetBool() then ply:StripWeapons() end
    CODQLoadout(ply)
end)

function CODQLoadout(ply)
    if !ply.codqloadout then return end
    for k, v in ipairs(ply.codqloadout) do
        ply:Give(v)
    end
end

gameevent.Listen("player_spawn")
hook.Add("PlayerSpawn", "CODQuickLoadout", function(ply) CODQLoadout(ply) return override:GetBool() end)