/*
 * File: fn_createUnit.sqf
 * Description:
 *    To be used instead of 'createUnit' scripting command.
 *    Adds additional behaviour, including passing a loadout instead of a classname.
 *    21/07/2023: Added ability to use a different unit class (for custom skeletons)
 *    28/07/2023: Be very careful if you're going to add 2 different base classes.
 *    28/07/2023: For example, adding a webknights elite to a squad of OPTRE elites will cause the OPTRE elites to not fire at all. Some mods don't do this, some do!
 *    28/07/2023: Make sure you test it if you do. Helps avoid issues like "Why does half of the squad suddenly become pacifists?"
 *    This version overwrites the Anti Plus version of the createUnit command! hooray!
 * Params:
 *    _group - Group to add the AI: Group
 *    _type - A classname in CfgVehicles, or a unit loadout array: String or Array
 *    _position - Position to create at: Position, Position2D, Object, Group
 *    _markers - Markers the AI can be placed on: Array
 *    _placement - Placement radius: Number
 *    _special - Unit special placement: String
 *    _identity - optional unit identity parameters, keys may include:
			- "face"
			- "speaker"
			- "pitch"
			- "firstName"
			- "lastName"
			All values of those keys must be strings except for "pitch" which is a number.
			If _identity parameter is not specified, a random identity will be applied to the unit according to its faction and type.
 * Returns:
 *    Object - created unit
 * Example Usage:
 *    [group, _type, position, markers, placement, special] call A3A_fnc_createUnit
*/

#include "\x\A3A\addons\core\script_component.hpp"

params ["_group", "_type", "_position", ["_markers", []], ["_placement", 0], ["_special", "NONE"], "_identity"];

private _unitDefinition = A3A_customUnitTypes getVariable [_type, []];

if !(_unitDefinition isEqualTo []) exitWith {
	_unitDefinition params ["_loadouts", "_traits",  "_unitProperties", "_unitClass"];
    private _canSkip = false;

    {
        if (_x select 0 isEqualTo "baseClass") then
		{
            _unitClass = _x select 1; // grab the classname
			if (_unitClass isEqualType []) then
			{
				if ((_unitClass select 0) isEqualType []) exitWith
				{
					private _weights = ((_x select 1) select 1);

					private _units = ((_x select 1) select 0);

					_unitClass = _units selectRandomWeighted _weights; // grab a random classname, weighted
					
					// [_units, _weights] call A3U_fnc_weightTest; // Only for debug. Don't forget to comment before updating, it's probably very intensive
				};
				_unitClass = selectRandom (_x select 1); // grab a random classname
			};
        };
        if (_x select 2 isEqualTo true) then
		{
            _canSkip = true;
        };
    } forEach _traits; // grab all data from base class trait

	private _unit = _group createUnit [_unitClass, _position, _markers, _placement, _special];
    [_unit] joinSilent _group; // normally, this command is literally pointless. But when we're mixing base classes (e.g opfor) but spawning them as blufor (swap enemy sides selection), it'll make them fight each other unless we do this

    if (_canSkip isEqualTo false) then {
	    _unit setUnitLoadout selectRandom _loadouts;
    };
	_unit setVariable ["unitType", _type, true];


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

    // Copy the already-selected group tag to the unit before identity creation.
    // This also makes the tag available to later identity/NATOinit code.
    private _groupCoalitionTag = _group getVariable [
        "Thorne_CoalitionTag",
        ""
    ];

    if (_groupCoalitionTag != "") then {
        _unit setVariable [
            "Thorne_CoalitionTag",
            _groupCoalitionTag,
            true
        ];
    };

	private _identityFaction = [
        _unit,
        Faction(side _unit),
        _type
    ] call _fnc_resolveThorneFaction;

    if (
        _groupCoalitionTag != ""
        && {_groupCoalitionTag != "BASE"}
    ) then {
        diag_log format [
            "[Thorne Coalition Identity] createUnit tag='%1' type='%2' faction='%3'",
            _groupCoalitionTag,
            _type,
            _identityFaction getOrDefault ["name", "UNKNOWN"]
        ];
    };

	private _identity = if (isNil "_identity") then {
		[
			_identityFaction,
			_type
		] call A3A_fnc_createRandomIdentity;

	} else {
		_identity;
	};

	[_unit, _identity] call A3A_fnc_setIdentity;

	//it's very fragile and non-extensible (adding second bool or string value into template will break this)
	{
		switch (true) do {
			case (_x isEqualType true): {
				_unit setVariable ["isRival", _x, true];
			};
			case (_x isEqualType ""): {
				_unit setVariable ["unitPrefix", _x, true];
			};
		};	
	} forEach _unitProperties;

	{
        if (_x select 0 isNotEqualTo "baseClass") then {
            _unit setUnitTrait _x;
        };
	} forEach _traits;
	_unit
};

private _unit = _group createUnit [_type, _position, _markers, _placement, _special];
_unit setVariable ["unitType", _type, true];
_unit