# Changelog

## 1.1.0 — new ammo panel (work in progress)

- **New ammo panel** in the bottom right, inspired by tactical shooters:
  label (MAGS / SHELLS / GRENADES), up to 3 mags with the one in the gun on
  the right (bar above it = round chambered), "+" when there are more, total
  mags; empty mag = dotted outline switching red / white every 0.3 s (white / faint
  white while there's no mag in the gun); empty weapons show a red 0;
  an empty weapon keeps its ammo on screen until it's reloaded or put away; dirty ZM66 mag = red stripes.
- Shotguns: "reserve | side saddles + in the gun", split chamber bar (live /
  anything chambered), red number when jammed. Double barrel: same layout,
  bar split in half, one half per barrel.
- Grenade launcher mode: loaded grenade + spares. Hand grenades: count.
- Fire mode column next to it, with only the weapon's modes, stacked from the
  top (blanks at the bottom, with no background); smaller icons.
- Fixed-size background: long contents just spill out to the left.
- Weapon list above the panel when switching weapons (grenades with their
  count, weapons as silhouettes); only the weapon being switched to is highlighted.
- Shows instantly on inspect / reload / weapon switch (fire mode change shows
  only the fire mode column) and fades out; firing keeps it up and brings it
  back while fading.
- Inventory selector back in the top right.
- The old bottom-centre panel is gone. Vulcanette, BFG, Thunder Buster and
  chainsaw temporarily use HD's own readout again until they get a design.
  Old inspect-panel options (mag size, numbers, always show...) don't affect
  the new panel yet.

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
