AddCSLuaFile()
local weaponlist = GetConVar("quickloadout_weapons")
local ptable = {}
table.CopyFromTo(string.Explode(", ", weaponlist:GetString()), ptable)
local keybind = GetConVar("quickloadout_key")
local showcat = GetConVar("quickloadout_showcategory")
local fontbig, fontsmall = GetConVar("quickloadout_ui_font"), GetConVar("quickloadout_ui_font_small")
local lastgiven = 0

-- local enabled = GetConVar("quickloadout_enable")
-- local override = GetConVar("quickloadout_override")
local maxslots = GetConVar("quickloadout_maxslots")
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

local function GenerateCategory(frame, name)
    local category = frame:Add("DListLayout")
    if name then category:SetName(name) end
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
    elseif IsValid(weapons.Get(item)) and surface.GetTextureNameByID(weapons.Get(item).WepSelectIcon) != "weapons/swep" then return surface.GetTextureNameByID(weapons.Get(item).WepSelectIcon)
    elseif file.Exists("materials/vgui/hud/" .. item .. ".vmt", "GAME") then
        frame:SetSize(ScrH() * 0.4, ScrH() * 0.2)
        frame:SetPos((parent:GetWide() - parent:GetTall()) * 0.25 + parent:GetTall() * 0.7, parent:GetTall() * 0.15)
        return "vgui/hud/" .. item .. ".vmt"
    elseif file.Exists("materials/vgui/entities/" .. item .. ".vmt", "GAME") then return "vgui/entities/" .. item .. ".vmt"
    elseif file.Exists("materials/entities/" .. item .. ".png", "GAME") then return "entities/" .. item .. ".png"
    else return "vgui/null" end
end

local function GenerateLabel(frame, name, class, panel)
    local button = frame:Add("DLabel")
    local function NameSetup()
        if istable(name) then
            return class or name
        else
            return name or class
        end
    end
    local text = NameSetup() or "Uh oh! Broken!"
    button:SetName(class)
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
            surface.DrawRect(math.max(button:GetWide() * 0.01, 1) , math.max(button:GetWide() * 0.005, 1), x - math.max(button:GetWide() * 0.02, 1), y - math.max(button:GetWide() * 0.01, 1))
        end
        button.OnCursorEntered = function(self)
            if self:GetToggle() then return end
            surface.PlaySound("garrysmod/ui_hover.wav")
            panel:SetImage(TestImage(class, panel), "vgui/null")
        end
        button.OnToggled = function(self, state)
            if state then
                surface.PlaySound("garrysmod/ui_click.wav")
            else
                surface.PlaySound("garrysmod/ui_return.wav")
            end
        end
    end
    return button
end

local function NetworkLoadout()
    if CurTime() < lastgiven + 1 then LocalPlayer():PrintMessage(HUD_PRINTCENTER, "You're sending loadouts too quick! Calm down.") return end
    lastgiven = CurTime()
    net.Start("quickloadout")
    net.SendToServer()
end

net.Receive("quickloadout", function() LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Your loadout will change on next spawn.") end)

local wtable = {}
local open = false

local function GenerateWeaponTable()
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

function QLOpenMenu()
    if open then return else open = true end
    local newloadout = false
    local function RefreshLoadout()
        newloadout = true
    end
    local mainmenu = vgui.Create("EditablePanel")
    mainmenu:SetZPos(-1)
    mainmenu:SetSize(ScrW(), ScrH())
    mainmenu.Paint = function(self, x, y)
        surface.SetDrawColor(col_bg)
        surface.DrawRect(0,0, (x - y) * 0.25, y)
        surface.SetMaterial(Material("vgui/gradient-l"))
        surface.DrawTexturedRect((x - y) * 0.25, 0, math.min(y * 1.5, x), y)
    end
    mainmenu:SetX(-mainmenu:GetWide())
    mainmenu:MoveTo(0, 0, 0.25, 0, 0.8)
    mainmenu:Show()
    mainmenu:MakePopup()

    local function CloseMenu()
        mainmenu:SetKeyboardInputEnabled(false)
        mainmenu:SetMouseInputEnabled(false)
        mainmenu:MoveTo(-mainmenu:GetWide(), 0, 0.25, 0, 1.5)
        timer.Simple(0.25, function()
            open = false
            mainmenu:Remove()
            if !newloadout then return end
            weaponlist:SetString(table.concat(ptable, ", "))
            NetworkLoadout()
        end)
    end

    function mainmenu:OnKeyCodePressed(key)
        if input.IsKeyDown(input.GetKeyCode(keybind:GetString())) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu") then
            CloseMenu()
        end
    end

    if table.IsEmpty(wtable) then
        print("Generating weapon table...")
        GenerateWeaponTable()
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
    local lbar, rbar = lscroller:GetVBar(), rscroller:GetVBar()
    lbar:SetHideButtons(true)
    rbar:SetHideButtons(true)
    lbar:SetWide(lcont:GetWide() * 0.05)
    rbar:SetWide(lcont:GetWide() * 0.05)
    lbar.Paint = function() end
    rbar.Paint = function() end
    lscroller:SetZPos(1)
    lscroller:SetSize(lcont:GetWide(), lcont:GetTall() * 0.8)
    rscroller:CopyBase(lscroller)
    lscroller:SetHeight(lscroller:GetTall() * 0.9)
    lscroller:SetY(lcont:GetTall() * 0.1 + lcont:GetWide() * 0.125)
    rscroller:SetY(lcont:GetTall() * 0.1)
    lbar.btnGrip.Paint = function(self, x, y)
        draw.RoundedBox(x, x * 0.25, x * 0.5, x * 0.5, y - x, Color(255, 255, 255, 128))
    end
    rbar.btnGrip.Paint = function(self, x, y)
        draw.RoundedBox(x, x * 0.25, x * 0.5, x * 0.5, y - x, Color(255, 255, 255, 128))
    end
    local weplist = GenerateCategory(lscroller)
    weplist:MakeDroppable("quickloadoutarrange", false)
    local category1 = GenerateCategory(rscroller, "x Cancel")
    local category2 = GenerateCategory(rscroller, "< Categories")
    local category3 = GenerateCategory(rscroller, "< Subcategories")
    local image = mainmenu:Add("DImage")
    image:SetImage("vgui/null", "vgui/null")
    image:SetSize(mainmenu:GetTall() * 0.4, mainmenu:GetTall() * 0.4)
    image:SetPos((mainmenu:GetWide() - mainmenu:GetTall()) * 0.25 + mainmenu:GetTall() * 0.7, mainmenu:GetTall() * 0.1)
    -- image:SetKeepAspect(true)
    local function GetMaxSlots()
        if maxslots:GetBool() then return " (Max " .. maxslots:GetInt() .. ")" else return "" end
    end

    local toptext = GenerateLabel(lcont, "Loadout" .. GetMaxSlots(), nil)
    toptext:SetY(lcont:GetTall() * 0.1)
    toptext.OnCursorEntered = function()
        if buttonclicked then return end
        image:SetImage("vgui/null", "vgui/null")
    end

    local closer = GenerateLabel(lcont, "Close", nil, image)
    closer:SetY(lcont:GetTall() * 0.9 - lcont:GetWide() * 0.13)
    closer.DoClickInternal = function(self)
        self:SetToggle(true)
        CloseMenu()
    end
    mainmenu.OnCursorEntered = function()
        if buttonclicked then return end
        image:SetImage("vgui/null", "vgui/null")
    end

    local options = GenerateCategory(lcont)
    options:SetVisible(false)
    options:SetSize(lcont:GetWide(), lcont:GetTall() * 0.1)
    options:SetY(lcont:GetWide() * 0.2)
    options:DockPadding(lcont:GetWide() * 0.025, 0, lcont:GetWide() * 0.025, 0)

    local optbut = GenerateLabel(lcont, "Options", collapse, image)
    optbut:SetY(lcont:GetWide() * 0.05)
    optbut.DoClickInternal = function(self)
        options:SetVisible(!self:GetToggle())
        weplist:SetVisible(self:GetToggle())
        toptext:SetVisible(self:GetToggle())
    end

    local enable = options:Add("DCheckBoxLabel")
    enable:SetConVar("quickloadout_enable_client")
    enable:SetText("Enable loadout")
    enable:SetTooltip("Toggles your loadout on or off, without clearing the list.")
    enable:SetFont("quickloadout_font_small")
    enable:SetTall(options:GetWide() * 0.125)
    enable:SetWrap(true)
    enable.Button.Toggle = function(self)
        self:SetValue( !self:GetChecked() )
        RefreshLoadout()
    end

    local default = options:Add("DCheckBoxLabel")
    default:SetConVar("quickloadout_default_client")
    default:SetText("Give default loadout")
    default:SetTooltip("Toggles default sandbox loadout on or off.")
    default:SetFont("quickloadout_font_small")
    default:SetTall(options:GetWide() * 0.125)
    default:SetWrap(true)
    default.Button.Toggle = function(self)
        self:SetValue( !self:GetChecked() )
        RefreshLoadout()
    end

    local enablecat = options:Add("DCheckBoxLabel")
    enablecat:SetConVar("quickloadout_showcategory")
    enablecat:SetText("Show categories")
    enablecat:SetTooltip("Toggles whether your equipped weapons should or should not show their weapon category underneath them.")
    enablecat:SetValue(showcat:GetBool())
    enablecat:SetFont("quickloadout_font_small")
    enablecat:SetWrap(true)

    local fontpanel = options:Add("EditablePanel")
    fontpanel:SetTooltip("The font Quick Loadout's GUI should use.\nYou can use any installed font on your computer, or found in Garry's Mod's ''resource/fonts'' folder.")
    local fonttext, fontfield = GenerateLabel(fontpanel, "Font"), fontpanel:Add("DTextEntry")
    fonttext:SetFontInternal("quickloadout_font_small")
    fonttext:SetWrap(false)
    fonttext:SetSize(fonttext:GetTextSize())
    fonttext:SetTextInset(0, 0)
    fonttext:DockMargin(0, 0, options:GetWide() * 0.025, options:GetWide() * 0.025)
    fonttext:Dock(LEFT)
    fontfield:SetConVar("quickloadout_ui_font")
    fontfield:AllowInput(true)
    fontfield:Dock(FILL)

    local colortext, bgsheet = GenerateLabel(options, "Colors"), options:Add("DPropertySheet")
    colortext:SetFontInternal("quickloadout_font_small")
    colortext:SetTextInset(0, 0)
    for k, v in ipairs(options:GetChildren()) do
        v:DockMargin(options:GetWide() * 0.025, 0, 0, options:GetWide() * 0.025)
    end
    local bgcolor, buttoncolor = bgsheet:Add("DColorMixer"), bgsheet:Add("DColorMixer")
    Derma_Install_Convar_Functions(bgcolor)
    bgsheet:SetFontInternal("quickloadout_font_small")
    bgsheet:SetTall(math.max(options:GetWide() * 0.8, 240))
    bgsheet:DockMargin(0, 0, 0, options:GetWide() * 0.025)
    bgsheet:AddSheet("Background", bgcolor, "icon16/script_palette.png")
    bgsheet:AddSheet("Buttons", buttoncolor, "icon16/style_edit.png")
    bgcolor:SetAlphaBar(false)
    bgcolor:SetConVar("quickloadout_ui_color_bg")
    bgcolor:SetColor(ColorAlpha(col_bg, 128))
    bgcolor.Think = function(self)
        col_bg = ColorAlpha(self:GetColor(), 64)
        self:ConVarChanged(self:GetColor().r .. " " .. self:GetColor().g .. " " .. self:GetColor().b)
    end
    Derma_Install_Convar_Functions(buttoncolor)
    buttoncolor:SetAlphaBar(false)
    buttoncolor:SetConVar("quickloadout_ui_color_button")
    buttoncolor:SetColor(ColorAlpha(col_hl, 128))
    buttoncolor.Think = function(self)
        col_hl = ColorAlpha(self:GetColor(), 128)
        self:ConVarChanged(self:GetColor().r .. " " .. self:GetColor().g .. " " .. self:GetColor().b)
    end
    local fontx, fonty = fonttext:GetTextSize()
    enable:SetSize(options:GetWide(), fonty)
    enablecat:SetSize(options:GetWide(), fonty)
    fontpanel:SetSize(options:GetWide(), fonty)
    colortext:SetSize(options:GetWide(), fonty)


    local function QuickName(name)
        if list.Get("Weapon")[name] then
            if showcat:GetBool() then return list.Get("Weapon")[name].PrintName .. "\n(" .. list.Get("Weapon")[name].Category .. ")" or name
            else return list.Get("Weapon")[name].PrintName or name end
        else return "Weapon N/A!\n" .. name end
    end

    local function TheCats(cat)
        if cat == category1 then return category2 else return category3 end
    end

    local function CreateWeaponButtons() -- my god this is awful but IT WORKS FLAWLESSLY?? -- it's a lot better now i think :)
        local icon = image:GetImage()

        local function PopulateCategory(parent, tbl, cont, cat, slot) -- good enough automated container refresh
            cat:Clear()
            local cancel = GenerateLabel(cat, cat:GetName(), collapse, image)
            cancel.DoClickInternal = function(self)
                cat:Hide()
                self:SetToggle(true)
                parent:SetToggle(false)
                parent:GetParent():Show()
                image:SetImage(icon, "vgui/null")
                if cat == category1 then cont:GetParent():Hide() end
            end
            for i, v in SortedPairs(tbl) do
                if !(table.HasValue(ptable, v) and !ptable[slot]) then
                    local button = GenerateLabel(cat, i, v, image)
                    button.DoRightClick = cancel.DoClickInternal
                    button.DoClickInternal = function()
                        if istable(v) then
                            PopulateCategory(button, v, cont, TheCats(cat), slot)
                            cat:Hide()
                        else
                            if table.HasValue(ptable, v) and ptable[slot] then
                                table.Merge(ptable, {[table.KeyFromValue(ptable, v)] = ptable[slot]})
                            end
                            table.Merge(ptable, {[slot] = v})
                            cat:Clear()
                            CreateWeaponButtons()
                            RefreshLoadout()
                            -- PrintTable(ptable)
                        end
                    end
                end
            end
            cat:Show()
        end

        rcont:Hide()
        weplist:Clear()

        local function WepSelector(button, index)
            button.DoClickInternal = function()
                image:SetImage(TestImage(button:GetName(), image), "vgui/null")
                rcont:Show()
                rscroller:GetVBar():SetScroll(0)
                category1:Hide()
                category2:Hide()
                category3:Hide()
                PopulateCategory(button, wtable, rscroller, category1, index)
                if button:GetToggle() then
                    rcont:Hide()
                else
                    for k, v in ipairs(weplist:GetChildren()) do
                        v:SetToggle(false)
                    end
                    category1:Show()
                end
                buttonclicked = true
            end
            button.DoRightClick = function(self)
                self:SetToggle(true)
                self:Toggle()
                if index > #ptable then return end
                table.remove(ptable, index)
                CreateWeaponButtons()
                RefreshLoadout()
                -- PrintTable(ptable)
            end
        end
        for i, v in ipairs(ptable) do
            local button = GenerateLabel(weplist, QuickName(v), v, image)
            WepSelector(button, i)
        end
        local newwep = GenerateLabel(weplist, "+ Add Weapon", "vgui/null", image)
        WepSelector(newwep, #ptable+1)
    end

    CreateWeaponButtons()
end

hook.Add("InitPostEntity", "QuickLoadoutInit", function()
    GenerateWeaponTable()
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
        if input.IsKeyDown(input.GetKeyCode(keybind:GetString())) and !input.LookupBinding("quickloadout_menu") and IsFirstTimePredicted() then QLOpenMenu() end
    end)
end

concommand.Add("quickloadout_menu", QLOpenMenu)
-- cvars.AddChangeCallback("quickloadout_weapons", NetworkLoadout)
-- cvars.AddChangeCallback("quickloadout_enable_client", NetworkLoadout)

hook.Add("PopulateToolMenu", "QuickLoadoutSettings", function()
    spawnmenu.AddToolMenuOption("Options", "Loadout", "QuickLoadoutSettings", "Quick Loadout", "", "", function(panel)
        panel:Help("Server settings")
        panel:CheckBox("Enable quick loadouts", "quickloadout_enable")
        panel:ControlHelp("Globally enables quick loadout on server.")
        local default = panel:ComboBox("Default loadout", "quickloadout_default")
        default:SetSortItems(false)
        default:AddChoice("User-defined", -1)
        default:AddChoice("Disabled", 0)
        default:AddChoice("Enabled", 1)
        panel:ControlHelp("Enable gamemode's default loadout.")
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
        -- binder:SetConVar("quickloadout_key")
        binder:DockMargin(60,10,60,10)
        binder:Dock(TOP)
        binder:CenterHorizontal()
        binder:SetText(string.upper(keybind:GetString() or "none"))
        binder.OnChange = function(self, key)
            keybind:SetString(input.GetKeyName(key))
            self:SetText(string.upper(input.GetKeyName(key) or "none"))
        end
    end)
end)