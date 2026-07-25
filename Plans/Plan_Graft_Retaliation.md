# Plan — Graft retaliation (stub)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`,
`Symbiote_Graft_Pool.md`). Deferred until scheduled. **Flesh out to Batch-1 depth before
implementing** — the sections below are the intended shape, not finished steps.

## Primitive to build first (with tests)

- **Attacker-aware damage-taken reaction.** The current hook
  `OnDamageTaken(owner_ID, resolver) -> float` (`character_trait.gd`) receives **no attacker
  ID**, so a graft cannot strike or pull the attacker. Mirror Coat solves the equivalent
  problem inside the resolver (`_TriggerMirrorCoat`, with the attacker ID in scope). Add
  either a new attacker-aware hook or in-resolver plumbing that lets a graft react to the
  attacker.

## Grafts that fall out

- **Glass Refraction** — when hit, backlash the attacker for magical damage `= 25%` of the
  Symbiote's Mysticism (via `ResolveTraitDamage` scaling Mysticism); bonus Mysticism
  `+12/16/20/24%`; drawback Resistance `-40%`.
- **Undertow** — when an enemy hits the Symbiote, pull that attacker back `6/7/8/9%` on the
  turn bar; bonus Health `+13/16/19/22%`; drawback: the Symbiote loses `5%` turn bar when
  hit. **Also needs** the turn-bar push/pull from `Plan_Graft_Turn_Bar_Control.md`.
- **Glamour** — single-target attacks against the Symbiote have a `25/30/35/40%` chance to be
  **Refracted** onto a random other character (reuses the existing Refracted marker; new
  redirect-on-attacker logic and a chance roll); Symbiote also deals `+10%` damage; drawback:
  takes `+10%` damage and is targeted 20% more often.

## Dependencies

Depends on the graft machinery (shipped) and this plan's attacker-aware reaction. Undertow
additionally depends on `Plan_Graft_Turn_Bar_Control.md`.
