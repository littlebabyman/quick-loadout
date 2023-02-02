local enabled = GetConVar("quickloadout_enable"):GetBool()
local override = GetConVar("quickloadout_override"):GetBool()
local maxslots = GetConVar("quickloadout_maxslots"):GetInt()

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
    if !enabled or !ply.quickloadout then return end
    ply:StripWeapons()
    if !override then hook.Run("PlayerLoadout", ply) end
    for k, v in ipairs(ply.quickloadout) do
        ply:Give(v)
    end
end

gameevent.Listen("player_spawn")
hook.Add("PlayerSpawn", "QuickLoadoutSpawn", function(ply) timer.Simple(0, function() QuickLoadout(ply) end) end)