# Plan — Graft healing primitives (stub)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`,
`Symbiote_Graft_Pool.md`). Deferred until scheduled. **Flesh out to Batch-1 depth before
implementing** — the sections below are the intended shape, not finished steps.

## Primitive to build first (with tests)

- **Public trait-facing heal.** Today `_ApplyHeal(character_ID, amount)`
  (`Scripts/Battle/battle_resolver.gd`) is private and there is no public heal for a trait
  to call (only `SetCurrentHealth`, which bypasses heal reduction and emits a `Damage`-kind
  result). Add a public `ResolveTraitHeal(target_ID, amount) -> Array[CombatResult]` that
  applies `_HealingMultiplier` (so it respects `IncomingHealReduction`, i.e. Blight/Carrion
  Bloom's drawback) and emits a `Heal` `CombatResult`.
- **Lifesteal.** `_ResolveDamage` computes the dealt amount but never heals the caster and
  there is no heal-for-%-of-damage pattern anywhere. Add a path that feeds the dealt amount
  back to the caster's trait (a hook or an opt-in flag on `ResolveTraitDamage`).

## Grafts that fall out

- **Hollow Hunger** — heal `10/13/16/19%` of damage dealt; drawback max Health `-15%`.
- **Carrion Bloom** — `Start_Turn`: heal the lowest-Health ally `3/4/5/6%` of that ally's max
  Health; bonus Health `+10/12/14/16%`; drawback: healing the Symbiote receives `-50%`
  (reuse Blight/`IncomingHealReduction` as a persistent self-effect).
- **Overgrowth** — `Start_Turn`: gain an Overgrowth stack and heal `1%` max Health per stack;
  at 6 stacks every ally gains Regeneration for `1/1/2/2` turns (via `ApplyBuff`) and stacks
  reset. No attribute bonus/drawback.

## Dependencies

Depends on the graft machinery (shipped) and this plan's own healing primitive. Independent
of the other roadmap batches.
