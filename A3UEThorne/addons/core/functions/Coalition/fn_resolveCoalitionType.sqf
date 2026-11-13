/*
    Resolves a logical AU loadout type through the faction selected for a group.

    Params:
        GROUP
        STRING prefix: "occ", "inv", "riv"
        STRING requested type

    Returns:
        STRING resolved type. BASE or missing mappings return the original type.
*/
params [
    ["_group", grpNull, [grpNull]],
    ["_prefix", "", [""]],
    ["_type", "", [""]]
];

if (
    isNull _group
    || {_type == ""}
    || {!(_prefix in ["occ", "inv", "riv"])}
) exitWith {
    _type
};

private _tag = _group getVariable [
    "Thorne_CoalitionTag",
    ""
];

if (_tag == "") then {
    _tag = [
        _group,
        _prefix,
        [_type]
    ] call Thorne_fnc_selectCoalitionForGroup;
};

if (_tag == "BASE") exitWith {
    _type
};

private _pool = Thorne_CoalitionFactions getOrDefault [
    _prefix,
    createHashMap
];

private _faction = _pool getOrDefault [
    _tag,
    createHashMap
];

private _unitMap = _faction getOrDefault [
    "Thorne_CoalitionUnitMap",
    createHashMap
];

private _resolved = _unitMap getOrDefault [
    _type,
    ""
];

if (_resolved == "") exitWith {
    diag_log format [
        "[Thorne Coalition] WARNING no mapping prefix='%1' tag='%2' type='%3'; using BASE type",
        _prefix,
        _tag,
        _type
    ];
    _type
};

_resolved
