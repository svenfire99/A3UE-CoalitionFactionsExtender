/*
    Coalition Override of AU 12.4.1 ABZ_fnc_poolFromFactions.

    Sources:
    - normal A3A primary factions: occ, inv, reb, riv
    - every loaded OCC/INV/RIV faction in Thorne_CoalitionFactions

    Traversal is iterative instead of recursive. This avoids the private
    recursive closure scope errors visible in AU's 12.4.1 implementation
    (_v / _x undefined) and safely ignores nil/scalar values.
*/

private _out = [];
private _factions = [];

// Normal primary A3A factions.
{
    private _fac = missionNamespace getVariable [
        "A3A_faction_" + _x,
        createHashMap
    ];

    if (_fac isEqualType createHashMap && {count _fac > 0}) then {
        _factions pushBackUnique _fac;
    };
} forEach ["occ", "inv", "reb", "riv"];

// Additional coalition factions already loaded by the extender.
if (!isNil "Thorne_CoalitionFactions") then {
    {
        private _sidePool = Thorne_CoalitionFactions getOrDefault [
            _x,
            createHashMap
        ];

        if (_sidePool isEqualType createHashMap) then {
            {
                if (
                    !isNil "_y"
                    && {_y isEqualType createHashMap}
                    && {count _y > 0}
                ) then {
                    _factions pushBackUnique _y;
                };
            } forEach _sidePool;
        };
    } forEach ["occ", "inv", "riv"];
};

// Stack entries are [value, depth].
private _stack = [];

{
    private _fac = _x;

    {
        private _key = toLower _x;

        // Match AU's stock exclusions.
        if (
            (_key find "vehicle") != 0
            && {(_key find "animations") != 0}
            && {(_key find "faces") != 0}
            && {(_key find "voices") != 0}
        ) then {
            if (!isNil "_y") then {
                _stack pushBack [_y, 0];
            };
        };
    } forEach _fac;
} forEach _factions;

while {count _stack > 0} do {
    private _entry = _stack deleteAt ((count _stack) - 1);

    _entry params [
        "_value",
        ["_depth", 0, [0]]
    ];

    if (_depth <= 8 && {!isNil "_value"}) then {
        switch (typeName _value) do {
            case "STRING": {
                if (_value != "") then {
                    _out pushBackUnique _value;
                };
            };

            case "ARRAY": {
                {
                    if (!isNil "_x") then {
                        _stack pushBack [
                            _x,
                            _depth + 1
                        ];
                    };
                } forEach _value;
            };

            case "HASHMAP": {
                {
                    if (!isNil "_y") then {
                        _stack pushBack [
                            _y,
                            _depth + 1
                        ];
                    };
                } forEach _value;
            };
        };
    };
};

diag_log format [
    "[A3UEThorne Coalition] Bazaar poolFromFactions factions=%1 uniqueClasses=%2",
    count _factions,
    count _out
];

_out
