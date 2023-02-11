AddCSLuaFile()
CreateConVar("quickloadout_enable", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Enable Quick Loadout.", 0, 1)
CreateConVar("quickloadout_override", 0, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Override default loadout.", 0, 1)
CreateConVar("quickloadout_maxslots", 5, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Max weapon slots in a loadout.", 0, 32)
CreateConVar("quickloadout_switchtime", 15, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Grace period length to switch loadout after spawn.", 0)
CreateConVar("quickloadout_switchtime_override", 0, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Force grace period off on pressing primary attack.", 0, 1)

if CLIENT then
    CreateClientConVar("quickloadout_weapons", "", true, true, "Quick loadout weapon classes.")
    CreateClientConVar("quickloadout_key", "n", true, false, "Quick loadout keybind.")
end