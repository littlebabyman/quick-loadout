AddCSLuaFile()
CreateClientConVar("codql_weapons", "", true, true, "Quick loadout weapon classes.")
local weaponlist = GetConVar("codql_weapons")

local function GenerateButton(frame, i, v, off)
    local button = vgui.Create("DButton", frame, v)
    local text = v or "ASS"
    button:SetWrap(true)
    button:SetText(text)
    button:SetWidth(frame:GetWide() - frame:GetVBar():GetWide() - 1)
    button:SetHeight(20)
    button:SetPos(0, off)
    return button, v
end

local function GenerateCategory(frame)
    local category = vgui.Create("DScrollPanel", frame)
    category:SetWidth(200)
    category:Dock(2)
    return category
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
    local ptable = string.Explode(" ", GetConVar("codql_weapons"):GetString())
    PrintTable(ptable)
    local wtable = {}
    for k, v in SortedPairs(list.Get( "Weapon" )) do
        if v.Spawnable and (!v.AdminOnly or LocalPlayer():IsSuperAdmin()) then
            if !wtable[v.Category] then
                wtable[v.Category] = {}
            end
            table.Merge(wtable[v.Category], {[v.ClassName] = v.PrintName or v.ClassName})
        end
    end
    -- PrintTable(wtable)
    -- print("Table printed!")
    local offset = 0
    local function WepSelector(index, wep, frame)
        print(wep)
        slot, weapon = GenerateButton(weplist, index, wep, offset)
        print(slot, weapon)
        offset = offset + slot:GetTall()
        slot.DoClick = function()
            offset = 0
            if IsValid(subcat) then subcat:Remove() end
            if IsValid(category) then category:Remove() end
            category = GenerateCategory(frame)
            for k, _ in SortedPairs(wtable) do
                button = GenerateButton(category, index, k, offset)
                offset = offset + button:GetTall()
                button.DoClick = function()
                    offset = 0
                    if IsValid(subcat) then subcat:Remove() end
                    subcat = GenerateCategory(frame)
                    for i, v in SortedPairs(wtable[k]) do
                        subbutton = GenerateButton(subcat, index, v, offset)
                        offset = offset + subbutton:GetTall()
                        subbutton.DoClick = function()
                            table.Merge(ptable, {[index] = i})
                            slot:SetText(v .. " (" .. k .. ")")
                            -- PrintTable(ptable)
                            subcat:Remove()
                            category:Remove()
                        end
                    end
                end
            end
        end
        slot.DoRightClick = function()
            if table.HasValue(ptable, wep) then
                table.remove(ptable, index)
                slot:Remove()
            end
        end
    end
    weplist = GenerateCategory(mainmenu)
    for i, v in ipairs(ptable) do
        WepSelector(i, v, mainmenu)
    end
    WepSelector(#ptable + 1, "Add Weapon", mainmenu)
    mainmenu.OnClose = function()
        print(table.concat(ptable," "))
        weaponlist:SetString(table.concat(ptable, " "))
    end
end