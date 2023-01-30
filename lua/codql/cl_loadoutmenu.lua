AddCSLuaFile()

function QLOpenMenu()
    local mainmenu = vgui.Create("DFrame")
    mainmenu:SetPos(ScrW() / 2-320, ScrH() / 2-240)
    mainmenu:SetSize(640, 480)
    mainmenu:SetTitle("Loadout")
    mainmenu:SetVisible(true)
    mainmenu:SetDraggable(false)
    mainmenu:ShowCloseButton(true)
    mainmenu:MakePopup()
    local category = vgui.Create("DScrollPanel", mainmenu)
    local catbar = category:GetVBar():GetWide()
    category:SetWidth(200)
    category:Dock(2)
    local subcat = vgui.Create("DScrollPanel", mainmenu)
    local subcatbar = subcat:GetVBar():GetWide()
    subcat:SetWidth(200)
    subcat:Dock(2)
    local wtable = {}
    -- PrintTable(wtable)
    for k, v in SortedPairs(list.Get( "Weapon" )) do
        if v.Spawnable then
            if !wtable[v.Category] then
                wtable[v.Category] = {}
            end
            table.Add(wtable[v.Category], {[v] = v.ClassName})
        end
    end
    PrintTable(wtable)
    print("Table printed!")
    local offset = 0
    for k, _ in SortedPairs(wtable) do
        local button = vgui.Create("DButton", category)
        button:SetText(k)
        button:SetWidth(category:GetWide() - catbar - 1)
        button:SetHeight(20)
        button:SetPos(0, offset)
        offset = offset + 21
        button.DoClick = function()
            for i, v in SortedPairs(wtable[k]) do
                local subbutton = vgui.Create("DButton", subcat)
                subbutton:SetText(v)
                subbutton:SetWidth(subcat:GetWide() - subcatbar - 1)
                subbutton:SetHeight(20)
                subbutton:SetPos(0, offset)
                offset = offset + 21
                subbutton.DoClick = function()
                end
            end
        end
    end
    PrintTable(wtable)
    print("Table printed!")
end