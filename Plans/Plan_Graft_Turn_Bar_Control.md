# Plan — Graft turn-bar control (stub)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`,
`Symbiote_Graft_Pool.md`). Deferred until scheduled. **Flesh out to Batch-1 depth before
implementing** — the sections below are the intended shape, not finished steps.

## Primitive to build first (with tests)

- **Resolver-side turn-bar ordering / position queries.** Position and proximity live only in
  the UI (`Scripts/UI/Battle_UI/turn_bar.gd`: `GetCharactersWithinRange`, a behind-range
  variant); the resolver's `TurnPositions` exposes only `IsCharacterInZone`. Plumb
  ordering/position queries (furthest-behind, within-N%-behind, nearest-within-width) into the
  resolver so traits can read them.
- **Public push/pull by percentage.** The only public turn-bar entry points are a skill's
  `turn_effect` / `TraitSkillResult._turn_bar_bump` (own targets) and
  `AccumulateTurnBarMovement`. Add a public push/pull wrapping `_EmitTurnBarBump`, which
  already honors **Anchor** (blocks all bumps) and **Steadfast** (blocks negative bumps).
- **Buff-gained / debuff-landed self hooks** (for Contagion Bond). No trigger fires when a
  character gains a buff or a debuff lands on it; add both here, since Contagion Bond is this
  batch's graft. (Distinct from the buff-*expired* / zone-*dissipated* triggers, which belong
  to `Plan_Graft_Event_Triggers.md`.)

## Grafts that fall out

- **Caravan Cadence** — `Start_Turn`: push the ally furthest behind on the turn bar forward
  `7/8/9/10%`; bonus Knowledge `+15/20/25/30%`; drawback: permanently Anchored (reuses the
  existing Anchor block in `_EmitTurnBarBump`).
- **Gravitic Rot** — `Start_Turn`: every enemy within 20% behind loses `5/6/7/8%` turn bar;
  drawback Speed `-10%`.
- **Contagion Bond** — nearest-within-width copying of buffs/debuffs (width `6/8/10/12%`);
  drawback: debuffs on the Symbiote last 2 turns longer. Uses this batch's own buff-gained /
  debuff-landed hooks (above).

## Dependencies

Depends on the graft machinery (shipped) and this plan's turn-bar and buff-gained/
debuff-landed primitives — all self-contained here.
