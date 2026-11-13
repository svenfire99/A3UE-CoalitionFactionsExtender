Thorne_CoalitionConfig = createHashMapFromArray [["occ", []], ["inv", []], ["riv", []]];
Thorne_CoalitionFactions = createHashMapFromArray [["occ", createHashMap], ["inv", createHashMap], ["riv", createHashMap]];
Thorne_CoalitionTypeFactionMap = createHashMap;
Thorne_SetupState = createHashMapFromArray [
    ["version", 2], ["coalitionEnabled", false],
    ["occupants", []], ["invaders", []], ["rivals", []],
    ["switchEnemySides", false], ["overrideSideLimits", false], ["overrideCamoLimits", false]
];

if (isServer && {!(missionNamespace getVariable ["Thorne_CoalitionEventsRegistered", false])}) then {
    missionNamespace setVariable ["Thorne_CoalitionEventsRegistered", true];

    ["A3A_event_serverGameSave", {
        params [["_pluginData", createHashMap, [createHashMap]]];
        _pluginData set [
            "A3UEThorne_Setup",
            missionNamespace getVariable ["Thorne_SetupState", createHashMap]
        ];
    }] call A3A_fnc_addEventHandler;

    ["A3A_event_serverGameLoad", {
        params [["_pluginData", createHashMap, [createHashMap]]];
        private _state = _pluginData getOrDefault ["A3UEThorne_Setup", createHashMap];
        if (_state isEqualType createHashMap && {count _state > 0}) then {
            missionNamespace setVariable ["Thorne_SetupState", _state];
        };
    }] call A3A_fnc_addEventHandler;
};

diag_log "[A3UEThorne Coalition] clean 12.4.1 runtime initialized";
