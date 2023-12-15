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
    if !ply.quickloadout then ply.qlspawntime = CurTime() + 1 end
    if ply:GetInfoNum("quickloadout_enable_client", 0) == 0 then ply.quickloadout = {}
    else ply.quickloadout = util.JSONToTable(util.Decompress(net.ReadData(len))) end -- whaddya know this IS more reliable!
    if !ply:Alive() or (time:GetFloat() > 0 and ply.qlspawntime + time:GetFloat() < CurTime()) then
        net.Start("quickloadout")
        net.Send(ply)
        return
    end
    ply:StripWeapons()
    ply:StripAmmo()
    hook.Run("PlayerLoadout", ply)
end)

function QuickLoadout(ply)
    local count = maxslots:GetBool() and maxslots:GetInt() or !game.SinglePlayer() and 32 or 0
    if !IsValid(ply) or !enabled:GetBool() or !ply.quickloadout or !ply:Alive() then return end
    local wtable = list.Get("Weapon")
    for k, wep in ipairs(ply.quickloadout) do
        if (!game.SinglePlayer() or maxslots:GetBool()) and count and count < k then break end
        if !wtable[wep] or !wtable[wep].Spawnable or (wtable[wep].AdminOnly and !ply:IsAdmin()) then count = count + 1
        else
            ply:Give(wep)
            local wget = ply:GetWeapon(wep)
            timer.Simple(0, function()
                if wget and IsValid(wget) then
                    ply:GiveAmmo(math.max(wget:GetMaxClip1(), 0) * clips:GetInt(), wget:GetPrimaryAmmoType(), true)
                    ply:GiveAmmo(math.max(wget:GetMaxClip2(), 0) * clips:GetInt(), wget:GetSecondaryAmmoType(), true)
                end
            end)
        end
    end
    if !(default:GetInt() == 1 or (default:GetInt() == -1 and ply:GetInfoNum("quickloadout_default_client", 1) == 1) or table.IsEmpty(ply:GetWeapons())) then
        return true
    end
end

-- hook.Add("PlayerInitialSpawn", "QuickLoadoutInitTable", function(ply) ply.quickloadout = {} end)

hook.Add("PlayerLoadout", "QuickLoadoutLoadout", QuickLoadout)

hook.Add("PlayerSpawn", "QuickLoadoutSpawn", function(ply)
    ply.qlspawntime = CurTime() or 0
end)

-- hook.Add("PostPlayerDeath", "QuickLoadoutDeath", function(ply)

-- end)

hook.Add("KeyPress", "QuickLoadoutCancel", function(ply, key)
    if !timestop:GetBool() then return end
    if ply.qlspawntime > 0 and key == IN_ATTACK then
        ply.qlspawntime = 0
    end
end)