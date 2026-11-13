/*
    Read A3UEThorne setup state from an AU selector/start HashMap.

    New format (the only format written):
      saveDataPlugins["A3UEThorne_Setup"] = HashMap

    Legacy top-level/plugin formats are read only for migration.
*/
params [
    ["_saveData", createHashMap, [createHashMap]]
];

private _baseFactions = _saveData getOrDefault ["factions", ["", "", "", "", ""]];
if !(_baseFactions isEqualType []) then { _baseFactions = ["", "", "", "", ""] };
while {count _baseFactions < 5} do { _baseFactions pushBack "" };

private _withPrimary = {
    params ["_primary", "_items"];
    private _out = [];
    if (_primary isEqualType "" && {_primary != ""}) then { _out pushBackUnique _primary };
    {
        private _name = "";
        if (_x isEqualType "") then { _name = _x };
        if (_x isEqualType [] && {count _x > 0}) then { _name = _x#0 };
        if (_name != "") then { _out pushBackUnique _name };
    } forEach _items;
    _out
};

private _state = createHashMapFromArray [
    ["version", 2],
    ["coalitionEnabled", false],
    ["occupants", [_baseFactions#0, []] call _withPrimary],
    ["invaders", [_baseFactions#1, []] call _withPrimary],
    ["rivals", [_baseFactions#4, []] call _withPrimary],
    ["switchEnemySides", false],
    ["overrideSideLimits", false],
    ["overrideCamoLimits", false]
];

private _plugins = _saveData getOrDefault ["saveDataPlugins", createHashMap];
if (_plugins isEqualType []) then { _plugins = createHashMapFromArray _plugins };
if !(_plugins isEqualType createHashMap) then { _plugins = createHashMap };

// Current clean format.
private _current = _plugins getOrDefault ["A3UEThorne_Setup", createHashMap];
if (_current isEqualType createHashMap && {count _current > 0}) exitWith {
    private _result = createHashMapFromArray [
        ["version", 2],
        ["coalitionEnabled", _current getOrDefault ["coalitionEnabled", false]],
        ["occupants", [_baseFactions#0, _current getOrDefault ["occupants", []]] call _withPrimary],
        ["invaders", [_baseFactions#1, _current getOrDefault ["invaders", []]] call _withPrimary],
        ["rivals", [_baseFactions#4, _current getOrDefault ["rivals", []]] call _withPrimary],
        ["switchEnemySides", _current getOrDefault ["switchEnemySides", false]],
        ["overrideSideLimits", _current getOrDefault ["overrideSideLimits", false]],
        ["overrideCamoLimits", _current getOrDefault ["overrideCamoLimits", false]]
    ];
    _result
};

// Transitional v2 plugin format from the 12.4 rebase attempts.
private _oldPlugin = _plugins getOrDefault ["A3UEThorne_Coalition", createHashMap];
if (_oldPlugin isEqualType createHashMap && {count _oldPlugin > 0}) exitWith {
    _state set ["coalitionEnabled", _oldPlugin getOrDefault ["enabled", false]];
    _state set ["occupants", [_baseFactions#0, _oldPlugin getOrDefault ["occ", []]] call _withPrimary];
    _state set ["invaders", [_baseFactions#1, _oldPlugin getOrDefault ["inv", []]] call _withPrimary];
    _state set ["rivals", [_baseFactions#4, _oldPlugin getOrDefault ["riv", []]] call _withPrimary];
    _state
};

// Original extender top-level keys (read-only migration).
private _legacyEnabled = _saveData getOrDefault [
    "Thorne_coalitionEnabled",
    _saveData getOrDefault ["Thorne_CoalitionEnabled", false]
];
private _legacyConfig = _saveData getOrDefault [
    "Thorne_coalitionConfig",
    _saveData getOrDefault ["Thorne_CoalitionConfig", [[], [], []]]
];
if !(_legacyConfig isEqualType []) then { _legacyConfig = [[], [], []] };

if (_legacyEnabled || {_legacyConfig isNotEqualTo [[], [], []]}) then {
    _state set ["coalitionEnabled", _legacyEnabled];
    _state set ["occupants", [_baseFactions#0, _legacyConfig param [0, []]] call _withPrimary];
    _state set ["invaders", [_baseFactions#1, _legacyConfig param [1, []]] call _withPrimary];
    _state set ["rivals", [_baseFactions#4, _legacyConfig param [2, []]] call _withPrimary];
};

private _mask = _saveData getOrDefault [
    "Thorne_factionOverrideMask",
    _saveData getOrDefault ["Thorne_FactionOverrideMask", 0]
];
if (_mask isEqualType 0) then {
    _state set ["switchEnemySides", (_mask mod 2) >= 1];
    _state set ["overrideSideLimits", (floor (_mask / 2) mod 2) >= 1];
    _state set ["overrideCamoLimits", (floor (_mask / 4) mod 2) >= 1];
};

_state
