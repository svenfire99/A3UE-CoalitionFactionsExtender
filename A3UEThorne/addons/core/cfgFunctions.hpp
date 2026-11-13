class CfgFunctions
{
    class A3A
    {
        class CREATE
        {
            class NATOinit { file = "\x\A3UEThorne\addons\core\functions\CREATE\fn_NATOinit.sqf"; };
            class spawnGroup { file = "\x\A3UEThorne\addons\core\functions\CREATE\fn_spawnGroup.sqf"; };
            class RivalsSpawnGroup { file = "\x\A3UEThorne\addons\core\functions\CREATE\fn_RivalsSpawnGroup.sqf"; };
            class RivalsCreateUnit { file = "\x\A3UEThorne\addons\core\functions\CREATE\fn_RivalsCreateUnit.sqf"; };
        };

        class FunctionsTemplates
        {
            class compatibilityLoadFaction { file = "\x\A3UEThorne\addons\core\functions\Templates\fn_compatibilityLoadFaction.sqf"; };
            class loadRivals { file = "\x\A3UEThorne\addons\core\functions\Templates\fn_loadRivals.sqf"; };
        };

        class Save
        {
            class collectSaveData { file = "\x\A3UEThorne\addons\core\functions\Save\fn_collectSaveData.sqf"; };
        };
    };

    class ABZ
    {
        class main
        {
            class poolFromFactions
            {
                file = "\x\A3UEThorne\addons\core\functions\Bazaar\fn_poolFromFactions.sqf";
            };
        };
    };

    class Thorne
    {
        tag = "Thorne";

        class Coalition
        {
            file = "\x\A3UEThorne\addons\core\functions\Coalition";
            class initCoalition { preInit = 1; };
            class readSetupState {};
            class prepareCoalitionState {};
            class loadCoalitionFaction {};
            class loadCoalitionForSide {};
            class resolveCoalitionType {};
            class selectCoalitionForGroup {};
            class mergeCoalitionVehicles {};
        };
    };
};
