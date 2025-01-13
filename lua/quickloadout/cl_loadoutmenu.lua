AddCSLuaFile()
local dir, gm = "quickloadout/", engine.ActiveGamemode() .. "/"
local ptable = {}
local loadouts = {}

if !file.Exists("quickloadout", "DATA") then
    file.CreateDir("quickloadout")
end

if !file.Exists(dir .. engine.ActiveGamemode(), "DATA") then
    file.CreateDir(dir .. engine.ActiveGamemode())
end

if file.Size(dir .. gm .. "client_loadouts.json", "DATA") <= 0 then
    file.Write(dir .. gm .. "client_loadouts.json", file.Exists(dir .. "client_loadouts.json", "DATA") and file.Read(dir .. "client_loadouts.json", "DATA") or "[]")
end

if file.Size(dir .. gm .. "autosave.json", "DATA") <= 0 then
    file.Write(dir .. gm .. "autosave.json", file.Exists(dir .. "autosave.json", "DATA") and file.Read(dir .. "autosave.json", "DATA") or "[]")
end

if file.Exists(dir .. gm .. "autosave.json", "DATA") then
    ptable = util.JSONToTable(file.Read(dir .. gm .. "autosave.json", "DATA"))
end

if file.Exists(dir .. gm .. "client_loadouts.json", "DATA") and !istable(util.JSONToTable(file.Read(dir .. gm .. "client_loadouts.json", "DATA"))) then
    print("Corrupted loadout table detected, creating back-up!!\ngarrysmod/data/" .. dir .. gm .. "client_loadouts_%y_%m_%d-%H_%M_%S_backup.json")
    file.Write(os.date(dir .. gm .. "client_loadouts_%y_%m_%d-%H_%M_%S_backup.json"), file.Read(dir .. gm .. "client_loadouts.json", "DATA"))
    file.Write(dir .. gm .. "client_loadouts.json", "[]")
end

local function LoadSavedLoadouts()
    loadouts = util.JSONToTable(file.Read(dir .. gm .. "client_loadouts.json", "DATA"))
end
-- print(file.Read(dir .. "client_loadouts.json", "DATA"))

local keybind = GetConVar("quickloadout_key")
local keybindload = GetConVar("quickloadout_key_load")
local cancelbind = GetConVar("quickloadout_menu_cancel")
local loadbind = GetConVar("quickloadout_menu_load")
local savebind = GetConVar("quickloadout_menu_save")
local modelbind = GetConVar("quickloadout_menu_model")
local showcat = GetConVar("quickloadout_showcategory")
local showslot = GetConVar("quickloadout_showslot")
local blur = GetConVar("quickloadout_ui_blur")
local fonts, fontscale = GetConVar("quickloadout_ui_fonts"), GetConVar("quickloadout_ui_font_scale")
local lastgiven = 0
local reminder = GetConVar("quickloadout_remind_client")

local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_default")
local maxslots = GetConVar("quickloadout_maxslots")
local slotlimit = GetConVar("quickloadout_slotlimit")
local time = GetConVar("quickloadout_gracetime")
local clips = GetConVar("quickloadout_spawnclips")
local fontsize
local color_default = Color(255, 255, 255, 192)

local function CreateFonts()
    local fonttable = string.Split(fonts:GetString():len() > 0 and fonts:GetString() or fonts:GetDefault(), ",")
    local scale = 1 --fontscale:GetFloat() didn't bother with setting up a refresher + current setup is not good for it
    surface.CreateFont("quickloadout_font_large", {
        font = string.Trim(fonttable[1]),
        extended = true,
        size = ScreenScaleH(20) * scale,
        outline = true,
    })
    surface.CreateFont("quickloadout_font_medium", {
        font = string.Trim(fonttable[1]),
        extended = true,
        size = ScreenScaleH(15) * scale,
        outline = true,
    })
    surface.CreateFont("quickloadout_font_small", {
        font = string.Trim(fonttable[2] or fonttable[1]),
        extended = true,
        size = ScreenScaleH(10) * scale,
        outline = true,
    })
    cam.Start2D()
    fontsize = draw.GetFontHeight("quickloadout_font_small")
    cam.End2D()
end

local function RefreshColors()
    local cvar_bg, cvar_but = string.ToColor(GetConVar("quickloadout_ui_color_bg"):GetString() .. " 255"), string.ToColor(GetConVar("quickloadout_ui_color_button"):GetString() .. " 255")
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
    local a, b, c, d = ColorAlpha(cvar_bg, 224) or Color(0,128,0,224), IsColor(LessenBG(cvar_bg)) and ColorAlpha(LessenBG(cvar_bg), 128) or Color(0,16,0,128), ColorAlpha(LessenButton(cvar_but), 128) or Color(0,96,0,128), ColorAlpha(cvar_but, 128) or Color(0,128,0,128)
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
        self:InvalidateChildren(true)
        frame:InvalidateLayout()
        if frame:GetName() == "DScrollPanel" then
            frame:GetVBar():SetScroll(0)
        end
        self:SetVisible(true)
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
    if hud and file.Exists("materials/vgui/hud/" .. item .. ".vmt", "GAME") then return "vgui/hud/" .. item
    elseif file.Exists("materials/entities/" .. item .. ".png", "GAME") then return "entities/" .. item .. ".png"
    elseif file.Exists("materials/vgui/entities/" .. item .. ".vmt", "GAME") then return "vgui/entities/" .. item
    -- else return "vgui/null"
    end
end

local wrong = "Uh oh! Broken!"

local function GenerateLabel(frame, name, class, panel)
    local button = frame:Add("DLabel")
    function NameSetup()
        return !istable(name) and name or class
    end
    local text = NameSetup() or wrong
    surface.SetFont("quickloadout_font_large")
    button.Name = class
    button:SetMouseInputEnabled(true)
    button:SetMinimumSize(nil, frame:GetWide() * 0.075)
    button:SetSize(frame:GetWide(), frame:GetWide() * 0.125)
    button:SetFontInternal("quickloadout_font_large")
    button:SetTextInset(frame:GetWide() * 0.025, 0)
    button:SetWrap(true)
    button:SetTextColor(color_default)
    button:DockMargin(math.max(button:GetWide() * 0.005, 1) , math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1), math.max(button:GetWide() * 0.005, 1))
    button:SetContentAlignment(7)
    button:SetText(text)
    button:SizeToContentsY(button:GetWide() * 0.015)
    if ispanel(panel) then
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
    button:SetFontInternal("quickloadout_font_large")
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

local function QLEditTime(t)
    return CurTime() < t and "\n".. math.Truncate(t - CurTime(),1)
end

local notipan = nil
local function QLNotify(noti)
    local spawn = !isstring(noti) and noti
    if spawn and !reminder:GetBool() then return end
    if IsValid(notipan) then notipan:Remove() end
    local text = "Your loadout will change next deployment."
    if spawn then text = "[ " .. string.NiceName(keybind:GetString()) .. " ] Change loadout"
    elseif isstring(noti) then text = noti
    end
    notipan = vgui.Create("DPanel", GetHUDPanel())
    notipan.Paint = nil
    local box = vgui.Create("DLabel", notipan)
    box:SetFont("quickloadout_font_medium")
    box:SetText(text)
    local spawntime = spawn and (LocalPlayer():Health() > 0 and (time:GetBool() and time:GetInt() or 2) or 10) or 3
    notipan:SetContentAlignment(8)
    box:SetContentAlignment(8)
    -- box:SetSize(box:GetTextSize())
    box:SizeToContents()
    box:Dock(FILL)
    notipan:SetSize(box:GetTextSize())
    notipan:SetTall(notipan:GetTall()*2)
    if spawn and time:GetBool() then
        local cutoff = vgui.Create("DLabel", notipan)
        cutoff:SetFont("quickloadout_font_medium")
        cutoff:SetText(spawntime)
        cutoff:SizeToContents()
        cutoff:SetContentAlignment(8)
        cutoff:SetSize(cutoff:GetTextSize())
        cutoff:Dock(FILL)
        local spawncutoff = CurTime() + spawntime
        cutoff.Think = function()
            if spawncutoff > CurTime() then
            cutoff:SetText(QLEditTime(spawncutoff) or "")
            end
        end
    end
    -- container:SizeToContentsY(draw.GetFontHeight("quickloadout_font_medium")*2)
    local wpos = (ScrW() - box:GetWide()) * 0.5
    notipan:SetPos(wpos, ScrH())
    notipan:MoveTo(wpos, ScrH() * 0.8, 0.2, 0, -1, function() notipan:MoveTo(wpos, ScrH(), .2, spawntime - 0.2, -1, function() notipan:Remove() end) end)
end

local function NetworkLoadout()
    if CurTime() < lastgiven + 1 then QLNotify("You're sending loadouts too quick! Calm down.") return end
    lastgiven = CurTime()
    local weps = util.Compress(util.TableToJSON(ptable))
    net.Start("quickloadout")
    net.WriteData(weps)
    net.SendToServer()
end

net.Receive("quickloadout", function()
    local spawn = net.ReadBool()
    if IsValid(notipan) then notipan:Remove() end
    QLNotify(spawn)
    -- if spawn then if !reminder:GetBool() then return end LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Press " .. string.NiceName(keybind:GetString()) .. " to modify your loadout.") return end LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Your loadout will change next deployment.")
end)

local function GenerateWeaponTable()
    rtable = list.Get("Weapon")
    local reftable
    for class, wep in pairs(rtable) do
        reftable = {}
        if wep.Spawnable then
            reftable = weapons.Get(class)
            if reftable then
                wep.Base = reftable.Base
                if reftable.Slot then wep.Slot = (tonumber(reftable.Slot) or 0)+1 end
                -- wep.Stats = {
                --     ["Damage"] = reftable.DamageMax or reftable.Damage_Max or reftable.Damage or reftable.Bullet and reftable.Bullet.Damage[1] or reftable.Primary.Damage,
                -- }
            end
            if !wtable[wep.Category] then
                wtable[wep.Category] = {}
            end
            local mat = (list.Get("ContentCategoryIcons")[wep.Category])
            local image = reftable and (reftable.LoadoutImage or reftable.HudImage)
            wep.Icon = mat
            wep.HudImage = image and (file.Exists("materials/" .. image, "GAME") and image) or TestImage(class, true)
            wep.Image = image and wep.HudImage or TestImage(class) -- or (file.Exists( "spawnicons/".. reftable.WorldModel, "MOD") and "spawnicons/".. reftable.WorldModel)
            wep.PrintName = reftable and (reftable.AbbrevName or reftable.PrintName) or wep.PrintName or wep.ClassName
            if !reftable or !(reftable.SubCategory or reftable.SubCatType) then
                wtable[wep.Category][wep.ClassName] = wep.PrintName
            else
                local cat = reftable.SubCategory or reftable.SubCatType
                if (cat) then
                    cat = string.gsub(string.gsub(string.gsub(string.gsub(cat, "ies$", "y"), "s$", ""), "^%d(%a)", "%1"), "^⠀", "​")
                    wep.SubCategory = cat
                    if !wtable[wep.Category][cat] then
                        wtable[wep.Category][cat] = {}
                    end
                    wtable[wep.Category][cat][wep.ClassName] = wep.PrintName
                end
                if reftable.SubCatTier and reftable.SubCatTier != "9Special" then wep.Rating = string.gsub(reftable.SubCatTier, "^%d(%a)", "%1") end
            end
        end
    end
end

local mat, bmat = Material("vgui/gradient-l"), Material("pp/blurscreen")

local refresh = false
function QLOpenMenu()
    local tmp = {}
    table.CopyFromTo(ptable, tmp)
    local buttonclicked = nil
    local tt = SysTime()
    local bindings = {keybind = keybind:GetString(), cancelbind = cancelbind:GetString(), loadbind = loadbind:GetString(), savebind = savebind:GetString(), modelbind = modelbind:GetString()}
    if open then return else open = true end
    refresh = false
    function RefreshLoadout(pnl)
        if IsValid(pnl) then for k,v in ipairs(pnl:GetChildren()) do v:SetVisible(true) end end
        refresh = true
    end
    local count = 0
    local count2 = {}
    local bg = vgui.Create("Panel")
    bg:SetParent(GetHUDPanel())
    bg:SetSize(ScrW(), ScrH())
    bg:SetZPos(-2)
    -- bg:NoClipping(true)
    bg.Paint = function(self, w, h)
        if !blur:GetBool() then return end
        local fract = math.Clamp( ( tt < SysTime() and SysTime() - tt or tt - SysTime() ) / 1, 0, 0.25 )
        -- local x, y = self:LocalToScreen( 0, 0 )
		for i = 0.33, 2, 0.33 do
			bmat:SetFloat( "$blur", fract * 5 * i )
			bmat:Recompute()
			if ( render ) then render.UpdateScreenEffectTexture() end
			-- surface.DrawTexturedRect( x * -1, y * -1, w, h )
		end
        surface.SetMaterial(bmat)
        surface.SetDrawColor(color_white)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    bg:Show()
    local mainmenu = vgui.Create("EditablePanel", bg)
    local scale = ScreenScale(1)
    wepimg = Material("vgui/null")
    mainmenu:SetZPos(-1)
    mainmenu:SetSize(bg:GetSize())
    local width, height = bg:GetSize()
    local bgcolor = ColorAlpha(col_bg, 64)
    mainmenu.Paint = function(self, x, y)
        surface.SetDrawColor(col_bg)
        surface.DrawRect(0,0, (x - y) * 0.25, y)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect((x - y) * 0.25, 0, math.min(y * 1.5, x), y)
    end
    mainmenu:SetX(-width)
    mainmenu:MoveTo(0, 0, 0.25, 0, 0.8)
    mainmenu:Show()
    mainmenu:MakePopup()

    function DefaultEnabled()
        return override:GetBool() and "Default loadout is on." or "Default loadout is off."
    end

    function GetMaxSlots()
        return (maxslots:GetBool() or slotlimit:GetBool()) and " (" .. ((maxslots:GetBool() and maxslots:GetInt() or !game.SinglePlayer() and "32") .. (slotlimit:GetBool() and " weapons, " or " weapon limit") or "") .. (slotlimit:GetBool() and slotlimit:GetInt() .. " per slot" or "") .. ")" or ""
    end

    function CloseMenu()
        tt = SysTime() + 0.25
        mainmenu:SetKeyboardInputEnabled(false)
        mainmenu:SetMouseInputEnabled(false)
        mainmenu:MoveTo(-width, 0, 0.25, 0, -0.8)
        -- mainmenu:SizeTo(0, height, 0.25, 0, 1.5)
        timer.Simple(0.25, function()
            open = false
            bg:Remove()
        end)
        if !refresh then return end
        file.Write(dir .. gm .. "autosave.json", util.TableToJSON(ptable))
        timer.Simple(0.2, function()
            mainmenu.Paint = nil
            NetworkLoadout()
        end)
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

    local options, optbut = GenerateCategory(lcont), GenerateLabel(lcont, "User Options", collapse, image)
    options:Hide()
    optbut:Dock(TOP)
    -- optbut:DockMargin(math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.155, 1))
    local closer = lcont:Add("Panel")
    closer.Text = "[ "..string.upper(bindings.keybind or "").." ]"
    closer:SetSize(lcont:GetWide(), lcont:GetWide() * 0.155)
    local ccancel, csave = GenerateLabel(closer, "Cancel", nil, image), GenerateLabel(closer, "Apply", nil, image)
    ccancel.Text = "[ "..string.upper(bindings.cancelbind or "").." ]"
    ccancel:SetWide(math.ceil(closer:GetWide() * 0.485))
    ccancel:Dock(FILL)
    ccancel.DoClickInternal = function(self)
        if csave:IsVisible() then QLNotify("Loadout changes discarded.") end
        ptable = tmp
        refresh = false
        self:SetToggle(true)
        CloseMenu()
    end
    ccancel.PaintOver = function(self, x, y)
        -- if refresh then return end
        draw.SimpleText((!refresh and ccancel.Text .. "/" .. closer.Text) or ccancel.Text, "quickloadout_font_small", x, y, color_default, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    csave:SetWide(math.ceil(closer:GetWide() * 0.485))
    csave:Dock(RIGHT)
    csave:Hide()
    csave.DoClickInternal = function(self)
        QLNotify("Loadout changes applied.")
        self:SetToggle(true)
        CloseMenu()
    end
    csave.PaintOver = function(self, x, y)
        draw.SimpleText(closer.Text, "quickloadout_font_small", x, y, color_default, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    closer:SizeToContentsY()
    local enable
    if enabled:GetBool() then
        enable = lcont:Add("DCheckBoxLabel")
        enable:SetConVar("quickloadout_enable_client")
        enable:SetText("Enable loadout")
        enable:SetTooltip("Toggles your loadout on or off, without clearing the list.")
        enable.Button.Toggle = function(self)
            self:SetValue( !self:GetChecked() )
            RefreshLoadout(closer)
        end
        enable:SetWrap(true)
    else
        enable = GenerateLabel(lcont, "Server has disabled custom loadouts.")
        enable:SetTextInset(0, 0)
    end
    enable:SetTall(lcont:GetWide() * 0.075)
    enable:SetTextColor(color_default)
    enable:SetFont("quickloadout_font_small")
    enable:DockMargin(lcont:GetWide() * 0.0475, lcont:GetWide() * 0.025, lcont:GetWide() * 0.0125, lcont:GetWide() * 0.015)
    enable:Dock(TOP)
    local trash = LocalPlayer():GetWeapons()
    local importer = GenerateLabel(lcont, "Import current weapons", nil, image)
    importer:SetFont("quickloadout_font_medium")
    importer:SetSize(lcont:GetWide(), lcont:GetWide() * 0.125)
    importer.DoClickInternal = function(self)
        local holster = GetConVar("holsterweapon_weapon") and GetConVar("holsterweapon_weapon"):GetString()
        local g = 0
        table.Empty(ptable)
        for k, v in ipairs(trash) do
            if holster and v:GetClass() == (rtable[holster] and holster or "weaponholster") then g = 1 continue end
            ptable[k-g] = v:GetClass()
        end
        CreateWeaponButtons()
        RefreshLoadout(closer)
    end
    importer.OnReleased = function(self)
        QLNotify("Imported currently equipped weapons to loadout.")
        self:SetToggle(true)
    end
    importer:Dock(TOP)
    local saveload = lcont:Add("Panel")
    saveload:SetSize(lcont:GetWide(), lcont:GetWide() * 0.155)
    local sbut, lbut, toptext = GenerateLabel(saveload, "Save", "vgui/null", image), GenerateLabel(saveload, "Load", "vgui/null", image), GenerateLabel(lcont)
    local modelpanel = vgui.Create("SpawnIcon", toptext)
    sbut.Text = "[ "..string.upper(bindings.savebind or "").." ]"
    lbut.Text = "[ "..string.upper(bindings.loadbind or "").." ]"
    modelpanel.Text = "[ "..string.upper(bindings.modelbind or "").." ]"
    sbut:SetWide(math.ceil(saveload:GetWide() * 0.485))
    sbut:Dock(LEFT)
    sbut.DoClickInternal = function(self)
        if IsValid(modelpanel.Window) then modelpanel.Window:Remove() end
        -- qllist:SetVisible(!self:GetToggle())
        lbut:SetToggle(false)
        -- weplist:SetVisible(self:GetToggle())
        if !self:GetToggle() then CreateLoadoutButtons(true) qllist:Show() weplist:Hide() else CreateWeaponButtons() qllist:Hide() weplist:Show() end
    end
    lbut:SetWide(math.ceil(saveload:GetWide() * 0.485))
    lbut:Dock(RIGHT)
    lbut.DoClickInternal = function(self)
        if IsValid(modelpanel.Window) then modelpanel.Window:Remove() end
        -- qllist:SetVisible(!self:GetToggle())
        sbut:SetToggle(false)
        -- weplist:SetVisible(self:GetToggle())
        if !self:GetToggle() then CreateLoadoutButtons(false) qllist:Show() weplist:Hide() else CreateWeaponButtons() qllist:Hide() weplist:Show() end
    end
    sbut.PaintOver = function(self, x, y)
        draw.SimpleText(self.Text, "quickloadout_font_small", x, y, color_default, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    lbut.PaintOver = function(self, x, y)
        draw.SimpleText(self.Text, "quickloadout_font_small", x, y, color_default, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    modelpanel.PaintOver = function(self, x, y)
        draw.SimpleText(self.Text, "quickloadout_font_small", x, y, color_default, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    saveload:SizeToContentsY()
    saveload:Dock(TOP)
    toptext:SetFont("quickloadout_font_medium")
    toptext:SizeToContentsY(draw.GetFontHeight("quickloadout_font_medium"))
    toptext:SetFont("quickloadout_font_large")
    local mdl, mskin, mbg = GetConVar("cl_playermodel"), GetConVar("cl_playerskin"), GetConVar("cl_playerbodygroups")
    -- for k, v in pairs(list.Get("DesktopWindows").PlayerEditor) do
    --     modelpanel.k = v
    -- end
    modelpanel.DoClickInternal = function()
        optbut:OnToggled(image:IsVisible())
        if IsValid(modelpanel.Window) then modelpanel.Window:Remove() return end
        local window = vgui.Create("DFrame", mainmenu)
        image:Hide()
        window.DoRemoval = window.Remove
        window.Remove = function() image:Show() window:DoRemoval() end
        window.Paint = rcont.Paint
        if rcont:IsVisible() then CreateWeaponButtons() end
        modelpanel.Window = window
        list.Get("DesktopWindows").PlayerEditor:init(window)
        if IsValid(window) then
            window:SetSize(mainmenu:GetWide() * 0.5, mainmenu:GetTall() * 0.8)
            window:SetPos(rcont:GetX(), mainmenu:GetTall() * 0.1)
        end
    end
    modelpanel.OnCursorEntered = optbut.OnCursorEntered
    modelpanel.Fade = modelpanel.Think
    modelpanel.Think = function(self)
        self:Fade()
        if player_manager.TranslatePlayerModel(mdl:GetString()) != self:GetModelName() then
            self:SetModel(player_manager.TranslatePlayerModel(mdl:GetString()))
            self:SetTooltip("Current model: "..mdl:GetString())
        end
    end
    modelpanel:SetModel(player_manager.TranslatePlayerModel(mdl:GetString()), mskin:GetInt(), mbg:GetString())
    modelpanel:SetSize(toptext:GetTall()*0.5, toptext:GetTall())
    modelpanel:SetTooltip("Current model: "..mdl:GetString())
    -- if ConVarExists("playermodel_selector") then modelpanel:SetConsoleCommand("playermodel_selector") end
    modelpanel.OnDepressed = function(self)
        mainmenu:MoveToBack()
    end
    -- modelpanel.PaintOver = function(x,y)

    -- end
    modelpanel:Dock(RIGHT)
    toptext.Name = GetMaxSlots()
    local panos = modelpanel:GetWide()
    toptext.PaintOver = function(self, x, y)
        if self:GetToggle() then return end
        draw.SimpleText(self.Name, "quickloadout_font_small", x - panos - math.max(lcont:GetWide() * 0.01, 1), y, color_default, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    toptext:Dock(TOP)
    toptext.OnCursorEntered = function()
        if buttonclicked then return end
        wepimg = Material("vgui/null")
    end
    optbut.DoClickInternal = function(self)
        options:SetVisible(!self:GetToggle())
        importer:SetVisible(self:GetToggle())
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

    closer:Dock(BOTTOM)
    -- local closer = GenerateLabel(lcont, "Close", nil, image)
    -- closer:Dock(BOTTOM)
    -- closer.DoClickInternal = function(self)
    --     self:SetToggle(true)
    --     CloseMenu()
    -- end
    mainmenu.OnCursorEntered = toptext.OnCursorEntered

    function mainmenu:OnKeyCodePressed(key)
        if input.GetKeyCode(savebind:GetString()) != -1 and key == input.GetKeyCode(savebind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_save") then sbut:DoClickInternal() sbut:DoClick() return end
        if input.GetKeyCode(loadbind:GetString()) != -1 and key == input.GetKeyCode(loadbind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_load") then lbut:DoClickInternal() lbut:DoClick() return end
        if input.GetKeyCode(modelbind:GetString()) != -1 and key == input.GetKeyCode(modelbind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_model") then modelpanel:DoClickInternal() modelpanel:DoClick() return end
        if input.GetKeyCode(cancelbind:GetString()) != -1 and key == input.GetKeyCode(cancelbind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_cancel") then ccancel:DoClickInternal() return end
        if input.GetKeyCode(keybind:GetString()) != -1 and key == input.GetKeyCode(keybind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu") then CloseMenu() return end
    end

    function CreateOptionsMenu()
        options:Clear()
        options:SetSize(lcont:GetWide(), lcont:GetTall() * 0.1)
        options:SetY(lcont:GetWide() * 0.2)
        options:DockPadding(lcont:GetWide() * 0.025, 0, lcont:GetWide() * 0.025, 0)

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
                RefreshLoadout(closer)
            end
        else
            default = GenerateLabel(options, DefaultEnabled())
            default:SetTextInset(0, 0)
        end
        default:SetTextColor(color_default)
        default:SetFont("quickloadout_font_small")
        local remind = options:Add("DCheckBoxLabel")
        remind:SetConVar("quickloadout_remind_client")
        remind:SetText("Loadout reminder on spawn")
        remind:SetTall(options:GetWide() * 0.125)
        remind:SetWrap(true)
        remind:SetTextColor(color_default)
        remind:SetFont("quickloadout_font_small")


        local bindpanel, canpanel, loadpanel, savepanel = options:Add("Panel"), options:Add("Panel"), options:Add("Panel"), options:Add("Panel")
        local binder, bindtext = vgui.Create("DBinder", bindpanel), GenerateLabel(bindpanel, "Loadout window key")
        bindtext:SetFont("quickloadout_font_small")
        bindtext:Dock(FILL)
        -- binder:SetConVar("quickloadout_key")
        binder.Paint = optbut.Paint
        binder:SetFont("quickloadout_font_small")
        binder:SetTextColor(color_default)
        -- binder:DockMargin(60,10,60,10)
        binder:Dock(RIGHT)
        binder:CenterHorizontal()
        binder:SetText(string.upper(bindings.keybind))
        binder.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                keybind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
                closer.Text = "[ "..string.upper(t or "").." ]"
            end)
        end
        local canner, cantext = vgui.Create("DBinder", canpanel), GenerateLabel(canpanel, "Close and cancel key")
        cantext:SetFont("quickloadout_font_small")
        cantext:Dock(FILL)
        -- binder:SetConVar("quickloadout_key")
        canner.Paint = optbut.Paint
        canner:SetFont("quickloadout_font_small")
        canner:SetTextColor(color_default)
        -- binder:DockMargin(60,10,60,10)
        canner:Dock(RIGHT)
        canner:CenterHorizontal()
        canner:SetText(string.upper(bindings.cancelbind))
        canner.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                keybind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
                ccancel.Text = "[ "..string.upper(t or "").." ]"
            end)
        end
        -- cl:Help("Loadout quickload bind")
        -- local qloader = vgui.Create("DBinder", cl)
        -- -- binder:SetConVar("quickloadout_key")
        -- qloader:DockMargin(60,10,60,10)
        -- qloader:Dock(TOP)
        -- qloader:CenterHorizontal()
        -- qloader:SetText(string.upper(keybindload:GetString() != "" and keybindload:GetString() or "none"))
        -- qloader.OnChange = function(self, key)
        --     timer.Simple(0, function()
        --         local t = input.GetKeyName(key)
        --         keybindload:SetString(t or "")
        --         self:SetText(string.upper(t or "none"))
        --     end)
        -- end
        -- cl:Help("Load menu toggle bind")
        local loader, loadtext = vgui.Create("DBinder", loadpanel), GenerateLabel(loadpanel, "Load menu key")
        loadtext:SetFont("quickloadout_font_small")
        loadtext:Dock(FILL)
        -- binder:SetConVar("quickloadout_key")
        loader.Paint = optbut.Paint
        loader:SetFont("quickloadout_font_small")
        loader:SetTextColor(color_default)
        -- loader:DockMargin(60,10,60,10)
        loader:Dock(RIGHT)
        loader:CenterHorizontal()
        loader:SetText(string.upper(bindings.loadbind))
        loader.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                loadbind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
                lbut.Text = "[ "..string.upper(t or "").." ]"
            end)
        end
        -- cl:Help("Save menu toggle bind")
        local saver, savetext = vgui.Create("DBinder", savepanel), GenerateLabel(savepanel, "Save menu key")
        savetext:SetFont("quickloadout_font_small")
        savetext:Dock(FILL)
        -- binder:SetConVar("quickloadout_key")
        saver.Paint = optbut.Paint
        saver:SetFont("quickloadout_font_small")
        saver:SetTextColor(color_default)
        -- saver:DockMargin(60,10,60,10)
        saver:Dock(RIGHT)
        saver:CenterHorizontal()
        saver:SetText(string.upper(bindings.savebind))
        saver.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                savebind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
                sbut.Text = "[ "..string.upper(t or "").." ]"
            end)
        end
        bindpanel:SetSize(binder:GetTextSize())
        canpanel:SetSize(canner:GetTextSize())
        loadpanel:SetSize(loader:GetTextSize())
        savepanel:SetSize(saver:GetTextSize())

        local enablecat = options:Add("DCheckBoxLabel")
        enablecat:SetConVar("quickloadout_showcategory")
        enablecat:SetText("Weapon categories")
        enablecat:SetTooltip("Toggles whether weapon buttons should or should not show their category underneath them.")
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

        local enableslot = options:Add("DCheckBoxLabel")
        enableslot:SetConVar("quickloadout_showslot")
        enableslot:SetText("Weapon slots")
        enableslot:SetTooltip("Toggles whether weapon buttons should or should not show their inventory slot underneath them.")
        enableslot:SetValue(showslot:GetBool())
        enableslot:SetFont("quickloadout_font_small")
        enableslot:SetWrap(true)
        enableslot:SetTextColor(color_default)
        enableslot.Button.Toggle = function(self)
            self:SetValue( !self:GetChecked() )
            sbut:SetToggle(false)
            lbut:SetToggle(false)
            timer.Simple(0, function() CreateWeaponButtons() end)
        end

        local enableblur = options:Add("DCheckBoxLabel")
        enableblur:SetConVar("quickloadout_ui_blur")
        enableblur:SetText("Background blur")
        enableblur:SetTooltip("Enables background blurring when the menu is open.")
        enableblur:SetValue(blur:GetBool())
        enableblur:SetFont("quickloadout_font_small")
        enableblur:SetWrap(true)
        enableblur:SetTextColor(color_default)

        local fontpanel = options:Add("Panel")
        fontpanel:SetTooltip("The font Quick Loadout's GUI should use.\nYou can use any installed font on your computer, or found in Garry's Mod's ''resource/fonts'' folder.\nLeave empty to use default fonts supplied.")
        local fonttext, fontfield, fontslider = GenerateLabel(fontpanel, "Fonts"), GenerateEditableLabel(fontpanel, fonts:GetString()) -- , options:Add("DNumSlider")
        local fonthelp = GenerateLabel(options, "Add \",\" for separate small font.")
        fonthelp:SetFont("quickloadout_font_small")
        fonthelp:SizeToContentsY(options:GetWide() * 0.025)
        fonthelp:SetTextInset(0, 0)
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
        fonthelp:Dock(TOP)

        local colortext, bgsheet = GenerateLabel(options, "Colors"), options:Add("DPropertySheet")
        colortext:SetFont("quickloadout_font_small")
        colortext:SetTextInset(0, 0)

        for k, v in ipairs(options:GetChildren()) do
            -- v:SizeToContents()
            v:DockMargin(options:GetWide() * 0.025, options:GetWide() * 0.025, options:GetWide() * 0.025, 0)
        end

        local bgpalette, btpalette = bgsheet:Add("DColorMixer"), bgsheet:Add("DColorMixer")
        Derma_Install_Convar_Functions(bgpalette)
        bgsheet:SetTall(math.max(options:GetWide() * 0.8, 240))
        bgsheet:DockMargin(0, options:GetWide() * 0.025, 0, 0)
        bgsheet:AddSheet("Background", bgpalette, "icon16/script_palette.png")
        bgsheet:AddSheet("Buttons", btpalette, "icon16/style_edit.png")
        bgpalette:SetAlphaBar(false)
        bgpalette:SetConVar("quickloadout_ui_color_bg")
        bgpalette:SetColor(ColorAlpha(col_bg, 224))
        bgpalette.Think = function(self)
            col_bg = ColorAlpha(self:GetColor(), 224)
            self:ConVarChanged(self:GetColor().r .. " " .. self:GetColor().g .. " " .. self:GetColor().b)
        end
        Derma_Install_Convar_Functions(btpalette)
        btpalette:SetAlphaBar(false)
        btpalette:SetConVar("quickloadout_ui_color_button")
        btpalette:SetColor(ColorAlpha(col_hl, 128))
        btpalette.Think = function(self)
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
        local ref, match, cat, slot = rtable[wep], "^[%w%d%p]+", showcat:GetBool(), showslot:GetBool()
        local bc = ref and tostring(ref.Category:match(match)):Trim()
        local short = bc and (ref.Category:len() > 7 and (ref.Base and ref.Base:find(bc:lower()) != nil and ref.Category:gsub(bc, "") or ref.Category:match("^[%u%d%p]+%s")) or ref.Category):gsub("%b()", ""):Trim()
        return ref and (slot and ref.Slot and "Slot " .. ref.Slot or "") .. " " .. (cat and "[" .. (short:gsub("[^%w.:+]", ""):len() > 7 and short:gsub("([^%c%s%p])[%l]+", "%1") or short):gsub("[^%w.:+]", "") .. "]" or "")
    end

    function TheCats(cat)
        if cat == category1 then return category2 else return category3 end
    end

    function CreateLoadoutButtons(saving)
        toptext:SetFont("quickloadout_font_medium")
        toptext:SetToggle(true)
        rcont:Show()
        category1:Hide()
        category2:Hide()
        category3:Hide()
        qllist:Clear()
        LoadSavedLoadouts()

        if saving then
            toptext:SetText("LMB save loadout\nRMB delete loadout")
            for i, v in ipairs(loadouts) do
                local button = GenerateEditableLabel(qllist, v.name)
                LoadoutSelector(button, i)
            end
            local newloadout = GenerateEditableLabel(qllist, "+ Save New")
            LoadoutSelector(newloadout, #loadouts + 1)
        else
            toptext:SetText("LMB equip and close\nRMB equip and edit")
            for i, v in ipairs(loadouts) do
                local button = GenerateLabel(qllist, v.name, "vgui/null", image)
                LoadoutSelector(button, i)
            end
            if !next(loadouts) then GenerateLabel(qllist, "No loadouts saved.") end
        end
    end

    function CreateWeaponButtons() -- it's a lot better now i think :)
        toptext:SetFont("quickloadout_font_large")
        toptext:SetText("Current loadout")
        toptext:SetToggle(false)
        rcont:Hide()
        weplist:Clear()
        count = maxslots:GetBool() and maxslots:GetInt() or game.SinglePlayer() and 0 or 32
        -- count2 = slotlimit:GetBool() and slotlimit:GetInt() or 0

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
        -- count2 = slotlimit:GetBool() and slotlimit:GetInt() or 0

        if loadouts[key] then
            for i, v in ipairs(loadouts[key].weps) do
                local button = GenerateLabel(category1, QuickName(v), v, image)
                WepSelector(button, i, v)
                button:SetIsToggle(false)
                button.DoClickInternal = function() end
                button.DoRightClick = button.DoClickInternal
            end
        else
            for i, v in ipairs(ptable) do
                local button = GenerateLabel(category1, QuickName(v), v, image)
                WepSelector(button, i, v)
                button:SetIsToggle(false)
                button.DoClickInternal = function() end
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
            wepimg = Material(ptable[slot] and rtable[ptable[slot]] and (rtable[ptable[slot]].HudImage or rtable[ptable[slot]].Image) or "vgui/null", "smooth")
            local ratio = wepimg:Width() / wepimg:Height()
            image.ImageRatio = ratio - 1
            if cat == category1 then buttonclicked = nil rcont:Hide() end
        end
        for key, v in SortedPairs(tbl) do
            if !(table.HasValue(ptable, key) and !ptable[slot]) then
                local button = GenerateLabel(cat, v, key, image)
                button.DoRightClick = cancel.DoClickInternal
                local offset = button:GetWide() * 0.1
                button:SizeToContentsY(fontsize)
                if istable(v) then
                    local wepcount, catcount = 0, 0
                    local numbers = ""
                    for sub, tab in pairs(v) do
                        if istable(tab) then
                            catcount = catcount + 1
                            wepcount = wepcount + table.Count(tab)
                        else
                            wepcount = wepcount + 1
                        end
                    end
                    numbers = (catcount > 0 and catcount .. " categor" .. (catcount > 1 and "ies" or "y") .. ", " or "") .. wepcount .. " weapon" .. (wepcount != 1 and "s" or "")
                    -- PrintTable(tbl)
                    button.PaintOver = function(self, x, y)
                        draw.SimpleText(numbers, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, color_default, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                    end
                    button.DoClickInternal = function()
                        PopulateCategory(button, v, cont, TheCats(cat), slot)
                        cat:Hide()
                    end
                continue end
                local ref = rtable[key]
                local usable = ref.Spawnable or ref.AdminOnly and LocalPlayer():IsAdmin()
                local wepimage = Material(ref and ref.Image or "vgui/null", "smooth")
                local ratio = wepimage:Width() / wepimage:Height()
                local cattext, weptext = ShortenCategory(key), ref.SubCategory and (ref.Rating and ref.Rating .. " " or "") .. ref.SubCategory
                button.Paint = function(self, x, y)
                    local active = button:IsHovered()
                    surface.SetDrawColor(usable and (active and col_hl or col_but) or (active and col_but or col_col))
                    surface.DrawRect(0 , 0, x, y)
                    surface.SetDrawColor(255, 255, 255, 192)
                    if ref.Image then
                        surface.SetMaterial(wepimage)
                        surface.DrawTexturedRect(x * 0.4, y * 0.5 - offset * 3.5 / ratio, offset * 8, offset * 8 / ratio)
                    end
                    draw.SimpleText(cattext, "quickloadout_font_small", x - offset * 0.125, y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                    if weptext then
                        draw.SimpleText(weptext, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                    end
                end
                button.DoClickInternal = function()
                    if table.HasValue(ptable, key) and ptable[slot] then
                        table.Merge(ptable, {[table.KeyFromValue(ptable, key)] = ptable[slot]})
                    end
                    table.Merge(ptable, {[slot] = key})
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
        button.PaintOver = function(self, x, y)
            draw.SimpleText(wepcount, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, colo, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
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
                    self._TextEdit:SetFont("quickloadout_font_medium")
                    self._TextEdit:SetPlaceholderText("New Loadout " .. key)
                end
            end
            button.OnLabelTextChanged = function(self, text)
                qllist:Clear()
                if string.len(text) < 1 then text = "New Loadout " .. key end
                table.Merge(loadouts, {[key] = {name = text, weps = ptable}})
                file.Write(dir .. gm .. "client_loadouts.json", util.TableToJSON(loadouts))
                sbut:DoClickInternal()
                sbut:DoClick()
            end
            button.DoRightClick = function(self)
                if !loadouts[key] then return end
                surface.PlaySound("garrysmod/ui_return.wav")
                if confirm then
                    CreateLoadoutButtons(true)
                else
                    confirm = true
                    button:SetFont("quickloadout_font_small")
                    button:SetText("LMB to confirm deletion\nRMB to cancel")
                    -- button:SizeToContentsY(fontsize)
                end
            end
        else
            button.DoClickInternal = function(self)
                QLNotify(loadouts[key].name .. " equipped!")
                ptable = loadouts[key].weps
                RefreshLoadout()
                CloseMenu()
            end
            button.DoRightClick = function(self)
                QLNotify(loadouts[key].name .. " loaded!")
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
        local ref = rtable[class]
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
        local icon = math.max(scale * 8, 16)
        button:SetText(button:GetText())
        if ref then
            cattext, weptext = ShortenCategory(class), ref.SubCategory and (ref.Rating and ref.Rating .. " " or "") .. ref.SubCategory
            button:SizeToContentsY(fontsize)
        else
            if unusable then button:SetFont(button:GetText() == "+ Add Weapon" and "quickloadout_font_medium" or "quickloadout_font_small") end
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
                surface.DrawTexturedRect(x - offset * 0.15 - icon, y - offset * 0.15 - icon, icon, icon)
            end
            draw.SimpleText(cattext, "quickloadout_font_small", x - offset * 0.125 - (ref.Icon and icon + offset * 0.25 or 0), y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
            if weptext then
                draw.SimpleText(weptext, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
            end
        end
        button.DoClickInternal = function()
            if IsValid(modelpanel.Window) then modelpanel.Window:Remove() end
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
    timer.Simple(1, function()
        if game.SinglePlayer() then
            net.Start("QLSPHack")
            net.WriteInt(input.GetKeyCode(keybind:GetString()), 9)
            net.SendToServer()
        end
        NetworkLoadout()
    end)
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
concommand.Add("quickloadout_reloadweapons", GenerateWeaponTable)
-- cvars.AddChangeCallback("quickloadout_weapons", NetworkLoadout)
-- cvars.AddChangeCallback("quickloadout_enable_client", NetworkLoadout)

hook.Add("PopulateToolMenu", "CATQuickLoadoutSettings", function()
    spawnmenu.AddToolMenuOption("Options", "Chen's Addons", "QuickLoadoutSettings", "Quick Loadout", "", "", function(panel)
        local sv, cl = vgui.Create("DForm"), vgui.Create("DForm")
        panel:AddItem(sv)
        panel:AddItem(cl)
        sv:SetName("Server")
        sv:CheckBox("Enable quick loadouts", "quickloadout_enable")
        sv:ControlHelp("Globally enables quick loadout on server.")
        local default = sv:ComboBox("Give default loadout", "quickloadout_default")
        default:SetSortItems(false)
        default:AddChoice("User-defined", -1)
        default:AddChoice("Disabled", 0)
        default:AddChoice("Enabled", 1)
        sv:ControlHelp("Enable gamemode's default loadout.")
        sv:NumSlider("Clips per weapon", "quickloadout_spawnclips", 0, 100, 0)
        sv:ControlHelp("How many clips worth of ammo each weapon is given.")
        sv:NumSlider("Spawn grace time", "quickloadout_gracetime", 0, 60, 0)
        sv:ControlHelp("Time you have to change loadout after spawning. 0 is infinite.\n15 is recommended for PvP events, 0 for pure sandbox.")
        sv:NumSlider("Max weapon slots", "quickloadout_maxslots", 0, 32, 0)
        sv:ControlHelp("Amount of weapons players can have on spawn. Max 32, 0 is infinite.")
        sv:CheckBox("Shooting cancels grace", "quickloadout_gracetime_override")
        sv:ControlHelp("Whether pressing the attack button disables grace period.")
        cl:SetName("Client")
        cl:CheckBox("Loadout reminder on spawn", "quickloadout_remind_client")
        cl:Help("Loadout window key")
        -- panel:CheckBox(maxslots, "Max weapons on spawn")
        local binder = vgui.Create("DBinder", cl)
        -- binder:SetConVar("quickloadout_key")
        binder:DockMargin(60,10,60,10)
        binder:Dock(TOP)
        binder:CenterHorizontal()
        binder:SetText(string.upper(keybind:GetString() != "" and keybind:GetString() or "none"))
        binder.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                keybind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
            end)
        end
        cl:Help("Loadout change cancel key")
        -- panel:CheckBox(maxslots, "Max weapons on spawn")
        local canner = vgui.Create("DBinder", cl)
        -- binder:SetConVar("quickloadout_key")
        canner:DockMargin(60,10,60,10)
        canner:Dock(TOP)
        canner:CenterHorizontal()
        canner:SetText(string.upper(cancelbind:GetString() != "" and cancelbind:GetString() or "none"))
        canner.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                cancelbind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
            end)
        end
        -- cl:Help("Loadout quickload bind")
        -- local qloader = vgui.Create("DBinder", cl)
        -- -- binder:SetConVar("quickloadout_key")
        -- qloader:DockMargin(60,10,60,10)
        -- qloader:Dock(TOP)
        -- qloader:CenterHorizontal()
        -- qloader:SetText(string.upper(keybindload:GetString() != "" and keybindload:GetString() or "none"))
        -- qloader.OnChange = function(self, key)
        --     timer.Simple(0, function()
        --         local t = input.GetKeyName(key)
        --         keybindload:SetString(t or "")
        --         self:SetText(string.upper(t or "none"))
        --     end)
        -- end
        cl:Help("Load menu toggle key")
        local loader = vgui.Create("DBinder", cl)
        -- binder:SetConVar("quickloadout_key")
        loader:DockMargin(60,10,60,10)
        loader:Dock(TOP)
        loader:CenterHorizontal()
        loader:SetText(string.upper(loadbind:GetString() != "" and loadbind:GetString() or "none"))
        loader.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                loadbind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
            end)
        end
        cl:Help("Save menu toggle key")
        local saver = vgui.Create("DBinder", cl)
        -- binder:SetConVar("quickloadout_key")
        saver:DockMargin(60,10,60,10)
        saver:Dock(TOP)
        saver:CenterHorizontal()
        saver:SetText(string.upper(savebind:GetString() != "" and savebind:GetString() or "none"))
        saver.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                savebind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
            end)
        end
        cl:Button("Open loadout menu", "quickloadout_menu")
        cl:Button("Reload weapon list", "quickloadout_reloadweapons")
        cl:Help("May freeze your game for a moment.\n")
    end)
end)

list.Set("DesktopWindows", "QuickLoadoutMenu", {
    title = "Quick Loadout",
    icon = "icon16/gun.png",
    init = QLOpenMenu
})