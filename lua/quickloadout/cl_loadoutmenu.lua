AddCSLuaFile()
local weaponlist = GetConVar("quickloadout_weapons")
local ptable = string.Explode(", ", weaponlist:GetString())
local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_override")
local maxslots = GetConVar("quickloadout_maxslots")

local function GenerateCategory(frame)
    local category = vgui.Create("DScrollPanel", frame)
    local bar = category:GetVBar()
    category:SetWidth(frame:GetTall() * 0.3)
    category:Dock(2)
    bar:SetHideButtons(true)
    return category
end

local function GenerateButton(frame, name, v, off)
    local button = vgui.Create("DButton", frame, v)
    local function QuickName()
        if !isstring(name) and !isnumber(name) and name.PrintName != nil then
            return name.PrintName .. " (" .. name.Category .. ")"
        else
            return v or "ASS"
        end
    end
    local text = QuickName()
    button:SetWrap(true)
    button:SetWidth(frame:GetWide() - frame:GetVBar():GetWide() - 1)
    button:SetHeight(frame:GetWide() * 0.15)
    button:SetTextInset(frame:GetWide() * 0.05, frame:GetTall() * 0.0)
    button:SetText(text)
    button:SetPos(0, off)
    button.OnReleased = function() for k, v in ipairs(frame:GetChild(0):GetChildren()) do v:SetToggle(false) end button:SetToggle(true) end
    return button
end

local function NetworkLoadout()
    net.Start("quickloadout")
    net.WriteTable(ptable)
    net.SendToServer()
end

function QLOpenMenu()
    local mainmenu = vgui.Create("DFrame")
    mainmenu:SetSize(ScrW() / 2, ScrH() / 2)
    mainmenu:SetPos((ScrW() - mainmenu:GetWide()) * 0.5, (ScrH() - mainmenu:GetTall()) * 0.5)
    mainmenu:SetTitle("Loadout")
    mainmenu:SetVisible(true)
    mainmenu:SetDraggable(false)
    mainmenu:ShowCloseButton(true)
    mainmenu:DockPadding((mainmenu:GetWide() - mainmenu:GetTall()) * 0.25, 0, 0, 0)
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
    local weplist = GenerateCategory(mainmenu)
    local category = GenerateCategory(mainmenu)
    local subcat = GenerateCategory(mainmenu)
    local offset = mainmenu:GetTall() * 0.1
    local function WepSelector(button, index, wep, frame)
        offset = mainmenu:GetTall() * 0.1
        for k, _ in SortedPairs(wtable) do
            cat = GenerateButton(category, index, k, offset)
            offset = offset + cat:GetTall()
            cat.DoClick = function()
                offset = mainmenu:GetTall() * 0.1
                for i, v in SortedPairs(wtable[k]) do
                    subbutton = GenerateButton(subcat, index, v, offset)
                    offset = offset + subbutton:GetTall()
                    subbutton.DoClick = function()
                        table.Merge(ptable, {[index] = i})
                        button:SetText(v .. " (" .. k .. ")")
                        -- PrintTable(ptable)
                        subcat:Clear()
                        category:Clear()
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
    for i, v in ipairs(ptable) do
        local slot = GenerateButton(weplist, list.Get("Weapon")[v], v, offset)
        offset = offset + slot:GetTall()
        slot.DoClick = function()
            subcat:Clear()
            category:Clear()
            WepSelector(slot, i, v, mainmenu)
        end
        slot.DoRightClick = function()
            subcat:Clear()
            category:Clear()
            WepEjector(slot, i, v)
        end
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