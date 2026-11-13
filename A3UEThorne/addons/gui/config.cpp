class CfgPatches
{
    class A3UEThorne_coalition_gui
    {
        name = "A3UEThorne Coalition GUI";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] =
        {
            "A3A_gui",
            "A3A_ultimate",
            "A3UEThorne_core"
        };
        author = "SvenBrandt99";
    };
};

#include "CfgFunctions.hpp"

#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\gui\dialogues\controls.hpp"
#include "\x\A3A\addons\gui\dialogues\dialogs.hpp"

#include "dialogues\ids.inc"
#include "dialogues\setupDialog.hpp"
