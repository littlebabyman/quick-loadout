AddCSLuaFile()
local weaponlist = GetConVar("quickloadout_weapons")
local ptable = {}
table.CopyFromTo(string.Explode(", ", weaponlist:GetString()), ptable)
local keybind = GetConVar("quickloadout_key")
local showcat = GetConVar("quickloadout_showcategory")
local enabled = GetConVar("quickloadout_enable_client")
local fontbig, fontsmall = GetConVar("quickloadout_ui_font"), GetConVar("quickloadout_ui_font_small")

-- local enabled = GetConVar("quickloadout_enable")
-- local override = GetConVar("quickloadout_override")
-- local maxslots = GetConVar("quickloadout_maxslots")
-- local time = GetConVar("quickloadout_switchtime")

local function CreateFonts()
    surface.CreateFont("quickloadout_font_large", {
        font = fontbig:GetString(),
        extended = true,
        size = ScrH() * 0.04
    })
    surface.CreateFont("quickloadout_font_small", {
        font = fontbig:GetString(),
        extended = true,
        size = ScrH() * 0.03
    })
end

local function RefreshColors()
    local cvar_bg, cvar_but = string.ToColor(GetConVar("quickloadout_ui_color_bg"):GetString() .. " 69"), string.ToColor(GetConVar("quickloadout_ui_color_button"):GetString() .. " 69")
    local function LessenBG(color)
        local temptbl = {r = 0, g = 0, b = 0, a = 0}
        for k, v in SortedPairs(color) do
            table.Merge(temptbl, {[k] = math.floor(v * 0.125)})
        end
    return Color(temptbl.r, temptbl.g, temptbl.b) end
    local function LessenButton(color)
        local temptbl = {r = 0, g = 0, b = 0, a = 0}
        for k, v in SortedPairs(color) do
           table.Merge(temptbl, {[k] = math.floor(v * 0.75)})
        end
    return Color(temptbl.r, temptbl.g, temptbl.b) end
    local a, b, c, d = ColorAlpha(cvar_bg, 64) or Color(0,128,0,64), IsColor(LessenBG(cvar_bg)) and ColorAlpha(LessenBG(cvar_bg), 128) or Color(0,16,0,128), ColorAlpha(LessenButton(cvar_but), 128) or Color(0,96,0,128), ColorAlpha(cvar_but, 128) or Color(0,128,0,128)
    return a, b, c, d
end

CreateFonts()
local col_bg, col_col, col_but, col_hl = RefreshColors()

cvars.AddChangeCallback("quickloadout_ui_color_bg" , function() col_bg, col_col, col_but, col_hl = RefreshColors() end)
cvars.AddChangeCallback("quickloadout_ui_color_button", function() col_bg, col_col, col_but, col_hl = RefreshColors() end)
cvars.AddChangeCallback("quickloadout_ui_font", function() timer.Simple(0, CreateFonts) end)
cvars.AddChangeCallback("quickloadout_ui_font_small", function() timer.Simple(0, CreateFonts) end)
hook.Add("OnScreenSizeChanged", "RecreateQLFonts", function() timer.Simple(0, CreateFonts) end)

local function GenerateCategory(frame)
    local category = frame:Add("DListLayout")
    category:SetZPos(2)
    category:SetSize(frame:GetWide(), frame:GetTall())
    return category
end

local function TestImage(item, frame)
    local image, parent = frame:GetImage(), frame:GetParent()
    if !item or istable(item) then return image end
    frame:SetSize(parent:GetTall() * 0.4, parent:GetTall() * 0.4)
    frame:SetPos((parent:GetWide() - parent:GetTall()) * 0.25 + parent:GetTall() * 0.7, parent:GetTall() * 0.05)
    if file.Exists("materials/" .. item .. ".vmt", "GAME") then return item
    elseif !list.Get("Weapon")[item] then return "vgui/avatar_default"
    elseif IsValid(weapons.Get(item)) and surface.GetTextureNameByID(weapons.Get(item).WepSelectIcon) != "weapons/swep" then return surface.GetTextureNameByID(weapons.Get(item).WepSelectIcon)
    elseif file.Exists("materials/vgui/hud/" .. item .. ".vmt", "GAME") then
        frame:SetSize(ScrH() * 0.4, ScrH() * 0.2)
        frame:SetPos((parent:GetWide() - parent:GetTall()) * 0.25 + parent:GetTall() * 0.7, parent:GetTall() * 0.15)
        return "vgui/hud/" .. item .. ".vmt"
    elseif file.Exists("materials/vgui/entities/" .. item .. ".vmt", "GAME") then return "vgui/entities/" .. item .. ".vmt"
    elseif file.Exists("materials/entities/" .. item .. ".png", "GAME") then return "entities/" .. item .. ".png"
    else return "vgui/null" end
end

local function GenerateLabel(frame, name, index, panel)
    local button = frame:Add("DLabel")
    local function NameSetup()
        if istable(name) then
            return index or name
        else
            return name or index
        end
    end
    local text = NameSetup() or "Uh oh! Broken!"
    button:SetName(index)
    button:SetMouseInputEnabled(true)
    button:SetSize(frame:GetWide(), frame:GetWide() * 0.125)
    button:SetFontInternal("quickloadout_font_large")
    button:SetTextInset(button:GetWide() * 0.05, 0)
    button:SetWrap(true)
    button:SetAutoStretchVertical(true)
    button:SetText(text)
    if ispanel(panel) then
        button:SetIsToggle(true)
        button.Paint = function(self, x, y)
            surface.SetDrawColor(col_but)
            if button:IsHovered() or button:GetToggle() then
                surface.SetDrawColor(col_hl)
            end
            surface.DrawRect(math.max(button:GetWide() * 0.01, 1) , math.max(button:GetWide() * 0.01, 1), x - math.max(button:GetWide() * 0.01, 1), y - math.max(button:GetWide() * 0.01, 1))
        end
        button.DoClickInternal = function(self)
            surface.PlaySound("garrysmod/ui_click.wav")
        end
        button.OnCursorEntered = function(self)
            surface.PlaySound("garrysmod/ui_hover.wav")
            panel:SetImage(TestImage(index, panel), "vgui/null")
        end
    end
    return button
end

local function NetworkLoadout()
    net.Start("quickloadout")
    net.SendToServer()
end

net.Receive("quickloadout", function() LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Your loadout will change on next spawn.") end)

local wtable = {}
local closing = false

function QLOpenMenu(refresh)
    if closing then return end
    local newloadout = refresh or false

    local mainmenu = vgui.Create("EditablePanel")
    mainmenu:SetZPos(-1)
    mainmenu:SetSize(ScrW(), ScrH())
    mainmenu.Paint = function(self, x, y)
        surface.SetDrawColor(col_bg)
        surface.DrawRect(0,0, y * 0.5, y)
        surface.SetMaterial(Material("vgui/gradient-l"))
        surface.DrawTexturedRect(y * 0.5, 0, y, y)
    end
    if !newloadout then
        mainmenu:SetX(-mainmenu:GetWide())
        mainmenu:MoveTo(0, 0, 0.25, 0, 0.8)
    end
    mainmenu:Show()
    mainmenu:MakePopup()
    local function CloseMenu()
        closing = true
        mainmenu:SetKeyboardInputEnabled(false)
        mainmenu:SetMouseInputEnabled(false)
        mainmenu:MoveTo(-mainmenu:GetWide(), 0, 0.25, 0, 1.5)
        timer.Simple(0.25, function()
            closing = false
            mainmenu:Remove()
            if !newloadout then return end
            weaponlist:SetString(table.concat(ptable, ", "))
        end)
    end

    function mainmenu:OnKeyCodePressed(key)
        if key == input.GetKeyCode(keybind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu") then
            CloseMenu()
        end
    end

    if table.IsEmpty(wtable) then
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
                    table.Merge(wtable[v.Category][reftable.SubCategory], {[v.PrintName or v.ClassName] = v.ClassName})
                else
                    table.Merge(wtable[v.Category], {[v.PrintName or v.ClassName] = v.ClassName})
                end
            end
        end
    end

    table.RemoveByValue(ptable, "")
    local buttonclicked = false
    local lcont, rcont = mainmenu:Add("Panel"), mainmenu:Add("Panel")
    lcont:SetZPos(0)
    lcont.Paint = function(self, x, y)
        surface.SetDrawColor(col_col)
        surface.DrawRect(0,0, x, y)
    end
    lcont:SetSize(mainmenu:GetTall() * 0.3, mainmenu:GetTall())
    lcont:SetX((mainmenu:GetWide() - mainmenu:GetTall()) * 0.25)
    rcont:CopyBase(lcont)
    rcont.Paint = function(self, x, y)
        surface.SetDrawColor(col_col)
        surface.DrawRect(0,0, x, y)
    end
    rcont:SetX(lcont:GetPos() + lcont:GetWide() * 1.1)
    rcont:Hide()
    local lscroller, rscroller = lcont:Add("DScrollPanel"), rcont:Add("DScrollPanel")
    lscroller:SetZPos(1)
    lscroller:SetSize(lcont:GetWide(), lcont:GetTall() * 0.8)
    rscroller:CopyBase(lscroller)
    lscroller:SetHeight(lscroller:GetTall() * 0.9)
    lscroller:SetY(lcont:GetTall() * 0.1 + lcont:GetWide() * 0.125)
    rscroller:SetY(lcont:GetTall() * 0.1)
    local weplist = GenerateCategory(lscroller)
    weplist:MakeDroppable("quickloadoutarrange", false)
    local category = GenerateCategory(rscroller)
    local subcat = GenerateCategory(rscroller)
    local subcat2 = GenerateCategory(rscroller)
    local image = mainmenu:Add("DImage")
    image:SetImage("vgui/null", "vgui/null")
    image:SetSize(mainmenu:GetTall() * 0.4, mainmenu:GetTall() * 0.4)
    image:SetPos((mainmenu:GetWide() - mainmenu:GetTall()) * 0.25 + mainmenu:GetTall() * 0.7, mainmenu:GetTall() * 0.1)
    -- image:SetKeepAspect(true)

    local toptext = GenerateLabel(lcont, "Loadout", nil)
    toptext:SetY(lcont:GetTall() * 0.1)
    toptext.OnCursorEntered = function()
        if buttonclicked then return end
        image:SetImage("vgui/null", "vgui/null")
    end

    local closer = GenerateLabel(lcont, "Close", nil, lcont)
    closer:SetY(lcont:GetTall() * 0.9 - lcont:GetWide() * 0.13)
    closer.DoClickInternal = function(self)
        CloseMenu()
        surface.PlaySound("garrysmod/ui_return.wav")
    end
    closer.OnCursorEntered = function(self)
        surface.PlaySound("garrysmod/ui_hover.wav")
    end
    mainmenu.OnCursorEntered = function()
        if buttonclicked then return end
        image:SetImage("vgui/null", "vgui/null")
    end

    local options = GenerateCategory(lcont)
    options:SetVisible(false)
    options:SetSize(lcont:GetWide(), lcont:GetTall() * 0.1)
    options:SetY(lcont:GetWide() * 0.2)
    options:DockPadding(lcont:GetWide() * 0.05, 0, lcont:GetWide() * 0.05, 0)

    local optbut = GenerateLabel(lcont, "Options", collapse, lcont)
    optbut:SetY(lcont:GetWide() * 0.05)
    optbut.DoClickInternal = function() end
    optbut.OnCursorEntered = function(self)
        surface.PlaySound("garrysmod/ui_hover.wav")
    end
    optbut.OnToggled = function(self, state)
        if state then
            surface.PlaySound("garrysmod/ui_click.wav")
        else
            surface.PlaySound("garrysmod/ui_return.wav")
        end
        options:SetVisible(state)
        weplist:SetVisible(!state)
        toptext:SetVisible(!state)
    end

    local enable = options:Add("DCheckBoxLabel")
    enable:SetConVar("quickloadout_enable_client")
    enable:SetText("Enable loadout")
    enable:SetValue(enabled:GetBool())
    enable:SetFont("quickloadout_font_small")
    enable:SetTall(options:GetWide() * 0.125)
    enable:SetWrap(true)

    local enablecat = options:Add("DCheckBoxLabel")
    enablecat:SetConVar("quickloadout_showcategory")
    enablecat:SetText("Show categories")
    enablecat:SetValue(showcat:GetBool())
    enablecat:SetFont("quickloadout_font_small")
    enablecat:SetWrap(true)

    local fontpanel = options:Add("EditablePanel")
    local fonttext = GenerateLabel(fontpanel, "Font")
    local fontfield = fontpanel:Add("DTextEntry")
    fonttext:SetFontInternal("quickloadout_font_small")
    fonttext:SetWrap(false)
    fonttext:SetSize(fonttext:GetTextSize())
    fonttext:SetTextInset(0, 0)
    fonttext:Dock(LEFT)
    fontfield:SetConVar("quickloadout_ui_font")
    fontfield:AllowInput(true)
    fontfield:SetTall(fonttext:GetTall())
    fontfield:Dock(TOP)
    local fontx, fonty = fonttext:GetTextSize()
    enable:SetSize(options:GetWide(), fonty)
    enablecat:SetSize(options:GetWide(), fonty)
    fontpanel:SetSize(options:GetWide(), fonty)

    local bgtext, bgcolor = GenerateLabel(options, "Background Color"), options:Add("DColorMixer")
    Derma_Install_Convar_Functions(bgcolor)
    bgtext:SetFontInternal("quickloadout_font_small")
    bgcolor:SetConVar("quickloadout_ui_color_bg")
    bgcolor:SetColor(ColorAlpha(col_bg, 128))
    bgcolor:SetAlphaBar(false)
    bgcolor.Think = function(self)
        col_bg = ColorAlpha(self:GetColor(), 64)
        self:ConVarChanged(self:GetColor().r .. " " .. self:GetColor().g .. " " .. self:GetColor().b)
    end
    local buttontext, buttoncolor = GenerateLabel(options, "Button Color"), options:Add("DColorMixer")
    Derma_Install_Convar_Functions(buttoncolor)
    buttontext:SetFontInternal("quickloadout_font_small")
    buttoncolor:SetConVar("quickloadout_ui_color_button")
    buttoncolor:SetColor(ColorAlpha(col_hl, 128))
    buttoncolor:SetAlphaBar(false)
    buttoncolor.Think = function(self)
        col_hl = ColorAlpha(self:GetColor(), 128)
        self:ConVarChanged(self:GetColor().r .. " " .. self:GetColor().g .. " " .. self:GetColor().b)
    end
    for k, v in ipairs(options:GetChildren()) do
        v:DockMargin(0, 0, 0, options:GetWide() * 0.025)
    end
    fonttext:DockMargin(0, 0, options:GetWide() * 0.025, options:GetWide() * 0.025)

    local function ResetMenu()
        newloadout = true
        QLOpenMenu(newloadout)
        mainmenu:Remove()
    end

    local function WepSelector(button, index, img, frame)
        local icon = img:GetImage()
        local cancel = GenerateLabel(category, "x Cancel", collapse, image)
        cancel.DoClickInternal = function(self)
            surface.PlaySound("garrysmod/ui_return.wav")
            buttonclicked = false
            img:SetImage(TestImage(ptable[1], img), "vgui/null")
            rcont:Hide()
            button:SetToggle(false)
        end
        for k, _ in SortedPairs(wtable) do
            cat = GenerateLabel(category, k, nil, image)
            cat.DoRightClick = function()
                buttonclicked = false
                surface.PlaySound("garrysmod/ui_return.wav")
                img:SetImage("vgui/null", "vgui/null")
                rcont:Hide()
                button:SetToggle(false)
            end
            cat.DoClick = function()
                subcat2:Clear()
                subcat:Clear()
                category:Hide()
                subcat:Show()
                local catbut = GenerateLabel(subcat, "< Categories", collapse, image)
                catbut.DoClickInternal = function(self)
                    surface.PlaySound("garrysmod/ui_return.wav")
                    category:Show()
                    img:SetImage(icon, "vgui/null")
                    subcat:Hide()
                end
                for i, v in SortedPairs(_) do
                    subbutton = GenerateLabel(subcat, i, v, image)
                    subbutton.DoRightClick = function()
                        surface.PlaySound("garrysmod/ui_return.wav")
                        img:SetImage(icon, "vgui/null")
                        category:Show()
                        subcat:Hide()
                    end
                    local temptbl = v
                    if istable(temptbl) then
                        subbutton.DoClick = function()
                            subcat:Hide()
                            subcat2:Clear()
                            subcat2:Show()
                            local catbut2 = GenerateLabel(subcat2, "< Subcategories", collapse, image)
                            catbut2.DoClickInternal = function(self)
                                surface.PlaySound("garrysmod/ui_return.wav")
                                img:SetImage(icon, "vgui/null")
                                subcat:Show()
                                subcat2:Hide()
                            end
                            for i, v in SortedPairs(temptbl) do
                                subbutton2 = GenerateLabel(subcat2, i, v, image)
                                subbutton2.DoRightClick = function()
                                    surface.PlaySound("garrysmod/ui_return.wav")
                                    img:SetImage(icon, "vgui/null")
                                    subcat:Show()
                                    subcat2:Hide()
                                end
                                subbutton2.DoClick = function()
                                    table.Merge(ptable, {[index] = v})
                                    ResetMenu()
                                end
                            end
                        end
                    else
                        subbutton.DoClick = function()
                            table.Merge(ptable, {[index] = v})
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
            rcont:Hide()
            ResetMenu()
        end
    end
    for i, v in ipairs(ptable) do
        local function QuickName()
            if list.Get("Weapon")[v] then
                if showcat:GetBool() then return list.Get("Weapon")[v].PrintName .. "\n(" .. list.Get("Weapon")[v].Category .. ")" or v
                else return list.Get("Weapon")[v].PrintName or v end
            else return "Weapon N/A!\n" .. v end
        end
        local slot = GenerateLabel(weplist, QuickName(), v, image)
        slot.DoClick = function()
            buttonclicked = true
            image:SetImage(TestImage(v, image), "vgui/null")
            rcont:Show()
            category:Clear()
            rscroller:GetVBar():SetScroll(0)
            subcat2:Hide()
            subcat:Hide()
            slot:SetToggle(true)
            WepSelector(slot, i, image, mainmenu)
            for k, button in ipairs(weplist:GetChild(0):GetChildren()) do
                button:SetToggle(false)
            end
            category:Show()
        end
        slot.DoRightClick = function()
            surface.PlaySound("garrysmod/ui_return.wav")
            subcat2:Hide()
            subcat:Hide()
            category:Hide()
            WepEjector(slot, i, v)
        end
    end
    local slot = GenerateLabel(weplist, "+ Add Weapon", "vgui/null", image)
    slot.DoClick = function()
        buttonclicked = true
        image:SetImage("vgui/null", "vgui/null")
        rcont:Show()
        category:Clear()
        rscroller:GetVBar():SetScroll(0)
        subcat2:Hide()
        subcat:Hide()
        slot:SetToggle(true)
        WepSelector(slot, #ptable + 1, image, mainmenu)
        for k, button in ipairs(weplist:GetChild(0):GetChildren()) do
            button:SetToggle(false)
        end
        category:Show()
    end
    slot.DoRightClick = function()
        surface.PlaySound("garrysmod/ui_return.wav")
        subcat2:Hide()
        subcat:Hide()
        category:Hide()
        WepEjector(slot, #ptable + 1, nil)
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
                table.Merge(wtable[v.Category][reftable.SubCategory], {[v.PrintName or v.ClassName] = v.ClassName})
            else
                table.Merge(wtable[v.Category], {[v.PrintName or v.ClassName] = v.ClassName})
            end
        end
    end
    if game.SinglePlayer() then
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
cvars.AddChangeCallback("quickloadout_enable_client", NetworkLoadout)

hook.Add("PopulateToolMenu", "QuickLoadoutSettings", function()
    spawnmenu.AddToolMenuOption("Options", "Loadout", "QuickLoadoutSettings", "Quick Loadout", "", "", function(panel)
        panel:Help("Server settings")
        panel:CheckBox("Enable quick loadouts", "quickloadout_enable")
        panel:ControlHelp("Globally enables quick loadout on server.")
        panel:CheckBox("Override default loadout", "quickloadout_override")
        panel:ControlHelp("Forcibly removes other weapons players spawn with.")
        panel:NumSlider("Spawn grace time", "quickloadout_switchtime", 0, 600, 0)
        panel:ControlHelp("Time you have to change loadout after spawning. 0 is infinite.")
        panel:NumSlider("Maximum weapon slots", "quickloadout_maxslots", 0, 32, 0)
        panel:ControlHelp("Amount of weapons you can have on spawn. Max 32, 0 is infinite.")
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