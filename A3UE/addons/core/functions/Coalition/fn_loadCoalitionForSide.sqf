/*
    Reads the selection published by the setup GUI.

    Only:
        WEST -> occ
        EAST -> inv

    Rebels, civilians and rivals are intentionally ignored.
*/
params ["_side"];

if !(_side in [west, east]) exitWith { false };

private _prefix =
    if (_side isEqualTo west) then { "occ" } else { "inv" };

private _netConfig = missionNamespace getVariable [
    "Thorne_CoalitionConfigNet",
    [[], []]
];

if !(_netConfig isEqualType [] && {count _netConfig >= 2}) then {
    diag_log format [
        "[Thorne Coalition] WARNING invalid network config: %1",
        _netConfig
    ];
    _netConfig = [[], []];
};

Thorne_CoalitionConfig set [
    "occ",
    _netConfig # 0
];

Thorne_CoalitionConfig set [
    "inv",
    _netConfig # 1
];

private _entries =
    Thorne_CoalitionConfig getOrDefault [_prefix, []];

diag_log format [
    "[Thorne Coalition] selected extras for %1 = %2",
    _prefix,
    _entries
];

{
    _x params [
        "_tag",
        "_file"
    ];

    [
        _side,
        _prefix,
        _tag,
        _file
    ] call Thorne_fnc_loadCoalitionFaction;

} forEach _entries;


// ------------------------------------------------------------
// Merge all vehicle pools into AU's normal faction
// ------------------------------------------------------------

if (_entries isNotEqualTo []) then {

    [_side] call Thorne_fnc_mergeCoalitionVehicles;

};


true