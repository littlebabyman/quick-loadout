local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_override")
local maxslots = GetConVar("quickloadout_maxslots")
local time = GetConVar("quickloadout_switchtime")
local timestop = GetConVar("quickloadout_switchtime_override")

util.AddNetworkString("quickloadout")
if game.SinglePlayer then
    local keybind = KEY_N
    util.AddNetworkString("QLSPHack")
    net.Receive("QLSPHack", function() keybind = net.ReadInt(9) end)
    hook.Add("PlayerButtonDown", "QuickLoadoutBind", function(ply, key)
        if key == keybind and IsFirstTimePredicted() then
            net.Start("QLSPHack")
            net.Send(ply)
        end
    end)
end

local hwep = "weaponholster"
hook.Add("InitPostEntity", "QLHolsterCheck", function()
    if ConVarExists("holsterweapon_weapon") and list.HasEntry("Weapon", GetConVar("holsterweapon_weapon"):GetString()) then
        hwep = GetConVar("holsterweapon_weapon"):GetString() or "weaponholster"
    end
end)

net.Receive("quickloadout", function(len, ply)
    ply.quickloadout = net.ReadTable()
    if (time:GetFloat() > 0 and ply.qlspawntime + time:GetFloat() < CurTime()) then
        net.Start("quickloadout")
        net.Send(ply)
        return
    end
    QuickLoadout(ply)
end)

function QuickLoadout(ply)
    if !enabled:GetBool() or !ply.quickloadout or !ply:Alive() then return end
    ply:StripWeapons()
    if !override:GetBool() then hook.Run("PlayerLoadout", ply) end
    for k, v in ipairs(ply.quickloadout) do
        if !maxslots:GetBool() or maxslots:GetInt() >= k then
            ply:Give(v)
        end
    end
    if ConVarExists("holsterweapon_weapon") then
        ply:Give(hwep)
    end
    -- PrintTable(ply.quickloadout)
end

hook.Add("PlayerSpawn", "QuickLoadoutSpawn", function(ply)
    ply.qlspawntime = CurTime()
    timer.Simple(0, function() QuickLoadout(ply) end)
end)

hook.Add("KeyPress", "QuickLoadoutCancel", function(ply, key)
    if !timestop:GetBool() then return end
    if ply.qlspawntime > 0 and key == IN_ATTACK then
        ply.qlspawntime = 0
    end
end)