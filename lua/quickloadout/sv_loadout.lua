local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_override")
local maxslots = GetConVar("quickloadout_maxslots")

util.AddNetworkString("quickloadout")

local hwep = "weaponholster"
hook.Add("InitPostEntity", "QLHolsterCheck", function()
    if ConVarExists("holsterweapon_weapon") && list.HasEntry("Weapon", GetConVar("holsterweapon_weapon"):GetString()) then
        hwep = GetConVar("holsterweapon_weapon"):GetString() or "weaponholster"
    end
end)

net.Receive("quickloadout", function(len, ply)
    ply.quickloadout = net.ReadTable()
    if ConVarExists("holsterweapon_weapon") then
        table.Add(ply.quickloadout, {[1] = hwep})
    end
    QuickLoadout(ply)
end)

function QuickLoadout(ply)
    if !enabled:GetBool() or !ply.quickloadout or !ply:Alive() then return end
    ply:StripWeapons()
    if !override:GetBool() then hook.Run("PlayerLoadout", ply) end
    for k, v in ipairs(ply.quickloadout) do
        ply:Give(v)
    end
end

gameevent.Listen("player_spawn")
hook.Add("PlayerSpawn", "QuickLoadoutSpawn", function(ply) timer.Simple(0, function() QuickLoadout(ply) end) end)