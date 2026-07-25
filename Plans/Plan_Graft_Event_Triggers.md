# Plan — Graft event triggers (stub)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`,
`Symbiote_Graft_Pool.md`). Deferred until scheduled. **Flesh out to Batch-1 depth before
implementing** — the sections below are the intended shape, not finished steps.

## Primitive to build first (with tests)

- **Buff-expired trigger.** Buff/debuff expiry currently only surfaces as a
  `Statuses_Removed` `CombatResult`; no `Combat_Event` fires. Add a trigger.
- **Zone-dissipated trigger.** When a zone's duration hits 0 in `TriggerZones` it is silently
  `free()`d with no `CombatResult` and no event. Emit a zone-dissipation `CombatResult` and
  add a trigger.
- **Broadened `Reagent_Consumed`.** The hook fires only on the consumer's own trait; broaden
  it so other subscribers (anywhere, either side) are notified.

## Grafts that fall out

- **Detritivore** — whenever a reagent is consumed, a buff expires, or a zone dissipates
  anywhere on either side, the Symbiote heals `2%` max Health and gains a **Scrap** stack
  worth `+2/3/4/5%` Resistance for the rest of the battle (no cap); drawback: begins each
  battle at `-20%` Resistance. No attribute bonus (Scrap stacks are the scaling).

## Dependencies

Depends on the graft machinery (shipped) and the three triggers above. **Hard-depends on the
public `ResolveTraitHeal` from `Plan_Graft_Healing_Primitives.md`** for Detritivore's
scavenge heal — schedule that batch first; do not add a separate heal here.

Note: the buff-*gained* / debuff-*landed* self hooks that Contagion Bond needs are **not**
owned by this batch — they belong to `Plan_Graft_Turn_Bar_Control.md` (Contagion Bond's home).
This batch owns only the buff-*expired* and zone-*dissipated* triggers plus the broadened
`Reagent_Consumed`.
