/*
    A3UE Coalition runtime initialization.

    Coalition slots:
        occ -> Occupants
        inv -> Invaders
        riv -> Rivals

    GUI compatibility:
    Existing GUI builds publish:
        Thorne_CoalitionConfigNet = [OCC, INV]

    Rival-aware GUI will publish:
        Thorne_CoalitionConfigNet = [OCC, INV, RIV]

    The third entry is optional so current saves/UI remain compatible.
*/

Thorne_CoalitionConfig = createHashMapFromArray [
    ["occ", []],
    ["inv", []],
    ["riv", []]
];

Thorne_CoalitionFactions = createHashMapFromArray [
    ["occ", createHashMap],
    ["inv", createHashMap],
    ["riv", createHashMap]
];

// unique generated unit type -> faction HashMap
// Used as a redundant identity fallback for units created outside spawnGroup.
Thorne_CoalitionTypeFactionMap = createHashMap;

diag_log "[Thorne Coalition] runtime configuration initialized (occ/inv/riv)";
