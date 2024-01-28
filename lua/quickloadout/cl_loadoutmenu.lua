AddCSLuaFile()
local weaponlist = GetConVar("quickloadout_weapons")
local dir, gm = "quickloadout/", engine.ActiveGamemode() .. "/"
local ptable = {}
local loadouts = {}

local function fileExists( path, dir )
    local f = file.Open( path, "r", dir )
    if f then
        f:Close()
        return true
    end
    return false
end

if !fileExists("quickloadout", "DATA") then
    file.CreateDir("quickloadout")
end

if !fileExists(dir .. engine.ActiveGamemode(), "DATA") then
    file.CreateDir(dir .. engine.ActiveGamemode())
end

if file.Size(dir .. "client_loadouts.json", "DATA") <= 0 then
    file.Write(dir .. "client_loadouts.json", "[]")
end

if file.Size(dir .. "autosave.json", "DATA") <= 0 then
    file.Write(dir .. "autosave.json", util.TableToJSON(string.Explode(", ", weaponlist:GetString())))
end

if file.Size(dir .. gm .. "client_loadouts.json", "DATA") <= 0 then
    file.Write(dir .. gm .. "client_loadouts.json", fileExists(dir .. "client_loadouts.json", "DATA") and file.Read(dir .. "client_loadouts.json", "DATA") or "[]")
end

if file.Size(dir .. gm .. "autosave.json", "DATA") <= 0 then
    file.Write(dir .. gm .. "autosave.json", fileExists(dir .. "autosave.json", "DATA") and file.Read(dir .. "autosave.json", "DATA") or "[]")
end

if fileExists(dir .. gm .. "autosave.json", "DATA") then
    ptable = util.JSONToTable(file.Read(dir .. gm .. "autosave.json", "DATA"))
end

if fileExists(dir .. gm .. "client_loadouts.json", "DATA") and !istable(util.JSONToTable(file.Read(dir .. gm .. "client_loadouts.json", "DATA"))) then
    print("Corrupted loadout table detected, creating back-up!!\ngarrysmod/data/" .. dir .. gm .. "client_loadouts_%y_%m_%d-%H_%M_%S_backup.json")
    file.Write(os.date(dir .. gm .. "client_loadouts_%y_%m_%d-%H_%M_%S_backup.json"), file.Read(dir .. gm .. "client_loadouts.json", "DATA"))
    file.Write(dir .. gm .. "client_loadouts.json", "[]")
end

local function LoadSavedLoadouts()
    loadouts = util.JSONToTable(file.Read(dir .. gm .. "client_loadouts.json", "DATA"))
end
-- print(file.Read(dir .. "client_loadouts.json", "DATA"))

local keybind = GetConVar("quickloadout_key")
local showcat = GetConVar("quickloadout_showcategory")
local fonts, fontscale = GetConVar("quickloadout_ui_fonts"), GetConVar("quickloadout_ui_font_scale")
local lastgiven = 0

local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_default")
local maxslots = GetConVar("quickloadout_maxslots")
local time = GetConVar("quickloadout_switchtime")
local clips = GetConVar("quickloadout_spawnclips")
local fontsize
local color_default = Color(255, 255, 255, 192)

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
        size = ScrH() * scale * 0.02,
    })
    cam.Start2D()
    fontsize = draw.GetFontHeight("quickloadout_font_small")
    cam.End2D()
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
    if name then category.Name = name end
    category:SetZPos(2)
    category:SetSize(frame:GetParent():GetSize())
    category:Dock(FILL)
    category.Show = function(self)
        self:SetVisible(true)
        if frame:GetName() == "DScrollPanel" then frame:GetVBar():SetScroll(0) timer.Simple(0, function() if !IsValid(frame) then return end frame:Rebuild() end) end
    end
    return category
end

local wtable = {}
local open = false
local rtable = {}
local wepimg = Material("vgui/null")

local function TestImage(item, hud)
    if !item then return "vgui/null" end
    -- if file.Exists("materials/" .. item .. ".vmt", "GAME") then return item
    if hud and fileExists("materials/vgui/hud/" .. item .. ".vmt", "GAME") then return "vgui/hud/" .. item
    elseif fileExists("materials/entities/" .. item .. ".png", "GAME") then return "entities/" .. item .. ".png"
    elseif fileExists("materials/vgui/entities/" .. item .. ".vmt", "GAME") then return "vgui/entities/" .. item
    -- else return "vgui/null"
    end
end

local function GenerateLabel(frame, name, class, panel)
    local button = frame:Add("DLabel")
    function NameSetup()
        return !istable(name) and name or class
    end
    local text = NameSetup() or "Uh oh! Broken!"
    surface.SetFont("quickloadout_font_large")
    button.Name = class
    button:SetMouseInputEnabled(true)
    button:SetMinimumSize(nil, frame:GetWide() * 0.075)
    button:SetSize(frame:GetWide(), frame:GetWide() * 0.125)
    button:SetFont("quickloadout_font_large")
    button:SetTextInset(frame:GetWide() * 0.025, 0)
    button:SetWrap(true)
    button:SetText(text)
    -- button:SetAutoStretchVertical(true)
    button:SetTextColor(color_default)
    button:DockMargin(math.max(button:GetWide() * 0.005, 1) , math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1))
    button:SetContentAlignment(7)
    button:SizeToContentsY(button:GetWide() * 0.015)
    if ispanel(panel) then
        local width, height = ScrW(), ScrH()
        button:SetIsToggle(true)
        button.Paint = function(self, x, y)
            local active = button:IsHovered() or button:GetToggle()
            surface.SetDrawColor(active and col_hl or col_but)
            surface.DrawRect(0 , 0, x, y)
        end
        button.OnCursorEntered = function(self)
            if self:GetToggle() then return end
            surface.PlaySound("garrysmod/ui_hover.wav")
            if class and !istable(class) then
                wepimg = Material(rtable[class] and (rtable[class].HudImage or rtable[class].Image) or "vgui/null", "smooth")
                local ratio = wepimg:Width() / wepimg:Height()
                panel.ImageRatio = ratio - 1
            end
        end
        button.OnToggled = function(self, state)
            surface.PlaySound(state and "garrysmod/ui_click.wav" or "garrysmod/ui_return.wav")
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
    button:SetTextInset(frame:GetWide() * 0.025, 0)
    button:SetWrap(true)
    if name then button:SetText(text) end
    button:SizeToContentsY(button:GetWide() * 0.015)
    button:SetTextColor(color_default)
    button:DockMargin(math.max(button:GetWide() * 0.005, 1) , math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1))
    button:SetContentAlignment(7)
    button.DoClickInternal = function(self)
        if self:GetToggle() then return end
        surface.PlaySound("garrysmod/ui_click.wav")
        button:DoDoubleClick()
    end
    button.Paint = function(self, x, y)
        local active = button:IsHovered() or button:GetToggle()
        surface.SetDrawColor(active and col_hl or col_but)
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
    local weps = util.Compress(util.TableToJSON(ptable))
    net.Start("quickloadout")
    net.WriteData(weps)
    net.SendToServer()
end

net.Receive("quickloadout", function() LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Your loadout will change next deployment.") end)

local function GenerateWeaponTable()
    rtable = list.Get("Weapon")
    local reftable
    for class, wep in pairs(rtable) do
        reftable = {}
        if wep.Spawnable then
            reftable = weapons.Get(class)
            if reftable then wep.Base = reftable.Base end
            if !wtable[wep.Category] then
                wtable[wep.Category] = {}
            end
            local mat = (list.Get("ContentCategoryIcons")[wep.Category])
            wep.Icon = mat
            wep.HudImage = TestImage(class, true)
            wep.Image = TestImage(class) -- or (fileExists( "spawnicons/".. reftable.WorldModel, "MOD") and "spawnicons/".. reftable.WorldModel)
            if !reftable or !(reftable.SubCategory or reftable.SubCatType) then
                wtable[wep.Category][wep.PrintName or wep.ClassName] = wep.ClassName
            else
                local cat = reftable.SubCategory or reftable.SubCatType
                if (cat) then
                    cat = string.gsub(cat, "^%d(%a)", "%1")
                    wep.SubCategory = cat
                    if !wtable[wep.Category][cat] then
                        wtable[wep.Category][cat] = {}
                    end
                    wtable[wep.Category][cat][wep.PrintName or wep.ClassName] = wep.ClassName
                end
                if reftable.SubCatTier then wep.Rating = string.gsub(reftable.SubCatTier, "^%d(%a)", "%1") end
            end
        end
    end
end

local mat = Material("vgui/gradient-l")

function QLOpenMenu()
    local tmp = {}
    table.CopyFromTo(ptable, tmp)
    local buttonclicked = nil
    if open then return else open = true end
    local refresh = false
    function RefreshLoadout(pnl)
        if IsValid(pnl) then for k,v in ipairs(pnl:GetChildren()) do v:SetVisible(true) end end
        refresh = true
    end
    local count = 0
    local mainmenu = vgui.Create("EditablePanel")
    wepimg = Material("vgui/null")
    mainmenu:SetZPos(-1)
    mainmenu:SetSize(ScrW(), ScrH())
    local width, height = mainmenu:GetSize()
    mainmenu.Paint = function(self, x, y)
        surface.SetDrawColor(col_bg)
        surface.DrawRect(0,0, (x - y) * 0.25, y)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect((x - y) * 0.25, 0, math.min(y * 1.5, x), y)
        draw.NoTexture()
    end
    mainmenu:SetX(-width)
    mainmenu:MoveTo(0, 0, 0.25, 0, 0.8)
    mainmenu:Show()
    mainmenu:MakePopup()

    function DefaultEnabled()
        return override:GetBool() and "Default loadout is on." or "Default loadout is off."
    end

    function GetMaxSlots()
        return maxslots:GetBool() and " (Max " .. maxslots:GetInt() .. ")" or !game.SinglePlayer() and " (Max 32)" or ""
    end

    function CloseMenu()
        mainmenu:SetKeyboardInputEnabled(false)
        mainmenu:SetMouseInputEnabled(false)
        mainmenu:MoveTo(-width, 0, 0.25, 0, 1.5)
        mainmenu:SizeTo(0, height, 0.25, 0, 1.5)
        timer.Simple(0.25, function()
            open = false
            mainmenu:Remove()
        end)
        if !refresh then return end
        file.Write(dir .. gm .. "autosave.json", util.TableToJSON(ptable))
        timer.Simple(0.2, function()
            mainmenu.Paint = nil
            NetworkLoadout()
        end)
    end

    function mainmenu:OnKeyCodePressed(key)
        if input.GetKeyCode(keybind:GetString()) != -1 and key == input.GetKeyCode(keybind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu") then
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
    lcont:DockPadding(math.max(lcont:GetWide() * 0.005, 1), lcont:GetWide() * 0.05, math.max(lcont:GetWide() * 0.005, 1), lcont:GetTall() * 0.1)
    rcont:CopyBase(lcont)
    rcont:DockPadding(math.max(lcont:GetWide() * 0.005, 1), lcont:GetTall() * 0.1, math.max(lcont:GetWide() * 0.005, 1), lcont:GetTall() * 0.1)
    rcont.Paint = lcont.Paint
    rcont:SetX(lcont:GetPos() + lcont:GetWide() * 1.1)
    rcont:Hide()
    local lscroller, rscroller = lcont:Add("DScrollPanel"), rcont:Add("DScrollPanel")
    local lbar, rbar = lscroller:GetVBar(), rscroller:GetVBar()
    local qllist, weplist = GenerateCategory(lscroller), GenerateCategory(lscroller)
    qllist:Hide()
    -- weplist:MakeDroppable("quickloadoutarrange", false)
    local category1, category2, category3 = GenerateCategory(rscroller, "x Cancel"), GenerateCategory(rscroller, "< Categories"), GenerateCategory(rscroller, "< Subcategories")
    local image = mainmenu:Add("Panel")
    image.ImageRatio = 0
    image.Paint = function(self, x, y)
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(wepimg)
        surface.DrawTexturedRect(0+(y*math.min(self.ImageRatio, 0)*0.25),0+(y*math.max(self.ImageRatio, 0)*0.25), x-(y*math.min(self.ImageRatio, 0)*0.5), y-(y*math.max(self.ImageRatio, 0)*0.5))
        draw.NoTexture()
    end
    image:SetSize(height * 0.4, height * 0.4)
    image:SetPos((width - height) * 0.25 + height * 0.7, height * 0.1)
    -- image:SetKeepAspect(true)

    local options, optbut = GenerateCategory(lcont), GenerateLabel(lcont, "Options", collapse, image)
    options:Hide()
    optbut:Dock(TOP)
    optbut:DockMargin(math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.155, 1))
    local saveload = lcont:Add("Panel")
    saveload:SetSize(lcont:GetWide(), lcont:GetWide() * 0.125)
    local sbut, lbut, toptext = GenerateLabel(saveload, "Save", "vgui/null", image), GenerateLabel(saveload, "Load", "vgui/null", image), GenerateLabel(lcont)
    sbut:SetWide(math.ceil(saveload:GetWide() * 0.485))
    sbut:Dock(LEFT)
    sbut.DoClickInternal = function(self)
        -- qllist:SetVisible(!self:GetToggle())
        lbut:SetToggle(false)
        -- weplist:SetVisible(self:GetToggle())
        if !self:GetToggle() then CreateLoadoutButtons(true) qllist:Show() weplist:Hide() else CreateWeaponButtons() qllist:Hide() weplist:Show() end
    end
    lbut:SetWide(math.ceil(saveload:GetWide() * 0.485))
    lbut:Dock(RIGHT)
    lbut.DoClickInternal = function(self)
        -- qllist:SetVisible(!self:GetToggle())
        sbut:SetToggle(false)
        -- weplist:SetVisible(self:GetToggle())
        if !self:GetToggle() then CreateLoadoutButtons(false) qllist:Show() weplist:Hide() else CreateWeaponButtons() qllist:Hide() weplist:Show() end
    end
    saveload:SizeToContentsY()
    saveload:Dock(TOP)
    toptext:Dock(TOP)
    toptext.OnCursorEntered = function()
        if buttonclicked then return end
        wepimg = Material("vgui/null")
    end
    optbut.DoClickInternal = function(self)
        options:SetVisible(!self:GetToggle())
        saveload:SetVisible(self:GetToggle())
        lscroller:SetVisible(self:GetToggle())
        toptext:SetVisible(self:GetToggle())
    end
    lscroller:SetZPos(1)
    lscroller:DockMargin(0, math.max(lscroller:GetParent():GetWide() * 0.005, 1), 0, math.max(lscroller:GetParent():GetWide() * 0.005, 1))
    lscroller:Dock(FILL)
    rscroller:CopyBase(lscroller)
    rscroller:DockMargin(0, math.max(rscroller:GetParent():GetWide() * 0.005, 1), 0, math.max(rscroller:GetParent():GetWide() * 0.005, 1))
    lbar:SetHideButtons(true)
    rbar:SetHideButtons(true)
    lbar:SetWide(lcont:GetWide() * 0.05)
    rbar:SetWide(lcont:GetWide() * 0.05)
    lbar.Paint = nil
    rbar.Paint = nil
    lbar.btnGrip.Paint = function(self, x, y)
        draw.RoundedBox(x, x * 0.25, x * 0.25, x * 0.5, y - x * 0.375, Color(255, 255, 255, 128))
    end
    rbar.btnGrip.Paint = lbar.btnGrip.Paint

    local closer = lcont:Add("Panel")
    closer:SetSize(lcont:GetWide(), lcont:GetWide() * 0.125)
    local ccancel, csave = GenerateLabel(closer, "Cancel", nil, image), GenerateLabel(closer, "Equip", nil, image)
    ccancel:SetWide(math.ceil(closer:GetWide() * 0.485))
    ccancel:Dock(FILL)
    ccancel.DoClickInternal = function(self)
        if csave:IsVisible() then LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Loadout changes discarded.") end
        ptable = tmp
        refresh = false
        self:SetToggle(true)
        CloseMenu()
    end
    csave:SetWide(math.ceil(closer:GetWide() * 0.485))
    csave:Dock(RIGHT)
    csave:Hide()
    csave.DoClickInternal = function(self)
        LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Loadout changes saved.")
        self:SetToggle(true)
        CloseMenu()
    end
    closer:SizeToContentsY()
    closer:Dock(BOTTOM)
    -- local closer = GenerateLabel(lcont, "Close", nil, image)
    -- closer:Dock(BOTTOM)
    -- closer.DoClickInternal = function(self)
    --     self:SetToggle(true)
    --     CloseMenu()
    -- end
    mainmenu.OnCursorEntered = toptext.OnCursorEntered

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
        enable:SetTextColor(color_default)
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
        default:SetTextColor(color_default)
        default:SetFont("quickloadout_font_small")

        local enablecat = options:Add("DCheckBoxLabel")
        enablecat:SetConVar("quickloadout_showcategory")
        enablecat:SetText("Weapon categories")
        enablecat:SetTooltip("Toggles whether your equipped weapons should or should not show their weapon category underneath them.")
        enablecat:SetValue(showcat:GetBool())
        enablecat:SetFont("quickloadout_font_small")
        enablecat:SetWrap(true)
        enablecat:SetTextColor(color_default)
        enablecat.Button.Toggle = function(self)
            self:SetValue( !self:GetChecked() )
            sbut:SetToggle(false)
            lbut:SetToggle(false)
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
        fonttext:SetTextColor(color_default)
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
        colortext:SizeToContents()
    end

    CreateOptionsMenu()

    function QuickName(name)
        local ref = rtable[name]
        return ref and language.GetPhrase(ref.PrintName) or name
    end

    function ShortenCategory(wep)
        local ref, match, show = rtable[wep], "^[%w%d%p]+", showcat:GetBool()
        local bc = ref and tostring(ref.Category:match(match)):Trim()
        local short = bc and (ref.Category:len() > 7 and (ref.Base and ref.Base:find(bc:lower()) != nil and ref.Category:gsub(bc, "") or ref.Category:match("^[%u%d%p]+%s")) or ref.Category):gsub("%b()", ""):Trim()
        return ref and (show and "[" .. (short:gsub("[^%w.:+]", ""):len() > 7 and short:gsub("([^%c%s%p])[%l]+", "%1") or short):gsub("[^%w.:+]", "") .. "]" or "")
    end

    function TheCats(cat)
        if cat == category1 then return category2 else return category3 end
    end

    function CreateLoadoutButtons(saving)
        rcont:Show()
        category1:Hide()
        category2:Hide()
        category3:Hide()
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
            local button = GenerateLabel(weplist, QuickName(v), v, image)
            WepSelector(button, i, v)
        end
        local newwep = GenerateLabel(weplist, "+ Add Weapon", "vgui/null", image)
        WepSelector(newwep, #ptable + 1, nil)
        -- if sbut:GetToggle() then sbut:Toggle()
        -- elseif lbut:GetToggle() then lbut:Toggle() end
        qllist:Hide()
        weplist:Show()
    end

    function CreatePreviewButtons(key)
        category1:Clear()
        count = maxslots:GetBool() and maxslots:GetInt() or game.SinglePlayer() and 0 or 32

        if loadouts[key] then
            for i, v in ipairs(loadouts[key].weps) do
                local button = GenerateLabel(category1, QuickName(v), v, image)
                WepSelector(button, i, v)
                button:SetIsToggle(false)
                button.DoClickInternal = nil
                button.DoRightClick = button.DoClickInternal
            end
        else
            for i, v in ipairs(ptable) do
                local button = GenerateLabel(category1, QuickName(v), v, image)
                WepSelector(button, i, v)
                button:SetIsToggle(false)
                button.DoClickInternal = nil
                button.DoRightClick = button.DoClickInternal
            end
        end
        -- category1:InvalidateLayout(true)
        -- print(category1:GetWide(), category1:GetTall())
        category1:Show()
    end

    function PopulateCategory(parent, tbl, cont, cat, slot) -- good enough automated container refresh
        cat:Clear()
        local cancel = GenerateLabel(cat, cat.Name, collapse, image)
        cancel.DoClickInternal = function(self)
            cat:Hide()
            self:SetToggle(true)
            parent:SetToggle(false)
            parent:GetParent():Show()
            wepimg = Material(ptable[slot] and (rtable[ptable[slot]].HudImage or rtable[ptable[slot]].Image) or "vgui/null", "smooth")
            local ratio = wepimg:Width() / wepimg:Height()
            image.ImageRatio = ratio - 1
            if cat == category1 then buttonclicked = nil rcont:Hide() end
        end
        for key, v in SortedPairs(tbl) do
            if !(table.HasValue(ptable, v) and !ptable[slot]) then
                local button = GenerateLabel(cat, key, v, image)
                button.DoRightClick = cancel.DoClickInternal
                local offset = button:GetWide() * 0.1
                if istable(v) then
                    button:SizeToContentsY(fontsize)
                    local wepcount, catcount = 0, 0
                    local numbers = ""
                    for sub, tab in pairs(v) do
                        if istable(tab) then
                            PrintTable(v)
                            catcount = catcount + 1
                            wepcount = wepcount + table.Count(tab)
                        else print(sub)
                            wepcount = wepcount + 1
                        end
                    end
                    numbers = (catcount > 0 and catcount .. " categor" .. (catcount > 1 and "ies" or "y") .. ", " or "") .. wepcount .. " weapon" .. (wepcount != 1 and "s" or "")
                    -- PrintTable(tbl)
                    button.PaintOld = button.Paint
                    button.Paint = function(self, x, y)
                        self:PaintOld(x, y)
                        draw.SimpleText(numbers, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, color_default, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                    end
                    button.DoClickInternal = function()
                        PopulateCategory(button, v, cont, TheCats(cat), slot)
                        cat:Hide()
                    end
                continue end
                if !rtable[v].Spawnable or rtable[v].AdminOnly and !LocalPlayer():IsAdmin() then
                    button.Paint = function(self, x, y)
                        local active = button:IsHovered()
                        surface.SetDrawColor(active and col_but or col_col)
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
                    RefreshLoadout(closer)
                end
            end
        end
        cat:Show()
    end

    function LoadoutSelector(button, key)
        -- print(button, key)
        local wepcount = (loadouts[key] and #loadouts[key].weps or #ptable) .. " weapons"
        local offset = button:GetWide() * 0.1
        button:SizeToContentsY(fontsize)
        button.PaintOld = button.Paint
        button.Paint = function(self, x, y)
            self:PaintOld(x, y)
            draw.SimpleText(wepcount, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, colo, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end
        if button.ClassName == "DLabelEditable" then
            local confirm = false
            button.DoClick = function(self)
                if confirm then
                    table.remove(loadouts, key)
                    file.Write(dir .. gm .. "client_loadouts.json", util.TableToJSON(loadouts))
                    CreateLoadoutButtons(true)
                elseif !loadouts[key] then
                    self._TextEdit:SetText("")
                end
            end
            button.OnLabelTextChanged = function(self, text)
                qllist:Clear()
                table.Merge(loadouts, {[key] = {name = text, weps = ptable}})
                file.Write(dir .. gm .. "client_loadouts.json", util.TableToJSON(loadouts))
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
                LocalPlayer():PrintMessage(HUD_PRINTCENTER, loadouts[key].name .. " equipped!")
                ptable = loadouts[key].weps
                RefreshLoadout(closer)
                CreateWeaponButtons()
                lbut:DoClickInternal()
                lbut:Toggle()
            end
        end
        button.OnCursorEntered = function(self)
            CreatePreviewButtons(key)
            if self:GetToggle() then return end
            surface.PlaySound("garrysmod/ui_hover.wav")
        end
    end

    function WepSelector(button, index, class)
        -- print(button:GetTextSize())
        local ref, active = rtable[class], button:IsHovered() or button:GetToggle()
        local unusable = (maxslots:GetBool() or !game.SinglePlayer()) and index > count or class and (!ref or !ref.Spawnable or (ref.AdminOnly and !LocalPlayer():IsAdmin()))
        -- button:SetWrap(false)
        -- button.Paint = function(self, x, y)
        --     surface.SetDrawColor(active and col_but or col_col)
        --     surface.DrawRect(0 , 0, x, y)
        -- end
        if unusable then count = count + 1 end
    
        local catimage = Material(ref and ref.Icon or "vgui/null", "smooth")
        local wepimage = Material(ref and ref.Image or "vgui/null", "smooth")
        local cattext, weptext
        local w, h, offset = wepimage:Width(), wepimage:Height(), button:GetWide() * 0.1
        local ratio = w / h
        local scale = math.max(ScreenScale(8), 16)
        if ref then
            cattext, weptext = ShortenCategory(class), ref.SubCategory and (ref.Rating and ref.Rating .. " " or "") .. ref.SubCategory
            button:SizeToContentsY(fontsize)
        else
            if unusable then button:SetFont("quickloadout_font_small") end
            button:SetWrap(false)
            button:SizeToContentsY(button:GetWide() * 0.015)
        end
        button.Paint = function(self, x, y)
            local active = button:IsHovered() or button:GetToggle()
            surface.SetDrawColor(unusable and (active and col_but or col_col) or (active and col_hl or col_but))
            surface.DrawRect(0 , 0, x, y)
            if !ref then return end
            surface.SetDrawColor(255, 255, 255, 192)
            if ref.Image then
                surface.SetMaterial(wepimage)
                surface.DrawTexturedRect(x * 0.4, y * 0.5 - offset * 3.5 / ratio, offset * 8, offset * 8 / ratio)
            end
            if ref.Icon then
                surface.SetMaterial(catimage)
                surface.DrawTexturedRect(x - offset * 0.15 - scale, y - offset * 0.15 - scale, scale, scale)
            end
            draw.SimpleText(cattext, "quickloadout_font_small", x - offset * 0.125 - (ref.Icon and scale + offset * 0.25 or 0), y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            if !ref.SubCategory then return end
            draw.SimpleText(weptext, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end
        button.DoClickInternal = function()
            rcont:Show()
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
            RefreshLoadout(closer)
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
        if input.GetKeyCode(keybind:GetString()) != -1 and input.IsKeyDown(input.GetKeyCode(keybind:GetString())) and !input.LookupBinding("quickloadout_menu") then QLOpenMenu() end
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
        panel:NumSlider("Clips per weapon", "quickloadout_spawnclips", 0, 100, 0)
        panel:ControlHelp("How many clips worth of ammo each weapon is given.")
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
                local t = input.GetKeyName(key)
                keybind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
            end)
        end
    end)
end)