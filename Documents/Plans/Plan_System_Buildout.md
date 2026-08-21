# Plan: System Buildout

Spawned by `Plan_Blowout_Alignment.md`'s `Coverage gaps` section (spawn condition met at that
plan's Phase 5) and by `Plan_Role_Kit_Rework.md`'s Phase 6. Both plans deliberately align and
rework what already exists without authoring new content; this plan collects what they found too
thinly populated, or promised but never built, to serve `Concept_Document.md` section 1.1's
pillar. Each entry names the gap, the phase that found it, and what closing it needs.

## Coverage gaps

* **Channel 3 has no threshold-crossing or cascade-on-cascade trigger.** `Types.Cascade_Trigger`
  covers `Status_Expired`, `Status_Landed`, and `Skill_Resolved` (the last landed by
  `Plan_Role_Kit_Rework.md`, consumed by the Sorcerer's Echo, Herald's Cut the Cloth, and Plague
  Doctor's Comorbidity). Two shapes `Concept_Document.md` 1.1.3 names have no trigger or content at
  all: a status or zone detonating on a Health or status-count threshold crossing, and an effect
  listening for another cascade instance landing. Needs a new `Types.Cascade_Trigger` value and
  `Post()` call site per shape before content can be authored against it. Found by
  `Plan_Blowout_Alignment.md` Phase 3.
* **Debuff ticks never post to `CascadeResolver`.** Herald of the Loom's Golden Thread gains
  Tension when a cascade instance resolves on an enemy, but a plain debuff tick (Plague, Burning,
  Hemorrhage) is not itself a cascade instance, so Golden Thread never sees one. Needs a `Post()`
  call site on the debuff-tick path. Found implementing `Role_Kit_Design.md` section 9.2.
* **The Relic item type has a settled contract but no code mechanism.** `Concept_Document.md`
  3.3.1 defines Relic as an item type orthogonal to rarity, carrying a unique effect and a fixed
  drawback; `Plan_Relic_Itemization.md` owns the design and the catalog. Nothing of it exists in
  code — `Types.Rarity` still carries `Relic` as a sixth tier, `EquipmentPreset.Setup()` rolls it
  no attributes, and there is no effect mechanism, no item-type roll, and no dispatch reaching a
  character's equipped Relic effects. Needs a code plan of its own; its main expense is that
  character-trait dispatch is wired to a single `_trait` field across roughly forty call sites in
  `Scripts/Battle/`. Found by `Plan_Blowout_Alignment.md` Phase 6.
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
  `Role_Kit_Design.md`'s coverage ledger (section 10.3).

## Watch for

* **The contrast baseline is unsettled**, carried from `Plan_Blowout_Alignment.md`: section 1.1.2
  measures a burst against the bursting champion's own basic skill; under the composition law the
  honest baseline may be the team's average per-action output instead. Left to settle against a
  playable burst.
* A gap closed here should be removed from this list in the same edit, not annotated as resolved.
