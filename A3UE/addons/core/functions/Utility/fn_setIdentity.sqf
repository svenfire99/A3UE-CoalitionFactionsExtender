/*
    Set face, voice, pitch and name of unit. Global effect and JIP-safe.

Scope: Any
Environment: Any
Public: Yes

Arguments:
    <OBJECT> Object to set identity for
    <STRING> Optional: Face of unit
    <STRING> Optional: Voice/speaker of unit
    <STRING> Optional: (Voice) pitch of unit
    <STRING> Optional: Name of unit
*/

#include "\x\A3A\addons\core\script_component.hpp"

params ["_unit", "_identity"];           // Don't care about the other params here

if (isNull _unit) exitWith {};

if (isNil "_identity" || {!(_identity isEqualType createHashMap)}) then {
    _identity = createHashMap;
};


// Resolve coalition faction from the group tag first.
// spawnGroup sets Thorne_CoalitionTag on the group BEFORE createUnit is called,
// so this works even before the unit itself receives its debug tag.
private _fnc_resolveThorneFaction = {
    params ["_unit", "_fallbackFaction", ["_type", ""]];

    private _resolvedFaction = _fallbackFaction;
    private _grp = group _unit;
    private _tag = if (isNull _grp) then { "" } else {
        _grp getVariable ["Thorne_CoalitionTag", ""]
    };

    private _prefix = switch (side _grp) do {
        case west: { "occ" };
        case east: { "inv" };
        default { "" };
    };

    if (
        _prefix != ""
        && {_tag != ""}
        && {_tag != "BASE"}
        && {!isNil "Thorne_CoalitionFactions"}
    ) then {
        private _sidePool = Thorne_CoalitionFactions getOrDefault [
            _prefix,
            createHashMap
        ];

        private _tagFaction = _sidePool getOrDefault [
            _tag,
            createHashMap
        ];

        if (
            _tagFaction isEqualType createHashMap
            && {count _tagFaction > 0}
        ) then {
            _resolvedFaction = _tagFaction;
        };
    };

    // Redundant fallback for coalition types created outside spawnGroup.
    if (
        _resolvedFaction isEqualTo _fallbackFaction
        && {_type != ""}
        && {!isNil "Thorne_CoalitionTypeFactionMap"}
    ) then {
        private _typeFaction = Thorne_CoalitionTypeFactionMap getOrDefault [
            _type,
            createHashMap
        ];

        if (
            _typeFaction isEqualType createHashMap
            && {count _typeFaction > 0}
        ) then {
            _resolvedFaction = _typeFaction;
        };
    };

    _resolvedFaction
};

private _firstName = _identity getOrDefault ["firstName", ""];
private _lastName = _identity getOrDefault ["lastName", ""];

if ((isNil "_firstName" || {_firstName isEqualTo ""}) || (isNil "_lastName" || {_lastName isEqualTo ""})) then {
    private _nameConfig = configfile >> "CfgWorlds" >> "GenericNames" >> "GreekMen";
    private _firstNames = configProperties [_nameConfig >> "FirstNames"] apply { getText(_x) };
    private _lastNames = configProperties [_nameConfig >> "LastNames"] apply { getText(_x) };

    private _type = _unit getVariable ["unitType", ""]; // Why do some units *not* have this set? I will never know!

    private _identityFaction = [
        _unit,
        Faction(side _unit),
        _type
    ] call _fnc_resolveThorneFaction;

    private _randomIdentity = [
        _identityFaction,
        _type
    ] call A3A_fnc_createRandomIdentity;


    _firstName = (
        [
            _randomIdentity getOrDefault ["firstName", ""],
            selectRandom _firstNames
        ]
        select {
            _x != ""
        }
    ) # 0;


    _lastName = (
        [
            _randomIdentity getOrDefault ["lastName", ""],
            selectRandom _lastNames
        ]
        select {
            _x != ""
        }
    ) # 0;
};

_identity set ["firstName", _firstName];
_identity set ["lastName", _lastName];

private _JIPID = "identity_" + netId _unit;
[_JIPID, _unit, _identity] remoteExec ["A3A_fnc_setIdentityLocal", 0, _JIPID];
// ([_JIPID] + _this) remoteExec ["A3A_fnc_setIdentityLocal", 0, _JIPID];

// This won't be 100% reliable because it's only installed locally, but it'll avoid remoteExec spam on connection
_unit addEventHandler ["Deleted", {
    remoteExec ["", "identity_" + netId _unit];
}];
