#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

params ["_positionX","_sideX","_typesX"];

private _groupX = createGroup _sideX;

private _prefix = "";
{
    if (_x isEqualType "") then {
        if ((_x find "loadouts_occ_") == 0) exitWith { _prefix = "occ" };
        if ((_x find "loadouts_inv_") == 0) exitWith { _prefix = "inv" };
        if ((_x find "loadouts_riv_") == 0) exitWith { _prefix = "riv" };
    };
} forEach _typesX;

if (_prefix != "" && {missionNamespace getVariable ["Thorne_CoalitionEnabledNet", false]}) then {
    [_groupX, _prefix, _typesX] call Thorne_fnc_selectCoalitionForGroup;
};
private _ranks = ["LIEUTENANT","SERGEANT","CORPORAL"];
private _countX = count _typesX;

if (_countX < 4) then {
	_ranks = _ranks - ["LIEUTENANT","SERGEANT"];
} else {
	if (_countX < 8) then {
		_ranks = _ranks - ["LIEUTENANT"]
	};
};
private _countRanks = (count _ranks - 1);

Debug_2("Side: %1 spawning group composition: %2", _sideX, _typesX);

for "_i" from 0 to (_countX - 1) do {
	private _requestedType = _typesX select _i;
    private _resolvedType = if (_prefix == "") then {
        _requestedType
    } else {
        [_groupX, _prefix, _requestedType] call Thorne_fnc_resolveCoalitionType
    };
    _unit = [_groupX, _resolvedType, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
	_unit allowDamage false;

	if (_i <= _countRanks) then { 
		_unit setRank (_ranks select _i) 
	};
	if ((_typesX select _i) in FactionGet(all,"SquadLeaders")) then {
		_groupX selectLeader _unit
	};
	sleep 0.25;
};

{_x allowDamage true} forEach units _groupX;


_groupX
