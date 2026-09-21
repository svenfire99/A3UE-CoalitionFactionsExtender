// note use of preInit & postInit will run for EVERY mission, use sparingly or with non a3a mission aborts in place, example check if the class (missionConfigFile >> "A3A") exists
class CfgFunctions
{
    // ---------------------------------------------------------
    // A3AU overrides
    // ---------------------------------------------------------
    class A3A
    {
        class CREATE
        {
            class createUnit { file = QPATHTOFOLDER(functions\CREATE\fn_createUnit.sqf); };
            class NATOinit { file = QPATHTOFOLDER(functions\CREATE\fn_NATOinit.sqf); };
            class spawnGroup { file = QPATHTOFOLDER(functions\CREATE\fn_spawnGroup.sqf); };
        };

        class FunctionsTemplates
        {
            class compatibilityLoadFaction { file = QPATHTOFOLDER(functions\Templates\fn_compatibilityLoadFaction.sqf); };
        };

        class Missions {
            class RES_Deserters { file = QPATHTOFOLDER(functions\Missions\fn_RES_Deserters.sqf); };
        };

        class Save
        {
            class saveLoop { file = QPATHTOFOLDER(functions\Save\fn_saveLoop.sqf); };
            class collectSaveData { file = QPATHTOFOLDER(functions\Save\fn_collectSaveData.sqf); };
        };

        class Utility
        {
            class setIdentity { file = QPATHTOFOLDER(functions\Utility\fn_setIdentity.sqf); };
        };
    };


    // ---------------------------------------------------------
    // Thorne coalition functions
    // ---------------------------------------------------------
    class Thorne
    {
        tag = "Thorne";

        class Coalition
        {
            file = QPATHTOFOLDER(functions\Coalition);

            class initCoalition { preInit = 1; };
            class loadCoalitionFaction {};
            class loadCoalitionForSide {};
            class resolveCoalitionType {};
            class mergeCoalitionVehicles {};
        };
    };
};
