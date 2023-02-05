AddCSLuaFile()
local weaponlist = GetConVar("quickloadout_weapons")
local ptable = string.Explode(", ", weaponlist:GetString())
local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_override")
local maxslots = GetConVar("quickloadout_maxslots")

local function GenerateButton(frame, i, v, off)
    local button = vgui.Create("DButton", frame, v)
    local text = v or "ASS"
    button:SetWrap(true)
    button:SetText(text)
    button:SetWidth(frame:GetWide() - frame:GetVBar():GetWide() - 1)
    button:SetHeight(20)
    button:SetPos(0, off)
    return button
end

local function GenerateCategory(frame)
    local category = vgui.Create("DScrollPanel", frame)
    category:SetWidth(200)
    category:Dock(2)
    return category
end

local function NetworkLoadout()
    net.Start("quickloadout")
    net.WriteTable(ptable)
    net.SendToServer()
end

function QLOpenMenu()
    local mainmenu = vgui.Create("DFrame")
    mainmenu:SetPos(ScrW() / 2-320, ScrH() / 2-240)
    mainmenu:SetSize(640, 480)
    mainmenu:SetTitle("Loadout")
    mainmenu:SetVisible(true)
    mainmenu:SetDraggable(false)
    mainmenu:ShowCloseButton(true)
    mainmenu:MakePopup()
    table.RemoveByValue(ptable, "")
    local wtable = {}
    for k, v in SortedPairs(list.Get( "Weapon" )) do
        if v.Spawnable and (!v.AdminOnly or LocalPlayer():IsSuperAdmin()) then
            if !wtable[v.Category] then
                wtable[v.Category] = {}
            end
            table.Merge(wtable[v.Category], {[v.ClassName] = v.PrintName or v.ClassName})
        end
    end
    local offset = 0
    local function WepSelector(button, index, wep, frame)
        offset = 0
        if IsValid(subcat) then subcat:Remove() end
        if IsValid(category) then category:Remove() end
        category = GenerateCategory(frame)
        for k, _ in SortedPairs(wtable) do
            cat = GenerateButton(category, index, k, offset)
            offset = offset + cat:GetTall()
            cat.DoClick = function()
                offset = 0
                if IsValid(subcat) then subcat:Remove() end
                subcat = GenerateCategory(frame)
                for i, v in SortedPairs(wtable[k]) do
                    subbutton = GenerateButton(subcat, index, v, offset)
                    offset = offset + subbutton:GetTall()
                    subbutton.DoClick = function()
                        table.Merge(ptable, {[index] = i})
                        button:SetText(v .. " (" .. k .. ")")
                        -- PrintTable(ptable)
                        subcat:Remove()
                        category:Remove()
                    end
                end
            end
        end
    end
    local function WepEjector(button, index, wep)
        if table.HasValue(ptable, wep) then
            table.remove(ptable, index)
            button:Remove()
        end
    end
    weplist = GenerateCategory(mainmenu)
    for i, v in ipairs(ptable) do
        local slot = GenerateButton(weplist, i, v, offset)
        offset = offset + slot:GetTall()
        slot.DoClick = function() WepSelector(slot, i, v, mainmenu) end
        slot.DoRightClick = function() WepEjector(slot, i, v) end
    end
    local slot = GenerateButton(weplist, #ptable + 1, "Add Weapon", offset)
    slot.DoClick = function() WepSelector(slot, #ptable + 1, nil, mainmenu) end
    slot.DoRightClick = function() WepEjector(slot, #ptable + 1, nil) end
    mainmenu.OnClose = function()
        weaponlist:SetString(table.concat(ptable, ", "))
        NetworkLoadout()
    end
end

hook.Add("InitPostEntity", "QuickLoadoutInit", NetworkLoadout)

concommand.Add("quickloadout_menu", QLOpenMenu)

hook.Add("PopulateToolMenu", "QuickLoadoutSettings", function()
    spawnmenu.AddToolMenuOption("Utilities", "Admin", "QuickLoadoutSettings", "Quick Loadout", "", "", function(panel)
        panel:CheckBox(enabled, "Enable quick loadouts")
        panel:CheckBox(override, "Override default loadout")
        -- panel:CheckBox(maxslots, "Max weapons on spawn")
        local binder = vgui.Create("DBinder", panel)
        -- binder:Set
    end)
end)