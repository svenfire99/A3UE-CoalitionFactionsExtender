class CfgFunctions
{
    class A3A
    {
        class SetupGUI
        {
            class setupDialog { file = "\x\A3UE\addons\gui\functions\SetupGUI\fn_setupDialog.sqf"; };
            class setupFactionsTab { file = "\x\A3UE\addons\gui\functions\SetupGUI\fn_setupFactionsTab.sqf"; };
            class setupLoadgameTab { file = "\x\A3UE\addons\gui\functions\SetupGUI\fn_setupLoadgameTab.sqf"; };
        };
    };

    class Thorne
    {
        tag = "Thorne";

        class CoalitionSetup
        {
            file = "\x\A3UE\addons\gui\functions\CoalitionSetup";
            class getFactionOverrides {};
            class applyFactionOverrides {};
        };
    };
};
