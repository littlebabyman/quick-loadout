AddCSLuaFile()
CreateConVar("quickloadout_enable", 1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Enable Quick Loadout.", 0, 1)
CreateConVar("quickloadout_default", -1, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Enable default loadout.", -1, 1)
CreateConVar("quickloadout_slotlimit", 0, {FCVAR_ARCHIVE + FCVAR_REPLICATED}, "Max weapons per slot in a loadout. Currently nonfunctional.", 0, 32)
CreateConVar("quickloadout_maxslots", 10, {FCVAR_ARCHIVE + FCVAR_REPLICATED}, "Max weapon slots in a loadout.", 0, 32)
CreateConVar("quickloadout_gracetime", 0, {FCVAR_ARCHIVE + FCVAR_REPLICATED}, "Grace period length (in seconds) to switch loadout after spawn.", 0)
CreateConVar("quickloadout_giveclips_primary", -1, {FCVAR_ARCHIVE + FCVAR_REPLICATED}, "Amount of clips worth of primary ammo a weapon gets upon applying a loadout. -1 uses weapon default instead.", -1)
CreateConVar("quickloadout_giveclips_secondary", -1, {FCVAR_ARCHIVE + FCVAR_REPLICATED}, "Amount of clips worth of secondary ammo a weapon gets upon applying a loadout. -1 uses weapon default instead.", -1)
CreateConVar("quickloadout_gracetime_override", 0, {FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY}, "Force grace period off on pressing primary attack.", 0, 1)

if CLIENT then
    CreateClientConVar("quickloadout_enable_client", 1, true, true, "Enable quick loadout sending.", 0, 1)
    CreateClientConVar("quickloadout_default_client", 1, true, true, "Request default loadout upon sending it.", 0, 1)
    CreateClientConVar("quickloadout_remind_client", 1, true, true, "Show reminder to press a keybind to edit your loadout.", 0, 1)
    CreateClientConVar("quickloadout_weapons", "", true, true, "Quick loadout weapon classes. Nonfunctional, only exists to bring 'old' autosaved loadout to new system.")
    CreateClientConVar("quickloadout_key", "n", true, false, "Quick loadout keybind.")
    CreateClientConVar("quickloadout_key_load", "m", true, false, "Quick loadout loadmenu keybind.")
    CreateClientConVar("quickloadout_menu_model", "b", true, false, "Quickly open the player model menu.")
    CreateClientConVar("quickloadout_menu_cancel", "c", true, false, "Cancel and discard all changes and close the menu.")
    CreateClientConVar("quickloadout_menu_save", "q", true, false, "Quickly switch to save menu.")
    CreateClientConVar("quickloadout_menu_load", "e", true, false, "Quickly switch to load menu.")
    CreateClientConVar("quickloadout_menu_options", "o", true, false, "Quickly switch to options menu.")
    CreateClientConVar("quickloadout_showcharacter", 1, true, false, "Show your player character on the menu.")
    CreateClientConVar("quickloadout_showcategory", 1, true, false, "Show weapon categories on weapon buttons.")
    CreateClientConVar("quickloadout_showsubcategory", 1, true, false, "Show weapon subcategories on weapon buttons.")
    CreateClientConVar("quickloadout_showslot", 1, true, false, "Show weapon slot on weapon buttons.")
    CreateClientConVar("quickloadout_ui_blur", 1, true, false, "Enable blur in the loadout menu.")
    CreateClientConVar("quickloadout_ui_fonts", "Bahnschrift Bold, Bahnschrift SemiCondensed", true, false, "Fonts used in the loadout menu. Separate two with \",\" to use a different font for small text.")
    CreateClientConVar("quickloadout_ui_font_scale", 1, true, false, "Overall scale of the fonts.", 0.5, 2)
    CreateClientConVar("quickloadout_ui_color_bg", "0 0 0", true, false, "Base color used for loadout menu background.")
    CreateClientConVar("quickloadout_ui_color_button", "96 128 192", true, false, "Base color used for loadout menu buttons.")
end