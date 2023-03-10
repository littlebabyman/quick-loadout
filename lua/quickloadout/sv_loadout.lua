local enabled = GetConVar("quickloadout_enable")
local default = GetConVar("quickloadout_default")
local maxslots = GetConVar("quickloadout_maxslots")
local time = GetConVar("quickloadout_switchtime")
local timestop = GetConVar("quickloadout_switchtime_override")
local clips = GetConVar("quickloadout_spawnclips")

util.AddNetworkString("quickloadout")
util.AddNetworkString("qlnotification")

if game.SinglePlayer() then
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

net.Receive("quickloadout", function(len, ply)
    if ply:GetInfoNum("quickloadout_enable_client", 0) == 0 then ply.quickloadout = {}
    else ply.quickloadout = net.ReadTable() end -- whaddya know this IS more reliable!
    if !ply:Alive() or (time:GetFloat() > 0 and ply.qlspawntime + time:GetFloat() < CurTime()) then
        net.Start("quickloadout")
        net.Send(ply)
        return
    end
    ply:StripWeapons()
    ply:StripAmmo()
    timer.Simple(0, function() hook.Run("PlayerLoadout", ply) end)
end)

function QuickLoadout(ply)
    local count = maxslots:GetBool() and maxslots:GetInt() or !game.SinglePlayer() and 32 or 0
    if !IsValid(ply) or !enabled:GetBool() or !ply.quickloadout or !ply:Alive() then return end
    for k, v in ipairs(ply.quickloadout) do
        if (!game.SinglePlayer() or maxslots:GetBool()) and count and count < k then break end
        if !list.Get("Weapon")[v] or !list.Get("Weapon")[v].Spawnable or (list.Get("Weapon")[v].AdminOnly and !ply:IsAdmin()) then count = count + 1
        else
            ply:Give(v)
            timer.Simple(0, function()
                if weapons.Get(v) then
                    ply:GiveAmmo(weapons.Get(v).Primary.ClipSize * clips:GetInt(), weapons.Get(v).Primary.Ammo, true)
                    ply:GiveAmmo(weapons.Get(v).Secondary.ClipSize * clips:GetInt(), weapons.Get(v).Secondary.Ammo, true)
                end
            end)
        end
    end
    if !(default:GetInt() == 1 or (default:GetInt() == -1 and ply:GetInfoNum("quickloadout_default_client", 1) == 1) or table.IsEmpty(ply.quickloadout)) then
        return true
    end
end

hook.Add("PlayerInitialSpawn", "QuickLoadoutInitTable", function(ply) ply.quickloadout = {} end)

hook.Add("PlayerLoadout", "QuickLoadoutLoadout", QuickLoadout)

hook.Add("PlayerSpawn", "QuickLoadoutSpawn", function(ply)
    ply.qlspawntime = CurTime()
end)

-- hook.Add("PostPlayerDeath", "QuickLoadoutDeath", function(ply)

-- end)

hook.Add("KeyPress", "QuickLoadoutCancel", function(ply, key)
    if !timestop:GetBool() then return end
    if ply.qlspawntime > 0 and key == IN_ATTACK then
        ply.qlspawntime = 0
    end
end)