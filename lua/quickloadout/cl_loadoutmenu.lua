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
local rmbclose = GetConVar("quickloadout_menu_rightclick")
local rmbmode = GetConVar("quickloadout_menu_rightclick_mode")
local escclose = GetConVar("quickloadout_menu_escapetoclose")
local cancelbind = GetConVar("quickloadout_menu_cancel")
local loadbind = GetConVar("quickloadout_menu_load")
local savebind = GetConVar("quickloadout_menu_save")
local optbind = GetConVar("quickloadout_menu_options")
local modelbind = GetConVar("quickloadout_menu_model")
local showcat = GetConVar("quickloadout_showcategory")
local showsubcat = GetConVar("quickloadout_showsubcategory")
local showslot = GetConVar("quickloadout_showslot")
local blur = GetConVar("quickloadout_ui_blur")
local showguy = GetConVar("quickloadout_showcharacter")
local showgun = GetConVar("quickloadout_showcharacter_weapon")
local fonts, fontscale = GetConVar("quickloadout_ui_fonts"), GetConVar("quickloadout_ui_font_scale")
local lastgiven = 0
local reminder = GetConVar("quickloadout_remind_client")

local enabled = GetConVar("quickloadout_enable")
local override = GetConVar("quickloadout_default")
local maxslots = GetConVar("quickloadout_maxslots")
local slotlimit = GetConVar("quickloadout_slotlimit")
local time = GetConVar("quickloadout_gracetime")
local modelcvar = GetConVar("quickloadout_applymodel")
-- local clips = GetConVar("quickloadout_giveclips")
local fontsize
local color_default, color_medium, color_light = Color(255, 255, 255, 191), Color(255, 255, 255, 127), Color(255, 255, 255, 95)

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
            table.Merge(temptbl, {[k] = math.floor(v * 0.125)}, true)
        end
    return Color(temptbl.r, temptbl.g, temptbl.b) end
    function LessenButton(color)
        local temptbl = {r = 0, g = 0, b = 0, a = 0}
        for k, v in SortedPairs(color) do
           table.Merge(temptbl, {[k] = math.floor(v * 0.75)}, true)
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

local uncategorized = ""

local function GenerateCategory(frame, name)
    local category = frame:Add("DListLayout")
    if name then category.Name = name end
    category:SetZPos(2)
    category:SetSize(frame:GetParent():GetSize())
    category:Dock(FILL)
    category.Show = function(self)
        frame:InvalidateLayout()
        -- self:SizeToChildren(false, true)
        self:InvalidateLayout()
        self:InvalidateChildren(true)
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
local wepimg = nil

local function TestImage(item, hud)
    if !item then return "vgui/null" end
    -- if file.Exists("materials/" .. item .. ".vmt", "GAME") then return item
    if hud and file.Exists("materials/vgui/hud/" .. item .. ".vmt", "GAME") then return "vgui/hud/" .. item
    elseif file.Exists("materials/entities/" .. item .. ".png", "GAME") then return "entities/" .. item .. ".png"
    elseif file.Exists("materials/vgui/entities/" .. item .. ".vmt", "GAME") then return "vgui/entities/" .. item
    -- else return "vgui/null"
    end
    return
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
    local fw, fh = frame:GetSize()
    button:SetMouseInputEnabled(true)
    button:SetMinimumSize(nil, fw * 0.075)
    button:SetSize(fw * 0.975, fw * 0.125)
    button:SetFontInternal("quickloadout_font_large")
    button:SetTextInset(fw * 0.025, 0)
    button:SetWrap(true)
    button:SetTextColor(color_white)
    local bw, bh = button:GetSize()
    button:DockMargin(math.max(bw * 0.005, 1) , math.max(bw * 0.005, 1), math.max(bw * 0.005, 1), math.max(bw * 0.005, 1))
    button:SetContentAlignment(7)
    button:SetText(text)
    button:SizeToContentsY(bw * 0.015)
    if ispanel(panel) and ispanel(panel.image) then
        button:SetIsToggle(true)
        button.Paint = function(self, x, y)
            local active = button:IsHovered() or button:GetToggle()
            surface.SetDrawColor(active and col_hl or col_but)
            surface.DrawRect(0 , 0, x, y)
        end
        button.OnCursorEntered = function(self)
            panel.image.Text = nil
            wepimg = nil
            panel.image.WepData = {}
            panel.theguy:SetWeapon("")
            if class and rtable[class] then
                panel.image.Text = class
                local icon = rtable[class].HudImage or rtable[class].Image
                if icon then
                    wepimg = Material(icon, "mips")
                    local ratio = wepimg:Width() / wepimg:Height()
                    panel.image.ImageRatio = ratio - 1
                end
                local stats = rtable[class].Stats
                if stats then
                    panel.image.WepData = stats
                    if ispanel(panel.theguy) then
                        panel.theguy:SetWeapon(panel.image.WepData.mdl or "")
                    end
                end
            end
            if self:GetToggle() then return end
            surface.PlaySound("garrysmod/ui_hover.wav")
        end
        button.OnToggled = function(self, state)
            surface.PlaySound(state and "garrysmod/ui_click.wav" or "garrysmod/ui_return.wav")
        end
    end
    button:InvalidateLayout(true)
    return button
end

local function GenerateEditableLabel(frame, name)
    local button = frame:Add("DLabelEditable")
    local text = name or "Uh oh! Broken!"
    surface.SetFont("quickloadout_font_large")
    button:SetName(name)
    local fw, fh = frame:GetSize()
    button:SetMouseInputEnabled(true)
    button:SetKeyboardInputEnabled(true)
    button:SetSize(fw * 0.975, fw * 0.125)
    button:SetFontInternal("quickloadout_font_large")
    button:SetTextInset(fw * 0.025, 0)
    button:SetWrap(true)
    if name then button:SetText(text) end
    local bw, bh = button:GetSize()
    button:SizeToContentsY(bw * 0.015)
    button:SetTextColor(color_white)
    button:DockMargin(math.max(bw * 0.005, 1) , math.max(bw * 0.005, 1), math.max(bw * 0.005, 1), math.max(bw * 0.005, 1))
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
    button:InvalidateLayout(true)
    return button
end

local function QLEditTime(t)
    return CurTime() < t and "\n".. math.Truncate(t - CurTime(),1)
end

local notipan = nil
local function QLNotify(note, priority)
    local spawn = !isstring(note) and note
    if spawn and !reminder:GetBool() then return end
    if IsValid(notipan) then
        if (notipan.Priority and !priority) then return end
        notipan.Spawn = spawn
        notipan.Priority = priority
        if (priority and notipan.Spawn and !spawn) then
            notipan:MoveTo((ScrW() - notipan:GetWide()) * 0.5, ScrH(), .2, 0, -1, function(data, pnl) pnl:Remove() end)
            return
        end
        if (!notipan.Priority or notipan.Priority and priority) then
            notipan:Remove()
        end
    end
    local text = "Your loadout will change next deployment."
    if isstring(note) then text = note
    elseif spawn or !note and priority then text = "[ " .. string.NiceName(keybind:GetString()) .. " ] Change loadout"
    end
    notipan = vgui.Create("DPanel", GetHUDPanel())
    notipan.Paint = nil
    notipan.Spawn = spawn
    notipan.Priority = priority
    local box = vgui.Create("DLabel", notipan)
    box:SetFont("quickloadout_font_medium")
    box:SetText(text)
    box:SetTextColor(color_white)
    local spawntime = spawn and (IsValid(LocalPlayer()) and LocalPlayer():Health() > 0 and (time:GetBool() and time:GetInt() or 0) or 8) or 1
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
        cutoff:SetTextColor(color_white)
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
    if !note and priority then
        notipan:SetPos(wpos, ScrH() * 0.8)
        notipan:MoveTo(wpos, ScrH(), 0.2, 0, -1, function(data, pnl) pnl:Remove() end)
        return
    end
    notipan:SetPos(wpos, ScrH())
    notipan:MoveTo(wpos, ScrH() * 0.8, 0.2, 0, -1, function(data, pnl) pnl:MoveTo(wpos, ScrH(), .2, spawntime + 1.8, -1, function(data, pnl) pnl:Remove() end) end)
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
    local spawn, prio = net.ReadBool(), net.ReadBool()
    QLNotify(spawn, prio)
    -- if spawn then if !reminder:GetBool() then return end LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Press " .. string.NiceName(keybind:GetString()) .. " to modify your loadout.") return end LocalPlayer():PrintMessage(HUD_PRINTCENTER, "Your loadout will change next deployment.")
end)

local char = "[%c%s%p]"

function ShortenCategory(wep)
    local ref, match, cat, slot = rtable[wep], "^[%w%d%p]+", showcat:GetBool(), showslot:GetBool()
    local nicecat = (language.GetPhrase(ref and ref.Category or wep))
    if !IsValid(nicecat) then return "" end
    local bc = string.gsub(string.match(nicecat, match):Trim(), char, "")
    local short = bc and (nicecat:len() > 7 and (ref and ref.Base and ref.Base:find(bc:lower()) != nil and nicecat:gsub(bc, "") or nicecat:match("^[%u%d%p]+%s")) or nicecat):gsub("%b()", ""):Trim()
    return (slot and ref and ref.Slot and " Slot " .. ref.Slot or "") .. " " .. (cat and "[" .. (short:gsub("[^%w.:+]", ""):len() > 7 and short:gsub("([^%c%s%p])[%l]+", "%1") or short):gsub("[^%w.:+]", "") .. "]" or "")
end

local function GenerateWeaponTable(force)
    if table.IsEmpty(wtable) or force then
        print("Generating weapon table...")
        rtable = list.Get("Weapon")
        local reftable = {}
        for class, wep in SortedPairs(rtable) do
            if wep.Spawnable then
                reftable = weapons.Get(class)
                local nicecat = language.GetPhrase(wep.Category)
                if !wtable[nicecat] then
                    wtable[nicecat] = {}
                end
                local mat = (list.Get("ContentCategoryIcons")[nicecat])
                local image = reftable and (reftable.LoadoutImage or reftable.HudImage)
                wep.Icon = mat
                wep.HudImage = image and (file.Exists("materials/" .. image, "GAME") and image) or TestImage(class, true)
                wep.Image = image and wep.HudImage or TestImage(class) -- or wep.SpawnIcon
                wep.PrintName = language.GetPhrase(reftable and (reftable.AbbrevName or reftable.PrintName) or wep.PrintName or class)
                local cat = reftable and ((weapons.IsBasedOn(class, "weapon_swcs_base") and string.NiceName(util.KeyValuesToTable(reftable.ItemDefVisuals or "").weapon_type or uncategorized)) or reftable.SubCategory or reftable.SubCatType) or uncategorized
                if (cat) then
                    cat = string.gsub(string.gsub(string.gsub(cat, "s$", ""), "^%d(%a)", "%1"), "^⠀", "​")
                    wep.SubCategory = cat
                    if !wtable[nicecat][cat] then
                        wtable[nicecat][cat] = {}
                    end
                    table.ForceInsert(wtable[nicecat][cat], {class = class, name = wep.PrintName})
                end
                -- if !reftable or !(reftable.SubCategory or reftable.SubCatType) then
                --     table.ForceInsert(wtable[nicecat][cat], {class = class, name = wep.PrintName})
                -- end
                if reftable then
                    wep.Base = reftable.Base
                    if reftable.Slot then wep.Slot = (tonumber(reftable.Slot) or 0)+1 end
                    wep.Stats = {
                        dmg = reftable.DamageMax or reftable.Damage_Max or reftable.Damage or reftable.Bullet and istable(reftable.Bullet.Damage) and reftable.Bullet.Damage[1] or reftable.Primary.Damage,
                        num = reftable.Num or reftable.Primary.NumShots or 1,
                        rof = reftable.RPM or reftable.Primary.RPM or (reftable.FireDelay and math.Round(60 / reftable.FireDelay) or reftable.Primary.Delay and reftable.Primary.Delay > 0 and math.Round(60 / reftable.Primary.Delay)),
                        ammo = game.GetAmmoName(game.GetAmmoID(tostring(reftable.AmmoType or reftable.Ammo or reftable.Primary.Ammo))),
                        mag = reftable.ClipSize or reftable.Primary.ClipSize,
                        ammo2 = game.GetAmmoName(game.GetAmmoID(tostring(reftable.Secondary.Ammo))),
                        mag2 = reftable.Secondary.ClipSize,
                        mdl = reftable.WorldModel,
                        holdtype = reftable.HoldType,
                    }
                    -- local mdl = "materials/spawnicons/" .. string.StripExtension() .. ".png"
                    -- if #reftable.WorldModel > 0 then
                    --     wep.SpawnIcon = file.Exists(mdl, "GAME") and mdl
                    -- end
                    if reftable.SubCatTier and reftable.SubCatTier != "9Special" then wep.Rating = string.gsub(reftable.SubCatTier, "^%d(%a)", "%1") end
                end
            end
            reftable = {}
        end
    end
    -- PrintTable(wtable)
end

local mat, bmat = Material("vgui/gradient-l"), Material("pp/blurscreen")
local warntext = "Disclaimer: Displayed stats may be inaccurate."
local holdtypetbl = {
    pistol = "idle_revolver",
    revolver = "idle_revolver",
    duel = "idle_dual",
    smg = "idle_rpg",
    ar2 = "idle_rpg",
    shotgun = "idle_passive",
    rpg = "idle_passive",
    physgun = "idle_passive",
    crossbow = "idle_rpg",
    camera = "idle_slam",
    slam = "idle_slam",
    grenade = "idle_slam",
    knife = "idle_slam",
    fist = "pose_standing_02",
}

local refresh = false
function QLOpenMenu()
    local tmp = {}
    table.CopyFromTo(ptable, tmp)
    local buttonclicked = nil
    local dtext = {string.NiceName(language.GetPhrase("damage")), "RPM", "APM"}
    local tt = SysTime()
    local bindings = {keybind = keybind:GetString(), cancelbind = cancelbind:GetString(), loadbind = loadbind:GetString(), savebind = savebind:GetString(), modelbind = modelbind:GetString(), optbind = optbind:GetString()}
    if open then return else open = true end
    refresh = false
    local scale, scale2 = ScreenScale(1), ScreenScaleH(1)
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
    local width, height = bg:GetSize()
    local mainmenu = vgui.Create("EditablePanel", bg)
    mainmenu.Close = function(self)
        CloseMenu()
    end
    function mainmenu:OnMousePressed(code)
        if code != MOUSE_RIGHT then return end
        if !rmbclose:GetBool() then return end
        CloseMenu(refresh and rmbmode:GetBool())
        return true
    end
    mainmenu:SetMouseInputEnabled(true)
    mainmenu:SetSize(width, height)
    mainmenu:SetZPos(-1)
    wepimg = nil
    local bgcolor = ColorAlpha(col_bg, 64)
    mainmenu.Paint = function(self, x, y)
        surface.SetDrawColor(col_bg)
        surface.DrawRect(0,0, (x - y) * 0.25, y)
        render.PushFilterMag(TEXFILTER.LINEAR)
        render.PushFilterMin(TEXFILTER.LINEAR)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect((x - y) * 0.25, 0, math.min(y * 1.5, x), y)
        render.PopFilterMag()
        render.PopFilterMin()
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

    function CloseMenu(apply)
        tt = SysTime() + 0.25
        mainmenu:SetKeyboardInputEnabled(false)
        mainmenu:SetMouseInputEnabled(false)
        mainmenu:MoveTo(-width, 0, 0.25, 0, 0.8, function(data, pnl) open = false bg:Remove() end)
        -- mainmenu:SizeTo(0, height, 0.25, 0, 1.5)
        if refresh then
            if !apply then
                ptable = tmp
            end
            QLNotify(apply and "Loadout changes applied." or "Loadout changes discarded.", !apply)
        end
        refresh = false
        if !apply then return end
        file.Write(dir .. gm .. "autosave.json", util.TableToJSON(ptable))
        timer.Simple(0, function()
            -- mainmenu.Paint = nil
            NetworkLoadout()
        end)
    end

    GenerateWeaponTable()
    table.RemoveByValue(ptable, "")
    local lcont, rcont = mainmenu:Add("Panel"), mainmenu:Add("Panel")
    lcont:SetZPos(0)
    lcont.Paint = function(self, x, y)
        surface.SetDrawColor(col_col)
        surface.DrawRect(0,0, x, y)
    end
    lcont:SetSize(height * 0.33, height)
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
    local category1, category2, category3 = GenerateCategory(rscroller, "◀ Cancel"), GenerateCategory(rscroller, "◀ Categories"), GenerateCategory(rscroller, "◀ Subcategories")
    category2.Icon = nil
    category2.Category = nil
    mainmenu.image = mainmenu:Add("Panel")
    mainmenu.image:SetMouseInputEnabled(false)
    mainmenu.theguy = vgui.Create("DModelPanel", mainmenu)
    mainmenu.theguy:SetMouseInputEnabled(false)
    AccessorFunc(mainmenu.theguy, "Entity2", "Entity2")
    mainmenu.theguy.DoPaint = mainmenu.theguy.Paint
    mainmenu.theguy.Paint = function(self, x, y)
        if !showguy:GetBool() then return end
        mainmenu.theguy:DoPaint(x, y)
    end
    mainmenu.image:SetZPos(0)
    mainmenu.image:SetSize(height * 0.45, height * 0.8)
    mainmenu.image:SetPos(rcont:GetPos() + rcont:GetWide() * 1.2, height * 0.1)
    mainmenu.image.WepData = {}
    mainmenu.image.ImageRatio = 1
    mainmenu.image.Text = nil
    mainmenu.image.Paint = function(self, x, y)
        if !wepimg then return end
        surface.SetDrawColor(color_white)
        render.PushFilterMag(TEXFILTER.LINEAR)
        render.PushFilterMin(TEXFILTER.LINEAR)
        surface.SetMaterial(wepimg)
        surface.DrawTexturedRect(0+(x*math.min(self.ImageRatio, 0)*0.25),0+(x*math.max(self.ImageRatio, 0)*0.25), x-(x*math.min(self.ImageRatio, 0)*0.5), x-(x*math.max(self.ImageRatio, 0)*0.5))
        render.PopFilterMag()
        render.PopFilterMin()
        draw.NoTexture()
    end
    mainmenu.image.Think = function(self)
        if !self.WepData.type then
            if self.WepData.ammo and isnumber(self.WepData.mag) then
                self.WepData.ammo = string.NiceName(language.GetPhrase(self.WepData.ammo))
                self.WepData.oneshot = self.WepData.mag == 1
                self.WepData.mag = (self.WepData.mag > 0 and "Capacity: " .. self.WepData.mag)
            end
            if self.WepData.ammo2 and isnumber(self.WepData.mag2) then
                self.WepData.ammo2 = string.NiceName(language.GetPhrase(self.WepData.ammo2))
                self.WepData.mag2 = (self.WepData.mag2 > 0 and "Alt. capacity: " .. self.WepData.mag2)
            end
            if self.WepData.dmg and self.WepData.dmg > 1 and !self.WepData.dmgrat then
                local ratmap = math.Remap(self.WepData.dmg * self.WepData.num, 0, 100, 0, 1)
                self.WepData.dmgrat = math.Clamp(ratmap, 0, 1)
                self.WepData.dmgrat2 = math.Clamp(ratmap - 1, 0, 1)
                self.WepData.dmgtotal = math.Round(self.WepData.dmg)
                if self.WepData.num > 1 then
                    self.WepData.dmgsplit = self.WepData.dmgtotal .. "×" .. self.WepData.num
                    self.WepData.dmgtotal = math.Round(self.WepData.dmg * self.WepData.num)
                end
            end
            if self.WepData.rof and !self.WepData.rofrat then
                local ratmap = math.Remap(self.WepData.rof, 0, 900, 0, 1)
                self.WepData.rofrat = math.Clamp(ratmap, 0, 1)
                self.WepData.rofrat2 = math.Clamp(ratmap - 1, 0, 1)
            end
            self.WepData.type = self.Text and rtable[self.Text].Stats and ((!self.WepData.mag or !self.WepData.ammo or !self.WepData.dmgtotal) and 3 or 2) or 0
        end
    end
    mainmenu.image.PaintOver = function(self, x, y)
        if !self.Text then return end
        if self.WepData.type == 0 then
            draw.SimpleText(self.Text, "quickloadout_font_small", x * 0.025, y - x * 0.025, color_light, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
            return
        end
        draw.SimpleText(self.Text, "quickloadout_font_small", x * 0.025, y - x * 0.075, color_light, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
        draw.SimpleText(warntext, "quickloadout_font_small", x * 0.025, y - x * 0.025, color_light, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
        if self.WepData.ammo then
            draw.SimpleText(self.WepData.ammo, "quickloadout_font_medium", x * 0.025, x * 0.95, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
            if self.WepData.mag then
                draw.SimpleText(self.WepData.mag, "quickloadout_font_medium", x * 0.025, x * 0.875, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
            end
        end
        if self.WepData.ammo2 then
            draw.SimpleText(self.WepData.ammo2, "quickloadout_font_medium", x * 0.975, x * 0.95, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, scale, bgcolor)
            if self.WepData.mag2 then
                draw.SimpleText(self.WepData.mag2, "quickloadout_font_medium", x * 0.975, x * 0.875, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, scale, bgcolor)
            end
        end
        if self.WepData.dmgrat then
            surface.SetDrawColor(col_bg)
            surface.DrawRect(x * 0.025, x * 1.1, x * 0.55, x * 0.04)
            surface.SetDrawColor(color_white)
            surface.DrawRect(x * 0.025 + (x * 0.55 - scale2) * self.WepData.dmgrat, x * 1.1, scale2, x * 0.04)
            surface.SetDrawColor(col_hl)
            surface.DrawRect(x * 0.025 + scale2, x * 1.1, (x * 0.55 - scale2) * self.WepData.dmgrat, x * 0.04)
            surface.SetDrawColor(color_white)
            surface.DrawRect(x * 0.025 + (x * 0.55 - scale2) * self.WepData.dmgrat2, x * 1.1, scale2, x * 0.04)
            surface.SetDrawColor(col_hl)
            surface.DrawRect(x * 0.025 + scale2, x * 1.1, (x * 0.55 - scale2) * self.WepData.dmgrat2, x * 0.04)
            surface.SetDrawColor(color_white)
            if self.WepData.dmgrat2 == 1 then
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(x * 0.575, x * 1.1, x * 0.02, x * 0.04)
                draw.NoTexture()
            end
            surface.DrawOutlinedRect(x * 0.025, x * 1.1, x * 0.55, x * 0.04, scale2)
            draw.SimpleText(self.WepData.dmgtotal, "quickloadout_font_large", x * 0.6, x * 1.115, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
            if self.WepData.dmgsplit then
                if !self.WepData.dmgxoff then self.WepData.dmgxoff = surface.GetTextSize(self.WepData.dmgtotal) end
                draw.SimpleText(self.WepData.dmgsplit, "quickloadout_font_medium", x * 0.625 + self.WepData.dmgxoff, x * 1.115, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
            end
            draw.SimpleText(dtext[1], "quickloadout_font_medium", x * 0.025, x * 1.05, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
        end
        if self.WepData.rofrat and !self.WepData.oneshot then
            surface.SetDrawColor(col_bg)
            surface.DrawRect(x * 0.025, x * 1.25, x * 0.55, x * 0.04)
            surface.SetDrawColor(color_white)
            surface.DrawRect(x * 0.025 + (x * 0.55 - scale2) * self.WepData.rofrat, x * 1.25, scale2, x * 0.04)
            surface.SetDrawColor(col_hl)
            surface.DrawRect(x * 0.025 + scale2, x * 1.25, (x * 0.55 - scale2) * self.WepData.rofrat, x * 0.04)
            surface.SetDrawColor(color_white)
            surface.DrawRect(x * 0.025 + (x * 0.55 - scale2) * self.WepData.rofrat2, x * 1.25, scale2, x * 0.04)
            surface.SetDrawColor(col_hl)
            surface.DrawRect(x * 0.025 + scale2, x * 1.25, (x * 0.55 - scale2) * self.WepData.rofrat2, x * 0.04)
            surface.SetDrawColor(color_white)
            if self.WepData.rofrat2 == 1 then
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(x * 0.575, x * 1.25, x * 0.02, x * 0.04)
                draw.NoTexture()
            end
            surface.DrawOutlinedRect(x * 0.025, x * 1.25, x * 0.55, x * 0.04, scale2)
            draw.SimpleText(self.WepData.rof, "quickloadout_font_large", x * 0.6, x * 1.265, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
            draw.SimpleText(dtext[self.WepData.type], "quickloadout_font_medium", x * 0.025, x * 1.2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, scale, bgcolor)
        end
    end
    -- image:SetKeepAspect(true)

    local optbut = GenerateLabel(lcont, "User Options", collapse, mainmenu)
    optbut:Dock(TOP)
    optbut.Text = "[ "..string.upper(bindings.optbind or "").." ]"
    optbut.PaintOver = function(self, x, y)
        -- if refresh then return end
        draw.SimpleText(optbut.Text, "quickloadout_font_small", x-scale2, y-scale2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    -- optbut:DockMargin(math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.005, 1), math.max(lcont:GetWide() * 0.155, 1))
    local closer = lcont:Add("Panel")
    closer.Text = "[ "..string.upper(bindings.keybind or "").." ]"
    closer:SetSize(lcont:GetWide(), lcont:GetWide() * 0.155)
    local ccancel, csave = GenerateLabel(closer, "Cancel", nil, mainmenu), GenerateLabel(closer, "Apply", nil, mainmenu)
    ccancel.Text = "[ "..string.upper(bindings.cancelbind or "").." ]"
    ccancel:SetWide(math.ceil(closer:GetWide() * 0.485))
    ccancel:Dock(FILL)
    ccancel.DoClickInternal = function(self)
        self:SetToggle(true)
        CloseMenu()
    end
    ccancel.PaintOver = function(self, x, y)
        -- if refresh then return end
        draw.SimpleText((!refresh and ccancel.Text .. "/" .. closer.Text) or ccancel.Text, "quickloadout_font_small", x-scale2, y-scale2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    csave:SetWide(math.ceil(closer:GetWide() * 0.485))
    csave:Dock(RIGHT)
    csave:Hide()
    csave.DoClickInternal = function(self)
        self:SetToggle(true)
        CloseMenu(refresh)
    end
    csave.PaintOver = function(self, x, y)
        draw.SimpleText(closer.Text, "quickloadout_font_small", x-scale2, y-scale2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    closer:SizeToContentsY()
    local closerbut = vgui.Create("DButton", mainmenu)
    closerbut:SetIsToggle(true)
    closerbut.OnToggled = ccancel.OnToggled
    closerbut.DoClickInternal = ccancel.DoClickInternal
    closerbut.DoClick = ccancel.DoClick
    closerbut.OnCursorEntered = ccancel.OnCursorEntered
    closerbut:SetText("")
    closerbut:SetSize(height * 0.04, height * 0.04)
    closerbut:SetPos(width - scale2 - closerbut:GetWide(), scale2)
    closerbut.Paint = function(self, x, y)
        draw.SimpleText("×", "quickloadout_font_large", x * 0.5, y * 0.5, color_default, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, scale, bgcolor)
    end
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
    enable:SetTextColor(color_white)
    enable:SetFont("quickloadout_font_small")
    enable:DockMargin(lcont:GetTall() * 0.0155, lcont:GetTall() * 0.00775, lcont:GetTall() * 0.0155, lcont:GetTall() * 0.00775)
    enable:Dock(TOP)
    local options = vgui.Create("DScrollPanel", lcont)
    local optbar = options:GetVBar() 
    optbar:SetHideButtons(true)
    optbar:SetWide(lcont:GetWide() * 0.05)
    optbar.Paint = nil
    optbar.btnGrip.Paint = function(self, x, y)
        draw.RoundedBox(x, x * 0.25, x * 0.25, x * 0.5, y - x * 0.375, color_medium)
    end
    options:Hide()
    options:Dock(FILL)
    local trash = LocalPlayer():GetWeapons()
    local importer = GenerateLabel(lcont, "Import current weapons", nil, mainmenu)
    importer:SetFont("quickloadout_font_medium")
    importer:SetSize(lcont:GetWide(), lcont:GetTall() * 0.04)
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
    saveload:SetSize(lcont:GetWide(), lcont:GetTall() * 0.05)
    local sbut, lbut, toptext = GenerateLabel(saveload, "Save", "vgui/null", mainmenu), GenerateLabel(saveload, "Load", "vgui/null", mainmenu), GenerateLabel(lcont)
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
        draw.SimpleText(self.Text, "quickloadout_font_small", x-scale2, y-scale2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    lbut.PaintOver = function(self, x, y)
        draw.SimpleText(self.Text, "quickloadout_font_small", x-scale2, y-scale2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    modelpanel.PaintOver = function(self, x, y)
        draw.SimpleText(self.Text, "quickloadout_font_small", x-scale2, y-scale2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
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
        optbut:OnToggled(mainmenu.image:IsVisible())
        if IsValid(modelpanel.Window) then modelpanel.Window:Remove() return end
        local window = vgui.Create("DFrame", mainmenu)
        mainmenu.image:Hide()
        window.DoRemoval = window.Remove
        window.Remove = function() mainmenu.image:Show() window:DoRemoval() end
        window.Paint = rcont.Paint
        if rcont:IsVisible() then CreateWeaponButtons() end
        modelpanel.Window = window
        list.Get("DesktopWindows").PlayerEditor:init(window)
        if IsValid(window) then
            window:SetDraggable(false)
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
            mainmenu.theguy:SetModel(self:GetModelName())
            mainmenu.theguy:ResetParameters()
            if modelcvar:GetBool() then RefreshLoadout(closer) end
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

    mainmenu.theguy:SetModel(modelpanel:GetModelName())
    function mainmenu.theguy:LayoutEntity() return end
    function mainmenu.theguy:SetWeapon( strModelName )

        -- Note - there's no real need to delete the old
        -- entity, it will get garbage collected, but this is nicer.
        if !showguy:GetBool() or !showgun:GetBool() then return end
        if ( IsValid( self.Entity2 ) ) then
            self.Entity2:Remove()
            self.Entity2 = nil
        end
    
        -- Note: Not in menu dll
        if ( !ClientsideModel ) then return end
        
        self.Entity2 = ClientsideModel( strModelName, RENDERGROUP_OTHER )
        if ( !IsValid( self.Entity2 ) ) then
            if !IsValid(self.Entity) then return end
            self.Entity:ResetSequence("pose_standing_02")
        return end
    
        self.Entity2:SetNoDraw( true )
        self.Entity2:SetIK( false )
        self.Entity2:ResetSequence( 0 )
        self.Entity2:AddEffects(EF_BONEMERGE)
        if !IsValid(self.Entity) then return end
        self.Entity2:SetParent(self.Entity)
        local holdtype = mainmenu.image.WepData.holdtype
        self.Entity:ResetSequence(holdtype and holdtypetbl[holdtype] or "idle_suitcase" or 1)
    
    end
    function mainmenu.theguy:GetWeapon()
    
        if ( !IsValid( self.Entity2 ) ) then return end
    
        return self.Entity2:GetModel()
    
    end
    function mainmenu.theguy:PostDrawModel(ent)
        if !IsValid(self.Entity) then return end
        if !IsValid(self.Entity2) then return end
        self.Entity2:DrawModel()
    end
    function mainmenu.theguy.Entity:GetPlayerColor() return LocalPlayer():GetPlayerColor() end
    function mainmenu.theguy:ResetParameters()
        self.Entity:ResetSequence("pose_standing_02")
        self.Entity:AddEffects(EF_ITEM_BLINK)
        self.Entity:SetEyeTarget(Vector(100, 0, 64))
        function mainmenu.theguy.Entity:GetPlayerColor() return LocalPlayer():GetPlayerColor() end
        if !self:GetWeapon() then return end
        self:SetWeapon( self:GetWeapon() )
    end
    mainmenu.theguy:SetZPos(-1)
    mainmenu.theguy:SetSize(height * 0.8, height * 0.6)
    mainmenu.theguy:SetPos(width - height * 0.65, height * 0.4)
    mainmenu.theguy:SetFOV(40)
    mainmenu.theguy:SetLookAt(Vector(20, 0, 50))
    mainmenu.theguy:SetCamPos(Vector(100, 70, 64))
    mainmenu.theguy:ResetParameters()

    -- end
    modelpanel:Dock(RIGHT)
    toptext.Name = GetMaxSlots()
    local panos = modelpanel:GetWide()
    toptext.PaintOver = function(self, x, y)
        if self:GetToggle() then return end
        draw.SimpleText(self.Name, "quickloadout_font_small", x - panos - math.max(lcont:GetWide() * 0.01, 1), y, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
    end
    toptext:Dock(TOP)
    toptext.OnCursorEntered = function()
        -- if buttonclicked then return end
        wepimg = nil
        mainmenu.image.Text = nil
        mainmenu.image.WepData = {}
        mainmenu.theguy:SetWeapon("")
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
    lbar.btnGrip.Paint = optbar.btnGrip.Paint
    rbar.btnGrip.Paint = optbar.btnGrip.Paint

    closer:Dock(BOTTOM)
    -- local closer = GenerateLabel(lcont, "Close", nil, image)
    -- closer:Dock(BOTTOM)
    -- closer.DoClickInternal = function(self)
    --     self:SetToggle(true)
    --     CloseMenu()
    -- end
    mainmenu.OnCursorEntered = toptext.OnCursorEntered

    function mainmenu:OnKeyCodePressed(key)
        if input.GetKeyCode(savebind:GetString()) != -1 and key == input.GetKeyCode(savebind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_save") then sbut:DoClickInternal() sbut:Toggle() return true end
        if input.GetKeyCode(loadbind:GetString()) != -1 and key == input.GetKeyCode(loadbind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_load") then lbut:DoClickInternal() lbut:Toggle() return true end
        if input.GetKeyCode(modelbind:GetString()) != -1 and key == input.GetKeyCode(modelbind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_model") then modelpanel:DoClickInternal() modelpanel:DoClick() modelpanel:OnDepressed() return true end
        if input.GetKeyCode(cancelbind:GetString()) != -1 and key == input.GetKeyCode(cancelbind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_cancel") then ccancel:DoClickInternal() ccancel:Toggle() return true end
        if input.GetKeyCode(optbind:GetString()) != -1 and key == input.GetKeyCode(optbind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu_options") then optbut:DoClickInternal() optbut:Toggle() return true end
        if input.GetKeyCode(keybind:GetString()) != -1 and key == input.GetKeyCode(keybind:GetString()) or input.GetKeyName(key) == input.LookupBinding("quickloadout_menu") then csave:DoClickInternal() csave:Toggle() return true end
    end

    function mainmenu:OnKeyCodeReleased(key)
        if escclose:GetBool() and key == KEY_ESCAPE then CloseMenu() return true end
    end

    function CreateOptionsMenu()
        options:Clear()
        options:SetSize(lcont:GetWide(), lcont:GetTall() * 0.1)
        -- options:Dock(FILL)
        options:SetY(lcont:GetWide() * 0.2)
        -- options:DockPadding(lcont:GetWide() * 0.025, 0, lcont:GetWide() * 0.025, 0)

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
        default:Dock(TOP)
        default:SetTextColor(color_white)
        default:SetFont("quickloadout_font_small")
        local remind = options:Add("DCheckBoxLabel")
        remind:Dock(TOP)
        remind:SetConVar("quickloadout_remind_client")
        remind:SetText("Loadout reminder on spawn")
        remind:SetTall(options:GetWide() * 0.125)
        remind:SetWrap(true)
        remind:SetTextColor(color_white)
        remind:SetFont("quickloadout_font_small")

        local bindhelp = GenerateLabel(options, "Bindings")
        bindhelp:Dock(TOP)
        bindhelp:SetFont("quickloadout_font_medium")
        bindhelp:SetTextInset(0, 0)
        bindhelp:SizeToContents()
        local bindpanel, canpanel, loadpanel, savepanel, optpanel = options:Add("Panel"), options:Add("Panel"), options:Add("Panel"), options:Add("Panel"), options:Add("Panel")
        bindpanel:Dock(TOP)
        canpanel:Dock(TOP)
        loadpanel:Dock(TOP)
        savepanel:Dock(TOP)
        optpanel:Dock(TOP)
        local binder, bindtext = vgui.Create("DBinder", bindpanel), GenerateLabel(bindpanel, "Loadout window key")
        bindtext:SetFont("quickloadout_font_small")
        bindtext:Dock(FILL)
        -- binder:SetConVar("quickloadout_key")
        binder.Paint = optbut.Paint
        binder:SetFont("quickloadout_font_small")
        binder:SetTextColor(color_white)
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
        canner:SetTextColor(color_white)
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
        loader:SetTextColor(color_white)
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
        saver:SetTextColor(color_white)
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
        
        local opter, opttext = vgui.Create("DBinder", optpanel), GenerateLabel(optpanel, "Options menu key")
        opttext:SetFont("quickloadout_font_small")
        opttext:Dock(FILL)
        -- binder:SetConVar("quickloadout_key")
        opter.Paint = optbut.Paint
        opter:SetFont("quickloadout_font_small")
        opter:SetTextColor(color_white)
        -- loader:DockMargin(60,10,60,10)
        opter:Dock(RIGHT)
        opter:CenterHorizontal()
        opter:SetText(string.upper(bindings.optbind))
        opter.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                optbind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
                optbut.Text = "[ "..string.upper(t or "").." ]"
            end)
        end

        bindpanel:SetSize(binder:GetTextSize())
        canpanel:SetSize(canner:GetTextSize())
        loadpanel:SetSize(loader:GetTextSize())
        savepanel:SetSize(saver:GetTextSize())
        optpanel:SetSize(opter:GetTextSize())

        local guihelp = GenerateLabel(options, "Interface")
        guihelp:Dock(TOP)
        guihelp:SetFont("quickloadout_font_medium")
        guihelp:SetTextInset(0, 0)
        guihelp:SizeToContents()

        local enablermb = options:Add("DCheckBoxLabel")
        enablermb:Dock(TOP)
        enablermb:SetConVar("quickloadout_menu_rightclick")
        enablermb:SetText("Right click background to close")
        enablermb:SetTooltip("Allows closing the menu by right clicking the background.")
        enablermb:SetValue(rmbclose:GetBool())
        enablermb:SetFont("quickloadout_font_small")
        enablermb:SetWrap(true)
        enablermb:SetTextColor(color_white)

        local rmbsave = options:Add("DCheckBoxLabel")
        rmbsave:Dock(TOP)
        rmbsave:SetConVar("quickloadout_menu_rightclick_mode")
        rmbsave:SetText("Autosave on background right click")
        rmbsave:SetTooltip("Saves the current loadout on right click if turned on.\nRequires above setting to function.")
        rmbsave:SetValue(rmbmode:GetBool())
        rmbsave:SetFont("quickloadout_font_small")
        rmbsave:SetWrap(true)
        rmbsave:SetTextColor(color_white)

        local enableesc = options:Add("DCheckBoxLabel")
        enableesc:Dock(TOP)
        enableesc:SetConVar("quickloadout_menu_escapetoclose")
        enableesc:SetText("ESC to close")
        enableesc:SetTooltip("Allows closing the menu by tapping escape.")
        enableesc:SetValue(escclose:GetBool())
        enableesc:SetFont("quickloadout_font_small")
        enableesc:SetWrap(true)
        enableesc:SetTextColor(color_white)

        local fontpanel = options:Add("Panel")
        fontpanel:Dock(TOP)
        fontpanel:SetTooltip("The font Quick Loadout's GUI should use.\nYou can use any installed font on your computer, or found in Garry's Mod's ''resource/fonts'' folder.\nLeave empty to use default fonts supplied.")
        local fonttext, fontfield, fontslider = GenerateLabel(fontpanel, "Fonts"), GenerateEditableLabel(fontpanel, fonts:GetString()) -- , options:Add("DNumSlider")
        local fonthelp = GenerateLabel(options, "To specify two separate fonts, add \",\" in between two font names.")
        fonthelp:SetTooltip("The font Quick Loadout's GUI should use.\nYou can use any installed font on your computer, or found in Garry's Mod's ''resource/fonts'' folder.\nLeave empty to use default fonts supplied.")
        fonthelp:SetFont("quickloadout_font_small")
        fonthelp:SetTextInset(0, 0)
        fonthelp:SizeToContentsY(options:GetWide() * 0.025)
        fonttext:SetFont("quickloadout_font_small")
        fonttext:SizeToContentsX(options:GetWide() * 0.05)
        fonttext:SizeToContentsY(options:GetWide() * 0.025)
        fonttext:SetTextInset(0, 0)
        fonttext:DockMargin(0, 0, options:GetWide() * 0.025, 0)
        fonttext:Dock(LEFT)
        fonttext:SetTextColor(color_white)
        Derma_Install_Convar_Functions(fontfield)
        fontfield:SetFont("quickloadout_font_small")
        fontfield:SetConVar("quickloadout_ui_fonts")
        fontfield.DoClickInternal = fontfield.DoDoubleClick
        fontfield.OnLabelTextChanged = function(self, text)
            fontfield:ConVarChanged(text)
            mainmenu:InvalidateChildren(true)
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

        local buthelp = GenerateLabel(options, "Buttons")
        buthelp:Dock(TOP)
        buthelp:SetFont("quickloadout_font_small")
        buthelp:SetTextInset(0, 0)
        buthelp:SizeToContents()

        local enablecat = options:Add("DCheckBoxLabel")
        enablecat:Dock(TOP)
        enablecat:SetConVar("quickloadout_showcategory")
        enablecat:SetText("Weapon categories")
        enablecat:SetTooltip("Toggles whether weapon buttons should or should not show their spawnmenu category underneath them.")
        enablecat:SetValue(showcat:GetBool())
        enablecat:SetFont("quickloadout_font_small")
        enablecat:SetWrap(true)
        enablecat:SetTextColor(color_white)
        enablecat.Button.Toggle = function(self)
            self:SetValue( !self:GetChecked() )
            sbut:SetToggle(false)
            lbut:SetToggle(false)
            timer.Simple(0, function() CreateWeaponButtons() end)
        end

        local enablesubcat = options:Add("DCheckBoxLabel")
        enablesubcat:Dock(TOP)
        enablesubcat:SetConVar("quickloadout_showsubcategory")
        enablesubcat:SetText("Weapon subcategories")
        enablesubcat:SetTooltip("Toggles whether weapon buttons should or should not show their weapon subcategory underneath them.")
        enablesubcat:SetValue(showsubcat:GetBool())
        enablesubcat:SetFont("quickloadout_font_small")
        enablesubcat:SetWrap(true)
        enablesubcat:SetTextColor(color_white)
        enablesubcat.Button.Toggle = function(self)
            self:SetValue( !self:GetChecked() )
            sbut:SetToggle(false)
            lbut:SetToggle(false)
            timer.Simple(0, function() CreateWeaponButtons() end)
        end

        local enableslot = options:Add("DCheckBoxLabel")
        enableslot:Dock(TOP)
        enableslot:SetConVar("quickloadout_showslot")
        enableslot:SetText("Weapon slots")
        enableslot:SetTooltip("Toggles whether weapon buttons should or should not show their inventory slot underneath them.")
        enableslot:SetValue(showslot:GetBool())
        enableslot:SetFont("quickloadout_font_small")
        enableslot:SetWrap(true)
        enableslot:SetTextColor(color_white)
        enableslot.Button.Toggle = function(self)
            self:SetValue( !self:GetChecked() )
            sbut:SetToggle(false)
            lbut:SetToggle(false)
            timer.Simple(0, function() CreateWeaponButtons() end)
        end

        local bghelp = GenerateLabel(options, "Background")
        bghelp:Dock(TOP)
        bghelp:SetFont("quickloadout_font_small")
        bghelp:SetTextInset(0, 0)
        bghelp:SizeToContents()

        local enableblur = options:Add("DCheckBoxLabel")
        enableblur:Dock(TOP)
        enableblur:SetConVar("quickloadout_ui_blur")
        enableblur:SetText("Background blur")
        enableblur:SetTooltip("Enables background blurring when the menu is open.")
        enableblur:SetValue(blur:GetBool())
        enableblur:SetFont("quickloadout_font_small")
        enableblur:SetWrap(true)
        enableblur:SetTextColor(color_white)

        local enableguy = options:Add("DCheckBoxLabel")
        enableguy:Dock(TOP)
        enableguy:SetConVar("quickloadout_showcharacter")
        enableguy:SetText("Background character")
        enableguy:SetTooltip("Shows your player character in the background when the menu is open.")
        enableguy:SetValue(showguy:GetBool())
        enableguy:SetFont("quickloadout_font_small")
        enableguy:SetWrap(true)
        enableguy:SetTextColor(color_white)

        local enablegun = options:Add("DCheckBoxLabel")
        enablegun:Dock(TOP)
        enablegun:SetConVar("quickloadout_showcharacter_weapon")
        enablegun:SetText("Background character weapons")
        enablegun:SetTooltip("Shows your player character holding the various weapons available.")
        enablegun:SetValue(showgun:GetBool())
        enablegun:SetFont("quickloadout_font_small")
        enablegun:SetWrap(true)
        enablegun:SetTextColor(color_white)

        local colortext, bgsheet = GenerateLabel(options, "Colors"), options:Add("DPropertySheet")
        colortext:Dock(TOP)
        colortext:SetFont("quickloadout_font_small")
        colortext:SetTextInset(0, 0)
        colortext:SizeToContents()
        bgsheet:Dock(TOP)

        local bgpalette, btpalette = bgsheet:Add("DColorMixer"), bgsheet:Add("DColorMixer")
        Derma_Install_Convar_Functions(bgpalette)
        bgsheet:SetTall(math.max(options:GetWide() * 0.8, 240))
        bgsheet:DockMargin(0, 0, 0, options:GetWide() * 0.025)
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
        for k, v in ipairs(options:GetCanvas():GetChildren()) do
            -- v:SizeToContents()
            v:DockMargin(options:GetWide() * 0.05, 0, options:GetWide() * 0.05, options:GetWide() * 0.025)
            -- v:Dock(TOP)
        end
    end

    CreateOptionsMenu()

    function QuickName(name)
        local ref = rtable[name]
        return ref and language.GetPhrase(ref.PrintName) or name
    end

    local char = "[%c%s%p]"

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
                local button = GenerateLabel(qllist, v.name, "vgui/null", mainmenu)
                LoadoutSelector(button, i)
            end
            if !next(loadouts) then GenerateLabel(qllist, "No loadouts saved.") end
        end
    end

    function CreateWeaponButtons() -- it's a lot better now i think :)
        toptext:SetFont("quickloadout_font_medium")
        toptext:SetText("Current loadout")
        toptext:SetToggle(false)
        rcont:Hide()
        weplist:Clear()
        count = maxslots:GetBool() and maxslots:GetInt() or game.SinglePlayer() and 0 or 32
        -- count2 = slotlimit:GetBool() and slotlimit:GetInt() or 0

        for i, v in ipairs(ptable) do
            local button = GenerateLabel(weplist, QuickName(v), v, mainmenu)
            WepSelector(button, i, v)
        end
        local newwep = GenerateLabel(weplist, "+ Add Weapon", "vgui/null", mainmenu)
        WepSelector(newwep, #ptable + 1, nil)
        -- if sbut:GetToggle() then sbut:Toggle()
        -- elseif lbut:GetToggle() then lbut:Toggle() end
        lscroller:InvalidateChildren(true)
        weplist:InvalidateLayout(true)
        qllist:Hide()
        weplist:Show()
    end

    function CreatePreviewButtons(key)
        category1:Clear()
        count = maxslots:GetBool() and maxslots:GetInt() or game.SinglePlayer() and 0 or 32
        -- count2 = slotlimit:GetBool() and slotlimit:GetInt() or 0

        if loadouts[key] then
            for i, v in ipairs(loadouts[key].weps) do
                local button = GenerateLabel(category1, QuickName(v), v, mainmenu)
                WepSelector(button, i, v)
                button:SetIsToggle(false)
                button.DoClickInternal = function() end
                button.DoRightClick = button.DoClickInternal
            end
        else
            for i, v in ipairs(ptable) do
                local button = GenerateLabel(category1, QuickName(v), v, mainmenu)
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

    function PopulateCategory(parent, tbl, cont, cat, slot, noclear) -- good enough automated container refresh
        local cat1 = cat == category1
        if !noclear then
            cat:Clear()
            local cancel = GenerateLabel(cat, cat.Name, collapse, mainmenu)
            cancel.DoClickInternal = function(self)
                cat:Hide()
                self:SetToggle(true)
                parent:SetToggle(false)
                parent:GetParent():Show()
                wepimg = nil
                mainmenu.image.Text = nil
                mainmenu.image.WepData = {}
                mainmenu.theguy:SetWeapon("")
                -- if ptable[slot] and rtable[ptable[slot]] then
                --     local weapon = rtable[ptable[slot]]
                --     local icon = weapon.HudImage or weapon.Image
                --     if icon then
                --         wepimg = Material(icon, "smooth")
                --         local ratio = wepimg:Width() / wepimg:Height()
                --         image.ImageRatio = ratio - 1
                --     end
                --     if weapon.Stats then
                --         image.WepData = weapon.Stats
                --     end
                -- end
                if cat1 then buttonclicked = nil rcont:Hide() end
            end
        end
        local cancel = cat:GetChild(0).DoClickInternal
        local sublist = table.Copy(tbl)
        -- table.sort(sublist, ItemComparator)
        table.SortByMember(sublist, "name", true)
        for key, v in SortedPairs(sublist) do
            local button = GenerateLabel(cat, v.name, v.class or key, mainmenu)
            button.DoRightClick = cancel
            button:SizeToContentsY(fontsize)
            button:InvalidateLayout(true)
            local icon = math.max(scale * 8, 16)
            local catimage = Material(!cat1 and category2.Icon or list.Get("ContentCategoryIcons")[key] or "vgui/null", "mips")
            if !v.class then
                local wepcount, catcount = 0, 0
                local numbers, subseq = "", table.IsSequential(v)
                for sub, tab in pairs(v) do
                    if !subseq then
                        if sub != uncategorized then catcount = catcount + 1 end
                        wepcount = wepcount + table.Count(tab)
                    else
                        wepcount = wepcount + 1
                    end
                end
                if catcount == 0 and wepcount == 1 then
                    button:Remove()
                    button = GenerateLabel(cat, (v[uncategorized] or v)[1].name, (v[uncategorized] or v)[1].class, mainmenu)
                    button.DoRightClick = cancel
                    button:SizeToContentsY(fontsize)
                    button:InvalidateLayout(true)
                    button.LoneRider = {ShortenCategory(key), list.Get("ContentCategoryIcons")[key]}
                else
                    numbers = (catcount > 1 and catcount .. " categories, " or "") .. wepcount .. " weapon" .. (wepcount != 1 and "s" or "")
                    if key == uncategorized then
                        button:Remove()
                        PopulateCategory(parent, v, cont, cat, slot, true)
                        continue
                    end
                    -- PrintTable(tbl)
                    button.PaintOver = function(self, x, y)
                        local offset = math.min(x * 0.1, y * 0.5)
                        surface.SetDrawColor(color_default)
                        draw.SimpleText(numbers, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                        if catimage then
                            surface.SetDrawColor(color_default)
                            render.PushFilterMag(TEXFILTER.LINEAR)
                            render.PushFilterMin(TEXFILTER.LINEAR)
                            surface.SetMaterial(catimage)
                            surface.DrawTexturedRect(x - offset * 0.15 - icon, y - offset * 0.15 - icon, icon, icon)
                            render.PopFilterMag()
                            render.PopFilterMin()
                        end
                        if !cat1 and category2.Category then
                            draw.SimpleText(category2.Category, "quickloadout_font_small", x - offset * 0.125 - (category2.Icon and icon + offset * 0.25 or 0), y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                        end
                    end
                    button.DoClickInternal = function()
                        if cat1 then
                            category2.Icon = list.Get("ContentCategoryIcons")[key]
                            category2.Category = ShortenCategory(key)
                        end
                        PopulateCategory(button, v, cont, TheCats(cat), slot)
                        cat:Hide()
                    end
                    continue
                end
            end
            local keyname = (button.LoneRider and (v[uncategorized] or v)[1] or v).class
            local ref = rtable[keyname]
            local haswep = (table.HasValue(ptable, keyname) and !ptable[slot])
            local usable = !haswep and (ref.Spawnable or ref.AdminOnly and LocalPlayer():IsAdmin())
            -- local catimage = Material(ref and ref.Icon or "vgui/null", "mips")
            local wepimage = Material(ref and ref.Image or "vgui/null", "mips")
            local ratio = wepimage:Width() / wepimage:Height()
            local weptext, eqnum = ref.SubCategory and (ref.Rating and ref.Rating .. " " or "") .. ref.SubCategory, table.HasValue(ptable, keyname) and "#"..tostring(table.KeyFromValue(ptable, keyname))
            if eqnum and ptable[slot] and slot != tonumber(table.KeyFromValue(ptable, keyname)) then
                eqnum = eqnum .. " ↔ " .. "#"..slot
            end
            button.Paint = function(self, x, y)
                local offset = math.min(x * 0.1, y * 0.5)
                local active = button:IsHovered()
                surface.SetDrawColor(usable and (active and col_hl or col_but) or (active and col_bg or col_col))
                surface.DrawRect(0 , 0, x, y)
                surface.SetDrawColor(color_default)
                render.PushFilterMag(TEXFILTER.LINEAR)
                render.PushFilterMin(TEXFILTER.LINEAR)
                if ref.Image then
                    surface.SetMaterial(wepimage)
                    surface.DrawTexturedRect(x * 0.4, y * 0.5 - offset * 3.5 / ratio, offset * 8, offset * 8 / ratio)
                end
                if catimage then
                    surface.SetMaterial(catimage)
                    surface.DrawTexturedRect(x - offset * 0.15 - icon, y - offset * 0.15 - icon, icon, icon)
                end
                render.PopFilterMag()
                render.PopFilterMin()
            end
            button.PaintOver = function(self, x, y)
                local offset = math.min(x * 0.1, y * 0.5)
                surface.SetDrawColor(color_default)
                if cat1 and button.LoneRider then
                    draw.SimpleText(button.LoneRider[1], "quickloadout_font_small", x - offset * 0.125 - (button.LoneRider[2] and icon + offset * 0.25 or 0), y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                elseif !cat1 and category2.Category then
                    draw.SimpleText(category2.Category, "quickloadout_font_small", x - offset * 0.125 - (category2.Icon and icon + offset * 0.25 or 0), y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                end
                -- draw.SimpleText(cattext, "quickloadout_font_small", x - offset * 0.125 - (ref.Icon and icon + offset * 0.25 or 0), y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                if weptext then
                    draw.SimpleText(weptext, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
                end
                if eqnum then
                    surface.SetDrawColor(color_medium)
                    draw.SimpleText(eqnum, "quickloadout_font_small", x - offset * 0.125, offset * 0.0675, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, scale, bgcolor)
                end
            end
            button.DoClickInternal = function(self)
                if table.HasValue(ptable, keyname) then
                    if !ptable[slot] then self:SetToggle(true) return end
                    table.Merge(ptable, {[table.KeyFromValue(ptable, keyname)] = ptable[slot]}, true)
                end
                table.Merge(ptable, {[slot] = keyname}, true)
                cat:Clear()
                CreateWeaponButtons()
                RefreshLoadout(closer)
            end
        end
        cat:Show()
    end

    function LoadoutSelector(button, key)
        -- print(button, key)
        local wepcount = (loadouts[key] and #loadouts[key].weps or #ptable) .. " weapons"
        button:SizeToContentsY(fontsize)
        button.PaintOver = function(self, x, y)
            local offset = math.min(x * 0.1, y * 0.5)
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
                table.Merge(loadouts, {[key] = {name = text, weps = ptable}}, true)
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
                QLNotify(loadouts[key].name .. " equipped!", true)
                ptable = loadouts[key].weps
                RefreshLoadout()
                CloseMenu(true)
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
    
        local catimage = Material(ref and ref.Icon or "vgui/null", "mips")
        local wepimage = Material(ref and ref.Image or "vgui/null", "mips")
        local cattext, weptext
        local eqnum = "#"..index
        local w, h = wepimage:Width(), wepimage:Height()
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
            local offset = math.min(x * 0.1, y * 0.5)
            local active = button:IsHovered() or button:GetToggle()
            surface.SetDrawColor(unusable and (active and col_bg or col_col) or (active and col_hl or col_but))
            surface.DrawRect(0 , 0, x, y)
            surface.SetDrawColor(color_default)
            if ref then
                render.PushFilterMag(TEXFILTER.LINEAR)
                render.PushFilterMin(TEXFILTER.LINEAR)
                if ref.Image then
                    surface.SetMaterial(wepimage)
                    surface.DrawTexturedRect(x * 0.4, y * 0.5 - offset * 3.5 / ratio, offset * 8, offset * 8 / ratio)
                end
                if ref.Icon then
                    surface.SetMaterial(catimage)
                    surface.DrawTexturedRect(x - offset * 0.15 - icon, y - offset * 0.15 - icon, icon, icon)
                end
                render.PopFilterMag()
                render.PopFilterMin()
            end
            -- surface.SetDrawColor(color_light)
            -- draw.SimpleText(eqnum, "quickloadout_font_small", x - offset * 0.125, offset * 0.0675, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, scale, bgcolor)
        end
        button.PaintOver = function(self, x, y)
            local offset = math.min(x * 0.1, y * 0.5)
            surface.SetDrawColor(color_default)
            if ref then
                draw.SimpleText(cattext, "quickloadout_font_small", x - offset * 0.125 - (ref.Icon and icon + offset * 0.25 or 0), y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
            end
            if weptext then
                draw.SimpleText(weptext, "quickloadout_font_small", offset * 0.25, y - offset * 0.125, surface.GetDrawColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, scale, bgcolor)
            end
            if eqnum then
                surface.SetDrawColor(color_medium)
                draw.SimpleText(eqnum, "quickloadout_font_small", x - offset * 0.125, offset * 0.0675, surface.GetDrawColor(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, scale, bgcolor)
            end
        end
        button.DoClickInternal = function()
            if IsValid(modelpanel.Window) then modelpanel.Window:Remove() end
            rcont:Show()
            category1:Hide()
            category1:Clear()
            category2:Hide()
            category2:Clear()
            category3:Hide()
            category3:Clear()
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
        button:InvalidateLayout(true)
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
concommand.Add("quickloadout_reloadweapons", function() GenerateWeaponTable(true) end)
-- cvars.AddChangeCallback("quickloadout_weapons", NetworkLoadout)
-- cvars.AddChangeCallback("quickloadout_enable_client", NetworkLoadout)

hook.Add("OnPauseMenuShow", "CATQuickLoadoutClose", function()
    if escclose:GetBool() and open then return false end
end)

hook.Add("PopulateToolMenu", "CATQuickLoadoutSettings", function()
    spawnmenu.AddToolMenuOption("Options", "Chen's Addons", "QuickLoadoutSettings", "Quick Loadout", "", "", function(panel)
        local sv, cl = vgui.Create("DForm"), vgui.Create("DForm")
        local binds = vgui.Create("DForm")
        panel:AddItem(sv)
        panel:AddItem(cl)
        binds:SetName("Key bindings")
        sv:SetName("Server")
        sv:CheckBox("Enable quick loadouts", "quickloadout_enable")
        sv:ControlHelp("Globally enables quick loadout on server.")
        local default = sv:ComboBox("Give default loadout", "quickloadout_default")
        default:SetSortItems(false)
        default:AddChoice("User-defined", -1)
        default:AddChoice("Disabled", 0)
        default:AddChoice("Enabled", 1)
        sv:ControlHelp("Enable gamemode's default loadout.")
        sv:NumSlider("Primary clips", "quickloadout_giveclips_primary", -1, 100, 0)
        sv:NumSlider("Secondary clips", "quickloadout_giveclips_secondary", -1, 100, 0)
        sv:Help("How many clips worth of ammo each weapon in a loadout is given.\n-1 to not override weapon defaults. Secondary requires primary to be 0 or higher.")
        sv:NumSlider("Spawn grace time", "quickloadout_gracetime", 0, 60, 0)
        sv:ControlHelp("Time you have to change loadout after spawning. 0 is infinite.\n15 is recommended for PvP events, 0 for pure sandbox.")
        sv:NumSlider("Max weapon slots", "quickloadout_maxslots", 0, 32, 0)
        sv:ControlHelp("Amount of weapons players can have on spawn. Max 32, 0 is infinite.")
        sv:CheckBox("Shooting cancels grace", "quickloadout_gracetime_override")
        sv:ControlHelp("Whether pressing the attack button disables grace period.")
        sv:CheckBox("Apply model on loadout", "quickloadout_applymodel")
        sv:ControlHelp("Enables applying a new model on setting a loadout.")
        cl:SetName("Client")
        cl:CheckBox("Loadout reminder on spawn", "quickloadout_remind_client")
        cl:AddItem(binds)
        binds:Help("Loadout window key")
        -- panel:CheckBox(maxslots, "Max weapons on spawn")
        local binder = vgui.Create("DBinder", binds)
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
        binds:Help("Loadout change cancel key")
        -- panel:CheckBox(maxslots, "Max weapons on spawn")
        local canner = vgui.Create("DBinder", binds)
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
        binds:Help("Load menu toggle key")
        local loader = vgui.Create("DBinder", binds)
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
        binds:Help("Save menu toggle key")
        local saver = vgui.Create("DBinder", binds)
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
        binds:Help("Options menu toggle key")
        local opter = vgui.Create("DBinder", binds)
        -- binder:SetConVar("quickloadout_key")
        opter:DockMargin(60,10,60,10)
        opter:Dock(TOP)
        opter:CenterHorizontal()
        opter:SetText(string.upper(optbind:GetString() != "" and optbind:GetString() or "none"))
        opter.OnChange = function(self, key)
            timer.Simple(0, function()
                local t = input.GetKeyName(key)
                optbind:SetString(t or "")
                self:SetText(string.upper(t or "none"))
            end)
        end
        cl:ControlHelp("")
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