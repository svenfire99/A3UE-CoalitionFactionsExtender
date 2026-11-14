/*
    Handles the initialization and tab switching on the setup dialog.
    This function should only be called from setupDialog onLoad and control activation EHs.

Environment: Scheduled for onLoad mode / Unscheduled for everything else unless specified

Arguments:
    <STRING> Mode, e.g. "onLoad", "switchTab"
    <ARRAY<ANY>> Array of params for the mode when applicable. Params for specific modes are documented in the modes.

Return Value:
    Nothing

*/

#include "..\..\dialogues\ids.inc"
#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\gui\dialogues\textures.inc"
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

params [["_mode", "", [""]], ["_params", [], [[]]]];

Debug_1("Loadgame dialog called with mode %1", _mode);

// Get display
private _display = findDisplay A3A_IDD_SETUPDIALOG;

private _listboxCtrl = _display displayCtrl A3A_IDC_SETUP_SAVESLISTBOX;
private _startCtrl = _display displayCtrl A3A_IDC_SETUP_STARTBUTTON;
private _newGameCtrl = _display displayCtrl A3A_IDC_SETUP_NEWGAMECHECKBOX;
private _copyGameCtrl = _display displayCtrl A3A_IDC_SETUP_COPYGAMECHECKBOX;
private _oldParamsCtrl = _display displayCtrl A3A_IDC_SETUP_OLDPARAMSCHECKBOX;
private _newSaveCtrl = _display displayCtrl A3A_IDC_SETUP_NAMESPACECHECKBOX;
private _saveInfoCtrl = _display displayCtrl A3A_IDC_SETUP_SAVEINFOTEXT;

private _saveBoxColumns = [
    ["gameID", "ID", 0, 12],
    ["mapStr", localize "STR_antistasi_setup_dialog_table_map", 14, 20, "mapStrShort"],
    ["name", localize "STR_antistasi_setup_dialog_table_name", 36, 44],
    ["verStr", localize "STR_antistasi_setup_dialog_table_version", 82, 12],
    ["timeStr", localize "STR_antistasi_setup_dialog_table_time", 94, 15],
    ["fileStr", localize "STR_antistasi_setup_dialog_table_file", 110, 8]
];

switch (_mode) do
{
    case ("onLoad"):
    {
        _display setVariable ["savedFactions", [[], [], []]];
        _display setVariable ["savedParams", createHashMap];
        _display setVariable ["Thorne_setupState", createHashMap];
        _listboxCtrl setVariable ["rowIndex", -1];

        private _platformIsWindows = A3A_setup_platform isEqualTo "Windows";
        _newSaveCtrl cbSetChecked _platformIsWindows;
        // _newSaveCtrl ctrlEnable _platformIsWindows; // ! Outright disable the control if platform isn't Windows
        if !(_platformIsWindows) then { _newSaveCtrl ctrlSetTooltip localize "STR_antistasi_dialogs_setup_use_new_namespace_warning" };

        // Do these programmatically so that we can reuse the column data
        private _headerCtrl = _display displayCtrl A3A_IDC_SETUP_SAVESHEADER;
        {
                private _ctrl = _display ctrlCreate ["A3A_Text_Small", -1, _headerCtrl];
                _ctrl ctrlSetPosition [GRID_W*(_x#2), 0, GRID_W*(_x#3), GRID_H*4];
                _ctrl ctrlCommit 0;
                _ctrl ctrlSetText (_x#1);
        } forEach _saveBoxColumns;
    };

    case ("update"):
    {
        private _rowIndex = _listboxCtrl getVariable "rowIndex";
        private _saveData = if (_rowIndex == -1) then {
            createHashMapFromArray [["map", ""]];
        } else {
            A3A_setup_saveData select _rowIndex;
        };
        private _sameMap = (worldName == _saveData get "map");
        private _newGame = cbChecked _newGameCtrl;

        // Update the controls according to selections
        _copyGameCtrl ctrlEnable (_sameMap and _newGame);
        if (!_sameMap and cbChecked _copyGameCtrl) exitWith { _copyGameCtrl cbSetChecked false };       // will re-call update
        _startCtrl ctrlEnable (_sameMap or _newGame);
        _copyGameCtrl ctrlShow _newGame;
        _oldParamsCtrl ctrlShow _newGame;
        _newSaveCtrl ctrlShow _newGame;
        (_display displayCtrl A3A_IDC_SETUP_COPYGAMETEXT) ctrlShow _newGame;
        (_display displayCtrl A3A_IDC_SETUP_OLDPARAMSTEXT) ctrlShow _newGame;
        (_display displayCtrl A3A_IDC_SETUP_NAMESPACETEXT) ctrlShow _newGame;
        (_display displayCtrl A3A_IDC_SETUP_HQPOSBUTTON) ctrlShow (_newGame && !cbChecked _copyGameCtrl);
        (_display displayCtrl A3A_IDC_SETUP_EDITZONES_BUTTON) ctrlShow (_newGame && !cbChecked _copyGameCtrl);

        private _setupState = if ((cbChecked _newGameCtrl and !cbChecked _copyGameCtrl) or !_sameMap) then {
            [createHashMapFromArray [["factions", ["", "", "", "", ""]]]] call Thorne_fnc_readSetupState
        } else {
            [_saveData] call Thorne_fnc_readSetupState
        };
        _display setVariable ["Thorne_setupState", _setupState];
        private _ctrl_coalitionEnabled = (_display displayCtrl THORNE_IDC_SETUP_COALITIONCHECK);
        private _value_coalitionEnabled = _setupState getOrDefault ["coalitionEnabled", false];
        if (cbChecked _ctrl_coalitionEnabled != _value_coalitionEnabled) then { _ctrl_coalitionEnabled cbSetChecked _value_coalitionEnabled };
        private _ctrl_switchEnemySides = (_display displayCtrl A3A_IDC_SETUP_SWITCHENEMYCHECK);
        private _value_switchEnemySides = _setupState getOrDefault ["switchEnemySides", false];
        if (cbChecked _ctrl_switchEnemySides != _value_switchEnemySides) then { _ctrl_switchEnemySides cbSetChecked _value_switchEnemySides };
        private _ctrl_overrideSideLimits = (_display displayCtrl A3A_IDC_SETUP_ANYENEMYCHECK);
        private _value_overrideSideLimits = _setupState getOrDefault ["overrideSideLimits", false];
        if (cbChecked _ctrl_overrideSideLimits != _value_overrideSideLimits) then { _ctrl_overrideSideLimits cbSetChecked _value_overrideSideLimits };
        private _ctrl_overrideCamoLimits = (_display displayCtrl A3A_IDC_SETUP_IGNORECAMOCHECK);
        private _value_overrideCamoLimits = _setupState getOrDefault ["overrideCamoLimits", false];
        if (cbChecked _ctrl_overrideCamoLimits != _value_overrideCamoLimits) then { _ctrl_overrideCamoLimits cbSetChecked _value_overrideCamoLimits };

        // If we're selecting a game to load, load factions if available
        private _factions = [_saveData get "factions", _saveData get "addonVics", _saveData get "DLC"];
        if (isNil {_factions#0}) then { _factions = [[], [], []] };
        if ((cbChecked _newGameCtrl and !cbChecked _copyGameCtrl) or !_sameMap) then { _factions = [[], [], []] };
        private _stateSignature = str _setupState;
        if (
            _factions isNotEqualTo (_display getVariable "savedFactions")
            || {_stateSignature != (_display getVariable ["Thorne_setupStateSignature", ""])}
        ) then {
            _display setVariable ["savedFactions", _factions];
            _display setVariable ["Thorne_setupStateSignature", _stateSignature];
            ["fillFactions"] call A3A_fnc_setupFactionsTab;
            ["fillContent"] call A3A_fnc_setupFactionsTab;
        };

        // If it's not a new game or load params or copy game is checked, load params
        private _params = if ("params" in _saveData) then [{ _saveData get "params" }, { createHashMap }];

        if ((_sameMap and !cbChecked _newGameCtrl) or cbChecked _copyGameCtrl or cbChecked _oldParamsCtrl) then {
            if (count _params > 0 and _params isNotEqualTo (_display getVariable "savedParams")) then { 
                _display setVariable ["savedParams", _params];
                ["fillParams"] call A3A_fnc_setupParamsTab;
            };
        } else {
            if (cbChecked _newGameCtrl && {!(_display getVariable ["paramsChangedSinceReset", false])}) then { 
                _display setVariable ["savedParams", createHashMap];
                ["fillParams"] call A3A_fnc_setupParamsTab;
            };
        };
        // ["clearLBSelection", [[_display displayCtrl A3A_IDC_SETUP_PARAMSPRESETS_SIZE, _display displayCtrl A3A_IDC_SETUP_PARAMSPRESETS_DIFF, _display displayCtrl A3A_IDC_SETUP_PARAMSPRESETS_CSTM]]] call A3A_fnc_setupParamsTab;
        // ["fillParams"] call A3A_fnc_setupParamsTab;
    };

    case ("setSaveData"):
    {
        { ctrlDelete _x } forEach allControls _listboxCtrl;             // doesn't touch config controls
        {
            _x params ["_varname", "", "_xpos", "_width", ["_toolTip", nil, [""]]];
            private _ctrls = [];
            {
                private _ctrl = _display ctrlCreate ["A3A_Text_Small", -1, _listboxCtrl];
                _ctrl ctrlSetPosition [GRID_W*_xpos, GRID_H*_forEachIndex*4, GRID_W*_width, GRID_H*4];
                _ctrl ctrlCommit 0;
                private _ctrlText = _x getOrDefault [_varname, ""];
                if (_varname isEqualTo "gameID") then { _ctrlText = _ctrlText select[0, 7] };
                _ctrl ctrlSetText _ctrlText;
                if (!isNil "_toolTip") then { _ctrl ctrlSetTooltip(_x getOrDefault[_toolTip, "N/A"]) };
                if (_x get "map" != worldName) then { _ctrl ctrlSetTextColor [0.6,0.6,0.6,1] };
                _ctrls pushBack _ctrl;
            } forEach A3A_setup_saveData;
            if (_varname == "name") then { _listboxCtrl setVariable ["nameCtrls", _ctrls] };
        } forEach _saveBoxColumns;

        ["selectSave", [-1]] call A3A_fnc_setupLoadgameTab;
    };

    case ("saveListClick"):
    {
        if (_params#1 != 0) exitWith {};                                            // ignore non-LMB clicks
        private _mpos = ctrlMousePosition _listBoxCtrl;
        if (_mpos#0 > (ctrlPosition _listBoxCtrl # 2) - 2*GRID_W) exitWith {};      // ignore scroll-bar region
        private _rowIndex = floor (_mpos#1 / (4*GRID_H));
        if (_rowIndex >= count A3A_setup_saveData) exitWith {};                      // ignore clicks below saves
        if (_rowIndex == _listboxCtrl getVariable "rowIndex") exitWith {};          // ignore if already selected
        ["selectSave", [_rowIndex]] call A3A_fnc_setupLoadgameTab;
        ["enableParamsTab"] call A3A_fnc_setupDialog;
    };

    case ("saveListDoubleClick"):
    {
        if (_params#1 != 0) exitWith {};                                            // ignore non-LMB clicks
        private _mpos = ctrlMousePosition _listBoxCtrl;
        if (_mpos#0 > (ctrlPosition _listBoxCtrl # 2) - 2*GRID_W) exitWith {};      // ignore scroll-bar region
        private _rowIndex = floor (_mpos#1 / (4*GRID_H));
        if (_rowIndex >= count A3A_setup_saveData) exitWith {};                      // ignore clicks below saves
        if (cbChecked _newGameCtrl) exitWith {};                                    // ignore new game clicks

        private _saveData = if (_rowIndex == -1) then {
            createHashMapFromArray [["map", ""]];
        } else {
            A3A_setup_saveData select _rowIndex;
        };
        if (!(worldName == _saveData get "map")) exitWith {};

        ["startGame"] call A3A_fnc_setupLoadgameTab;
    };

    case ("selectSave"):
    {
        _params params ["_rowIndex"];
        Debug_1("SelectSave called with index %1", _rowIndex);

        private _selectBar = _display displayCtrl A3A_IDC_SETUP_GAMESELECTBOX;
        _selectBar ctrlShow (_rowIndex != -1);
        _selectBar ctrlSetPositionY _rowIndex*GRID_H*4;
        _selectBar ctrlCommit 0;

        _listBoxCtrl setVariable ["rowIndex", _rowIndex];
        ["updateSaveInfoText"] call A3A_fnc_setupLoadgameTab;
        ["update"] call A3A_fnc_setupLoadgameTab;
    };

    case ("startGame"):
    {
        private _saveData = createHashMap;
        private _confirmText = "";
        if (cbChecked _newGameCtrl and !cbChecked _copyGameCtrl) then {
            _saveData set ["startType", "new"];
            _saveData set ["name", ctrlText (_display displayCtrl A3A_IDC_SETUP_NAMEEDITBOX)];
            _saveData set ["startPos", markerPos "Synd_HQ"];
            _confirmText = localize "STR_antistasi_dialogs_setup_confirm_start_create";
        } else {
            private _oldSave = A3A_setup_saveData select (_listboxCtrl getVariable "rowIndex");
            _saveData set ["gameID", _oldSave get "gameID"];
            _saveData set ["serverID", _oldSave get "serverID"];
            if (cbChecked _copyGameCtrl) then {
                _saveData set ["startType", "copy"];
                _saveData set ["name", ctrlText (_display displayCtrl A3A_IDC_SETUP_NAMEEDITBOX)];
                _confirmText = format [localize "STR_antistasi_dialogs_setup_confirm_start_copy", _oldSave get "gameID"];
            } else {
                _saveData set ["startType", "load"];
                _saveData set ["name", _oldSave getOrDefault ["name", ""]];
                _confirmText = format [localize "STR_antistasi_dialogs_setup_confirm_start_load", _oldSave get "gameID"];
            };
        };
        if (_saveData get "name" != "") then {
            //extra space because localize trims trailing spaces in these localization keys
            _confirmText = _confirmText + " " + format [localize "STR_antistasi_dialogs_setup_confirm_game_name", _saveData get "name"];
        };
        _saveData set ["useNewNamespace", cbChecked _newSaveCtrl];

        // Factions tab: [factions, addonvics, DLC]
        private _factions = ["getFactions"] call A3A_fnc_setupFactionsTab;
        private _contentData = ["getContent"] call A3A_fnc_setupFactionsTab;
        _saveData set ["factions", _factions];
        _saveData set ["addonVics", _contentData#0];
        _saveData set ["DLC", _contentData#1];

        private _getOrder = {
            params ["_idc", "_primary"];

            private _lb = _display displayCtrl _idc;

            // Read the ACTUAL selected rows from the control at the moment
            // Start Game is pressed.
            private _selected = [];

            for "_i" from 0 to ((lbSize _lb) - 1) do {
                if (_lb lbIsSelected _i) then {
                    private _data = _lb lbData _i;
                    if (_data != "") then {
                        _selected pushBackUnique _data;
                    };
                };
            };

            // Preserve previous selection order so the first selected faction
            // remains the primary faction.
            private _order = _lb getVariable [
                "Thorne_selectionOrder",
                []
            ];

            if !(_order isEqualType []) then {
                _order = [_order];
            } else {
                _order = +_order;
            };

            _order = _order select {
                _x in _selected
            };

            {
                _order pushBackUnique _x;
            } forEach _selected;

            // AU still needs one normal primary faction in its factions array.
            // Keep that primary at index 0 without discarding coalition members.
            if (
                _primary != ""
                && {_primary in _selected}
            ) then {
                if !(_primary in _order) then {
                    _order insert [0, [_primary]];
                };
            };

            // Fallback for single-select/legacy states.
            if (
                _order isEqualTo []
                && {_primary != ""}
            ) then {
                _order = [_primary];
            };

            _lb setVariable [
                "Thorne_selectionOrder",
                _order
            ];

            _order
        };
        private _occSelection = [
            A3A_IDC_SETUP_OCCUPANTSLISTBOX,
            _factions#0
        ] call _getOrder;

        private _invSelection = [
            A3A_IDC_SETUP_INVADERSLISTBOX,
            _factions#1
        ] call _getOrder;

        private _rivSelection = [
            A3A_IDC_SETUP_RIVALSLISTBOX,
            _factions#4
        ] call _getOrder;

        private _coalitionCtrl =
            _display displayCtrl THORNE_IDC_SETUP_COALITIONCHECK;

        private _hasMultipleSelections =
            (count _occSelection > 1)
            || {count _invSelection > 1}
            || {count _rivSelection > 1};

        private _coalitionEnabled =
            cbChecked _coalitionCtrl
            || {_hasMultipleSelections};

        // Multi-selection and coalition-disabled are contradictory states.
        // Normalise the GUI immediately so the saved state always matches
        // what the player actually selected.
        if (_hasMultipleSelections && {!cbChecked _coalitionCtrl}) then {
            _coalitionCtrl cbSetChecked true;
            diag_log "[A3UEThorne Coalition] auto-enabled coalition because multiple factions are selected";
        };

        private _setupState = createHashMapFromArray [
            ["version", 2],
            ["coalitionEnabled", _coalitionEnabled],
            ["occupants", _occSelection],
            ["invaders", _invSelection],
            ["rivals", _rivSelection],
            ["switchEnemySides", cbChecked (_display displayCtrl A3A_IDC_SETUP_SWITCHENEMYCHECK)],
            ["overrideSideLimits", cbChecked (_display displayCtrl A3A_IDC_SETUP_ANYENEMYCHECK)],
            ["overrideCamoLimits", cbChecked (_display displayCtrl A3A_IDC_SETUP_IGNORECAMOCHECK)]
        ];

        diag_log format [
            "[A3UEThorne Coalition] setup selections OCC=%1 INV=%2 RIV=%3",
            _occSelection,
            _invSelection,
            _rivSelection
        ];
        _display setVariable ["Thorne_setupState", _setupState];
        private _plugins = _saveData getOrDefault ["saveDataPlugins", createHashMap];
        if (_plugins isEqualType []) then { _plugins = createHashMapFromArray _plugins };
        if !(_plugins isEqualType createHashMap) then { _plugins = createHashMap };
        _plugins set ["A3UEThorne_Setup", _setupState];
        _saveData set ["saveDataPlugins", _plugins];

        private _invEnabled = ctrlEnabled A3A_IDC_SETUP_INVADERSLISTBOX;
        private _rivEnabled = ctrlEnabled A3A_IDC_SETUP_RIVALSLISTBOX;
        private _displayNames = {
            params ["_value"];

            private _arr = if (_value isEqualType []) then {
                +_value
            } else {
                if (_value isEqualType "") then {
                    if (_value == "") then { [] } else { [_value] }
                } else {
                    []
                }
            };

            (_arr apply {
                private _cfg = A3A_SETUP_CONFIGFILE/"A3A"/"Templates"/_x;
                if (isClass _cfg) then {
                    getText (_cfg/"name")
                } else {
                    _x
                }
            }) joinString ", "
        };
        private _factionNames = [
            getText (A3A_SETUP_CONFIGFILE/"A3A"/"Templates"/_factions#2/"name"),
            getText (A3A_SETUP_CONFIGFILE/"A3A"/"Templates"/_factions#3/"name"),
            [_occSelection] call _displayNames,
            [
                localize "STR_params_afk_disabled",
                [_invSelection] call _displayNames
            ] select _invEnabled,
            [
                localize "STR_params_afk_disabled",
                [_rivSelection] call _displayNames
            ] select _rivEnabled
        ];
        _confirmText = _confirmText + endl + format [localize "STR_antistasi_dialogs_setup_confirm_factions", _factionNames#0, _factionNames#1, _factionNames#2, _factionNames#3, _factionNames#4];

        // Params tab: Array of [name, value]
        private _savedParams = ["getParams"] call A3A_fnc_setupParamsTab;
        _saveData set["params", _savedParams];

        // Set data & function for confirmation, then open confirmation box
        _display setVariable ["confirmData", [_confirmText, A3A_fnc_setupLoadgameTab, "startGameConfirm"]];
        _display setVariable ["newSaveData", _saveData];
        Debug_1("Prepared save data: %1", _saveData);
        createDialog "A3A_SetupConfirmDialog";
    };

    case ("startGameConfirm"):
    {
        // Send the start request to the server and close dialog

        (_display getVariable "newSaveData") remoteExec ["A3A_fnc_startGame", 2];
        ["serverClose"] call A3A_fnc_setupDialog;          // make sure the confirm dialog is closed first
    };

    case ("updateSaveInfoText"):
    {
        private _lbCurSel = _listboxCtrl getVariable "rowIndex";
        switch (true) do {
            case (_lbCurSel isEqualTo -1): { _saveInfoCtrl ctrlSetText localize "STR_antistasi_dialogs_setup_new_save" };
            case (cbChecked _copyGameCtrl): { _saveInfoCtrl ctrlSetText format [localize "STR_antistasi_dialogs_setup_copy_save", A3A_setup_saveData select _lbCurSel get "gameID" select[0, 4]] };
            case (cbChecked _newGameCtrl): { _saveInfoCtrl ctrlSetText localize "STR_antistasi_dialogs_setup_new_save" };
            default { _saveInfoCtrl ctrlSetText format [localize "STR_antistasi_dialogs_setup_edit_save", A3A_setup_saveData select _lbCurSel get "gameID" select[0, 4]] };
        };
    };

    case ("newGameCheck"):
    {
        ["updateSaveInfoText"] call A3A_fnc_setupLoadGameTab;
        ["update"] call A3A_fnc_setupLoadgameTab;
        ["enableParamsTab"] call A3A_fnc_setupDialog;
    };

    case ("copyGameCheck"):
    {
        // exitWith so that we don't infinite loop
        if (cbChecked _copyGameCtrl && cbChecked _oldParamsCtrl) exitWith { _oldParamsCtrl cbSetChecked false; ["updateSaveInfoText"] call A3A_fnc_setupLoadGameTab };
        ["updateSaveInfoText"] call A3A_fnc_setupLoadGameTab;
        ["update"] call A3A_fnc_setupLoadgameTab;
    };

    case ("oldParamsCheck"):
    {
        if (cbChecked _copyGameCtrl && cbChecked _oldParamsCtrl) exitWith { _copyGameCtrl cbSetChecked false;  ["updateSaveInfoText"] call A3A_fnc_setupLoadGameTab };
        ["updateSaveInfoText"] call A3A_fnc_setupLoadGameTab;
        ["update"] call A3A_fnc_setupLoadgameTab;
    };

    case ("oldNamespaceCheck"):
    {
        // Doesn't need to do anything here
    };

    case ("setHQPos"):
    {
        createDialog "A3A_SetupHQPosDialog";
    };

    case ("editZones"):
    {
        createDialog "A3A_SetupEditZonesDialog";
    };

    case ("deleteGame"):
    {
        private _index = _listboxCtrl getVariable ["rowIndex", -1];
        if (_index == -1) exitWith {};

        private _saveData = A3A_setup_saveData select _index;
        private _str = format [localize "STR_antistasi_dialogs_setup_confirm_delete", _saveData get "gameID", _saveData get "mapStr"];
        _display setVariable ["confirmData", [_str, A3A_fnc_setupLoadgameTab, "deleteGameConfirmed"]];
        createDialog "A3A_SetupConfirmDialog";
    };

    case ("deleteGameConfirmed"):
    {
        private _index = _listboxCtrl getVariable "rowIndex";
        private _saveData = A3A_setup_saveData select _index;
        [_saveData get "serverID", _saveData get "gameID", _saveData get "map"] remoteExecCall ["A3A_fnc_deleteSave", 2];
        A3A_setup_saveData deleteAt _index;
        ["setSaveData"] call A3A_fnc_setupLoadgameTab;
    };

    case ("renameGame"):
    {
        private _index = _listboxCtrl getVariable ["rowIndex", -1];
        if (_index == -1) exitWith {};
        private _nameBoxCtrl = _display displayCtrl A3A_IDC_SETUP_NAMEEDITBOX;
        private _newName = ctrlText _nameBoxCtrl;

        // Set name in save data
        private _saveData = A3A_setup_saveData select _index;
        _saveData set ["name", _newName];

        // Set immediately on server too
        private _saveTarget = [_saveData get "serverID", _saveData get "gameID", _saveData get "map"];
        ["name", _newName, _saveTarget] remoteExecCall ["A3A_fnc_writebackSaveVar", 2];

        // Set name in the displayed table
        private _nameCtrl = _listboxCtrl getVariable "nameCtrls" select _index;
        _nameCtrl ctrlSetText _newName;

        // Clear the name edit box
        _nameBoxCtrl ctrlSetText "";
    };
};
