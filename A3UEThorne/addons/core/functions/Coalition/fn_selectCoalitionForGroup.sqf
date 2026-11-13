/*
    Selects one coalition member for an entire group.

    Params:
        GROUP  group
        STRING prefix: "occ", "inv", "riv"
        ARRAY  requested logical unit types

    Returns:
        STRING selected tag ("BASE" or an extra faction tag)

    Selection is compatibility-aware: an extra faction is only eligible if
    it has a mapped unit type for every loadouts_* type requested.
*/
params [
    ["_group", grpNull, [grpNull]],
    ["_prefix", "", [""]],
    ["_types", [], [[]]]
];

if (isNull _group) exitWith { "BASE" };
if !(_prefix in ["occ", "inv", "riv"]) exitWith { "BASE" };

_group setVariable [
    "Thorne_CoalitionPrefix",
    _prefix,
    false
];

private _existing = _group getVariable [
    "Thorne_CoalitionTag",
    ""
];

if (_existing != "") exitWith {
    _existing
};

if (isNil "Thorne_CoalitionFactions") exitWith {
    _group setVariable ["Thorne_CoalitionTag", "BASE", false];
    "BASE"
};

private _pool = Thorne_CoalitionFactions getOrDefault [
    _prefix,
    createHashMap
];

private _compatibleTags = [];

{
    private _tag = _x;
    private _faction = _pool getOrDefault [
        _tag,
        createHashMap
    ];

    private _unitMap = _faction getOrDefault [
        "Thorne_CoalitionUnitMap",
        createHashMap
    ];

    private _compatible = true;

    {
        private _type = _x;

        if (
            _type isEqualType ""
            && {(_type find "loadouts_") == 0}
            && {(_unitMap getOrDefault [_type, ""]) == ""}
        ) then {
            _compatible = false;
        };
    } forEach _types;

    if (_compatible) then {
        _compatibleTags pushBack _tag;
    };

} forEach keys _pool;

private _selection = ["BASE"];
_selection append _compatibleTags;

private _tag = selectRandom _selection;

_group setVariable [
    "Thorne_CoalitionTag",
    _tag,
    false
];

diag_log format [
    "[Thorne Coalition] selectGroup prefix='%1' tag='%2' compatible=%3 types=%4",
    _prefix,
    _tag,
    _compatibleTags,
    _types
];

_tag
