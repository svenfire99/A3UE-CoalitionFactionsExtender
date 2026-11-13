/*
    A3UE coalition setup dialog.
    Base layout stays entirely AU-owned; only the three enemy list styles
    and one checkbox are changed.
*/
class A3UE_Coalition_SetupDialog : A3A_SetupDialog
{
    class Controls : Controls
    {
        class TitlebarText : TitlebarText {};
        class TabButtons : TabButtons {};
        class LoadgameTab : LoadgameTab {};

        class FactionsTab : FactionsTab
        {
            class Controls : Controls
            {
                class RebelsLabel : RebelsLabel {};
                class RebelsListBox : RebelsListBox {};

                class CiviliansLabel : CiviliansLabel {};
                class CiviliansListBox : CiviliansListBox {};

                class OccupantsLabel : OccupantsLabel {};
                class OccupantsListBox : A3A_Listbox_Small
                {
                    idc = A3A_IDC_SETUP_OCCUPANTSLISTBOX;
                    style = 32;
                    onLBSelChanged = "['factionSelected', _this] call A3A_fnc_setupFactionsTab";
                    x = 44 * GRID_W;
                    y = 8 * GRID_H;
                    w = 38 * GRID_W;
                    h = 88 * GRID_H;
                };

                class InvadersLabel : InvadersLabel {};
                class InvadersListBox : A3A_Listbox_Small
                {
                    idc = A3A_IDC_SETUP_INVADERSLISTBOX;
                    style = 32;
                    onLBSelChanged = "['factionSelected', _this] call A3A_fnc_setupFactionsTab";
                    x = 84 * GRID_W;
                    y = 8 * GRID_H;
                    w = 38 * GRID_W;
                    h = 40 * GRID_H;
                };

                class RivalsLabel : RivalsLabel {};
                class RivalsListBox : A3A_Listbox_Small
                {
                    idc = A3A_IDC_SETUP_RIVALSLISTBOX;
                    style = 32;
                    onLBSelChanged = "['factionSelected', _this] call A3A_fnc_setupFactionsTab";
                    x = 84 * GRID_W;
                    y = 54 * GRID_H;
                    w = 38 * GRID_W;
                    h = 42 * GRID_H;
                };

                class ModifiersGroup : ModifiersGroup
                {
                    h = 24 * GRID_H;

                    class controls : controls
                    {
                        class Label : Label {};

                        class Background : Background
                        {
                            h = 20 * GRID_H;
                        };

                        class SwitchEnemyCheck : SwitchEnemyCheck {};
                        class SwitchEnemyText : SwitchEnemyText {};
                        class AnyEnemyCheck : AnyEnemyCheck {};
                        class AnyEnemyText : AnyEnemyText {};
                        class IgnoreCamoCheck : IgnoreCamoCheck {};
                        class IgnoreCamoText : IgnoreCamoText {};
                        class ShowMissingCheck : ShowMissingCheck {};
                        class ShowMissingText : ShowMissingText {};

                        class CoalitionCheck : SwitchEnemyCheck
                        {
                            idc = THORNE_IDC_SETUP_COALITIONCHECK;
                            y = 20 * GRID_H;
                            onCheckedChanged = "['coalitionToggle', _this] call A3A_fnc_setupFactionsTab";
                        };

                        class CoalitionText : SwitchEnemyText
                        {
                            idc = -1;
                            text = "Enable faction coalitions";
                            y = 20 * GRID_H;
                            tooltip = "Allow multiple Occupant and Invader factions. (Hold CTRL/SHIFT to select multiple factions.)";
                        };
                    };
                };

                class DLCContentGroup : DLCContentGroup
                {
                    y = 30 * GRID_H;
                    h = 20 * GRID_H;

                    class controls : controls
                    {
                        class Label : Label {};
                        class Background : Background { h = 16 * GRID_H; };
                        class Box : Box { h = 16 * GRID_H; };
                    };
                };

                class AddonContentGroup : AddonContentGroup
                {
                    y = 52 * GRID_H;
                    h = 44 * GRID_H;

                    class controls : controls
                    {
                        class Label : Label {};
                        class Background : Background { h = 40 * GRID_H; };
                        class Box : Box { h = 40 * GRID_H; };
                    };
                };
            };
        };

        class ParamsTab : ParamsTab {};
    };
};
