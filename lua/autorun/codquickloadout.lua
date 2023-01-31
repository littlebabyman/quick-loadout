include("codql/sh_cvars.lua")
if SERVER then
    include("codql/sv_loadout.lua")
end
if CLIENT then
    include("codql/cl_loadoutmenu.lua")
end