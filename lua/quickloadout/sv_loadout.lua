local enabled = GetConVar("quickloadout_enable")
local default = GetConVar("quickloadout_default")
local maxslots = GetConVar("quickloadout_maxslots")
local time = GetConVar("quickloadout_gracetime")
local timestop = GetConVar("quickloadout_gracetime_override")
local clips = GetConVar("quickloadout_giveclips")

util.AddNetworkString("quickloadout")
util.AddNetworkString("qlnotification")

if game.SinglePlayer() then
    local keybind = -1
    util.AddNetworkString("QLSPHack")
    net.Receive("QLSPHack", function() keybind = net.ReadInt(9) end)
    hook.Add("PlayerButtonDown", "QuickLoadoutBind", function(ply, key)
        if keybind <= 0 then return end
        if key == keybind and IsFirstTimePredicted() then
            net.Start("QLSPHack")
            net.Send(ply)
        end
    end)
end

net.Receive("quickloadout", function(len, ply)
    -- if !ply.qlspawntime then ply.qlspawntime = CurTime() + 1 return end
    if !ply.quickloadout then ply.qlspawntime = CurTime() + 1 end
    if ply:GetInfoNum("quickloadout_enable_client", 0) == 0 then ply.quickloadout = {}
    else
        local dt = util.JSONToTable(util.Decompress(net.ReadData(len)))
        ply.quickloadout = dt
    end -- whaddya know this IS more reliable!
    if !ply:Alive() or (time:GetFloat() > 0 and ply.qlspawntime + time:GetFloat() < CurTime()) then
        net.Start("quickloadout")
        net.WriteBool(false)
        net.Send(ply)
        return
    end
    ply:StripWeapons()
    ply:StripAmmo()
    hook.Run("PlayerLoadout", ply)
end)

local exctab = {
    weapon_crossbow = true,
    weapon_rpg = true,
    weapon_frag = true,
    weapon_slam = true,
    weapon_rpg_hl1 = true,
    weapon_satchel = true,
    weapon_handgrenade = true,
    weapon_snark = true,
    weapon_tripmine = true,
    weapon_hornetgun = true
}

function QuickLoadout(ply)
    local count = maxslots:GetBool() and maxslots:GetInt() or !game.SinglePlayer() and 32 or 0
    if !IsValid(ply) or !enabled:GetBool() or !ply.quickloadout or table.IsEmpty(ply.quickloadout) or !ply:Alive() then return end
    timer.Simple(0, function()
        local wtable, ammomult = list.Get("Weapon"), clips:GetInt()
        for k, wep in ipairs(ply.quickloadout) do
            if (!game.SinglePlayer() or maxslots:GetBool()) and count and count < k then break end
            if !wtable[wep] or !wtable[wep].Spawnable or (wtable[wep].AdminOnly and !ply:IsAdmin()) then count = count + 1
            else
                ply:Give(wep, ammomult >= 0 or exctab[wep])
                local wget = ply:GetWeapon(wep)
                if ammomult < 0 then continue end
                timer.Simple(0, function()
                    if !(wget and IsValid(wget)) then return end
                    local ammo1, ammo2, type1, type2 = wget:GetMaxClip1(), wget:GetMaxClip2(), wget:GetPrimaryAmmoType(), wget:GetSecondaryAmmoType()
                    if wget:GetPrimaryAmmoType() >= 1 and ammo1 != 0 then
                        ply:GiveAmmo(math.max(ammo1, 1) * (ammomult+(type1 == type2 and 2 or 1)), type1, true)
                    end --Giving extra clip only to primary is intentional, and doubled if it's guessed to be akimbo
                    if wget:GetSecondaryAmmoType() >= 1 and ammo2 != 0 then
                        ply:GiveAmmo(math.max(ammo2, 1) * (ammomult), type2, true)
                    end
                end)
            end
        end
        ply:SelectWeapon(ply.quickloadout[1])
    end)
    ply:SetActiveWeapon(NULL)
    if !(default:GetInt() == 1 or (default:GetInt() == -1 and ply:GetInfoNum("quickloadout_default_client", 1) == 1)) then
        return true
    end
end

-- hook.Add("PlayerInitialSpawn", "QuickLoadoutInitTable", function(ply) ply.quickloadout = {} end)

hook.Add("PlayerLoadout", "QuickLoadoutLoadout", QuickLoadout)

hook.Add("PlayerSpawn", "QuickLoadoutSpawn", function(ply, trans)
    -- if !trans then
        ply.qlspawntime = CurTime() or 0
    -- end
    timer.Remove("QLPlayerSpawn" .. ply:UserID())
    if IsValid(ply) then
        net.Start("quickloadout")
        net.WriteBool(true)
        net.Send(ply)
    end
end)

hook.Add("PostPlayerDeath", "QuickLoadoutDeath", function(ply)
    timer.Create("QLPlayerSpawn" .. ply:UserID(), 10, 1, function()
        if IsValid(ply) then
            net.Start("quickloadout")
            net.WriteBool(true)
            net.Send(ply)
        end
    end)
end)

hook.Add("KeyPress", "QuickLoadoutCancel", function(ply, key)
    if !timestop:GetBool() then return end
    if ply.qlspawntime > 0 and key == IN_ATTACK then
        ply.qlspawntime = 0
    end
end)