# Plan — Graft on-kill and conditional damage (stub)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`,
`Symbiote_Graft_Pool.md`). Deferred until scheduled. **Flesh out to Batch-1 depth before
implementing** — the sections below are the intended shape, not finished steps.

## Primitive to build first (with tests)

- **Killing-blow hook fired on the killer.** No such hook exists: `_HandleDeath`
  (`Scripts/Battle/battle_resolver.gd`) fires only the *dying* character's `On_Death` and its
  allies' `Ally_Death`; nothing fires on the killer, and `Combat_Event` has no `On_Kill`.
  Detect the alive→dead transition attributable to the caster and notify the killer's trait.
- **Target-Health-conditional damage modifier.** A damage-scaling adjustment that reads the
  target's current-Health band (e.g. lowest-Health target, or above/below a threshold).

## Grafts that fall out

- **Bloodscent** — attacks deal `+20/25/30/35%` to the enemy with the lowest current Health,
  and a killing blow heals the Symbiote for `15%` of its max Health; drawback: `-25%` damage
  against any enemy above 50% Health. No attribute bonus (damage rides on Resistance).

## Dependencies

Depends on the graft machinery (shipped) and both primitives above. **Hard-depends on the
public `ResolveTraitHeal` from `Plan_Graft_Healing_Primitives.md`** for the killing-blow
heal — schedule that batch first; do not add a separate heal here.
