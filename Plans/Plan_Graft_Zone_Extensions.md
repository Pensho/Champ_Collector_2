# Plan — Graft zone extensions (stub)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`,
`Symbiote_Graft_Pool.md`). Deferred until scheduled. **Flesh out to Batch-1 depth before
implementing** — the sections below are the intended shape, not finished steps.

## Primitive to build first (with tests)

- **Dual-faction zone.** A `Zone` (`Scripts/Battle/zone.gd`) has a single `_target` and a
  single effect kind (`_ResolveZoneEffect` handles only Flicker/Lava). Add a zone that buffs
  allies **and** debuffs enemies from the same placement.
- **Zone charge replenishment / cap.** Charges are just `_duration`, decremented per trigger,
  with no cap and no replenishment. Add a per-owner-turn charge gain up to a maximum.
- **Affected-by-zone trait hook.** `TriggerZones` never consults the affected character's
  trait; add a hook so a graft can react to being touched by any zone.

## Grafts that fall out

- **Living Bloom** (Spore Bloom) — `Start_Combat`: seed a dual-faction zone with 5 charges,
  gaining a charge each of the Symbiote's turns up to 5; enemies stopping in it gain Blight
  (1 turn), allies gain Regeneration (1 turn); bonus Knowledge `+15/20/25/30%` (zone potency
  scales with Knowledge, the standard ally-zone rule); no drawback.
- **Rootfeeder** — whenever the Symbiote is affected by any zone (either side), heal
  `4/5/6/7%` max Health on top of the zone effect (consumes one charge normally, never clears
  early); drawback: enemy-placed zones affect the Symbiote at `+50%` effect.

## Dependencies

Depends on the graft machinery (shipped) and the three zone primitives above. **Hard-depends
on the public `ResolveTraitHeal` from `Plan_Graft_Healing_Primitives.md`** for Rootfeeder's
extra heal — schedule that batch first; do not add a separate heal here.
