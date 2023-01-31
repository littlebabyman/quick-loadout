AddCSLuaFile()
CreateConVar("codql_enable", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Enable Quick Loadout.", 0, 1)
CreateConVar("codql_override", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Override default loadout.", 0, 1)
CreateConVar("codql_maxslots", 5, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Max weapon slots in a loadout.", 0, 8^8)