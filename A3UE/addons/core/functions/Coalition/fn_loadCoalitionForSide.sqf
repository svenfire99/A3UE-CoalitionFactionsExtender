/*
    Loads all configured extras for one coalition slot.

    Supported selectors:
        west  -> occ
        east  -> inv
        "occ"
        "inv"
        "riv"

    Current two-slot GUI remains valid:
        [OCC, INV]

    Rival-aware GUI later supplies:
        [OCC, INV, RIV]
*/

params ["_selector"];

if (isNil "Thorne_CoalitionConfig") then {
    call Thorne_fnc_initCoalition;
};

private _prefix = "";

if (_selector isEqualType "") then {
    if (_selector in ["occ", "inv", "riv"]) then {
        _prefix = _selector;
    };
} else {
    if (_selector isEqualTo Occupants) then {
        _prefix = "occ";
    };

    if (_selector isEqualTo Invaders) then {
        _prefix = "inv";
    };
};

if (_prefix == "") exitWith {
    diag_log format [
        "[Thorne Coalition] WARNING loadCoalitionForSide unsupported selector=%1",
        _selector
    ];
    false
};

private _netConfig = missionNamespace getVariable [
    "Thorne_CoalitionConfigNet",
    [[], [], []]
];

if !(_netConfig isEqualType []) then {
    diag_log format [
        "[Thorne Coalition] WARNING invalid network config type: %1",
        _netConfig
    ];
    _netConfig = [[], [], []];
};

// Backward compatibility with existing [OCC, INV] data.
private _occ = _netConfig param [0, []];
private _inv = _netConfig param [1, []];
private _riv = _netConfig param [2, []];

Thorne_CoalitionConfig set ["occ", _occ];
Thorne_CoalitionConfig set ["inv", _inv];
Thorne_CoalitionConfig set ["riv", _riv];

// Reset this slot when a campaign is restarted without restarting Arma.
Thorne_CoalitionFactions set [
    _prefix,
    createHashMap
];

private _entries = Thorne_CoalitionConfig getOrDefault [
    _prefix,
    []
];

diag_log format [
    "[Thorne Coalition] selected extras for %1 = %2",
    _prefix,
    _entries
];

private _loadSide = switch (_prefix) do {
    case "occ": { Occupants };
    case "inv": { Invaders };
    // A3AU's Rival loader verifies/registers against EAST/OPFOR classes.
    case "riv": { east };
    default { sideUnknown };
};

{
    if (_x isEqualType [] && {count _x >= 2}) then {
        _x params [
            "_tag",
            "_file"
        ];

        [
            _loadSide,
            _prefix,
            _tag,
            _file
        ] call Thorne_fnc_loadCoalitionFaction;
    } else {
        diag_log format [
            "[Thorne Coalition] WARNING malformed %1 coalition entry: %2",
            _prefix,
            _x
        ];
    };
} forEach _entries;

// Merge vehicle categories only after all extras are loaded.
if (_entries isNotEqualTo []) then {
    [_prefix] call Thorne_fnc_mergeCoalitionVehicles;
};

true
