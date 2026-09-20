/*
    Thorne_fnc_loadCoalitionFaction

    Parameters:
        0: SIDE   - west / east
        1: STRING - "occ" / "inv"
        2: STRING - coalition tag, e.g. "BAF"
        3: STRING - template file
*/

params [
    ["_side", sideUnknown, [west]],
    ["_prefix", "", [""]],
    ["_tag", "", [""]],
    ["_file", "", [""]]
];

diag_log format [
    "[Thorne Coalition] loadCoalitionFaction PARAMS side=%1 prefix='%2' tag='%3' file='%4'",
    _side,
    _prefix,
    _tag,
    _file
];


// -------------------------------------------------------------------------
// Validation
// -------------------------------------------------------------------------

if !(_side in [west, east]) exitWith {
    diag_log format [
        "[Thorne Coalition] ERROR invalid side: %1",
        _side
    ];

    false
};

if !(_prefix in ["occ", "inv"]) exitWith {
    diag_log format [
        "[Thorne Coalition] ERROR invalid prefix: '%1'",
        _prefix
    ];

    false
};

if (_tag isEqualTo "") exitWith {
    diag_log "[Thorne Coalition] ERROR empty faction tag";
    false
};

if (_file isEqualTo "") exitWith {
    diag_log format [
        "[Thorne Coalition] ERROR empty faction file for tag='%1'",
        _tag
    ];

    false
};


// -------------------------------------------------------------------------
// Default faction
// -------------------------------------------------------------------------

private _defaultFile =
    "\x\A3A\addons\core\Templates\Templates\FactionDefaults\EnemyDefaults.sqf";

diag_log format [
    "[Thorne Coalition] loading raw faction tag='%1' defaults='%2' faction='%3'",
    _tag,
    _defaultFile,
    _file
];


// -------------------------------------------------------------------------
// Load normal AU faction
// -------------------------------------------------------------------------

private _faction = [
    [
        _defaultFile,
        _file
    ]
] call A3A_fnc_loadFaction;


if (isNil "_faction") exitWith {
    diag_log format [
        "[Thorne Coalition] ERROR loadFaction returned nil tag='%1'",
        _tag
    ];

    false
};


if !(_faction isEqualType createHashMap) exitWith {
    diag_log format [
        "[Thorne Coalition] ERROR loadFaction returned invalid type tag='%1': %2",
        _tag,
        _faction
    ];

    false
};


// -------------------------------------------------------------------------
// Read loadouts
// -------------------------------------------------------------------------

private _allDefinitions = _faction getOrDefault [
    "loadouts",
    createHashMap
];

diag_log format [
    "[Thorne Coalition] faction parsed tag='%1' name='%2' loadouts=%3",
    _tag,
    _faction getOrDefault ["name", "UNKNOWN"],
    count _allDefinitions
];

if ((count _allDefinitions) == 0) exitWith {
    diag_log format [
        "[Thorne Coalition] ERROR faction '%1' has no loadouts",
        _tag
    ];

    false
};


// -------------------------------------------------------------------------
// Compile faction groups
//
// IMPORTANT:
// Do NOT use "occ" directly because that would overwrite the main faction.
// Give every coalition faction its own prefix.
// -------------------------------------------------------------------------

private _coalitionPrefix = format [
    "%1_%2",
    _prefix,
    _tag
];

[
    _faction,
    _coalitionPrefix
] call A3A_fnc_compileGroups;


// -------------------------------------------------------------------------
// Register custom unit types
// -------------------------------------------------------------------------

private _unitClassMap = _side call SCRT_fnc_unit_getUnitMap;

private _baseUnitClass = if (_side isEqualTo west) then {
    "a3a_unit_west"
} else {
    "a3a_unit_east"
};

private _registeredNames = createHashMap;

{
    private _loadoutName = _x;
    private _definition = _y;

    private _unitClass = _unitClassMap getOrDefault [
        _loadoutName,
        _baseUnitClass
    ];

    /*
        Standard AU:
            loadouts_occ_military_Rifleman

        Coalition:
            loadouts_occ_BAF_military_Rifleman
    */

    private _globalName = format [
        "loadouts_%1_%2_%3",
        _prefix,
        _tag,
        _loadoutName
    ];

    [
        _globalName,
        _definition + [_unitClass]
    ] call A3A_fnc_registerUnitType;

    /*
        Map the original AU classname to our coalition classname.

        military_Rifleman
              ->
        loadouts_occ_BAF_military_Rifleman
    */

    _registeredNames set [
        format [
            "loadouts_%1_%2",
            _prefix,
            _loadoutName
        ],
        _globalName
    ];

} forEach _allDefinitions;


// -------------------------------------------------------------------------
// Attach resolution map to faction
// -------------------------------------------------------------------------

_faction set [
    "Thorne_CoalitionUnitMap",
    _registeredNames
];

_faction set [
    "Thorne_CoalitionTag",
    _tag
];

_faction set [
    "Thorne_CoalitionPrefix",
    _prefix
];


// -------------------------------------------------------------------------
// Store faction
// -------------------------------------------------------------------------

if (isNil "Thorne_CoalitionFactions") then {

    Thorne_CoalitionFactions = createHashMapFromArray [
        ["occ", createHashMap],
        ["inv", createHashMap]
    ];

};

private _sidePool = Thorne_CoalitionFactions getOrDefault [
    _prefix,
    createHashMap
];

_sidePool set [
    _tag,
    _faction
];

Thorne_CoalitionFactions set [
    _prefix,
    _sidePool
];


diag_log format [
    "[Thorne Coalition] LOADED tag='%1' prefix='%2' name='%3' units=%4 coalitionPool=%5",
    _tag,
    _prefix,
    _faction getOrDefault ["name", "UNKNOWN"],
    count _registeredNames,
    keys _sidePool
];

true