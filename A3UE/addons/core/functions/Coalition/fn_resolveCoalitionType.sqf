/*
    Convert an ordinary A3AU generated type into the selected coalition alias.

    Example:
      loadouts_occ_military_Rifleman
    becomes:
      loadouts_occ_BAF_military_Rifleman
*/
params ["_type", "_side", "_tag"];

if !(_type isEqualType "") exitWith { "" };
if (_tag == "") exitWith { "" };

private _prefix = switch (_side) do {
    case west: { "occ" };
    case east: { "inv" };
    default { "" };
};
if (_prefix == "") exitWith { "" };

private _normalPrefix = format ["loadouts_%1_", _prefix];
if ((_type find _normalPrefix) != 0) exitWith { _type };

private _localName = _type select [count _normalPrefix];
private _key = format ["%1:%2", _prefix, _tag];
private _map = Thorne_CoalitionUnitTypes getOrDefault [_key, createHashMap];

_map getOrDefault [_localName, ""]
