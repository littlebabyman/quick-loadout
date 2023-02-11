AddCSLuaFile()
local weaponlist = GetConVar("quickloadout_weapons")
local ptable = string.Explode(", ", weaponlist:GetString())
local keybind = GetConVar("quickloadout_key")
-- local enabled = GetConVar("quickloadout_enable")
-- local override = GetConVar("quickloadout_override")
-- local maxslots = GetConVar("quickloadout_maxslots")
-- local time = GetConVar("quickloadout_switchtime")
local closed = false

local function GenerateCategory(frame)
    local category = vgui.Create("DScrollPanel", frame)
    local bar = category:GetVBar()
    category:SetWidth(frame:GetTall() * 0.3)
    category:Dock(2)
    category:DockMargin(0, frame:GetTall() * 0.1, 0, frame:GetTall() * 0.1)
    bar:SetHideButtons(true)
    return category
end

local function GenerateButton(frame, name, index, off)
    local button = vgui.Create("DButton", frame, index)
    local function QuickName()
        if istable(name) then
            return index or "ASS"
        else
            return name or index or "ASS"
        end
    end
    local text = QuickName()
    button:SetWrap(true)
    button:SetWidth(frame:GetWide() - 1)
    button:SetHeight(frame:GetWide() * 0.15)
    button:SetTextInset(frame:GetWide() * 0.05, 0)
    button:SetText(text)
    button:SetPos(0, off)
    return button
end

local function NetworkLoadout()
    net.Start("quickloadout")
    net.WriteTable(ptable)
    net.SendToServer()
end

net.Receive("quickloadout", function() LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Your loadout will change on next spawn.") end)

local wtable = {}

function QLOpenMenu(refresh)
    if closed then return end
    local newloadout = refresh or false
    local mainmenu = vgui.Create("DFrame")
    mainmenu:SetSize(ScrW() * 0.5, ScrH() * 0.5)
    mainmenu:Center()
    mainmenu:SetTitle("Loadout")
    mainmenu:SetVisible(true)
    mainmenu:SetDraggable(false)
    mainmenu:ShowCloseButton(true)
    mainmenu:DockPadding((mainmenu:GetWide() - mainmenu:GetTall()) * 0.25, 0, mainmenu:GetTall() * 0.02, 0)
    mainmenu:MakePopup()

    local function ResetMenu()
        newloadout = true
        QLOpenMenu(newloadout)
        mainmenu:Remove()
    end

    function mainmenu:OnKeyCodePressed(key)
        if key == input.GetKeyCode(keybind:GetString()) then
            mainmenu:Close()
        end
    end

    if GetConVar("sv_cheats"):GetBool() and GetConVar("developer"):GetBool() then
        for k, v in SortedPairs(list.Get( "Weapon" )) do
            if v.Spawnable and (!v.AdminOnly or LocalPlayer():IsSuperAdmin()) then
                local reftable = weapons.Get(k)
                if !wtable[v.Category] then
                    wtable[v.Category] = {}
                end
                if reftable and reftable.SubCategory then
                    if !wtable[v.Category][reftable.SubCategory] then
                        wtable[v.Category][reftable.SubCategory] = {}
                    end
                    table.Merge(wtable[v.Category][reftable.SubCategory], {[v.ClassName] = v.PrintName or v.ClassName})
                else
                    table.Merge(wtable[v.Category], {[v.ClassName] = v.PrintName or v.ClassName})
                end
            end
        end
    end

    table.RemoveByValue(ptable, "")
    local weplist = GenerateCategory(mainmenu)
    local category = GenerateCategory(mainmenu)
    local subcat = GenerateCategory(mainmenu)
    local subcat2 = GenerateCategory(mainmenu)
    weplist:DockMargin(0, mainmenu:GetTall() * 0.1, mainmenu:GetTall() * 0.02, mainmenu:GetTall() * 0.1)
    local offset = 0
    local function WepSelector(button, index, wep, frame)
        offset = 0
        for k, _ in SortedPairs(wtable) do
            cat = GenerateButton(category, k, nil, offset)
            offset = offset + cat:GetTall() * 1.1
            cat.DoRightClick = function()
                category:Clear()
                subcat2:Clear()
                subcat:Clear()
                button:SetSelected(false)
            end
            cat.DoClick = function()
                subcat2:Clear()
                subcat:Clear()
                category:SetWidth(0)
                subcat:SetWidth(frame:GetTall() * 0.3)
                local catbut = GenerateButton(subcat, "< Categories", collapse, 0)
                catbut.DoClick = function()
                    category:SetWidth(frame:GetTall() * 0.3)
                    subcat2:Clear()
                    subcat:Clear()
                end
                offset = cat:GetTall() * 1.1
                for i, v in SortedPairsByMemberValue(wtable[k], _) do
                    subbutton = GenerateButton(subcat, v, i, offset)
                    offset = offset + subbutton:GetTall() * 1.1
                    subbutton.DoRightClick = function()
                        category:SetWidth(frame:GetTall() * 0.3)
                        subcat2:Clear()
                        subcat:Clear()
                    end
                    subbutton.DoClick = function()
                        local temptbl = v
                        if istable(temptbl) then
                            subcat:SetWidth(0)
                            subcat2:SetWidth(frame:GetTall() * 0.3)
                            local catbut2 = GenerateButton(subcat2, "< Subcategories", collapse, 0)
                            catbut2.DoClick = function()
                                subcat:SetWidth(frame:GetTall() * 0.3)
                                subcat2:Clear()
                            end
                            offset = cat:GetTall() * 1.1
                            for i, v in SortedPairsByMemberValue(temptbl, v) do
                                subbutton2 = GenerateButton(subcat2, v, i, offset)
                                offset = offset + subbutton2:GetTall() * 1.1
                                subbutton2.DoRightClick = function()
                                    subcat:SetWidth(frame:GetTall() * 0.3)
                                    subcat2:Clear()
                                end
                                subbutton2.DoClick = function()
                                    table.Merge(ptable, {[index] = i})
                                    ResetMenu()
                                end
                            end
                        else
                            table.Merge(ptable, {[index] = i})
                            ResetMenu()
                        end
                    end
                end
            end
        end
    end
    local function WepEjector(button, index, wep)
        if table.HasValue(ptable, wep) then
            table.remove(ptable, index)
            ResetMenu()
        end
    end
    for i, v in ipairs(ptable) do
        local slot = GenerateButton(weplist, list.Get("Weapon")[v].PrintName .. " (" .. list.Get("Weapon")[v].Category .. ")", v, offset)
        offset = offset + slot:GetTall() * 1.1
        slot.DoClick = function()
            category:SetWidth(mainmenu:GetTall() * 0.3)
            subcat2:Clear()
            subcat:Clear()
            category:Clear()
            WepSelector(slot, i, v, mainmenu)
            for k, button in ipairs(weplist:GetChild(0):GetChildren()) do
                button:SetSelected(false)
            end
            slot:SetSelected(true)
        end
        slot.DoRightClick = function()
            subcat2:Clear()
            subcat:Clear()
            category:Clear()
            WepEjector(slot, i, v)
        end
    end
    local slot = GenerateButton(weplist, nil,"+ Add Weapon",  offset)
    slot.DoClick = function() WepSelector(slot, #ptable + 1, nil, mainmenu) end
    slot.DoRightClick = function() WepEjector(slot, #ptable + 1, nil) end
    mainmenu.OnClose = function()
        closed = true
        timer.Simple(0, function() closed = false end)
        if !newloadout then return end
        weaponlist:SetString(table.concat(ptable, ", "))
        NetworkLoadout()
    end
end

hook.Add("InitPostEntity", "QuickLoadoutInit", function()
    for k, v in SortedPairs(list.Get( "Weapon" )) do
        if v.Spawnable and (!v.AdminOnly or LocalPlayer():IsSuperAdmin()) then
            local reftable = weapons.Get(k)
            if !wtable[v.Category] then
                wtable[v.Category] = {}
            end
            if reftable and reftable.SubCategory then
                if !wtable[v.Category][reftable.SubCategory] then
                    wtable[v.Category][reftable.SubCategory] = {}
                end
                table.Merge(wtable[v.Category][reftable.SubCategory], {[v.ClassName] = v.PrintName or v.ClassName})
            else
                table.Merge(wtable[v.Category], {[v.ClassName] = v.PrintName or v.ClassName})
            end
        end
    end
    if game.SinglePlayer() then
        if input.LookupBinding("quickloadout_menu") then return end
        net.Start("QLSPHack")
        net.WriteInt(input.GetKeyCode(keybind:GetString()), 9)
        net.SendToServer()
    end
    NetworkLoadout()
end)

if game.SinglePlayer() then
    cvars.AddChangeCallback("quickloadout_key", function()
        if game.SinglePlayer() then
            net.Start("QLSPHack")
            net.WriteInt(input.GetKeyCode(keybind:GetString()), 9)
            net.SendToServer()
        end
    end)
    net.Receive("QLSPHack", function() if !input.LookupBinding("quickloadout_menu") then QLOpenMenu() end end)
else
    hook.Add("PlayerButtonDown", "QuickLoadoutBind", function(ply, key)
        if key == input.GetKeyCode(keybind:GetString()) and !input.LookupBinding("quickloadout_menu") and IsFirstTimePredicted() then QLOpenMenu() end
    end)
end

concommand.Add("quickloadout_menu", QLOpenMenu)
cvars.AddChangeCallback("quickloadout_weapons", NetworkLoadout)

hook.Add("PopulateToolMenu", "QuickLoadoutSettings", function()
    spawnmenu.AddToolMenuOption("Utilities", "Admin", "QuickLoadoutSettings", "Quick Loadout", "", "", function(panel)
        panel:Help("Server settings")
        panel:CheckBox("Enable quick loadouts", "quickloadout_enable")
        panel:ControlHelp("Globally enables quick loadout on server.")
        panel:CheckBox("Override default loadout", "quickloadout_override")
        panel:ControlHelp("Forcibly removes other weapons players spawn with.")
        panel:NumSlider("Spawn grace time", "quickloadout_switchtime", 0, 600, 0)
        panel:ControlHelp("Time you have to change loadout after spawning. 0 is infinite.")
        panel:NumSlider("Maximum weapon slots", "quickloadout_maxslots", 0, 32, 0)
        panel:ControlHelp("Amount of weapons you can have on spawn. Max 32.")
        panel:CheckBox("Shooting cancels grace", "quickloadout_switchtime_override")
        panel:ControlHelp("Whether pressing the attack button disables grace period.")
        panel:Help("Client settings")
        panel:Help("Loadout window bind")
        -- panel:CheckBox(maxslots, "Max weapons on spawn")
        local binder = vgui.Create("DBinder", panel)
        binder:DockMargin(60,10,60,10)
        binder:Dock(TOP)
        binder:CenterHorizontal()
        binder:SetText(string.upper(keybind:GetString() or "none"))
        function binder:OnChange(key)
            keybind:SetString(input.GetKeyName(key))
            binder:SetText(string.upper(input.GetKeyName(key) or "none"))
        end
    end)
end)