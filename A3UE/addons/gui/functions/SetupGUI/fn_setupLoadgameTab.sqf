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

#include "\x\A3A\addons\gui\dialogues\ids.inc"
#include "..\..\dialogues\ids.inc"
#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\gui\dialogues\textures.inc"
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

params["_mode", "_params"];

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
    ["gameID", "ID", 0, 9],
    ["mapStr", localize "STR_antistasi_setup_dialog_table_map", 9, 25],
    ["name", localize "STR_antistasi_setup_dialog_table_name", 25, 45],
    ["verStr", localize "STR_antistasi_setup_dialog_table_version", 70, 12],
    ["timeStr", localize "STR_antistasi_setup_dialog_table_time", 82, 15],
    ["fileStr", localize "STR_antistasi_setup_dialog_table_file", 97, 9]
];

switch (_mode) do
{
    case ("onLoad"):
    {
        _display setVariable ["savedFactions", [[], [], []]];
        _display setVariable ["savedCoalition", [false, [[], []]]];
        _display setVariable ["savedParams", []];
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

        // If we're selecting a game to load, load factions if available.
        private _factions = [_saveData get "factions", _saveData get "addonVics", _saveData get "DLC"];
        if (isNil {_factions#0}) then { _factions = [[], [], []] };

        private _loadingExistingSetup =
            _sameMap
            && {
                !cbChecked _newGameCtrl
                || {cbChecked _copyGameCtrl}
            };

        if (!_loadingExistingSetup) then {
            _factions = [[], [], []];
        };

        // -----------------------------------------------------------------
        // Thorne coalition persistence
        //
        // Old saves do not contain these fields, so they cleanly fall back
        // to coalition disabled with no extra factions.
        // -----------------------------------------------------------------
        private _coalitionEnabled = false;
        private _coalitionConfig = [[], []];

        if (_loadingExistingSetup) then {
            _coalitionEnabled = _saveData getOrDefault [
                "Thorne_coalitionEnabled",
                false
            ];

            _coalitionConfig = _saveData getOrDefault [
                "Thorne_coalitionConfig",
                [[], []]
            ];

            if !(
                _coalitionConfig isEqualType []
                && {count _coalitionConfig >= 2}
            ) then {
                diag_log format [
                    "[Thorne Coalition Save] WARNING invalid saved coalition config: %1",
                    _coalitionConfig
                ];
                _coalitionConfig = [[], []];
            };
        };

        private _coalitionState = [
            _coalitionEnabled,
            _coalitionConfig
        ];

        private _factionsChanged =
            _factions isNotEqualTo (_display getVariable "savedFactions");

        private _coalitionChanged =
            _coalitionState isNotEqualTo (
                _display getVariable [
                    "savedCoalition",
                    [false, [[], []]]
                ]
            );

        if (_coalitionChanged) then {
            _display setVariable [
                "savedCoalition",
                _coalitionState
            ];

            missionNamespace setVariable [
                "Thorne_CoalitionConfigNet",
                _coalitionConfig,
                true
            ];

            private _coalitionCheck =
                _display displayCtrl THORNE_IDC_SETUP_COALITIONCHECK;

            _coalitionCheck cbSetChecked _coalitionEnabled;

            // Prepare the selected config-name arrays BEFORE fillFactions.
            // The coalition-aware fill function uses these to restore the
            // normal orange LB_MULTI highlighting.
            if (
                _coalitionEnabled
                && {count (_factions param [0, []]) >= 2}
            ) then {
                private _savedFactionIDs = _factions # 0;

                private _occMain = _savedFactionIDs # 0;
                private _invMain = _savedFactionIDs # 1;

                private _occSelected = [_occMain];
                private _invSelected = [_invMain];

                {
                    if (
                        _x isEqualType []
                        && {count _x > 0}
                    ) then {
                        _occSelected pushBackUnique (_x # 0);
                    };
                } forEach (_coalitionConfig param [0, []]);

                {
                    if (
                        _x isEqualType []
                        && {count _x > 0}
                    ) then {
                        _invSelected pushBackUnique (_x # 0);
                    };
                } forEach (_coalitionConfig param [1, []]);

                _display setVariable [
                    "Thorne_occSelections",
                    _occSelected
                ];

                _display setVariable [
                    "Thorne_invSelections",
                    _invSelected
                ];

                private _occCtrl =
                    _display displayCtrl A3A_IDC_SETUP_OCCUPANTSLISTBOX;

                private _invCtrl =
                    _display displayCtrl A3A_IDC_SETUP_INVADERSLISTBOX;

                _occCtrl setVariable [
                    "Thorne_primaryFaction",
                    _occMain
                ];

                _invCtrl setVariable [
                    "Thorne_primaryFaction",
                    _invMain
                ];

                diag_log format [
                    "[Thorne Coalition Save] prepared restore enabled=true OCC=%1 INV=%2",
                    _occSelected,
                    _invSelected
                ];
            } else {
                _display setVariable [
                    "Thorne_occSelections",
                    []
                ];

                _display setVariable [
                    "Thorne_invSelections",
                    []
                ];

                if (_loadingExistingSetup) then {
                    diag_log "[Thorne Coalition Save] loaded save with coalition disabled";
                };
            };
        };

        if (_factionsChanged || _coalitionChanged) then {
            _display setVariable ["savedFactions", _factions];
            ["fillFactions"] call A3A_fnc_setupFactionsTab;
            ["fillContent"] call A3A_fnc_setupFactionsTab;
        };

        // If it's not a new game or load params or copy game is checked, load params
        private _params = _saveData get "params";
        if (isNil "_params") then { _params = [] };               // getOrDefault doesn't work because input code may set nils
        if ((_sameMap and !cbChecked _newGameCtrl) or cbChecked _copyGameCtrl or cbChecked _oldParamsCtrl) then {
            if (count _params > 0 and _params isNotEqualTo (_display getVariable "savedParams")) then { 
                _display setVariable ["savedParams", _params];
                ["fillParams"] call A3A_fnc_setupParamsTab;
            };
        } else {
            if (cbChecked _newGameCtrl && {!(_display getVariable ["paramsChangedSinceReset", false])}) then { 
                _display setVariable ["savedParams", []];
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
            _x params ["_varname", "", "_xpos", "_width"];
            private _ctrls = [];
            {
                private _ctrl = _display ctrlCreate ["A3A_Text_Small", -1, _listboxCtrl];
                _ctrl ctrlSetPosition [GRID_W*_xpos, GRID_H*_forEachIndex*4, GRID_W*_width, GRID_H*4];
                _ctrl ctrlCommit 0;
                _ctrl ctrlSetText (_x getOrDefault [_varname, ""]);
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

        // -----------------------------------------------------------------
        // Persist Thorne coalition setup alongside AU's normal five factions.
        //
        // setupFactionsTab/getFactions has already refreshed
        // Thorne_CoalitionConfigNet at this point.
        // -----------------------------------------------------------------
        private _coalitionEnabled =
            cbChecked (_display displayCtrl THORNE_IDC_SETUP_COALITIONCHECK);

        private _coalitionData = missionNamespace getVariable [
            "Thorne_CoalitionConfigNet",
            [[], []]
        ];

        if !(
            _coalitionData isEqualType []
            && {count _coalitionData >= 2}
        ) then {
            diag_log format [
                "[Thorne Coalition Save] WARNING invalid runtime coalition config: %1",
                _coalitionData
            ];
            _coalitionData = [[], []];
        };

        // If coalition mode is disabled, never carry old/stale extra factions
        // into a newly created or edited save.
        if (!_coalitionEnabled) then {
            _coalitionData = [[], []];

            missionNamespace setVariable [
                "Thorne_CoalitionConfigNet",
                _coalitionData,
                true
            ];
        };

        _saveData set [
            "Thorne_coalitionEnabled",
            _coalitionEnabled
        ];

        _saveData set [
            "Thorne_coalitionConfig",
            _coalitionData
        ];

        diag_log format [
            "[Thorne Coalition Save] saving enabled=%1 config=%2",
            _coalitionEnabled,
            _coalitionData
        ];

        private _invEnabled = ctrlEnabled A3A_IDC_SETUP_INVADERSLISTBOX;
        private _rivEnabled = ctrlEnabled A3A_IDC_SETUP_RIVALSLISTBOX;


        // ------------------------------------------------------------
        // Normal faction display names
        // ------------------------------------------------------------

        private _rebelName =
            getText (
                A3A_SETUP_CONFIGFILE
                / "A3A"
                / "Templates"
                / (_factions # 2)
                / "name"
            );

        private _civName =
            getText (
                A3A_SETUP_CONFIGFILE
                / "A3A"
                / "Templates"
                / (_factions # 3)
                / "name"
            );

        private _occMainName =
            getText (
                A3A_SETUP_CONFIGFILE
                / "A3A"
                / "Templates"
                / (_factions # 0)
                / "name"
            );

        private _invMainName =
            getText (
                A3A_SETUP_CONFIGFILE
                / "A3A"
                / "Templates"
                / (_factions # 1)
                / "name"
            );

        private _rivalName =
            getText (
                A3A_SETUP_CONFIGFILE
                / "A3A"
                / "Templates"
                / (_factions # 4)
                / "name"
            );


        // ------------------------------------------------------------
        // Coalition data
        //
        // Format:
        // [
        //     OCC extras,
        //     INV extras
        // ]
        //
        // Extra entry:
        // [configName, templatePath]
        // ------------------------------------------------------------

        private _coalitionData = missionNamespace getVariable [
            "Thorne_CoalitionConfigNet",
            [[], []]
        ];

        private _occExtras = _coalitionData param [
            0,
            []
        ];

        private _invExtras = _coalitionData param [
            1,
            []
        ];


        // ------------------------------------------------------------
        // Resolve configName -> display name
        // ------------------------------------------------------------

        private _fnc_getFactionDisplayName = {
            params ["_configName"];

            private _cfg =
                A3A_SETUP_CONFIGFILE
                / "A3A"
                / "Templates"
                / _configName;

            if (isClass _cfg) exitWith {
                getText (_cfg / "name")
            };

            _configName
        };


        // ------------------------------------------------------------
        // Build OCC list
        // ------------------------------------------------------------

        private _occNames = [
            _occMainName
        ];

        {
            _x params [
                "_configName",
                ["_templatePath", ""]
            ];

            private _displayName = [
                _configName
            ] call _fnc_getFactionDisplayName;

            _occNames pushBackUnique _displayName;

        } forEach _occExtras;


        // ------------------------------------------------------------
        // Build INV list
        // ------------------------------------------------------------

        private _invNames = [
            _invMainName
        ];

        {
            _x params [
                "_configName",
                ["_templatePath", ""]
            ];

            private _displayName = [
                _configName
            ] call _fnc_getFactionDisplayName;

            _invNames pushBackUnique _displayName;

        } forEach _invExtras;


        // ------------------------------------------------------------
        // Convert to confirmation text
        // ------------------------------------------------------------

        private _occDisplay =
            _occNames joinString ", ";

        private _invDisplay =
            _invNames joinString ", ";


        // ------------------------------------------------------------
        // Build same array AU expects
        // ------------------------------------------------------------

        private _factionNames = [

            // Rebels
            _rebelName,

            // Civilians
            _civName,

            // Occupants
            _occDisplay,

            // Invaders
            [
                localize "STR_params_afk_disabled",
                _invDisplay
            ] select _invEnabled,

            // Rivals
            [
                localize "STR_params_afk_disabled",
                _rivalName
            ] select _rivEnabled

        ];
        _confirmText = _confirmText + endl + format [localize "STR_antistasi_dialogs_setup_confirm_factions", _factionNames#0, _factionNames#1, _factionNames#2, _factionNames#3, _factionNames#4];

        // Params tab: Array of [name, value]
        private _paramsData = ["getParams"] call A3A_fnc_setupParamsTab;
        _saveData set ["params", _paramsData];

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
            case (cbChecked _copyGameCtrl): { _saveInfoCtrl ctrlSetText format [localize "STR_antistasi_dialogs_setup_copy_save", A3A_setup_saveData select _lbCurSel get "gameID"] };
            case (cbChecked _newGameCtrl): { _saveInfoCtrl ctrlSetText localize "STR_antistasi_dialogs_setup_new_save" };
            default { _saveInfoCtrl ctrlSetText format [localize "STR_antistasi_dialogs_setup_edit_save", A3A_setup_saveData select _lbCurSel get "gameID"] };
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
        private _newName = ctrlText (_display displayCtrl A3A_IDC_SETUP_NAMEEDITBOX);

        // Set name in save data
        private _saveData = A3A_setup_saveData select _index;
        _saveData set ["name", _newName];

        // Set immediately on server too
        private _saveTarget = [_saveData get "serverID", _saveData get "gameID", _saveData get "map"];
        ["name", _newName, _saveTarget] remoteExecCall ["A3A_fnc_writebackSaveVar", 2];

        // Set name in the displayed table
        private _nameCtrl = _listboxCtrl getVariable "nameCtrls" select _index;
        _nameCtrl ctrlSetText _newName;
    };
};
