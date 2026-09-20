# Antistasi Ultimate – Coalition Factions Extender

A small extender for **Antistasi Ultimate** that allows multiple factions to be used on the same side during a campaign.

Instead of being limited to one Occupant and one Invader faction, the setup menu can be used to select multiple factions and combine them into a coalition.

## How it works

When starting a new campaign, the normal Antistasi faction selection is extended with a **Faction Coalitions** option.

When enabled:

- Multiple **Occupant** factions can be selected.
- Multiple **Invader** factions can be selected.
- Rebels, Civilians and Rivals still use the normal single-faction selection.
- The first selected faction is used as the primary Antistasi faction.
- Additional factions are loaded as coalition members.

### Infantry

Infantry is selected on a **per-group basis**.

A squad is always spawned from one faction, instead of mixing units from different factions inside the same group.

Example:

```text
Squad 1 -> French Army
Squad 2 -> British Armed Forces
Squad 3 -> Bundeswehr
Squad 4 -> US Army
```

### Vehicles

Vehicle pools from all selected coalition factions are combined with the primary faction.

This allows bases, patrols, QRFs and other vehicle spawns to use equipment from every faction in the coalition.

For example, one airbase can contain French, British and American aircraft at the same time.

### Saving

Coalition settings are integrated into the Antistasi save system.

The following information is saved and restored:

- Whether coalition mode is enabled
- Selected Occupant factions
- Selected Invader factions
- Primary factions
- Coalition configuration

When loading a campaign, the selected factions are automatically restored and the coalition is rebuilt.

## Structure

The extender mainly consists of:

```text
addons/
├── core/
│   └── functions/
│       ├── Coalition/
│       ├── CREATE/
│       ├── Templates/
│       └── Save/
│
└── gui/
    ├── dialogues/
    └── functions/
        └── SetupGUI/
```

### Core

Handles:

- Loading additional faction templates
- Coalition faction registration
- Group faction selection
- Vehicle pool merging
- Save persistence

### GUI

Handles:

- Coalition checkbox
- Multi-selection for Occupants and Invaders
- Restoring selections from saves
- Coalition information in the confirmation dialog

## Requirements

- Arma 3
- Antistasi Ultimate
- Any mods required by the selected faction templates

## Compatibility

The extender uses existing **Antistasi Ultimate faction templates**.

This means no separate mixed faction templates are required. Any compatible faction already supported by Antistasi Ultimate can be used as part of a coalition, provided its required mods are loaded.

## Credits

**Antistasi Ultimate Community**  
For Antistasi Ultimate and its faction/template system.

**SvenBrandt99**  
Coalition extender and implementation.
