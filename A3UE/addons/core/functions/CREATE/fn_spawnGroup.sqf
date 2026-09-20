/*
    Thorne Coalition override of A3A_fnc_spawnGroup

    Behaviour:
    - WEST and EAST can use coalition factions.
    - One faction is selected PER GROUP.
    - The original/main A3AU faction is also part of the random pool.
    - GUER/CIV/Rivals are left completely untouched.
    - If the selected coalition faction cannot provide the entire group,
      the normal A3AU faction is used instead.
*/

#include "..\..\script_component.hpp"

params [
    "_positionX",
    "_sideX",
    "_typesX"
];

private _groupX = createGroup _sideX;


// ========================================================================
// Coalition selection
// ========================================================================

private _prefix = switch (_sideX) do {
    case west: { "occ" };
    case east: { "inv" };
    default { "" };
};

private _selectedTag = "";
private _resolvedTypes = +_typesX;


/*
    IMPORTANT:
    Only WEST/Occupier and EAST/Invader use coalition logic.

    GUER, CIV and any other sides continue with normal A3AU behaviour.
*/
if (
    _prefix != ""
    && {!isNil "Thorne_CoalitionFactions"}
) then {

    private _sidePool = Thorne_CoalitionFactions getOrDefault [
        _prefix,
        createHashMap
    ];

    private _coalitionTags = keys _sidePool;


    // --------------------------------------------------------------------
    // Determine which coalition factions can actually spawn this group.
    // --------------------------------------------------------------------

    private _compatibleTags = [];

    {
        private _tag = _x;

        private _coalitionFaction = _sidePool getOrDefault [
            _tag,
            createHashMap
        ];

        private _unitMap = _coalitionFaction getOrDefault [
            "Thorne_CoalitionUnitMap",
            createHashMap
        ];

        private _compatible = true;


        {
            private _requestedType = _x;

            /*
                Only generated A3AU loadout names have to be translated.

                Things such as direct CfgVehicles classes should remain
                unchanged and therefore do not affect compatibility.
            */
            if (
                _requestedType isEqualType ""
                && {
                    (_requestedType find "loadouts_") == 0
                }
            ) then {

                private _coalitionType = _unitMap getOrDefault [
                    _requestedType,
                    ""
                ];

                if (_coalitionType == "") then {
                    _compatible = false;
                };

            };

        } forEach _typesX;


        if (_compatible) then {
            _compatibleTags pushBack _tag;
        };

    } forEach _coalitionTags;


    /*
        BASE means:
            Use the normal faction selected in Antistasi.

        Example WEST:
            BASE = AMF
            BAF  = coalition faction

        Example EAST:
            BASE = ION
            AFRF = coalition faction

        This gives every group a random faction, while retaining the
        normal faction selected through Antistasi's setup menu.
    */
    private _selectionPool = ["BASE"];

    {
        _selectionPool pushBack _x;
    } forEach _compatibleTags;


    _selectedTag = selectRandom _selectionPool;


    // --------------------------------------------------------------------
    // Resolve entire group if a coalition faction was selected.
    // --------------------------------------------------------------------

    if (_selectedTag != "BASE") then {

        private _selectedFaction = _sidePool getOrDefault [
            _selectedTag,
            createHashMap
        ];

        private _unitMap = _selectedFaction getOrDefault [
            "Thorne_CoalitionUnitMap",
            createHashMap
        ];

        _resolvedTypes = [];


        {
            private _requestedType = _x;
            private _resolvedType = _requestedType;


            if (
                _requestedType isEqualType ""
                && {
                    (_requestedType find "loadouts_") == 0
                }
            ) then {

                _resolvedType = _unitMap getOrDefault [
                    _requestedType,
                    _requestedType
                ];

            };


            _resolvedTypes pushBack _resolvedType;

        } forEach _typesX;

    };


    // Store useful debug metadata on the group.
    _groupX setVariable [
        "Thorne_CoalitionTag",
        _selectedTag,
        false
    ];


    diag_log format [
        "[Thorne Coalition] spawnGroup side=%1 prefix=%2 selected='%3' compatible=%4 original=%5 resolved=%6",
        _sideX,
        _prefix,
        _selectedTag,
        _compatibleTags,
        _typesX,
        _resolvedTypes
    ];

};


// ========================================================================
// Original A3AU spawnGroup behaviour
// ========================================================================

private _ranks = [
    "LIEUTENANT",
    "SERGEANT",
    "CORPORAL"
];

private _countX = count _resolvedTypes;


if (_countX < 4) then {

    _ranks = _ranks - [
        "LIEUTENANT",
        "SERGEANT"
    ];

} else {

    if (_countX < 8) then {
        _ranks = _ranks - [
            "LIEUTENANT"
        ];
    };

};


private _countRanks = count _ranks - 1;

Debug_2(
    "Side: %1 spawning group composition: %2",
    _sideX,
    _resolvedTypes
);


// ========================================================================
// Spawn units
// ========================================================================

for "_i" from 0 to (_countX - 1) do {

    private _resolvedType =
        _resolvedTypes select _i;

    /*
        Keep original type separately.

        This matters for leader detection because the main A3AU faction
        knows the generic type, not our coalition-prefixed alias.
    */
    private _originalType =
        _typesX select _i;


    private _unit = [
        _groupX,
        _resolvedType,
        _positionX,
        [],
        0,
        "NONE"
    ] call A3A_fnc_createUnit;


    if (!isNull _unit) then {

        _unit allowDamage false;


        // ---------------------------------------------------------------
        // Rank
        // ---------------------------------------------------------------

        if (_i <= _countRanks) then {
            _unit setRank (
                _ranks select _i
            );
        };


        // ---------------------------------------------------------------
        // Leader
        // ---------------------------------------------------------------

        private _currentFaction = switch (_sideX) do {
            case west: {
                missionNamespace getVariable [
                    "A3A_faction_occ",
                    createHashMap
                ]
            };

            case east: {
                missionNamespace getVariable [
                    "A3A_faction_inv",
                    createHashMap
                ]
            };

            case independent: {
                missionNamespace getVariable [
                    "A3A_faction_reb",
                    createHashMap
                ]
            };

            case civilian: {
                missionNamespace getVariable [
                    "A3A_faction_civ",
                    createHashMap
                ]
            };

            default {
                createHashMap
            };
        };

        private _squadLeaders = _currentFaction getOrDefault [
            "SquadLeaders",
            []
        ];

        if (_originalType in _squadLeaders) then {
            _groupX selectLeader _unit;
        };


        // Useful for debugging in Zeus/debug console.
        _unit setVariable [
            "Thorne_CoalitionTag",
            _selectedTag,
            true
        ];

        _unit setVariable [
            "Thorne_OriginalUnitType",
            _originalType,
            true
        ];

    } else {

        diag_log format [
            "[Thorne Coalition] ERROR createUnit failed side=%1 faction='%2' original='%3' resolved='%4'",
            _sideX,
            _selectedTag,
            _originalType,
            _resolvedType
        ];

    };


    sleep 0.25;
};


// Re-enable damage after the entire squad exists.
{
    _x allowDamage true;
} forEach units _groupX;


_groupX