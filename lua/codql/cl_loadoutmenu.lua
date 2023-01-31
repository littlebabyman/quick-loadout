AddCSLuaFile()
CreateClientConVar("codql_weapons", "", true, true, "Quick loadout weapon classes.")
local weaponlist = GetConVar("codql_weapons")

function QLOpenMenu()
    local mainmenu = vgui.Create("DFrame")
    mainmenu:SetPos(ScrW() / 2-320, ScrH() / 2-240)
    mainmenu:SetSize(640, 480)
    mainmenu:SetTitle("Loadout")
    mainmenu:SetVisible(true)
    mainmenu:SetDraggable(false)
    mainmenu:ShowCloseButton(true)
    mainmenu:MakePopup()
    local weplist = vgui.Create("DScrollPanel", mainmenu)
    local weplistbar = weplist:GetVBar():GetWide()
    weplist:SetWidth(200)
    weplist:Dock(2)
    local category = vgui.Create("DScrollPanel", mainmenu)
    local catbar = category:GetVBar():GetWide()
    category:SetWidth(200)
    category:Dock(2)
    local subcat = vgui.Create("DScrollPanel", mainmenu)
    local subcatbar = subcat:GetVBar():GetWide()
    subcat:SetWidth(200)
    subcat:Dock(2)
    local ptable = string.Explode(" ", GetConVar("codql_weapons"):GetString())
    PrintTable(ptable)
    local wtable = {}
    for k, v in SortedPairs(list.Get( "Weapon" )) do
        if v.Spawnable then
            if !wtable[v.Category] then
                wtable[v.Category] = {}
            end
            table.Merge(wtable[v.Category], {[v.ClassName] = v.PrintName or v.ClassName})
        end
    end
    -- PrintTable(wtable)
    -- print("Table printed!")
    local offset = 0
    local function WepSelector(index, wep)
        local weapon = vgui.Create("DButton", weplist)
        weapon:SetWrap(true)
        weapon:SetText(wep or "Add Weapon")
        weapon:SetWidth(category:GetWide() - weplistbar - 1)
        weapon:SetHeight(20)
        weapon:SetPos(0, offset)
        offset = offset + weapon:GetTall()
        weapon.DoClick = function()
            offset = 0
            for k, _ in SortedPairs(wtable) do
                local button = vgui.Create("DButton", category)
                button:SetWrap(true)
                button:SetText(k)
                button:SetWidth(category:GetWide() - catbar - 1)
                button:SetHeight(20)
                button:SetPos(0, offset)
                offset = offset + button:GetTall()
                button.DoClick = function()
                    offset = 0
                    for i, v in SortedPairs(wtable[k]) do
                        local subbutton = vgui.Create("DButton", subcat)
                        subbutton:SetWrap(true)
                        subbutton:SetText(v)
                        subbutton:SetWidth(subcat:GetWide() - subcatbar - 1)
                        subbutton:SetHeight(20)
                        subbutton:SetPos(0, offset)
                        offset = offset + subbutton:GetTall()
                        subbutton.DoClick = function()
                            table.Merge(ptable, {[index] = i})
                            weapon:SetText(v .. " (" .. k .. ")")
                            PrintTable(ptable)
                        end
                    end
                end
            end
        end
        if !IsValid(wep) then
            weapon.DoRightClick = function()
                table.remove(ptable, index)
                weapon:Remove()
            end
        end
    end
    for i, v in ipairs(ptable) do
        WepSelector(i, v)
    end
    WepSelector(#ptable + 1, "Add Weapon")
    mainmenu.OnClose = function()
        print(table.concat(ptable," "))
        weaponlist:SetString(table.concat(ptable, " "))
    end
end