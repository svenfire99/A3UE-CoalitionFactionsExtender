/*
    Returns A3UE-persisted faction setup overrides.

    Layout:
        0 Switch enemy sides
        1 Override side limits
        2 Override camo limits

    "Show missing mods" is intentionally not persisted.
*/
#include "\x\A3A\addons\gui\dialogues\ids.inc"

params [
    ["_display", displayNull, [displayNull]]
];

if (isNull _display) exitWith {
    [false, false, false]
};

[
    cbChecked (_display displayCtrl A3A_IDC_SETUP_SWITCHENEMYCHECK),
    cbChecked (_display displayCtrl A3A_IDC_SETUP_ANYENEMYCHECK),
    cbChecked (_display displayCtrl A3A_IDC_SETUP_IGNORECAMOCHECK)
]
