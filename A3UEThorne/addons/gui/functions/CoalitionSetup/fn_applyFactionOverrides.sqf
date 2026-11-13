/*
    Applies saved faction setup overrides before AU rebuilds faction lists.

    Layout:
        0 Switch enemy sides
        1 Override side limits
        2 Override camo limits
*/
#include "\x\A3A\addons\gui\dialogues\ids.inc"

params [
    ["_display", displayNull, [displayNull]],
    ["_state", [false, false, false], [[]]]
];

if (isNull _display) exitWith { false };

if (count _state < 3) then {
    _state = [false, false, false];
};

(_display displayCtrl A3A_IDC_SETUP_SWITCHENEMYCHECK)
    cbSetChecked (_state # 0);

(_display displayCtrl A3A_IDC_SETUP_ANYENEMYCHECK)
    cbSetChecked (_state # 1);

(_display displayCtrl A3A_IDC_SETUP_IGNORECAMOCHECK)
    cbSetChecked (_state # 2);

true
