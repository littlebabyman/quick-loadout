AddCSLuaFile()
local weaponlist = GetConVar("quickloadout_weapons")
local ptable = {}
local loadouts = {}

if string.len(weaponlist:GetString()) > 0 then
    table.Add(ptable, string.Explode(", ", weaponlist:GetString()))
else print("it's empty!!! zero!!!") end

if file.Size("quickloadout/client_loadouts.json", "DATA") <= 0 then
    file.CreateDir("quickloadout")
    file.Write("quickloadout/client_loadouts.json", "[]")
end

if !istable(util.JSONToTable(file.Read("quickloadout/client_loadouts.json", "DATA"))) then
    print("Corrupted loadout table detected, creating back-up!!\ngarrysmod/data/quickloadout/client_loadouts_%y_%m_%d-%H_%M_%S_backup.json")
    file.Write(os.date("quickloadout/client_loadouts_%y_%m_%d-%H_%M_%S_backup.json"), file.Read("quickloadout/client_loadouts.json", "DATA"))
    file.Write("quickloadout/client_loadouts.json", "[]")
end

local function LoadSavedLoadouts()
    loadouts = util.JSONToTable(file.Read("quickloadout/client_loadouts.json", "DATA"))
end
-- print(file.Read("quickloadout/client_loadouts.json", "DATA"))

local keybind = GetConVar("quickloadout_key")
local showcat = GetConVar("quickloadout_showcategory")
local fonts, fontscale = GetConVar("quickloadout_ui_fonts"), GetConVar("quickloadout_ui_font_scale")
local lastgiven = 0
local buttonclicked = nil

local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_default")
local maxslots = GetConVar("quickloadout_maxslots")
local time = GetConVar("quickloadout_switchtime")

local function CreateFonts()
    local fonttable = string.Split(fonts:GetString() or {}, ", ")
    local scale = fontscale:GetFloat()
    surface.CreateFont("quickloadout_font_large", {
        font = fonttable[1],
        extended = true,
        size = ScrH() * scale * 0.04,
    })
    surface.CreateFont("quickloadout_font_small", {
        font = fonttable[2] or fonttable[1],
        extended = true,
        size = ScrH() * scale * 0.03,
    })
end

local function RefreshColors()
    local cvar_bg, cvar_but = string.ToColor(GetConVar("quickloadout_ui_color_bg"):GetString() .. " 69"), string.ToColor(GetConVar("quickloadout_ui_color_button"):GetString() .. " 69")
    function LessenBG(color)
        local temptbl = {r = 0, g = 0, b = 0, a = 0}
        for k, v in SortedPairs(color) do
            table.Merge(temptbl, {[k] = math.floor(v * 0.125)})
        end
    return Color(temptbl.r, temptbl.g, temptbl.b) end
    function LessenButton(color)
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
cvars.AddChangeCallback("quickloadout_ui_fonts", function() timer.Simple(0, CreateFonts) end)
-- cvars.AddChangeCallback("quickloadout_ui_font", function() timer.Simple(0, CreateFonts) end)
-- cvars.AddChangeCallback("quickloadout_ui_font_small", function() timer.Simple(0, CreateFonts) end)
hook.Add("OnScreenSizeChanged", "RecreateQLFonts", function() timer.Simple(0, CreateFonts) end)

local function GenerateCategory(frame, name)
    local category = frame:Add("DListLayout")
    if name then category:SetName(name) end
    category:SetZPos(2)
    category:SetSize(frame:GetParent():GetSize())
    return category
end

local function TestImage(item, frame)
    local image, x, y = frame:GetImage(), frame:GetParent():GetSize()
    if !item or istable(item) then return image end
    frame:SetSize(y * 0.4, y * 0.4)
    frame:SetPos((x - y) * 0.25 + y * 0.7, y * 0.05)
    if file.Exists("materials/" .. item .. ".vmt", "GAME") then return item
    elseif file.Exists("materials/vgui/hud/" .. item .. ".vmt", "GAME") then
        frame:SetSize(ScrH() * 0.4, ScrH() * 0.2)
        frame:SetPos((x - y) * 0.25 + y * 0.7, y * 0.15)
        return "vgui/hud/" .. item .. ".vmt"
    elseif file.Exists("materials/vgui/entities/" .. item .. ".vmt", "GAME") then return "vgui/entities/" .. item .. ".vmt"
    elseif file.Exists("materials/entities/" .. item .. ".png", "GAME") then return "entities/" .. item .. ".png"
    else return "vgui/null" end
end

local function GenerateLabel(frame, name, class, panel)
    local button = frame:Add("DLabel")
    function NameSetup()
        if istable(name) then
            return class or name
        else
            return name or class
        end
    end
    local text = NameSetup() or "Uh oh! Broken!"
    surface.SetFont("quickloadout_font_large")
    button:SetName(class)
    button:SetMouseInputEnabled(true)
    button:SetMinimumSize(nil, frame:GetWide() * 0.125)
    button:SetSize(frame:GetWide(), frame:GetWide() * 0.125)
    button:SetFont("quickloadout_font_large")
    button:SetTextInset(button:GetWide() * 0.05, 0)
    button:SetWrap(true)
    button:SetText(text)
    button:SetAutoStretchVertical(true)
    button:SetTextColor(Color(255, 255, 255, 192))
    button:DockMargin(math.max(button:GetWide() * 0.005, 1) , math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1))
    button:SetContentAlignment(4)
    if ispanel(panel) then
        button:SetIsToggle(true)
        button.Paint = function(self, x, y)
            surface.SetDrawColor(col_but)
            if button:IsHovered() or button:GetToggle() then
                surface.SetDrawColor(col_hl)
            end
            surface.DrawRect(0 , 0, x, y)
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

local function GenerateEditableLabel(frame, name)
    local button = frame:Add("DLabelEditable")
    local text = name or "Uh oh! Broken!"
    surface.SetFont("quickloadout_font_large")
    button:SetName(name)
    button:SetMouseInputEnabled(true)
    button:SetKeyboardInputEnabled(true)
    button:SetSize(frame:GetWide(), frame:GetWide() * 0.125)
    button:SetFont("quickloadout_font_large")
    button:SetTextInset(button:GetWide() * 0.05, 0)
    button:SetWrap(true)
    if name then button:SetText(text) end
    button:SizeToContentsY()
    button:SetTextColor(Color(255, 255, 255, 192))
    button:DockMargin(math.max(button:GetWide() * 0.005, 1) , math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1))
    button.DoClickInternal = function(self)
        if self:GetToggle() then return end
        surface.PlaySound("garrysmod/ui_click.wav")
        button:DoDoubleClick()
    end
    button.Paint = function(self, x, y)
        surface.SetDrawColor(col_but)
        if button:IsHovered() or button:GetToggle() then
            surface.SetDrawColor(col_hl)
        end
        surface.DrawRect(0 , 0, x, y)
    end
    button.OnCursorEntered = function(self)
        if self:GetToggle() then return end
        surface.PlaySound("garrysmod/ui_hover.wav")
    end
    return button
end

local function NetworkLoadout()
    if CurTime() < lastgiven + 1 then LocalPlayer():PrintMessage(HUD_PRINTCENTER, "You're sending loadouts too quick! Calm down.") return end
    lastgiven = CurTime()
    net.Start("quickloadout")
    net.WriteTable(ptable)
    net.SendToServer()
end

net.Receive("quickloadout", function() LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Your loadout will change on next spawn.") end)

local wtable = {}
local open = false

local function GenerateWeaponTable()
    for k, v in SortedPairs(list.Get( "Weapon" )) do
        if v.Spawnable then
            local reftable = weapons.Get(k)
            if !wtable[v.Category] then
                wtable[v.Category] = {}
            end
            if reftable and (reftable.SubCategory or reftable.SubCatType) then
                if !wtable[v.Category][reftable.SubCategory or string.sub(reftable.SubCatType, 2)] then
                    wtable[v.Category][reftable.SubCategory or string.sub(reftable.SubCatType, 2)] = {}
                end
                table.Merge(wtable[v.Category][reftable.SubCategory or string.sub(reftable.SubCatType, 2)], {[v.PrintName or v.ClassName] = v.ClassName})
            else
                table.Merge(wtable[v.Category], {[v.PrintName or v.ClassName] = v.ClassName})
            end
        end
    end
end

function QLOpenMenu()
    buttonclicked = nil
    if open then return else open = true end
    local refresh = false
    function RefreshLoadout()
        refresh = true
    end
    local count = 0
    local mainmenu = vgui.Create("EditablePanel")
    mainmenu:SetZPos(-1)
    mainmenu:SetSize(ScrW(), ScrH())
    local width, height = mainmenu:GetSize()
    mainmenu.Paint = function(self, x, y)
        surface.SetDrawColor(col_bg)
        surface.DrawRect(0,0, (x - y) * 0.25, y)
        surface.SetMaterial(Material("vgui/gradient-l"))
        surface.DrawTexturedRect((x - y) * 0.25, 0, math.min(y * 1.5, x), y)
    end
    mainmenu:SetX(-width)
    mainmenu:MoveTo(0, 0, 0.25, 0, 0.8)
    mainmenu:Show()
    mainmenu:MakePopup()

    function DefaultEnabled()
        if override:GetBool() then
            return "Default loadout is on."
        else
            return "Default loadout is off."
        end
    end
    
    function GetMaxSlots()
        return maxslots:GetBool() and " (Max " .. maxslots:GetInt() .. ")" or !game.SinglePlayer() and " (Max 32)" or ""
    end

    function CloseMenu()
        mainmenu:SetKeyboardInputEnabled(false)
        mainmenu:SetMouseInputEnabled(false)
        mainmenu:MoveTo(-width, 0, 0.25, 0, 1.5)
        timer.Simple(0.25, function()
            open = false
            mainmenu:Remove()
        end)
        if !refresh then return end
        weaponlist:SetString(table.concat(ptable, ", "))
        NetworkLoadout()
    end

    function mainmenu:OnKeyCodePressed(key)
        if input.GetKeyCode(keybind:GetString()) != -1 and input.IsKeyDown(input.GetKeyCode(keybind:GetString())) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu") then
            CloseMenu()
        end
    end

    if table.IsEmpty(wtable) then
        print("Generating weapon table...")
        GenerateWeaponTable()
    end
    table.RemoveByValue(ptable, "")
    local lcont, rcont = mainmenu:Add("Panel"), mainmenu:Add("Panel")
    lcont:SetZPos(0)
    lcont.Paint = function(self, x, y)
        surface.SetDrawColor(col_col)
        surface.DrawRect(0,0, x, y)
    end
    lcont:SetSize(height * 0.3, height)
    lcont:SetX((width - height) * 0.25)
    lcont:DockPadding(math.max(lcont:GetWide() * 0.005, 1), lcont:GetTall() * 0.1, math.max(lcont:GetWide() * 0.005, 1), lcont:GetTall() * 0.1)
    rcont:CopyBase(lcont)
    rcont:DockPadding(math.max(lcont:GetWide() * 0.005, 1), lcont:GetTall() * 0.1, math.max(lcont:GetWide() * 0.005, 1), lcont:GetTall() * 0.1)
    rcont.Paint = lcont.Paint
    rcont:SetX(lcont:GetPos() + lcont:GetWide() * 1.1)
    rcont:Hide()
    local lscroller, rscroller = lcont:Add("DScrollPanel"), rcont:Add("DScrollPanel")
    local lbar, rbar = lscroller:GetVBar(), rscroller:GetVBar()
    local qllist, weplist = GenerateCategory(lscroller), GenerateCategory(lscroller)
    qllist:Hide()
    weplist:MakeDroppable("quickloadoutarrange", false)
    local category1, category2, category3 = GenerateCategory(rscroller, "x Cancel"), GenerateCategory(rscroller, "< Categories"), GenerateCategory(rscroller, "< Subcategories")
    local image = mainmenu:Add("DImage")
    image:SetImage("vgui/null", "vgui/null")
    image:SetSize(height * 0.4, height * 0.4)
    image:SetPos((width - height) * 0.25 + height * 0.7, height * 0.1)
    -- image:SetKeepAspect(true)

    local saveload = lcont:Add("Panel")
    saveload:SetSize(lcont:GetWide(), lcont:GetWide() * 0.125)
    saveload:SizeToContentsY()
    saveload:Dock(TOP)
    local sbut, lbut, toptext = GenerateLabel(saveload, "Save", "vgui/null", image), GenerateLabel(saveload, "Load", "vgui/null", image), GenerateLabel(lcont)
    sbut:SetWide(math.ceil(saveload:GetWide() * 0.485))
    sbut:Dock(LEFT)
    sbut.DoClickInternal = function(self)
        qllist:SetVisible(!self:GetToggle())
        lbut:SetToggle(false)
        weplist:SetVisible(self:GetToggle())
        if !self:GetToggle() then CreateLoadoutButtons(true) else CreateWeaponButtons() end
    end
    lbut:SetWide(math.ceil(saveload:GetWide() * 0.485))
    lbut:Dock(RIGHT)
    lbut.DoClickInternal = function(self)
        qllist:SetVisible(!self:GetToggle())
        sbut:SetToggle(false)
        weplist:SetVisible(self:GetToggle())
        if !self:GetToggle() then CreateLoadoutButtons(false) else CreateWeaponButtons() end
    end
    toptext:Dock(TOP)
    toptext.OnCursorEntered = function()
        if buttonclicked then return end
        image:SetImage("vgui/null", "vgui/null")
    end
    lscroller:SetZPos(1)
    lscroller:DockMargin(0, math.max(lscroller:GetParent():GetWide() * 0.005, 1), math.max(lscroller:GetParent():GetWide() * 0.005, 1), math.max(lscroller:GetParent():GetWide() * 0.005, 1))
    lscroller:Dock(FILL)
    rscroller:CopyBase(lscroller)
    rscroller:DockMargin(0, math.max(rscroller:GetParent():GetWide() * 0.005, 1), math.max(lscroller:GetParent():GetWide() * 0.005, 1), math.max(rscroller:GetParent():GetWide() * 0.005, 1))
    lbar:SetHideButtons(true)
    rbar:SetHideButtons(true)
    lbar:SetWide(lcont:GetWide() * 0.05)
    rbar:SetWide(lcont:GetWide() * 0.05)
    lbar.Paint = nil
    rbar.Paint = nil
    lbar.btnGrip.Paint = function(self, x, y)
        draw.RoundedBox(x, x * 0.25, x * 0.5, x * 0.5, y - x, Color(255, 255, 255, 128))
    end
    rbar.btnGrip.Paint = lbar.btnGrip.Paint

    local closer = GenerateLabel(lcont, "Close", nil, image)
    closer:Dock(BOTTOM)
    closer.DoClickInternal = function(self)
        self:SetToggle(true)
        CloseMenu()
    end
    mainmenu.OnCursorEntered = toptext.OnCursorEntered

    local options, optbut = GenerateCategory(lcont), GenerateLabel(lcont, "Options", collapse, image)
    options:SetVisible(false)
    optbut:SetY(lcont:GetWide() * 0.05)
    optbut.DoClickInternal = function(self)
        options:SetVisible(!self:GetToggle())
        saveload:SetVisible(self:GetToggle())
        lscroller:SetVisible(self:GetToggle())
        toptext:SetVisible(self:GetToggle())
    end
    function CreateOptionsMenu()
        options:Clear()
        options:SetSize(lcont:GetWide(), lcont:GetTall() * 0.1)
        options:SetY(lcont:GetWide() * 0.2)
        options:DockPadding(lcont:GetWide() * 0.025, 0, lcont:GetWide() * 0.025, 0)


        local enable
        if enabled:GetBool() then
            enable = options:Add("DCheckBoxLabel")
            enable:SetConVar("quickloadout_enable_client")
            enable:SetText("Enable loadout")
            enable:SetTooltip("Toggles your loadout on or off, without clearing the list.")
            enable:SetTall(options:GetWide() * 0.125)
            enable:SetWrap(true)
            enable.Button.Toggle = function(self)
                self:SetValue( !self:GetChecked() )
                RefreshLoadout()
            end
        else
            enable = GenerateLabel(options, "Loadouts are disabled.")
            enable:SetTextInset(0, 0)
        end
        enable:SetTextColor(Color(255, 255, 255, 192))
        enable:SetFont("quickloadout_font_small")


        local default
        if override:GetInt() == -1 then
            default = options:Add("DCheckBoxLabel")
            default:SetConVar("quickloadout_default_client")
            default:SetText("Give default loadout")
            default:SetTooltip("Toggles default sandbox loadout on or off.")
            default:SetTall(options:GetWide() * 0.125)
            default:SetWrap(true)
            default.Button.Toggle = function(self)
                self:SetValue( !self:GetChecked() )
                RefreshLoadout()
            end
        else
            default = GenerateLabel(options, DefaultEnabled())
            default:SetTextInset(0, 0)
        end
        default:SetTextColor(Color(255, 255, 255, 192))
        default:SetFont("quickloadout_font_small")

        local enablecat = options:Add("DCheckBoxLabel")
        enablecat:SetConVar("quickloadout_showcategory")
        enablecat:SetText("Show categories")
        enablecat:SetTooltip("Toggles whether your equipped weapons should or should not show their weapon category underneath them.")
        enablecat:SetValue(showcat:GetBool())
        enablecat:SetFont("quickloadout_font_small")
        enablecat:SetWrap(true)
        enablecat:SetTextColor(Color(255, 255, 255, 192))
        enablecat.Button.Toggle = function(self)
            self:SetValue( !self:GetChecked() )
            timer.Simple(0, function() CreateWeaponButtons() end)
        end

        local fontpanel = options:Add("Panel")
        fontpanel:SetTooltip("The font Quick Loadout's GUI should use.\nYou can use any installed font on your computer, or found in Garry's Mod's ''resource/fonts'' folder.")
        local fonttext, fontfield, fontslider = GenerateLabel(fontpanel, "Font"), GenerateEditableLabel(fontpanel, fonts:GetString()) -- , options:Add("DNumSlider")
        fonttext:SetFont("quickloadout_font_small")
        fonttext:SizeToContentsX(options:GetWide() * 0.05)
        fonttext:SizeToContentsY(options:GetWide() * 0.025)
        fonttext:SetTextInset(0, 0)
        fonttext:DockMargin(0, 0, options:GetWide() * 0.025, 0)
        fonttext:Dock(LEFT)
        fonttext:SetTextColor(Color(255, 255, 255, 192))
        Derma_Install_Convar_Functions(fontfield)
        fontfield:SetFont("quickloadout_font_small")
        fontfield:SetConVar("quickloadout_ui_fonts")
        fontfield.DoClickInternal = fontfield.DoDoubleClick
        fontfield.OnLabelTextChanged = function(self, text)
            fontfield:ConVarChanged(text)
        end
        fontfield:Dock(FILL)
        -- fontslider.Label:SetFontInternal("quickloadout_font_small")
        -- fontslider.Label:SetText("Font scale")
        -- fontslider.Label:SizeToContentsX(options:GetWide() * 0.05)
        -- fontslider.Label:SizeToContentsY(options:GetWide() * 0.025)
        -- fontslider:SetConVar("quickloadout_ui_font_scale")
        -- fontslider:SetMinMax(fontscale:GetMin(), fontscale:GetMax())
        fontpanel:SetSize(fonttext:GetTextSize())

        local colortext, bgsheet = GenerateLabel(options, "Colors"), options:Add("DPropertySheet")
        colortext:SetFont("quickloadout_font_small")
        colortext:SetTextInset(0, 0)
        colortext:SizeToContents()

        for k, v in ipairs(options:GetChildren()) do
            -- v:SizeToContents()
            v:DockMargin(options:GetWide() * 0.025, options:GetWide() * 0.025, options:GetWide() * 0.025, 0)
        end

        local bgcolor, buttoncolor = bgsheet:Add("DColorMixer"), bgsheet:Add("DColorMixer")
        Derma_Install_Convar_Functions(bgcolor)
        bgsheet:SetTall(math.max(options:GetWide() * 0.8, 240))
        bgsheet:DockMargin(0, options:GetWide() * 0.025, 0, 0)
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
    end

    CreateOptionsMenu()

    function QuickName(dev, name)
        if LocalPlayer():IsSuperAdmin() and GetConVar("developer"):GetBool() then return dev .. " " .. name end
        if list.Get("Weapon")[name] then
            if showcat:GetBool() then return list.Get("Weapon")[name].PrintName .. "\n(" .. list.Get("Weapon")[name].Category .. ")" or name
            else return list.Get("Weapon")[name].PrintName or name end
        else return name end
    end

    function TheCats(cat)
        if cat == category1 then return category2 else return category3 end
    end
    function CreateLoadoutButtons(saving)
        rcont:Hide()
        qllist:Clear()
        LoadSavedLoadouts()
        toptext:SetFont("quickloadout_font_small")

        if saving then
            toptext:SetText("LMB save\nRMB delete")
            for i, v in ipairs(loadouts) do
                local button = GenerateEditableLabel(qllist, v.name)
                LoadoutSelector(button, i)
            end
            local newloadout = GenerateEditableLabel(qllist, "+ Save New")
            LoadoutSelector(newloadout, #loadouts + 1)
        else
            toptext:SetText("LMB load & close\nRMB load & edit")
            for i, v in ipairs(loadouts) do
                local button = GenerateLabel(qllist, v.name, "vgui/null", image)
                LoadoutSelector(button, i)
            end
            if !next(loadouts) then GenerateLabel(qllist, "No loadouts saved.") end
        end
    end

    function CreateWeaponButtons() -- it's a lot better now i think :)
        toptext:SetFont("quickloadout_font_large")
        toptext:SetText("Loadout" .. GetMaxSlots())
        rcont:Hide()
        weplist:Clear()
        count = maxslots:GetBool() and maxslots:GetInt() or game.SinglePlayer() and 0 or 32

        for i, v in ipairs(ptable) do
            local button = GenerateLabel(weplist, QuickName(i, v), v, image)
            WepSelector(button, i, v)
        end
        local newwep = GenerateLabel(weplist, "+ Add Weapon", "vgui/null", image)
        WepSelector(newwep, #ptable + 1, nil)
    end

    function PopulateCategory(parent, tbl, cont, cat, slot) -- good enough automated container refresh
        cat:Clear()
        local cancel = GenerateLabel(cat, cat:GetName(), collapse, image)
        cancel.DoClickInternal = function(self)
            cat:Hide()
            self:SetToggle(true)
            parent:SetToggle(false)
            parent:GetParent():Show()
            image:SetImage(TestImage(ptable[slot], image), "vgui/null")
            if cat == category1 then cont:GetParent():Hide() buttonclicked = nil end
        end
        for i, v in SortedPairs(tbl) do
            if !(table.HasValue(ptable, v) and !ptable[slot]) then
                local button = GenerateLabel(cat, i, v, image)
                button.DoRightClick = cancel.DoClickInternal
                if istable(v) then
                    button.DoClickInternal = function()
                        PopulateCategory(button, v, cont, TheCats(cat), slot)
                        cat:Hide()
                    end
                else
                    if !list.Get("Weapon")[v].Spawnable or list.Get("Weapon")[v].AdminOnly and !LocalPlayer():IsAdmin() then
                        button.Paint = function(self, x, y)
                            surface.SetDrawColor(col_col)
                            if button:IsHovered() then
                                surface.SetDrawColor(col_but)
                            end
                            surface.DrawRect(0 , 0, x, y)
                        end
                    end
                    button.DoClickInternal = function()
                        if table.HasValue(ptable, v) and ptable[slot] then
                            table.Merge(ptable, {[table.KeyFromValue(ptable, v)] = ptable[slot]})
                        end
                        table.Merge(ptable, {[slot] = v})
                        cat:Clear()
                        CreateWeaponButtons()
                        RefreshLoadout()
                    end
                end
            end
        end
        cat:Show()
    end

    function LoadoutSelector(button, key)
        -- print(button, key)
        if button.ClassName == "DLabelEditable" then
            local confirm = false
            button.DoClick = function(self)
                if confirm then
                    table.remove(loadouts, key)
                    file.Write("quickloadout/client_loadouts.json", util.TableToJSON(loadouts))
                    CreateLoadoutButtons(true)
                elseif !loadouts[key] then
                    self._TextEdit:SetText("")
                end
            end
            button.OnLabelTextChanged = function(self, text)
                qllist:Clear()
                table.Merge(loadouts, {[key] = {name = text, weps = ptable}})
                file.Write("quickloadout/client_loadouts.json", util.TableToJSON(loadouts))
                sbut:DoClickInternal()
                sbut:DoClick()
            end
            button.DoRightClick = function(self)
                surface.PlaySound("garrysmod/ui_return.wav")
                if confirm then
                    CreateLoadoutButtons(true)
                else
                    confirm = true
                    button:SetFont("quickloadout_font_small")
                    button:SetText("LMB to confirm\nRMB to cancel")
                    button:SizeToContentsY()
                end
            end
        else
            button.DoClickInternal = function(self)
                LocalPlayer():PrintMessage(HUD_PRINTCENTER, loadouts[key].name .. " equipped!")
                ptable = loadouts[key].weps
                RefreshLoadout()
                CloseMenu()
            end
            button.DoRightClick = function(self)
                ptable = loadouts[key].weps
                RefreshLoadout()
                CreateWeaponButtons()
                lbut:DoClickInternal()
                lbut:Toggle()
            end
        end
    end

    function WepSelector(button, index, class)
        if (maxslots:GetBool() or !game.SinglePlayer()) and index > count or class and (!list.Get("Weapon")[class] or !list.Get("Weapon")[class].Spawnable or (list.Get("Weapon")[class].AdminOnly and !LocalPlayer():IsAdmin())) then
            button.Paint = function(self, x, y)
                surface.SetDrawColor(col_col)
                if button:IsHovered() or button:GetToggle() then
                    surface.SetDrawColor(col_but)
                end
                surface.DrawRect(0 , 0, x, y)
            end
            count = count + 1
        end
        button.DoClickInternal = function()
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
            buttonclicked = index
        end
        button.DoRightClick = function(self)
            self:SetToggle(true)
            self:Toggle()
            if index > #ptable then return end
            table.remove(ptable, index)
            CreateWeaponButtons()
            RefreshLoadout()
        end
    end
    CreateWeaponButtons()
end

hook.Add("HUDShouldDraw", "QLHideWeaponSelector", function(name)
    if open and name == "CHudWeaponSelection" then return false end
end)

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
        if input.GetKeyCode(keybind:GetString()) != -1 and input.IsKeyDown(input.GetKeyCode(keybind:GetString())) and !input.LookupBinding("quickloadout_menu") and IsFirstTimePredicted() then QLOpenMenu() end
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
        panel:NumSlider("Spawn grace time", "quickloadout_switchtime", 0, 60, 0)
        panel:ControlHelp("Time you have to change loadout after spawning. 0 is infinite.\n15 is recommended for PvP events, 0 for pure sandbox.")
        panel:NumSlider("Max weapon slots", "quickloadout_maxslots", 0, 32, 0)
        panel:ControlHelp("Amount of weapons players can have on spawn. Max 32, 0 is infinite.")
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
            timer.Simple(0, function()
                keybind:SetString(input.GetKeyName(key) or "")
                self:SetText(string.upper(input.GetKeyName(key) or "none"))
            end)
        end
    end)
end)