/*
    Thorne_fnc_mergeCoalitionVehicles

    Merges vehicle pools from all selected coalition factions
    into the NORMAL A3AU main faction.

    Only WEST / OCC and EAST / INV are supported.

    Infantry/groups/loadouts are NOT merged here.
    Rebels, Civilians and Rivals are NOT touched.
*/

params ["_side"];

if !(_side in [west, east]) exitWith {
    false
};

private _prefix = if (_side isEqualTo west) then {
    "occ"
} else {
    "inv"
};


// ------------------------------------------------------------
// Get normal/main AU faction
// ------------------------------------------------------------

private _mainFaction = missionNamespace getVariable [
    "A3A_faction_" + _prefix,
    createHashMap
];

if ((count _mainFaction) == 0) exitWith {

    diag_log format [
        "[Thorne Coalition Vehicles] ERROR no main faction found for prefix='%1'",
        _prefix
    ];

    false
};


// ------------------------------------------------------------
// Get loaded coalition factions
// ------------------------------------------------------------

if (isNil "Thorne_CoalitionFactions") exitWith {

    diag_log format [
        "[Thorne Coalition Vehicles] no coalition container for prefix='%1'",
        _prefix
    ];

    false
};

private _pool = Thorne_CoalitionFactions getOrDefault [
    _prefix,
    createHashMap
];

if ((count _pool) == 0) exitWith {

    diag_log format [
        "[Thorne Coalition Vehicles] no extra factions loaded for prefix='%1'",
        _prefix
    ];

    true
};


// ------------------------------------------------------------
// Vehicle arrays we want to combine
// ------------------------------------------------------------

private _arrayKeys = [

    // Ground
    "vehiclesBasic",
    "vehiclesLightUnarmed",
    "vehiclesLightArmed",
    "vehiclesTrucks",
    "vehiclesCargoTrucks",
    "vehiclesAmmoTrucks",
    "vehiclesRepairTrucks",
    "vehiclesFuelTrucks",
    "vehiclesMedical",

    // Armor
    "vehiclesLightAPCs",
    "vehiclesAPCs",
    "vehiclesIFVs",
    "vehiclesTanks",
    "vehiclesLightTanks",
    "vehiclesAA",
    "vehiclesArtillery",
    "vehiclesAirborne",

    // Boats
    "vehiclesTransportBoats",
    "vehiclesGunBoats",
    "vehiclesAmphibious",

    // Aircraft
    "vehiclesPlanesCAS",
    "vehiclesPlanesAA",
    "vehiclesPlanesTransport",

    "vehiclesHelisLight",
    "vehiclesHelisTransport",
    "vehiclesHelisLightAttack",
    "vehiclesHelisAttack",
    "vehiclesAirPatrol",

    // Special/common enemy pools
    "vehiclesMilitiaLightArmed",
    "vehiclesMilitiaCars",
    "vehiclesPolice",

    // Statics if defined as arrays
    "staticMGs",
    "staticAT",
    "staticAA",
    "staticMortars",

    // UAVs
    "uavsAttack",
    "uavsPortable"
];


// ------------------------------------------------------------
// Merge arrays
// ------------------------------------------------------------

{
    private _key = _x;

    private _merged = +(
        _mainFaction getOrDefault [
            _key,
            []
        ]
    );

    {
        private _tag = _x;
        private _coalitionFaction = _y;

        private _extra = _coalitionFaction getOrDefault [
            _key,
            []
        ];

        if (_extra isEqualType []) then {

            {
                _merged pushBackUnique _x;
            } forEach _extra;

        };

    } forEach _pool;

    _mainFaction set [
        _key,
        _merged
    ];

} forEach _arrayKeys;


// ------------------------------------------------------------
// Rebuild derived AU arrays
// ------------------------------------------------------------

private _lightArmedTroop =
    (_mainFaction getOrDefault [
        "vehiclesLightArmed",
        []
    ]) select {

        ([_x, true] call BIS_fnc_crewCount)
        -
        ([_x, false] call BIS_fnc_crewCount)
        >= 4

    };

_mainFaction set [
    "vehiclesLightArmedTroop",
    _lightArmedTroop
];


private _vehiclesArmor =
    (_mainFaction getOrDefault ["vehiclesTanks", []])
    +
    (_mainFaction getOrDefault ["vehiclesAA", []])
    +
    (_mainFaction getOrDefault ["vehiclesArtillery", []])
    +
    (_mainFaction getOrDefault ["vehiclesLightAPCs", []])
    +
    (_mainFaction getOrDefault ["vehiclesAPCs", []])
    +
    (_mainFaction getOrDefault ["vehiclesLightTanks", []])
    +
    (_mainFaction getOrDefault ["vehiclesAirborne", []])
    +
    (_mainFaction getOrDefault ["vehiclesIFVs", []]);

_vehiclesArmor = _vehiclesArmor arrayIntersect _vehiclesArmor;

_mainFaction set [
    "vehiclesArmor",
    _vehiclesArmor
];


// ------------------------------------------------------------
// Put modified faction back into mission namespace
// ------------------------------------------------------------

missionNamespace setVariable [
    "A3A_faction_" + _prefix,
    _mainFaction
];


diag_log format [
    "[Thorne Coalition Vehicles] merged coalition vehicles into '%1'. factions=%2 planesCAS=%3 helisAttack=%4 tanks=%5 lightArmed=%6",
    _prefix,
    keys _pool,
    count (_mainFaction getOrDefault ["vehiclesPlanesCAS", []]),
    count (_mainFaction getOrDefault ["vehiclesHelisAttack", []]),
    count (_mainFaction getOrDefault ["vehiclesTanks", []]),
    count (_mainFaction getOrDefault ["vehiclesLightArmed", []])
];

true