local enabled = GetConVar("quickloadout_enable")
local default = GetConVar("quickloadout_default")
local model = GetConVar("quickloadout_applymodel")
local maxslots = GetConVar("quickloadout_maxslots")
local time = GetConVar("quickloadout_gracetime")
local timestop = GetConVar("quickloadout_gracetime_override")
local clips1 = GetConVar("quickloadout_giveclips_primary")
local clips2 = GetConVar("quickloadout_giveclips_secondary")

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
    if ply.qltransition then ply.qltransition = false return end
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
        net.WriteBool(false)
        net.Send(ply)
        return
    end
    if model:GetBool() then hook.Run("PlayerSetModel", ply) ply:SetupHands() end
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
    if ply.qltransition then return end
    local count = maxslots:GetBool() and maxslots:GetInt() or !game.SinglePlayer() and 32 or 0
    if !IsValid(ply) or !enabled:GetBool() or !ply.quickloadout or !ply:Alive() then return end
    ply:StripWeapons()
    ply:StripAmmo()
    if !table.IsEmpty(ply.quickloadout) then
        ply:SetActiveWeapon(NULL)
        ply.QLPreventSwitch = true
        local wtable = list.Get("Weapon")
        local ammomult1, ammomult2 = clips1:GetInt(), clips2:GetInt()
        for k, wep in ipairs(ply.quickloadout) do
            if (!game.SinglePlayer() or maxslots:GetBool()) and count and count < k then break end
            if !wtable[wep] or !wtable[wep].Spawnable or (wtable[wep].AdminOnly and !ply:IsAdmin()) then count = count + 1
            else
                ply:Give(wep, ammomult1 >= 0 or exctab[wep])
                local wget = ply:GetWeapon(wep)
                if ammomult1 < 0 then continue end
                timer.Simple(0, function()
                    if !(wget and IsValid(wget)) then return end
                    local ammo1, ammo2, type1, type2 = wget:GetMaxClip1(), wget:GetMaxClip2(), wget:GetPrimaryAmmoType(), wget:GetSecondaryAmmoType()
                    wget:SetClip1(ammo1)
                    wget:SetClip2(type2)
                    if wget:GetPrimaryAmmoType() >= 1 and ammo1 != 0 then
                        ply:GiveAmmo(math.max(ammo1, 1) * (ammomult1), type1, true)
                    end --Giving extra clip only to primary is intentional, and doubled if it's guessed to be akimbo
                    if wget:GetSecondaryAmmoType() >= 1 and ammo2 != 0 then
                        ply:GiveAmmo(math.max(ammo2, 1) * (ammomult2), type2, true)
                    end
                end)
            end
        end
        timer.Simple(0, function()
            ply.QLPreventSwitch = false
            local weps = ply:GetWeapons()
            if !IsValid(weps[1]) then return end
            ply:SelectWeapon(weps[1])
            ply:SetSaveValue("m_hLastWeapon", weps[2] or NULL)
        end)
    end
    if !(ply:GetInfoNum("quickloadout_enable_client", 1) == 0 or default:GetInt() == 1 or (default:GetInt() == -1 and ply:GetInfoNum("quickloadout_default_client", 1) == 1)) then
        return true
    end
end

hook.Add("PlayerSwitchWeapon", "QuickLoadoutPreventSwitch", function(ply, old, new)
    if ply.QLPreventSwitch then return true end
end)
-- hook.Add("PlayerInitialSpawn", "QuickLoadoutInitTable", function(ply) ply.quickloadout = {} end)

hook.Add("PlayerLoadout", "QuickLoadoutLoadout", QuickLoadout)

hook.Add("PlayerSpawn", "QuickLoadoutSpawn", function(ply, trans)
    -- if !trans then
        ply.qltransition = trans
        ply.qlspawntime = CurTime() or 0
    -- end
    timer.Remove("QLPlayerSpawn" .. ply:UserID())
    if IsValid(ply) then
        net.Start("quickloadout")
        net.WriteBool(true)
        net.WriteBool(time:GetFloat() > 0)
        net.Send(ply)
    end
end)

hook.Add("PostPlayerDeath", "QuickLoadoutDeath", function(ply)
    timer.Create("QLPlayerSpawn" .. ply:UserID(), 10, 1, function()
        if IsValid(ply) then
            net.Start("quickloadout")
            net.WriteBool(true)
            net.WriteBool(false)
            net.Send(ply)
        end
    end)
end)

hook.Add("KeyPress", "QuickLoadoutCancel", function(ply, key)
    if time:GetFloat() <= 0 then return end
    if !timestop:GetBool() then return end
    if ply.qlspawntime > 0 and key == IN_ATTACK and ply.qlspawntime + 0.2 < CurTime() then
        if (ply.qlspawntime + time:GetFloat() > CurTime()) then
            net.Start("quickloadout")
            net.WriteBool(false)
            net.WriteBool(true)
            net.Send(ply)
        end
        ply.qlspawntime = 0
    end
end)