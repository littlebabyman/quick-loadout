AddCSLuaFile()
include("quickloadout/sh_cvars.lua")
if SERVER then
    include("quickloadout/sv_loadout.lua")
    AddCSLuaFile("quickloadout/cl_loadoutmenu.lua")
end
if CLIENT then
    include("quickloadout/cl_loadoutmenu.lua")
end