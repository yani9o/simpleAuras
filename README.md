# simpleAuras

### ⚠️ **Information**
- This AddOn is not actively developed anymore.
- There will be functions that don't work as they should.

<img width="508" height="322" alt="image" src="https://github.com/user-attachments/assets/15338563-4fbd-454c-9609-3d95f0214cc0" />


## Known Issues
- Learning new AuraDuration gets prematurely completed if another player's aura with the same name runs out on the same target before yours - no way to get casterID when an aura fades.
- Skills that apply Auras with the same name may show "learning" all the time (maybe this one is fixed now - wasn't able to test yet).
- Having more than 16 auras shows auras outside the GUI frame (scrollframe possible, but then has more/other issues)
- AddOn is kinda heavy on ressources (compared to other addons), will optimize in a future update.
- /sa learnall 1 tries to learn spells without aura (i.e. smite, shadowbolt, etc.)


## Console Commands:
/sa or /sa show or /sa hide - Show/hide simpleAuras Settings.

/sa refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5).

### SuperWoW commands:
/sa learn X Y - manually set duration Y of spellID X.

/sa forget X - forget AuraDuration of SpellID X (or use 'all' instead to delete all durations).

/sa update X - force AuraDurations updates (1 = re-learn aura durations. Default: 0).

/sa showlearning X - shows learning of new AuraDurations in chat (1 = show. Default: 0).

/sa learnall X - learn all AuraDurations, even if no Aura is set up. (1 = Active. Default: 0).


## Settings (/sa)
<img width="819" height="605" alt="image" src="https://github.com/user-attachments/assets/ffd56904-f840-41b5-80bd-63550fef2ba3" />


### Overview
Shows all existing auras.

- [+] / Add Aura: Creates a new, blank aura.
- [i] / Import: Opens a window to import one or multiple auras from a text string.
- [e] / Export: Exports all your auras into a single text string.
- v / ^: Sort aura priority (higher in the list = will be shown over other auras below)

  *(you can also sort auras via drag & drop)*
- Movable Auras: While in settings, you can move any visible aura by holding down `Ctrl`+`Alt`+`Shift` keys and dragging it.


### Aura-Editor
Shows the currently edited aura only.

Enabled/Disabled:
- A master toggle at the top of the editor to quickly turn an aura on or off. Disabled auras are highlighted in red in the main list.

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
- Show Duration*/Stacks: Shows Duration in the center of the icon/texture, stacks are under that.


Conditions:
- Unit: Which unit the aura is on.
- Type: is it a buff or a debuff.
- Low Duration Color*: If the auracolor should change at or below "lowduration"
- Low Duration in secs*: Allways active, changes durationcolor to red if at or below, also changes color if activated.
- In/Out of Combat: When aura should be shown
- In Raid / In Party: Restricts the aura to only be active when you are in a raid or party (but not a raid).

Buff/Debuff:
- Invert: Activate to show aura if not found.
- Dual: Mirrors the aura (if xpos = -150, then it will show a mirrored icon/texture at xpos 150).

Cooldown:
- Always: Shows Cooldown Icon if it's on CD or not.
- No CD: Show when not on CD.
- CD: Show when on CD.


Other:
- [c] / Copy: Copies the aura.
- [e] / Export: Exports only the current aura into a text string.
- Delete: Deletes the aura after confirmation.

\* = For these functions to work on targets SuperWoW is REQUIRED! Also only shows your own AuraDurations.


## SuperWoW Features
If SuperWoW is installed, simpleAuras will automatically learn unkown durations of most of **your own** auras with the first cast (needs to run out to be accurate).

Some Spells aren't properly tracked because they use different names during apply and fade or don't trigger the event used to track them (Enlighten -> Enlightened and Weakened Soul for example).

In those cases, use "/sa learn X Y" to manually set duration Y for aura with ID X.

## Special Thanks / Credits
- Torio ([SuperCleveRoidMacros](https://github.com/jrc13245/SuperCleveRoidMacros))
- [MPOWA](https://github.com/MarcelineVQ/ModifiedPowerAuras) (Textures)
