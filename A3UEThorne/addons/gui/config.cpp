class CfgPatches
{
    class A3UEThorne_gui
    {
        name = "A3UEThorne - Coalition Setup GUI";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"A3A_gui", "A3A_ultimate", "A3UEThorne_core"};
        author = "ThorneOfCallisto";
        A3A_compatibility[] = {12, 4};
    };
};

#include "CfgFunctions.hpp"
#include "\x\A3A\addons\gui\dialogues\defines.hpp"
#include "\x\A3A\addons\gui\dialogues\textures.inc"
#include "\x\A3A\addons\gui\dialogues\controls.hpp"
#include "dialogues\ids.inc"
#include "dialogues\setupDialog.hpp"
