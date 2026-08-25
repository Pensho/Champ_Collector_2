# Plan: System Buildout

Spawned by `Plan_Blowout_Alignment.md`'s `Coverage gaps` section (spawn condition met at that
plan's Phase 5) and by `Plan_Role_Kit_Rework.md`'s Phase 6. Both plans deliberately align and
rework what already exists without authoring new content; this plan collects what they found too
thinly populated, or promised but never built, to serve `Concept_Document.md` section 1.1's
pillar. Each entry names the gap, the phase that found it, and what closing it needs.

The Channel 3 gaps this plan carried are now owned by `Plan_Channel_3_Unification.md`, which
covers the cascade channel as a whole rather than as isolated missing triggers.

## Coverage gaps

* **Refutation's documented damage never shipped.** `Concept_Document.md` 3.2.4.2 says Refutation
  deals damage to an enemy whose zone it removes, scaling with Knowledge at 10% of a standard hit
  per remaining charge; `Refutation.tres` carries no damage parameters. The Scholar's kit passed its
  contract without it (Field of Study and Opportunist already carry the Role's declared
  contribution), so it was left unresolved rather than blocking the kit. Needs either the damage
  effect authored or the doc's promise removed. Found settling `Role_Kit_Design.md` section 9.14.
* **Weight of Law has no owner.** The zone skill exists in `Concept_Document.md` 3.2.4.3 and
  `Role_Kit_Design.md` 10.3 lists it as claimed by no player or enemy skill. Its Stun payload puts
  it under the puzzle-breaking-status policy (10.1: no Role applies Stun without a severe drawback),
  so assigning it needs that drawback designed alongside whichever kit takes it. Found by
  `Role_Kit_Design.md`'s coverage ledger (section 10.3). Should not be listed as claimed.

## Watch for

* **The contrast baseline is unsettled**, carried from `Plan_Blowout_Alignment.md`: section 1.1.2
  measures a burst against the bursting champion's own basic skill; under the composition law the
  honest baseline may be the team's average per-action output instead. Left to settle against a
  playable burst.
* A gap closed here should be removed from this list in the same edit, not annotated as resolved.
