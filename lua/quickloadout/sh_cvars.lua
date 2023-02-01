AddCSLuaFile()
CreateConVar("quickloadout_enable", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Enable Quick Loadout.", 0, 1)
CreateConVar("quickloadout_override", 0, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Override default loadout.", 0, 1)
CreateConVar("quickloadout_maxslots", 5, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Max weapon slots in a loadout.", 0, 8^8)
if CLIENT then
    CreateClientConVar("quickloadout_weapons", "", true, true, "Quick loadout weapon classes.")
end