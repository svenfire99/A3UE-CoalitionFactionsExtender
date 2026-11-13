/* Prepare coalition extras from A3A_saveData before template loading. */
params [["_saveData", createHashMap, [createHashMap]]];

private _state = [_saveData] call Thorne_fnc_readSetupState;
missionNamespace setVariable ["Thorne_SetupState", _state];

private _enabled = _state getOrDefault ["coalitionEnabled", false];
private _slots = [
    ["occupants", "occ"],
    ["invaders", "inv"],
    ["rivals", "riv"]
];
private _net = [];

{
    _x params ["_key", "_prefix"];
    private _selected = +(_state getOrDefault [_key, []]);
    private _extras = if (_enabled && {count _selected > 1}) then { _selected select [1] } else { [] };
    private _entries = [];
    {
        private _cfg = configFile/"A3A"/"Templates"/_x;
        if !(isClass _cfg) then {
            diag_log format ["[A3UEThorne Coalition] missing template config '%1'", _x];
            continue;
        };
        private _base = getText (_cfg/"basepath");
        private _file = getText (_cfg/"file");
        if (_base == "" || {_file == ""}) then { continue };
        _entries pushBack [_x, _base + "\" + _file + ".sqf"];
    } forEach _extras;
    _net pushBack _entries;
} forEach _slots;

missionNamespace setVariable ["Thorne_CoalitionEnabledNet", _enabled, true];
missionNamespace setVariable ["Thorne_CoalitionConfigNet", _net, true];

Thorne_CoalitionConfig = createHashMapFromArray [
    ["occ", _net param [0, []]],
    ["inv", _net param [1, []]],
    ["riv", _net param [2, []]]
];

_enabled
