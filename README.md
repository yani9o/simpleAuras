# simpleAuras


<img width="457" height="292" alt="image" src="https://github.com/user-attachments/assets/03f280cf-36ac-4139-ab03-1f26d70bf8ad" />


## Console Commands:
/sa or /sa show or /sa hide - Show/hide simpleAuras Settings

/sa refresh X - Set refresh rate. (1 to 100 updates per second. Default: 10)


## Settings (/sa)
<img width="817" height="539" alt="image" src="https://github.com/user-attachments/assets/6d9809da-b9d6-412b-8ca8-c7e4be413ac2" />

### Overview
Shows all existing auras.

- [+] / Add Aura: Creates a new, blank aura.
- v / ^: Sort aura priority (higher in the list = will be shown over other auras below)


### Aura-Editor
Shows the currently edited aura only.

####Aura/Spellname Name:
- Name of the aura to track (has to be exactly the same name)


Icon/Texture:
- Color: Basecolor of the aura.
- Autodetect: Gets icon from buff.
- Browse: Choose a texture.
- Scale: Basescale of 1 is 48x48px.
- x/y pos: Position from center of the screen.
- Show Duration*/Stacks*: Shows Duration in the center of the icon/texture, stacks are under that.


Conditions:
- Unit: Which unit the aura is on.
- Type: is it a buff or a debuff.
- Low Duration Color*: If the auracolor should change at or below "lowduration"
- Low Duration in secs*: Allways active, changes durationcolor to red if at or below, also changes color if activated.
- In/Out of Combat: When aura should be shown

Buff/Debuff:
- Invert: Activate to show aura if not found.
- Dual: Mirrors the aura (if xpos = -150, then it will show a mirrored icon/texture at xpos 150).

Cooldown:
- No CD: Show when not on CD.
- CD: Show when on CD.


Other:
- [c] / Copy: Copies the aura.
- Delete: Deletes the aura after confirmation.

\* = Target Duration/Stacks need SuperWoW and CleveRoidMacros' [Testbranch](https://github.com/jrc13245/CleveRoidMacros/tree/test)!
