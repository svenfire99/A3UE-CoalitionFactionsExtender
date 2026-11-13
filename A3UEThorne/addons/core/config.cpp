#include "script_component.hpp"

class CfgPatches
{
    class A3UEThorne_core
    {
        name = "A3UEThorne - Faction Coalitions";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"A3A_core", "A3A_ultimate", "A3A_bazaar"};
        author = "ThorneOfCallisto";
        A3A_compatibility[] = {12, 4};
    };
};

#include "cfgFunctions.hpp"
