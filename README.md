# HD Tactical HUD

A minimal, tactical-shooter style HUD for **Hideous Destructor**, plus **Centered Magnified Scopes**, in one `.pk3`.

[Português (Brasil)](README.pt-BR.md)

> **Status: 1.1.0, work in progress.** The ammo display is being **redone** (new tactical-shooter style panel in the bottom right). See [Roadmap](#roadmap) and the [changelog](CHANGELOG.md).

## Requirements

- [UZDoom](https://github.com/UZDoom/UZDoom) (made and tested on UZDoom 5.x).
- [Hideous Destructor](https://codeberg.org/mc776/hideousdestructor) **5.0.1a**.

## Installation

1. Download `HD-Tactical-HUD-v1.1.0.pk3` from [Releases](../../releases).
2. Load it **after** Hideous Destructor:

   ```
   uzdoom -file hd-5.0.1a.pk7 HD-Tactical-HUD-v1.1.0.pk3
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

### Ammo
- **Inspect key** (hold to keep it up): shows, at the bottom centre, what's **in the gun** and then the **spare ammo**. Each mag/cell is a silhouette that drains from the top down.
- Can also open on **reload / secondary reload / unload**, only if the weapon really starts doing it.
- Optional **"always show the weapon's ammo"** (spares still only on inspect).
- Visual **mag-check motion**: the weapon lowers a bit and comes back up (speed and depth adjustable). Purely visual, it never changes the weapon's state.
- Fire mode label (SEMI / BURST / AUTO / GRENADE, Vulcanette RPM, Thunder Buster mode).
- Ammo colour can follow the player's colour (HD's green).

Weapons with their own display (HD's ammo readout is hidden for them):

| Weapon | What's shown |
|---|---|
| Pistol, SMG, ZM66, Liberator | Loaded mag + chambered round (+ grenade launcher). ZM66 always shows its red counter; a refilled ("dirty") ZM66 mag shows pulsing red stripes and a garbage number. |
| Vulcanette | Feeding mag (with counter), small battery on top of the 4 queued-mag boxes, a round that drains with the 5 chambers. |
| BFG 9000 | Both batteries (+ harness label); shows by itself while charging. |
| Thunder Buster, Lumberjack (chainsaw) | Battery. |
| Hunter | One shell: hull = tube, brass = chamber (white = live, dark = spent, faint = empty), red stripes when jammed; side saddles. Quick look after each pump. |

Every other weapon keeps **HD's original ammo readout**, placed above the BPM.

### Inventory and items
- Item selector in the **bottom right** (off / on / only when changed).
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

**Planned**
- **Redo the ammo HUD.** The current inspect panel works, but I don't like how it looks; it will be redesigned.

**Still missing**
- Own displays for: **Slayer**, **revolver**, **Boss rifle**, **Brontornis**, **rocket launcher**, **Blooper**, and weapons from other addons (they currently fall back to HD's readout).
- Info that disappeared together with HD's readout on the supported weapons: **scope zoom level**, **grenade airburst distance**, **Thunder Buster range finder**, **chainsaw wall-damage meter**.
- Compass isn't tied to the FOV (its letters don't line up exactly with the world).

**Known limitations**
- The mag-check motion is a generic lower/raise, not each weapon's own animation.
- In-game testing so far has been done by one person; please report problems in [Issues](../../issues).

## Building

The `.pk3` is just a zip of the repository files:

```
./build.sh          # creates HD-Tactical-HUD-v<version>.pk3
```

## Credits

- **Hideous Destructor** by Matt (mc776) and contributors.
- Paper doll based on the Doomguy sprite from *Doom* (id Software).
- Inspired by tactical shooters such as *Ready or Not*, *Insurgency: Sandstorm* and *Escape from Tarkov*.
