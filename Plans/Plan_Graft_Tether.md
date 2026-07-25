# Plan — Graft tether (stub)

Part of the Symbiote Graft Pool (`Plans/Plan_Symbiote_Graft_Pool.md`,
`Symbiote_Graft_Pool.md`). Deferred until scheduled. **Flesh out to Batch-1 depth before
implementing** — the sections below are the intended shape, not finished steps.

## Primitive to build first (with tests)

- **Persistent random-ally tether with attribute sharing.** No cross-character
  attribute-sharing mechanism exists. Add a tether that, at start of battle, binds the
  Symbiote to a random ally and shares a fraction of the Symbiote's attributes to that ally,
  re-tethering to another random living ally if the tethered one dies.

## Grafts that fall out

- **Symbiotic Anchor** — `Start_Combat`: tether to a random ally, granting it bonus
  Resistance `= 20%` of the Symbiote's Resistance and bonus Attack `= 20%` of the Symbiote's
  Attack (re-tether on death); bonus Resistance `+14/16/18/20%` (also raises the shared
  Resistance); drawback: the Symbiote's own Defence `-30%` and CritDamage `-30%`.

## Dependencies

Depends on the graft machinery (shipped) and the tether primitive above. Independent of the
other roadmap batches.
