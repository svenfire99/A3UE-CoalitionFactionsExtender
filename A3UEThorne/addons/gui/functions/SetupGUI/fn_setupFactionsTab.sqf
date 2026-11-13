/*
Function: A3A_fnc_setupFactionsTab
    Handles the initialization and tab switching on the setup dialog.
    This function should only be called from setupDialog onLoad and control activation EHs.
Author: John Jordan (jaj22)

Environment: Scheduled for onLoad, sendData and serverClose modes. Unscheduled for everything else.

Arguments:
    <STRING> Mode, e.g. "onLoad", "switchTab"
    <ARRAY<ANY>> Array of params for the mode when applicable. Params for specific modes are documented in the modes.


Modes:
    - update does nothing
    - factionSelected called no new item selectionNames
    - fillFactions fills faction tab with the factions
    - getFactions getter for selected items in tab

Return Value:
    on mode getFactions - returns array of selected items in dialog in form [_factions, _addons, _dlc]

*/

#include "..\..\dialogues\ids.inc"
#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\gui\dialogues\textures.inc"
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

params [["_mode", "", [""]], ["_params", [], [[]]]];

Debug_1("setupFactionsTab called with mode %1", _mode);

private _display = findDisplay A3A_IDD_SETUPDIALOG;
private _worldName = toLower worldName;

if (isNil "A3A_setup_loadedPatches") exitWith { Error("No patch data. Load order fuckup?") };

// Input: faction config, output: true/false
private _fnc_factionLoaded = {
    getArray (_this/"requiredAddons") findIf { !(_x in A3A_setup_loadedPatches) } == -1
};
// local version: getArray (_x/"requiredAddons") findIf { !(isClass (configFile/"CfgPatches"/_x)) } != -1;

// Split factions by side and priority-sort
if (isNil {_display getVariable "validFactions"}) then
{
    private _fnc_prioritySort = {
        params ["_factions"];
        private _factionSort = [];
        {
            private _priority = getNumber (_x/"priority") + 0.01*_forEachIndex;
            private _maps = getArray (_x/"maps");
            if (count _maps > 0) then { _priority = _priority + ([-2, 2] select (_worldName in _maps)) };
            if !(_x call _fnc_factionLoaded) then { _priority = _priority - 100 };
            _factionSort pushBack [_priority, _x];
        } forEach _factions;

        _factionSort sort false;
        _factionSort apply { _x#1 };
    };

    // prep the valid factions for current modset
    private _factions = [[], [], [], [], []];
    private _factTypeHM = createHashMapFromArray [["Occ", 0], ["Inv", 1], ["Reb", 2], ["Civ", 3], ["Riv", 4]];
    {
        if (getText (_x/"side") == "") then { continue };
        private _factIndex = _factTypeHM get getText (_x/"side");
        (_factions select _factIndex) pushBack _x;
    } forEach ("true" configClasses (A3A_SETUP_CONFIGFILE/"A3A"/"Templates"));

    _factions = _factions apply { [_x] call _fnc_prioritySort };
    _display setVariable ["validFactions", _factions];
};

if (isNil {_display getVariable "isContentInitialized"}) then {
    // Fill the addon vics
    private _addonTable = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BOX;
    private _checkCtrls = [];
    {
        private _textCtrl = _display ctrlCreate ["A3A_Text_Small", -1, _addonTable];
        _textCtrl ctrlSetPosition [GRID_W*4, count _checkCtrls*GRID_H*4, GRID_W*40, GRID_H*4];
        _textCtrl ctrlCommit 0;
        if !(_x call _fnc_factionLoaded) then { _textCtrl ctrlSetTextColor A3A_COLOR_TEXT_DARKER_SQF };
        _textCtrl ctrlSetText getText (_x/"displayName");
        _textCtrl ctrlSetTooltip getText (_x/"description");

        private _checkCtrl = _display ctrlCreate ["A3A_Checkbox", -1, _addonTable];
        _checkCtrl ctrlSetPosition [0, count _checkCtrls*GRID_H*4, GRID_W*4, GRID_H*4];
        _checkCtrl ctrlCommit 0;
        _checkCtrl ctrlEnable (_x call _fnc_factionLoaded);				// disable if requirement failed
        _checkCtrl setVariable ["name", configName _x];
        _checkCtrls pushBack _checkCtrl;

    } forEach ("true" configClasses (A3A_SETUP_CONFIGFILE/"A3A"/"AddonVics"));
    _addonTable setVariable ["checkCtrls", _checkCtrls];

    // Fill the DLC
    // Fetch these automatically but remove DLC without equipment and vehicles
    //private _loadedDLC = getLoadedModsInfo select {_x#3 and !(_x#1 in ["A3","curator","argo","tacops"])};
    private _dlcTable = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BOX;
    _checkCtrls = [];
    {
        private _textCtrl = _display ctrlCreate ["A3A_Text_Small", -1, _dlcTable];
        _textCtrl ctrlSetPosition [GRID_W*4, count _checkCtrls*GRID_H*4, GRID_W*40, GRID_H*4];
        _textCtrl ctrlCommit 0;
        _textCtrl ctrlSetText _x#0;

        private _checkCtrl = _display ctrlCreate ["A3A_Checkbox", -1, _dlcTable];
        _checkCtrl ctrlSetPosition [0, count _checkCtrls*GRID_H*4, GRID_W*4, GRID_H*4];
        _checkCtrl ctrlCommit 0;
        _checkCtrl setVariable ["name", _x#1];
        _checkCtrls pushBack _checkCtrl;

    } forEach A3A_setup_loadedDLC;
    _dlcTable setVariable ["checkCtrls", _checkCtrls];

    _display setVariable ["isContentInitialized", true];
};

private _fnc_getSelectedData = {
    params ["_listbox"];

    private _selected = [];

    for "_i" from 0 to ((lbSize _listbox) - 1) do {
        if (_listbox lbIsSelected _i) then {
            private _data = _listbox lbData _i;
            if (_data != "") then {
                _selected pushBackUnique _data;
            };
        };
    };

    _selected
};

switch (_mode) do
{
    case ("update"): {
        _params params [["_listboxes", [], [[]]]];

        // ! look away now lest you have an aneurysm looking at all the duplicated code
        // ! not much to be done when the same items need to be accessed both from here and from inside the event handlers :(

        private _rebLBCtrl = _display displayCtrl A3A_IDC_SETUP_REBELSLISTBOX;
        private _civLBCtrl = _display displayCtrl A3A_IDC_SETUP_CIVILIANSLISTBOX;
        private _invLBCtrl = _display displayCtrl A3A_IDC_SETUP_INVADERSLISTBOX;
        private _rivLBCtrl = _display displayCtrl A3A_IDC_SETUP_RIVALSLISTBOX;

        
        private _rebLBHandler =_rebLBCtrl getVariable "LBHandler";
        if (!isNil "_rebLBHandler") then { _rebLBCtrl ctrlRemoveEventHandler ["MouseMoving", _rebLBHandler] };
        if (_rebLBCtrl in _listboxes) then {
            _rebLBHandler = _rebLBCtrl ctrlAddEventHandler ["MouseMoving", {
                params ["_rebLBCtrl", "_xPos", "_yPos", "_mouseOver"];

                private _display = findDisplay A3A_IDD_SETUPDIALOG;
                private _civLabelCtrl = _display displayCtrl A3A_IDC_SETUP_CIVILIANSLABEL;
                private _civLBCtrl = _display displayCtrl A3A_IDC_SETUP_CIVILIANSLISTBOX;

                if (_mouseOver) then {
                    if (_rebLBCtrl getVariable "Expanded") exitWith {};
                    _rebLBCtrl setVariable ["Expanded", true];
                    
                    private _rebLBSize = lbSize _rebLBCtrl;
                    private _LBx = 4 * GRID_W;
                    private _rebLBy = 8 * GRID_H;
                    private _LBw = 38 * GRID_W;
                    private _Lh = 4 * GRID_H;
                    private _rebLBh = ((_rebLBSize * 3.25) min 66) * GRID_H;
                    private _civLy = (_rebLBy + _rebLBh + 2 * GRID_H);
                    private _civLBy = (_civLy + 4 * GRID_H);
                    private _civLBh = (92 * GRID_H - _civLy);
                    _rebLBCtrl ctrlSetPosition [_LBx, _rebLBy, _LBw, _rebLBh];
                    _civLabelCtrl ctrlSetPosition [_LBx, _civLy, _LBw, _Lh];
                    _civLBCtrl ctrlSetPosition [_LBx, _civLBy, _LBw, _civLBh];
                    { _x ctrlCommit 0.4 } forEach [_rebLBCtrl, _civLabelCtrl, _civLBCtrl];
                } else {
                    _rebLBCtrl ctrlSetPosition [4 * GRID_W, 8 * GRID_H, 38 * GRID_W, 40 * GRID_H];
                    _civLabelCtrl ctrlSetPosition [4 * GRID_W, 50 * GRID_H, 38 * GRID_W, 4 * GRID_H];
                    _civLBCtrl ctrlSetPosition [4 * GRID_W, 54 * GRID_H, 38 * GRID_W, 42 * GRID_H];
                    { _x ctrlCommit 0.4 } forEach [_rebLBCtrl, _civLabelCtrl, _civLBCtrl];
                    _rebLBCtrl setVariable ["Expanded", false];
                };
            }];
            _rebLBCtrl setVariable ["LBHandler", _rebLBHandler];
        };

        private _civLBHandler = _civLBCtrl getVariable "LBHandler";
        if (!isNil "_civLBHandler") then { _civLBCtrl ctrlRemoveEventHandler ["MouseMoving", _civLBHandler] };
        if (_civLBCtrl in _listboxes) then {
            _civLBHandler = _civLBCtrl ctrlAddEventHandler ["MouseMoving", {
                params ["_civLBCtrl", "_xPos", "_yPos", "_mouseOver"];

                private _display = findDisplay A3A_IDD_SETUPDIALOG;
                private _civLabelCtrl = _display displayCtrl A3A_IDC_SETUP_CIVILIANSLABEL;
                private _rebLBCtrl = _display displayCtrl A3A_IDC_SETUP_REBELSLISTBOX;

                if (_mouseOver) then {
                    if (_civLBCtrl getVariable "Expanded") exitWith {};
                    _civLBCtrl setVariable ["Expanded", true];
                    
                    _rebLBCtrl ctrlSetPosition [4 * GRID_W, 8 * GRID_H, 38 * GRID_W, 16 * GRID_H];
                    _civLabelCtrl ctrlSetPosition [4 * GRID_W, 26 * GRID_H, 38 * GRID_W, 4 * GRID_H];
                    _civLBCtrl ctrlSetPosition [4 * GRID_W, 30 * GRID_H, 38 * GRID_W, 66 * GRID_H];
                    { _x ctrlCommit 0.4 } forEach [_rebLBCtrl, _civLabelCtrl, _civLBCtrl];
                } else {
                    _rebLBCtrl ctrlSetPosition [4 * GRID_W, 8 * GRID_H, 38 * GRID_W, 40 * GRID_H];
                    _civLabelCtrl ctrlSetPosition [4 * GRID_W, 50 * GRID_H, 38 * GRID_W, 4 * GRID_H];
                    _civLBCtrl ctrlSetPosition [4 * GRID_W, 54 * GRID_H, 38 * GRID_W, 42 * GRID_H];
                    { _x ctrlCommit 0.4 } forEach [_rebLBCtrl, _civLabelCtrl, _civLBCtrl];
                    _civLBCtrl setVariable ["Expanded", false];
                };
            }];
            _civLBCtrl setVariable ["LBHandler", _civLBHandler];
        };

        private _invLBHandler = _invLBCtrl getVariable "LBHandler";
        if (!isNil "_invLBHandler") then { _invLBCtrl ctrlRemoveEventHandler ["MouseMoving", _invLBHandler] };
        if (_invLBCtrl in _listboxes) then {
            _invLBHandler = _invLBCtrl ctrlAddEventHandler ["MouseMoving", {
                params ["_invLBCtrl", "_xPos", "_yPos", "_mouseOver"];

                private _display = findDisplay A3A_IDD_SETUPDIALOG;
                private _rivLabelCtrl = _display displayCtrl A3A_IDC_SETUP_RIVALSLABEL;
                private _rivLBCtrl = _display displayCtrl A3A_IDC_SETUP_RIVALSLISTBOX;

                if (_mouseOver) then {
                    if (_invLBCtrl getVariable "Expanded") exitWith {};
                    _invLBCtrl setVariable ["Expanded", true];
                    
                    private _invLBSize = lbSize _invLBCtrl;
                    private _LBx = 84 * GRID_W;
                    private _invLBy = 8 * GRID_H;
                    private _LBw = 38 * GRID_W;
                    private _Lh = 4 * GRID_H;
                    private _invLBh = ((_invLBSize * 3.25) min 66) * GRID_H;
                    private _rivLy = (_invLBy + _invLBh + 2 * GRID_H);
                    private _rivLBy = (_rivLy + 4 * GRID_H);
                    private _rivLBh = (92 * GRID_H - _rivLy);
                    _invLBCtrl ctrlSetPosition [_LBx, _invLBy, _LBw, _invLBh];
                    _rivLabelCtrl ctrlSetPosition [_LBx, _rivLy, _LBw, _Lh];
                    _rivLBCtrl ctrlSetPosition [_LBx, _rivLBy, _LBw, _rivLBh];
                    { _x ctrlCommit 0.4 } forEach [_invLBCtrl, _rivLabelCtrl, _rivLBCtrl];
                } else {
                    _invLBCtrl ctrlSetPosition [84 * GRID_W, 8 * GRID_H, 38 * GRID_W, 40 * GRID_H];
                    _rivLabelCtrl ctrlSetPosition [84 * GRID_W, 50 * GRID_H, 38 * GRID_W, 4 * GRID_H];
                    _rivLBCtrl ctrlSetPosition [84 * GRID_W, 54 * GRID_H, 38 * GRID_W, 42 * GRID_H];
                    { _x ctrlCommit 0.4 } forEach [_invLBCtrl, _rivLabelCtrl, _rivLBCtrl];
                    _invLBCtrl setVariable ["Expanded", false];
                };
            }];
            _invLBCtrl setVariable ["LBHandler", _invLBHandler];
        };

        private _rivLBHandler = _rivLBCtrl getVariable "LBHandler";
        if (!isNil "_rivLBHandler") then { _rivLBCtrl ctrlRemoveEventHandler ["MouseMoving", _rivLBHandler] };
        if (_rivLBCtrl in _listboxes) then {
            _rivLBHandler = _rivLBCtrl ctrlAddEventHandler ["MouseMoving", {
                params ["_rivLBCtrl", "_xPos", "_yPos", "_mouseOver"];

                private _display = findDisplay A3A_IDD_SETUPDIALOG;
                private _rivLabelCtrl = _display displayCtrl A3A_IDC_SETUP_RIVALSLABEL;
                private _invLBCtrl = _display displayCtrl A3A_IDC_SETUP_INVADERSLISTBOX;

                if (_mouseOver) then {
                    if (_rivLBCtrl getVariable "Expanded") exitWith {};
                    _rivLBCtrl setVariable ["Expanded", true];
                    
                    _invLBCtrl ctrlSetPosition [84 * GRID_W, 8 * GRID_H, 38 * GRID_W, 16 * GRID_H];
                    _rivLabelCtrl ctrlSetPosition [84 * GRID_W, 26 * GRID_H, 38 * GRID_W, 4 * GRID_H];
                    _rivLBCtrl ctrlSetPosition [84 * GRID_W, 30 * GRID_H, 38 * GRID_W, 66 * GRID_H];
                    { _x ctrlCommit 0.4 } forEach [_invLBCtrl, _rivLabelCtrl, _rivLBCtrl];
                } else {
                    _invLBCtrl ctrlSetPosition [84 * GRID_W, 8 * GRID_H, 38 * GRID_W, 40 * GRID_H];
                    _rivLabelCtrl ctrlSetPosition [84 * GRID_W, 50 * GRID_H, 38 * GRID_W, 4 * GRID_H];
                    _rivLBCtrl ctrlSetPosition [84 * GRID_W, 54 * GRID_H, 38 * GRID_W, 42 * GRID_H];
                    { _x ctrlCommit 0.4 } forEach [_invLBCtrl, _rivLabelCtrl, _rivLBCtrl];
                    _rivLBCtrl setVariable ["Expanded", false];
                };
            }];
            _rivLBCtrl setVariable ["LBHandler", _rivLBHandler];
        };

        private _modCGCtrl = _display displayCtrl A3A_IDC_SETUP_OVERRIDES;
        private _dlcCGCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT;
        private _addCGCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT;
        
        private _dlcCGHandler = _dlcCGCtrl getVariable "LBHandler";
        if (!isNil "_dlcCGHandler") then { _dlcCGCtrl ctrlRemoveEventHandler ["MouseMoving", _dlcCGHandler] };
        _dlcCGHandler = _dlcCGCtrl ctrlAddEventHandler ["MouseMoving", {
            params ["_dlcCGCtrl", "_xPos", "_yPos", "_mouseOver"];

            private _display = findDisplay A3A_IDD_SETUPDIALOG;
            private _dlcBGCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BG;
            //private _dlcBoxCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BOX;
            private _dlcBoxCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BOX;
            private _addCGCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT;
            private _addLabelCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_LABEL;
            private _addBGCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BG;
            //private _addBoxCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BOX;
            private _addBoxCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BOX;

            private _dlcCGx = 124 * GRID_W;
            private _dlcCGy = 30 * GRID_H;
            private _dlcCGw = 32 * GRID_W;
            private _dlcCGh = 22 * GRID_H;

            private _addCGx = 124 * GRID_W;
            private _addCGy = 54 * GRID_H;
            private _addCGw = 32 * GRID_W;
            private _addCGh = 42 * GRID_H;
            
            if (_mouseOver) then {
                if (_dlcCGCtrl getVariable "Expanded") exitWith {};
                _dlcCGCtrl setVariable ["Expanded", true];
                
                _dlcCGCtrl ctrlSetPosition [_dlcCGx, _dlcCGy, _dlcCGw, _dlcCGh + (20 * GRID_H)];
                { _x ctrlSetPosition [0, 4 * GRID_H, _dlcCGw, _dlcCGh + (16 * GRID_H)] } forEach [_dlcBGCtrl, _dlcBoxCtrl];

                _addCGCtrl ctrlSetPosition [_addCGx, _addCGy + (20 * GRID_H), _addCGw, _addCGh - (20 * GRID_H)];
                _addLabelCtrl ctrlSetPosition [0, 0, _addCGw, 4 * GRID_H];
                {_x ctrlSetPosition [0, 4 * GRID_H, _addCGw, _addCGh - (24 * GRID_H)] } forEach [_addBGCtrl, _addBoxCtrl];

                { _x ctrlCommit 0.4 } forEach [_dlcCGCtrl, _dlcBGCtrl, _dlcBoxCtrl, _addCGCtrl, _addLabelCtrl, _addBGCtrl, _addBoxCtrl];
            } else {
                _dlcCGCtrl ctrlSetPosition [_dlcCGx, _dlcCGy, _dlcCGw, _dlcCGh];
                {_x ctrlSetPosition [0, 4 * GRID_H, _dlcCGw, _dlcCGh - (4 * GRID_H)] } forEach [_dlcBGCtrl, _dlcBoxCtrl];

                _addCGCtrl ctrlSetPosition [_addCGx, _addCGy, _addCGw, _addCGh];
                _addLabelCtrl ctrlSetPosition [0, 0, _addCGw, 4 * GRID_H];
                {_x ctrlSetPosition [0, 4 * GRID_H, _addCGw, _addCGh - (4 * GRID_H)] } forEach [_addBGCtrl, _addBoxCtrl];

                { _x ctrlCommit 0.4 } forEach [_dlcCGCtrl, _dlcBGCtrl, _dlcBoxCtrl, _addCGCtrl, _addLabelCtrl, _addBGCtrl, _addBoxCtrl];
                _dlcCGCtrl setVariable ["Expanded", false];
            };
        }];
        _dlcCGCtrl setVariable ["LBHandler", _dlcCGHandler];

        private _addCGHandler = _addCGCtrl getVariable "LBHandler";
        if (!isNil "_addCGHandler") then { _addCGCtrl ctrlRemoveEventHandler ["MouseMoving", _addCGHandler] };
        _addCGHandler = _addCGCtrl ctrlAddEventHandler ["MouseMoving", {
            params ["_addCGCtrl", "_xPos", "_yPos", "_mouseOver"];

            private _display = findDisplay A3A_IDD_SETUPDIALOG;
            private _dlcCGCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT;
            private _dlcBGCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BG;
            //private _dlcBoxCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BOX;
            private _dlcBoxCtrl = _display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BOX;
            private _addLabelCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_LABEL;
            private _addBGCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BG;
            //private _addBoxCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BOX;
            private _addBoxCtrl = _display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BOX;

            private _dlcCGx = 124 * GRID_W;
            private _dlcCGy = 30 * GRID_H;
            private _dlcCGw = 32 * GRID_W;
            private _dlcCGh = 22 * GRID_H;

            private _addCGx = 124 * GRID_W;
            private _addCGy = 54 * GRID_H;
            private _addCGw = 32 * GRID_W;
            private _addCGh = 42 * GRID_H;
            
            if (_mouseOver) then {
                if (_addCGCtrl getVariable "Expanded") exitWith {};
                _addCGCtrl setVariable ["Expanded", true];
                
                _dlcCGCtrl ctrlSetPosition [_dlcCGx, _dlcCGy, _dlcCGw, _dlcCGh - (18 * GRID_H)];
                { _x ctrlSetPosition [0, 4 * GRID_H, _dlcCGw, _dlcCGh - (14 * GRID_H)] } forEach [_dlcBGCtrl, _dlcBoxCtrl];

                _addCGCtrl ctrlSetPosition [_addCGx, _addCGy - (18 * GRID_H), _addCGw, _addCGh + (18 * GRID_H)];
                _addLabelCtrl ctrlSetPosition [0, 0, _addCGw, 4 * GRID_H];
                {_x ctrlSetPosition [0, 4 * GRID_H, _addCGw, _addCGh + (14 * GRID_H)] } forEach [_addBGCtrl, _addBoxCtrl];

                { _x ctrlCommit 0.4 } forEach [_dlcCGCtrl, _dlcBGCtrl, _dlcBoxCtrl, _addCGCtrl, _addLabelCtrl, _addBGCtrl, _addBoxCtrl];
            } else {
                _dlcCGCtrl ctrlSetPosition [_dlcCGx, _dlcCGy, _dlcCGw, _dlcCGh];
                {_x ctrlSetPosition [0, 4 * GRID_H, _dlcCGw, _dlcCGh - (4 * GRID_H)] } forEach [_dlcBGCtrl, _dlcBoxCtrl];

                _addCGCtrl ctrlSetPosition [_addCGx, _addCGy, _addCGw, _addCGh];
                _addLabelCtrl ctrlSetPosition [0, 0, _addCGw, 4 * GRID_H];
                {_x ctrlSetPosition [0, 4 * GRID_H, _addCGw, _addCGh - (4 * GRID_H)] } forEach [_addBGCtrl, _addBoxCtrl];

                { _x ctrlCommit 0.4 } forEach [_dlcCGCtrl, _dlcBGCtrl, _dlcBoxCtrl, _addCGCtrl, _addLabelCtrl, _addBGCtrl, _addBoxCtrl];
                _addCGCtrl setVariable ["Expanded", false];
            };
        }];
        _addCGCtrl setVariable ["LBHandler", _addCGHandler];
    };

    case ("factionSelected"):
    {
        _params params ["_listbox", "_rowIndex"];
        if (_rowIndex == -1) exitWith {};
        private _data = _listbox lbData _rowIndex;
        if (_data == "") exitWith { _listbox lbSetCurSel (_listbox getVariable ["lastSel", 0]) };
        _listbox setVariable ["lastSel", _rowIndex];

        private _multi = (ctrlIDC _listbox) in [
            A3A_IDC_SETUP_OCCUPANTSLISTBOX,
            A3A_IDC_SETUP_INVADERSLISTBOX,
            A3A_IDC_SETUP_RIVALSLISTBOX
        ];
        if (!_multi) exitWith {};

        private _enabled = cbChecked (_display displayCtrl THORNE_IDC_SETUP_COALITIONCHECK);
        private _selectedData = [_listbox] call _fnc_getSelectedData;
        private _order = _listbox getVariable ["Thorne_selectionOrder", []];
        if !(_order isEqualType []) then {
            _order = [_order];
        };
        _order = _order select { _x in _selectedData };
        {
            _order pushBackUnique _x;
        } forEach _selectedData;

        if (!_enabled) then {
            if (_data in _selectedData) then { _order = [_data] };
            if (_order isEqualTo []) then { _order = [_data] };
            for "_i" from 0 to (lbSize _listbox - 1) do {
                _listbox lbSetSelected [_i, (_listbox lbData _i) == (_order#0)];
            };
        };

        if (_order isEqualTo []) then {
            _order = [_data];
            _listbox lbSetSelected [_rowIndex, true];
        };
        _listbox setVariable ["Thorne_selectionOrder", _order];
    };

    case ("fillFactions"):
    {
        private _expandLBs = [];
        private _savedBundle = _display getVariable ["savedFactions", [[], [], []]];
        _savedBundle params ["_savedFactions", "_savedAddons", "_savedDLC"];
        if !(_savedFactions isEqualType []) then { _savedFactions = [] };
        if (_savedFactions isEqualTo []) then { _savedFactions = ["", "", "", "", ""] };
        while {count _savedFactions < 5} do { _savedFactions pushBack "" };

        private _state = _display getVariable ["Thorne_setupState", createHashMap];
        if !(_state isEqualType createHashMap) then { _state = createHashMap };
        private _coalitionEnabled = _state getOrDefault ["coalitionEnabled", false];
        private _selectedArrays = [
            _state getOrDefault ["occupants", [_savedFactions#0]],
            _state getOrDefault ["invaders", [_savedFactions#1]],
            [_savedFactions#2],
            [_savedFactions#3],
            _state getOrDefault ["rivals", [_savedFactions#4]]
        ];

        private _fnc_fillListBox = {
            params ["_listboxIDC", "_factions", "_selected", ["_multi", false]];
            private _listbox = _display displayCtrl _listboxIDC;
            private _selectedArray = if (_selected isEqualType []) then {+_selected} else {[_selected]};
            _selectedArray = _selectedArray select {_x != ""};
            if (_selectedArray isEqualTo []) then {
                private _old = _listbox getVariable ["Thorne_selectionOrder", []];
                if !(_old isEqualType []) then {
                    _old = [_old];
                };
                if (_old isNotEqualTo []) then { _selectedArray = +_old };
            };
            private _primary = _selectedArray param [0, ""];
            _listbox lbSetCurSel -1;
            lbClear _listbox;
            {
                private _index = _listbox lbAdd getText(_x/"name");
                if (_x call _fnc_factionLoaded) then {
                    _listbox lbSetPicture [_index, getText(_x/"flagTexture")];
                    _listbox lbSetPictureRight [_index, getText(_x/"logo")];
                    _listbox lbSetData [_index, configName _x];
                    _listbox lbSetTooltip [_index, getText(_x/"description")];
                    if ((configName _x) in _selectedArray) then { _listbox lbSetSelected [_index, true] };
                    if (_primary == configName _x) then { _listbox lbSetCurSel _index };
                } else {
                    _listbox lbSetPicture [_index, "a3\data_f\flags\flag_white_dmg_co.paa"];
                    _listbox lbSetPictureColor [_index, [1,1,1,0.3]];
                    _listbox lbSetTooltip [_index, format[localize "STR_A3AP_setupFactionsTab_noLoaded", (getArray(_x/"requiredAddons")) joinString ", "]];
                    _listbox lbSetColor [_index, A3A_COLOR_TEXT_DARKER_SQF];
                    _listbox lbSetSelectColor [_index, A3A_COLOR_TEXT_DARKER_SQF];
                };
            } forEach _factions;
            if (lbCurSel _listbox == -1 && {lbSize _listbox > 0}) then {
                _listbox lbSetCurSel 0;
                _listbox lbSetSelected [0, true];
                _selectedArray = [_listbox lbData 0];
            };
            if (!_multi && {lbCurSel _listbox >= 0}) then {
                _selectedArray = [_listbox lbData lbCurSel _listbox];
            };
            _listbox setVariable ["Thorne_selectionOrder", _selectedArray];
            if (count _factions > 12) then { _expandLBs pushBack _listbox };
        };

        private _factions = +(_display getVariable "validFactions");
        if (!cbChecked (_display displayCtrl A3A_IDC_SETUP_IGNORECAMOCHECK)) then {
            _factions = _factions apply { _x select { getArray (_x/"climate") isEqualTo [] or A3A_climate in getArray (_x/"climate") } };
        };
        private _missingFactions = _factions apply { _x select { !(_x call _fnc_factionLoaded) } };
        _factions = _factions apply { _x select { _x call _fnc_factionLoaded } };
        if (cbChecked (_display displayCtrl A3A_IDC_SETUP_SWITCHENEMYCHECK)) then {
            _factions = [_factions#1, _factions#0, _factions#2, _factions#3, _factions#4];
        };
        if (cbChecked (_display displayCtrl A3A_IDC_SETUP_ANYENEMYCHECK)) then {
            _factions = [_factions#0 + _factions#1, _factions#1 + _factions#0, _factions#2, _factions#3, _factions#4];
        };

        // Ensure every saved coalition member remains visible if its requirements are loaded.
        private _failed = [];
        {
            private _bucket = _forEachIndex;
            {
                private _cfg = A3A_SETUP_CONFIGFILE/"A3A"/"Templates"/_x;
                if !(isClass _cfg) then { _failed pushBackUnique _x; continue };
                if !(_cfg call _fnc_factionLoaded) then { _failed pushBackUnique _x; continue };
                (_factions#_bucket) pushBackUnique _cfg;
            } forEach _x;
        } forEach _selectedArrays;
        if (_failed isNotEqualTo []) then {
            private _msg = "Couldn't load factions from save:";
            { _msg = _msg + endl + _x } forEach _failed;
            ["Setup", _msg] spawn A3A_fnc_customHint;
        };
        if (cbChecked (_display displayCtrl A3A_IDC_SETUP_SHOWMISSINGCHECK)) then {
            { _x append _missingFactions#_forEachIndex } forEach _factions;
        };

        [A3A_IDC_SETUP_OCCUPANTSLISTBOX, _factions#0, _selectedArrays#0, true] call _fnc_fillListBox;
        [A3A_IDC_SETUP_INVADERSLISTBOX, _factions#1, _selectedArrays#1, true] call _fnc_fillListBox;
        [A3A_IDC_SETUP_REBELSLISTBOX, _factions#2, _selectedArrays#2, false] call _fnc_fillListBox;
        [A3A_IDC_SETUP_CIVILIANSLISTBOX, _factions#3, _selectedArrays#3, false] call _fnc_fillListBox;
        [A3A_IDC_SETUP_RIVALSLISTBOX, _factions#4, _selectedArrays#4, true] call _fnc_fillListBox;
        ["update", [_expandLBs]] call A3A_fnc_setupFactionsTab;
    };

    case ("coalitionToggle"):
    {
        private _enabled = cbChecked (_display displayCtrl THORNE_IDC_SETUP_COALITIONCHECK);
        {
            private _lb = _display displayCtrl _x;
            private _selected = [_lb] call _fnc_getSelectedData;
            private _order = _lb getVariable ["Thorne_selectionOrder", []];
            if !(_order isEqualType []) then {
                _order = [_order];
            };
            _order = _order select {_x in _selected};
            { _order pushBackUnique _x } forEach _selected;
            if (!_enabled && {_order isNotEqualTo []}) then {
                _order resize 1;
                for "_i" from 0 to (lbSize _lb - 1) do { _lb lbSetSelected [_i, (_lb lbData _i) == (_order#0)] };
            };
            _lb setVariable ["Thorne_selectionOrder", _order];
        } forEach [A3A_IDC_SETUP_OCCUPANTSLISTBOX, A3A_IDC_SETUP_INVADERSLISTBOX, A3A_IDC_SETUP_RIVALSLISTBOX];
    };

    case ("getFactions"):
    {
        private _primary = {
            params ["_idc"];
            private _lb = _display displayCtrl _idc;
            private _order = _lb getVariable ["Thorne_selectionOrder", []];
            if !(_order isEqualType []) then {
                _order = [_order];
            };
            if (_order isNotEqualTo []) exitWith {_order#0};
            if (lbCurSel _lb >= 0) exitWith {_lb lbData lbCurSel _lb};
            ""
        };
        private _single = {
            params ["_idc"];
            private _lb = _display displayCtrl _idc;
            if (lbCurSel _lb < 0) exitWith {""};
            _lb lbData lbCurSel _lb
        };
        [
            [A3A_IDC_SETUP_OCCUPANTSLISTBOX] call _primary,
            [A3A_IDC_SETUP_INVADERSLISTBOX] call _primary,
            [A3A_IDC_SETUP_REBELSLISTBOX] call _single,
            [A3A_IDC_SETUP_CIVILIANSLISTBOX] call _single,
            [A3A_IDC_SETUP_RIVALSLISTBOX] call _primary
        ]
    };

    case ("getContent"):
    {
        private _addons = [];
        {
            if (cbChecked _x) then { _addons pushBack (_x getVariable "name") };
        } forEach ((_display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BOX) getVariable "checkCtrls");

        private _dlc = [];
        {
            if (cbChecked _x) then { _dlc pushBack (_x getVariable "name") };
        } forEach ((_display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BOX) getVariable "checkCtrls");


        [_addons, _dlc];
    };

    case ("fillContent"):
    {
        // Add saved factions if valid
        // configNames of the occ/inv/reb/civ factions, written by setupLoadgameTab
        (_display getVariable "savedFactions") params ["_savedFactions", "_savedAddons", "_savedDLC"];
        Debug_3("Saved factions: %1 Addons: %2 DLC: %3", _savedFactions, _savedAddons, _savedDLC);

        // Should now set the addonvics & DLC tickboxes according to the save data
        private _addonCtrls = (_display displayCtrl A3A_IDC_SETUP_ADDONCONTENT_BOX) getVariable "checkCtrls";
        private _dlcCtrls = (_display displayCtrl A3A_IDC_SETUP_DLCCONTENT_BOX) getVariable "checkCtrls";
        { _x cbSetChecked false } forEach _addonCtrls + _dlcCtrls;

        {
            private _addon = _x;
            private _index = _addonCtrls findIf { _x getVariable "name" == _addon };
            if (_index == -1) then { Error_1("Addon vics template %1 not found", _x); continue };
            if !(ctrlEnabled (_addonCtrls#_index)) then { Error_1("Addon vics template %1 not loaded", _x); continue };
            (_addonCtrls#_index) cbSetChecked true;
        } forEach _savedAddons;

        {
            private _dlc = _x;
            private _index = _dlcCtrls findIf { _x getVariable "name" == _dlc };
            if (_index == -1) then { Error_1("DLC %1 not loaded", _x); continue };
            (_dlcCtrls#_index) cbSetChecked true;
        } forEach _savedDLC;
    };

    default {
        Error_1("Called with unknown mode %1", _mode);
    };
};
