/*
    Runtime containers only.
    Actual OCC/INV extra selections are supplied by the setup GUI.
*/
Thorne_CoalitionConfig = createHashMapFromArray [
    ["occ", []],
    ["inv", []]
];

Thorne_CoalitionFactions = createHashMapFromArray [
    ["occ", createHashMap],
    ["inv", createHashMap]
];

diag_log "[Thorne Coalition] runtime configuration initialized";
