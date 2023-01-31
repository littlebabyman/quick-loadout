local enabled = GetConVar("codql_enable"):GetBool()
local override = GetConVar("codql_override"):GetBool()
local maxslots = GetConVar("codql_maxslots"):GetInt()

util.AddNetworkString("codqloadout")

local weps = list.HasEntry("Weapon")
local holster, hwep = ConVarExists("holsterweapon_weapon"), "weaponholster"
hook.Add("InitPostEntity", "CODQLHolsterCheck", function()
    if holster && list.HasEntry("Weapon", GetConVar("holsterweapon_weapon"):GetString()) then
        hwep = GetConVar("holsterweapon_weapon"):GetString()
    end
end)
net.Receive("codqloadout", function(len, ply)
    ply.codqloadout = net.ReadTable()
    CODQLoadout(ply)
end)

function CODQLoadout(ply)
    if !enabled or !ply.codqloadout then return end
    if override then ply:StripWeapons() end
    for k, v in ipairs(ply.codqloadout) do
        ply:Give(v)
    end
    if holster then ply:Give(hwep) end
end

gameevent.Listen("player_spawn")
hook.Add("PlayerSpawn", "CODQuickLoadout", function(ply) timer.Simple(0, function() CODQLoadout(ply) end) end)