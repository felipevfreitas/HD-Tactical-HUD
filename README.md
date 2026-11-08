# HD Tactical HUD

A minimal, tactical-shooter style HUD for **Hideous Destructor**, plus **Centered Magnified Scopes**, in one `.pk3`.

[Português (Brasil)](README.pt-BR.md)

> **Status: 1.1.0.** New tactical-shooter style ammo panel in the bottom right. See [Roadmap](#roadmap) and the [changelog](CHANGELOG.md).

## Requirements

- [UZDoom](https://github.com/UZDoom/UZDoom) (made and tested on UZDoom 5.x).
- [Hideous Destructor](https://codeberg.org/mc776/hideousdestructor) **5.0.1a**.

## Installation

1. Download `HDTacticalHUD-v1.1.0.pk3` from [Releases](../../releases).
2. Load it **after** Hideous Destructor:

   ```
   uzdoom -file hd-5.0.1a.pk7 HDTacticalHUD-v1.1.0.pk3
   ```

3. Bind the **Inspect ammo** key: *Options → Tactical HUD → Inspect ammo key* (no key is bound by default).

> **Don't load `BossScopeCentralizado.pk3` or `BossScopeCentralizado-ModernHUD.pk3` together with this mod.** The scope addon is already included, and loading it twice makes the game fail to start (the same classes would be defined twice).

## Features

### Health (bottom left)
- **Paper doll** of the Doomguy, filled white with health and draining from the top down, turning yellow → orange → red; pulses when critical.
- **Lost maximum health** (wounds, blood loss, burns…) grows from the top in dark red with darker diagonal stripes.
- Red flash when hit hard.
- **Armour** on the doll, as a coloured **outline** (1–3 px) or a **vest** on the torso; green = garrison, blue = battle armour; drains with durability.
- **ECG** next to the doll, driven by HD's real heartbeat, with BPM (gold/red when dangerous).

### Ammo (bottom right)
A tactical-shooter style panel, shown when it matters and fading out on its own:
- **Mags**: up to 3 mags (the one in the gun on the right, with a bar above it = round chambered), "+" and the total when some spare mags don't fit on screen. Empty mag = dotted outline blinking red/white; no mag in the gun = blinking white; refilled ("dirty") ZM66 mag = red stripes. Empty spare mags are hidden unless you turn them on.
- **Shells / rounds**: "reserve | side saddles + in the gun" for the Hunter and the double barrel, "reserve | in the gun" for the Boss rifle and the revolver. Bar above the number: live round / anything chambered (Hunter, Boss), one half per barrel (double barrel). Red 0 when empty.
- **Grenade launcher mode**: loaded grenade + spares. **Hand grenades**: count.
- **Fire mode column** with only the weapon's modes.
- **Weapon list** (silhouettes) above it when switching weapons; grenades as one entry with a count.
- Shows on weapon switch, inspect key (hold to keep it), reload/unload (only if the weapon really starts doing it), pump, fire mode change (fire mode column only). Empty or jammed weapon: shows on the next trigger pull and the ammo stays until reloaded or put away. Sprinting/jumping/mantling doesn't count as a weapon switch.
- Optional visual **mag-check motion** on the inspect key (the weapon lowers a bit and comes back up). Purely visual.

Tripwires and other addons' weapons keep **HD's own ammo readout**, above the BPM, for now.

### Inventory and items
- Item selector in the **top right** (off / on / only when changed).
- Keys and worn items (blood bag, radsuit…) in the **top right**.

### Compass (top centre)
- **Minimal** (sliding letters) or **bar with ticks**.
- Always, or only while holding Use.
- **Inertia**: off / light / smooth / heavy, like a liquid-damped compass.
- **Spacing**: short / medium / long.

### Other
- **Safe zone**: keep the HUD inside 16:9 / 16:10 / 4:3 / 21:9, plus side and top/bottom margins.
- English and Portuguese (pt / pt-BR / pt-PT).
- All options under *Options → Tactical HUD* (main options + *Advanced options*, with *Reset to defaults*).

### Centered Magnified Scopes (included)
Formerly *Boss Scope Centralizado*. Draws HD's magnified scopes in the centre of the screen, with:
scope size, screen outside the scope (normal / black / blurred), zoom outside the scope, normalized scope sensitivity, and a switch to turn the whole addon off.
Options: *Tactical HUD → Centered Magnified Scopes*. The blur needs OpenGL or Vulkan.

## Roadmap

**Still missing**
- Ammo panel designs for **tripwires** and weapons from other addons (they currently fall back to HD's readout).
- Info that disappeared together with HD's readout on the supported weapons: **Boss scope zoom / drop adjustment**, **grenade airburst distance**.
- Compass isn't tied to the FOV (its letters don't line up exactly with the world).

**Known limitations**
- The mag-check motion is a generic lower/raise, not each weapon's own animation.
- In-game testing so far has been done by one person; please report problems in [Issues](../../issues).

## Building

The `.pk3` is just a zip of the repository files:

```
./build.sh          # creates HDTacticalHUD-v<version>.pk3
```

## Credits

- **Hideous Destructor** by Matt (mc776) and contributors.
- Paper doll based on the Doomguy sprite from *Doom* (id Software).
- Inspired by tactical shooters such as *Ready or Not*, *Insurgency: Sandstorm* and *Escape from Tarkov*.
