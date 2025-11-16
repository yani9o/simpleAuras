# simpleAuras

### ⚠️ **Information**
- This AddOn is still in development.
- There will be functions that don't work as they should.
- Please report bugs.
- Currently don't have time to work alot on the AddOn, but i check Issues often.


<img width="508" height="322" alt="image" src="https://github.com/user-attachments/assets/15338563-4fbd-454c-9609-3d95f0214cc0" />


## Known Issues
- Learning new AuraDuration gets prematurely completed if another player's aura with the same name runs out on the same target before yours - no way to get casterID when an aura fades.
- Skills that apply Auras with the same name may show "learning" all the time (maybe this one is fixed now - wasn't able to test yet).
- AddOn is kinda heavy on ressources (compared to other addons), will optimize in a future update.
- /sa learnall 1 tries to learn spells without aura (i.e. smite, shadowbolt, etc.). Use `/sa nolearning <spellID>` to exclude specific spells from learning.


## Console Commands:
/sa or /sa show or /sa hide - Show/hide simpleAuras Settings.

/sa refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5).

### SuperWoW commands:
/sa learn X Y - manually set duration Y of spellID X.

/sa forget X - forget AuraDuration of SpellID X (or use 'all' instead to delete all durations).

/sa update X - force AuraDurations updates (1 = re-learn aura durations. Default: 0).

/sa showlearning X - shows learning of new AuraDurations in chat (1 = show. Default: 0).

/sa learnall X - learn all AuraDurations, even if no Aura is set up. (1 = Active. Default: 0).

/sa nolearning X - exclude spellID X from learning (toggle). Use 'list' to show all excluded spells, 'clear' to clear all exclusions.


## Settings (/sa)
<img width="819" height="605" alt="image" src="https://github.com/user-attachments/assets/ffd56904-f840-41b5-80bd-63550fef2ba3" />


### Overview
Shows all existing auras.

- [+] / Add Aura: Creates a new, blank aura.
- [i] / Import: Opens a window to import one or multiple auras from a text string.
- [e] / Export: Exports all your auras into a single text string.
- v / ^: Sort aura priority (for organizational purposes)
- Scroll: Mouse wheel to scroll through aura list (unlimited auras supported)

  *(you can also sort auras via drag & drop)*
- Movable Auras: While in settings, you can move any visible aura by holding down `Ctrl`+`Alt`+`Shift` keys and dragging it.
- Layer Control: Use Layer field to control which auras display on top (higher number = on top)


### Aura-Editor
Shows the currently edited aura only.

Enabled/Disabled:
- A master toggle at the top of the editor to quickly turn an aura on or off. Disabled auras are highlighted in red in the main list.

Layer:
- Frame stacking order (0-999). Higher layer number = displayed on top of lower layers. Default: 0.

My Casts only*:
- Only tracks your own casts of edited aura.

Aura/Spellname Name:
- Name of the aura to track (has to be exactly the same name)


Icon/Texture:
- Color: Basecolor of the aura.
- Autodetect: Gets icon from buff.
- Browse: Choose a texture.
- Scale: Basescale of 1 is 48x48px.
- x/y pos: Position from center of the screen.
- Show Duration*/Stacks: Shows Duration and/or Stacks on the icon/texture.
- Duration Size/Stacks Size: Adjustable font size for duration and stacks text (default: 20 for duration, 14 for stacks).
  - Text positioning:
    - If both Duration and Stacks are enabled: Duration appears at the top, Stacks at the bottom.
    - If only Duration is enabled: Duration appears centered.
    - If only Stacks is enabled: Stacks appear centered.


Conditions:
- Unit: Which unit the aura is on.
  - For Buff/Debuff types: `Player` or `Target`
  - For Poison type: `MH` (MainHand) or `OH` (OffHand)
- Type: Type of aura to track.
  - `Buff`: Tracks beneficial effects
  - `Debuff`: Tracks harmful effects
  - `Cooldown`: Tracks spell/item cooldowns
  - `Reactive`: Tracks proc-based abilities (Riposte, Overpower, etc)
  - `Poison`: Tracks poison enchantments on weapons
- Low Duration Color*: If the auracolor should change at or below "lowduration"
- Low Duration in secs*: Allways active, changes durationcolor to red if at or below, also changes color if activated.
- In/Out of Combat: When aura should be shown
- In Raid / In Party: Restricts the aura to only be active when you are in a raid or party (but not a raid).

Buff/Debuff:
- Invert: Activate to show aura if not found.
- Dual: Mirrors the aura (if xpos = -150, then it will show a mirrored icon/texture at xpos 150).

Poison:
- Unit: Select `MH` (MainHand) or `OH` (OffHand) to track poison on that weapon slot
- Automatically detects poison presence, duration, and charges
- Updates every 3 seconds (independent of refresh rate setting)

Cooldown:
- Always: Shows Cooldown Icon if it's on CD or not.
- No CD: Show when not on CD.
- CD: Show when on CD.
- Equipped: Enable red warning color when item is in bags instead of equipped (useful for trinkets).


Other:
- [c] / Copy: Copies the aura.
- [e] / Export: Exports only the current aura into a text string.
- Delete: Deletes the aura after confirmation.

\* = For these functions to work on targets SuperWoW is REQUIRED! Also only shows your own AuraDurations.


## Poison Tracking

simpleAuras can track poison enchantments on your weapons (MainHand and OffHand). This allows you to monitor when your poisons expire and how many charges remain.

### How to set up:

1. **Create the aura:**
   - Type: `Poison`
   - Unit: Select `MH` (MainHand) or `OH` (OffHand)
   - Aura Name: Can be any name (poison type is detected automatically)
   - Enable: `Show Duration` and/or `Show Stacks` as needed
   - Duration Size/Stacks Size: Adjust font sizes for better visibility

2. **Usage:**
   - The aura will automatically detect when a poison is applied to the selected weapon
   - Shows remaining duration and charges (if available)
   - Updates every 3 seconds (independent of refresh rate)
   - Updates immediately when weapon is changed or poison is applied/removed

### Notes:
- Poison data updates use a fixed 3-second timer for performance (independent of `/sa refresh` setting)
- Works best with weapon slots that can have poisons applied
- Charges display depends on poison type (some poisons don't show charge count)

## Reactive Spells Setup (Riposte, Overpower, etc)

Reactive spells are proc-based abilities that become available after specific events (dodge, parry, block). Unlike buffs and cooldowns, they require **manual duration setup**.

### How to set up:

1. **Create the aura:**
   - Type: `Reactive`
   - Aura Name: Exact spell name (e.g., `Riposte`, `Surprise Attack`)
   - Enable: `Show Duration`
   - Conditions: Set as needed (In Combat, etc)

2. **Set duration manually (REQUIRED):**
   ```
   /sa reactduration Riposte 5
   /sa reactduration "Surprise Attack" 6
   /sa reactduration Overpower 5
   ```

3. **Test it:**
   - Wait for proc to trigger (dodge/parry/block)
   - Icon will appear with timer countdown
   - Timer refreshes on repeated procs (when detected)
   - Icon disappears when you use the ability or timer expires

### Known Limitations:
- **Manual duration required:** Vanilla API doesn't provide proc expiration events.
- **Refresh detection:** `COMBAT_TEXT_UPDATE` only fires when ability *becomes* available, not on subsequent procs while already active.

## Cooldown Tracking

simpleAuras tracks cooldowns for:
- **Spells** from your spellbook
- **Items** in your bags (potions, food, etc)
- **Equipped items** (trinkets, engineering items, etc)

### Item Cooldown Features:
- **Auto-detection:** Automatically finds items in bags and equipped slots
- **Smart caching:** Remembers itemID for continued tracking even when item is consumed
- **Equipped warning:** Enable "Equipped" checkbox for trinkets/items to show red warning when item is in bags instead of equipped
- **Works with:** Trinkets, engineering items, potions, bandages, and any usable items

### Setup Example (Trinket):
1. Create aura: Type `Cooldown`, Name: exact item name (e.g., `Earthstrike`)
2. Enable `Autodetect` to get icon automatically
3. Enable `Equipped` checkbox to get red warning when trinket is in bag
4. Set show condition: `Always`, `CD`, or `No CD`

## SuperWoW Features
If SuperWoW is installed, simpleAuras will automatically learn unkown durations of most of **your own** auras with the first cast (needs to run out to be accurate).

When `/sa learnall 1` is enabled, the addon will also learn durations of spells cast by other players.

Some Spells aren't properly tracked because they use different names during apply and fade or don't trigger the event used to track them (Enlighten -> Enlightened and Weakened Soul for example).

In those cases, use "/sa learn X Y" to manually set duration Y for aura with ID X.

### Excluding Spells from Learning
If you want to prevent certain spells from being learned (e.g., instant cast spells that don't apply auras), use `/sa nolearning <spellID>`. This command toggles the exclusion - run it again to remove the spell from the exclusion list.

Examples:
- `/sa nolearning 18321` - Exclude spell ID 18321 from learning
- `/sa nolearning list` - Show all excluded spells
- `/sa nolearning clear` - Clear all exclusions

## Special Thanks / Credits
- Torio ([SuperCleveRoidMacros](https://github.com/jrc13245/SuperCleveRoidMacros))
- [MPOWA](https://github.com/MarcelineVQ/ModifiedPowerAuras) (Textures)
