/*
    Do NOT redefine A3A_SetupDialog directly.

    A3UE_Coalition_SetupDialog inherits the current A3AU dialog and only
    changes the faction controls needed for coalition selection.
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
                // Rebels stay normal single-select.
                class RebelsLabel : RebelsLabel {};
                class RebelsListBox : RebelsListBox {};

                // Civilians stay normal single-select.
                class CiviliansLabel : CiviliansLabel {};
                class CiviliansListBox : CiviliansListBox {};

                class OccupantsLabel : OccupantsLabel {};

                // LB_MULTI = 32. This keeps multiple selected rows highlighted
                // with A3AU's normal orange selected-row background.
                class OccupantsListBox : OccupantsListBox
                {
                    style = 32;
                };

                class InvadersLabel : InvadersLabel {};

                class InvadersListBox : InvadersListBox
                {
                    style = 32;
                };

                // Rivals stay normal single-select.
                class RivalsLabel : RivalsLabel {};
                class RivalsListBox : RivalsListBox {};

                // Add one extra checkbox below the existing four override rows.
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

                // Shift the remaining right-side groups down to make room.
                class DLCContentGroup : DLCContentGroup
                {
                    y = 30 * GRID_H;
                    h = 20 * GRID_H;

                    class controls : controls
                    {
                        class Label : Label {};
                        class Background : Background
                        {
                            h = 16 * GRID_H;
                        };
                        class Box : Box
                        {
                            h = 16 * GRID_H;
                        };
                    };
                };

                class AddonContentGroup : AddonContentGroup
                {
                    y = 52 * GRID_H;
                    h = 44 * GRID_H;

                    class controls : controls
                    {
                        class Label : Label {};
                        class Background : Background
                        {
                            h = 40 * GRID_H;
                        };
                        class Box : Box
                        {
                            h = 40 * GRID_H;
                        };
                    };
                };
            };
        };

        class ParamsTab : ParamsTab {};
    };
};
