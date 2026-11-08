# Changelog

## 1.1.0 — new ammo panel

- **New ammo panel** in the bottom right, inspired by tactical shooters:
  label (MAGS / SHELLS / GRENADES), up to 3 mags with the one in the gun on
  the right (bar above it = round chambered), "+" when there are more, total
  mags; empty mag = dotted outline switching red / white every 0.3 s (white / faint
  white while there's no mag in the gun); empty weapons show a red 0;
  an empty weapon keeps its ammo on screen until it's reloaded or put away; dirty ZM66 mag = red stripes.
- Shotguns: "reserve | side saddles + in the gun", split chamber bar (live /
  anything chambered), red number when jammed. Double barrel: same layout,
  bar split in half, one half per barrel.
- Boss rifle and revolver: "reserve | in the gun" (ROUNDS); the Boss uses
  the split chamber bar (jammed = blinking), the revolver one bar segment per
  chamber (live / spent / empty).
- Grenade launcher mode: 40mm grenade icons (loaded + spares, bar above the
  loaded one, dotted red / white when empty). Hand grenades: count.
- Empty spare mags are hidden by default (option to show them, as a plain
  dotted outline). A jammed ZM66 behaves like an empty one: shows on the
  next click and its chamber bar blinks white / red.
- Vulcanette: feeding mag with the chamber bar split in 5 (one per chamber),
  the 4 queued mags as a 2x2 block, vertical battery bar; 2100 / 700 rpm in
  the fire mode column.
- Thunder Buster: battery as the mag (CELLS), detonator / scattershot modes.
  BFG: main battery as the mag, charge battery as a vertical bar.
- Rocket launcher: "reserve | in the gun", amber chamber bar with HEAT
  loaded, rocket / grenade modes. Blooper and Brontornis: like the
  underbarrel launcher.
- Fire mode column next to it, with only the weapon's modes, stacked from the
  top (blanks at the bottom, with no background); smaller icons.
- Fixed-size background: long contents just spill out to the left.
- Weapon list above the panel when switching weapons (grenades with their
  count, weapons as silhouettes); only the weapon being switched to is highlighted.
- Shows instantly on inspect / reload / weapon switch (fire mode change shows
  only the fire mode column) and fades out; firing keeps it up and brings it
  back while fading.
- Inventory selector back in the top right.
- The old bottom-centre inspect panel and its options (inspect time, mag
  numbers, mag size, always show weapon ammo, weapon name, fire mode label)
  are removed. Vulcanette, BFG, Thunder Buster and chainsaw use HD's own
  readout again until they get a design.

## 1.0.0 — first release

- Health paper doll with lost max health, damage flash, armour outline/vest.
- ECG + BPM.
- Ammo inspect panel (key / hold / reload / unload / pump), mag-check motion, "always show weapon ammo".
- Own ammo displays for pistol, SMG, ZM66, Liberator, Vulcanette, BFG, Thunder Buster, chainsaw and Hunter; HD's readout for the rest.
- Fire mode label.
- Inventory bottom right, keys and worn items top right.
- Compass (minimal / bar) with inertia and spacing options.
- Safe zone.
- Centered Magnified Scopes (formerly Boss Scope Centralizado) included.
- English and Portuguese.
