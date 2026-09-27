class CfgFunctions
{
    class A3A
    {
        class CREATE
        {
            class createUnit { file = QPATHTOFOLDER(functions\CREATE\fn_createUnit.sqf); };
            class NATOinit { file = QPATHTOFOLDER(functions\CREATE\fn_NATOinit.sqf); };
            class spawnGroup { file = QPATHTOFOLDER(functions\CREATE\fn_spawnGroup.sqf); };

            class RivalsCrewTypeForVehicle { file = QPATHTOFOLDER(functions\CREATE\fn_RivalsCrewTypeForVehicle.sqf); };
            class RivalsSpawnGroup { file = QPATHTOFOLDER(functions\CREATE\fn_RivalsSpawnGroup.sqf); };
            class RivalsSpawnVehicle { file = QPATHTOFOLDER(functions\CREATE\fn_RivalsSpawnVehicle.sqf); };
            class RivalsCargoSeats { file = QPATHTOFOLDER(functions\CREATE\fn_RivalsCargoSeats.sqf); };
            class RivalsCreateUnit { file = QPATHTOFOLDER(functions\CREATE\fn_RivalsCreateUnit.sqf); };
            class RivalsCreateVehicleCrew { file = QPATHTOFOLDER(functions\CREATE\fn_RivalsCreateVehicleCrew.sqf); };
        };

        class FunctionsTemplates
        {
            class compatibilityLoadFaction { file = QPATHTOFOLDER(functions\Templates\fn_compatibilityLoadFaction.sqf); };
            class loadRivals { file = QPATHTOFOLDER(functions\Templates\fn_loadRivals.sqf); };
        };

        class Utility
        {
            class setIdentity { file = QPATHTOFOLDER(functions\Utility\fn_setIdentity.sqf); };
        };

        class Save
        {
            class saveLoop { file = QPATHTOFOLDER(functions\Save\fn_saveLoop.sqf); };
            class collectSaveData { file = QPATHTOFOLDER(functions\Save\fn_collectSaveData.sqf); };
        };
    };

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
            class selectCoalitionForGroup {};
            class mergeCoalitionVehicles {};
        };
    };
};
