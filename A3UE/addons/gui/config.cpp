class CfgPatches
{
    class A3UE_coalition_gui
    {
        name = "A3UE Coalition GUI";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] =
        {
            "A3A_gui",
            "A3A_ultimate",
            "A3UE_core"
        };
        author = "ThorneOfCallisto";
    };
};

#include "CfgFunctions.hpp"

#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\gui\dialogues\controls.hpp"
#include "\x\A3A\addons\gui\dialogues\dialogs.hpp"

#include "dialogues\ids.inc"
#include "dialogues\setupDialog.hpp"
