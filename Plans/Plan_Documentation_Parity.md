# Plan: Documentation Parity

Bring `Concept_Document.md` back in line with the implemented game, per the CLAUDE.md
rule that design changes made during implementation must flow back into the concept
document. Documentation-only plan — no code changes except where a design decision
falls out of it.

## Status

Not started. No dependency on the code plans; can be done first.

## Findings

The combat-formula chapter (`Concept_Document.md` 3.2.1) describes an older design.
The implemented formulas (see `Technical_Design_Document.md` 7.4) are materially
different and generally better, but the concept document is the stated design source
of truth, so the mismatch will mislead future planning.

| Concept document says | Implementation does |
|---|---|
| Damage = `(Attack - Defence) * Random_Multiplier`, minimum-damage clause for negatives | Ratio-based mitigation: `caster_scaled / (effective_defence + caster_scaled + 1)` scaled onto a `MINIMUM_DMG_PERCENT` floor, with per-skill `defense_ignore_factor` and attribute-weighted scaling from the skill data |
| Separate magical formula using `(Resistance + Defence) / 2` | No separate magical path; skills scale off any attribute mix via `damage_scaling`, defence is the only mitigator |
| Debuff success = `Base Chance + (Accuracy - Resistance) * Multiplier`, capped 10%-90% | Straight contest: `Accuracy * rand(0.95..1.0) < Resistance * rand(0.95..1.0)` resists — no base chance, no caps |
| Turn order: highest Speed acts first each round, ties randomized | Continuous turn bar (as correctly described elsewhere in section 3.2) |
| Critical hits: fixed 5-10% chance, static multiplier | `CritChance` attribute rolled per hit; multiplier is `CritDamage` reduced by half the defender's Knowledge, floored at `MINIMUM_CRIT_DAMAGE` |

Additional parity items:

- **Expose Weakness magnitude conflict:** concept says 50%; caster-side tick in
  `Skills.gd` uses 30% while target-side snapshot uses 50%. Needs one answer
  (also flagged in `Plan_Data_Driven_Status_Effects.md`, step 1).
- **No minimum debuff hit chance:** with the implemented resist contest, a
  low-Accuracy champion can be mathematically unable to land debuffs on a
  high-Resistance boss. This undercuts the "puzzle encounter" design in section 3.2,
  which assumes debuffs like Enfeeble/Expose Weakness are the intended solutions.
  Decide: accept as design (document it), or add a base-chance/cap mechanic (then a
  small code change follows, ideally alongside `Plan_Combat_Correctness_Fixes.md`).
- **Burning stacking from Lava zones** — decide and document (cross-referenced from
  `Plan_Combat_Correctness_Fixes.md`, step 7).

## Steps

1. **Rewrite `Concept_Document.md` 3.2.1** to describe the implemented damage,
   mitigation, and critical-hit formulas as the design of record. Where the old text
   captured intent worth keeping (e.g. minimum damage so every hit matters), restate
   that intent in terms of the current formula (`MINIMUM_DMG_PERCENT`).
2. **Decide the debuff-application design** (minimum hit chance or not) and rewrite
   the debuff formula subsection accordingly. If a code change results, file it as a
   follow-up step in `Plan_Combat_Correctness_Fixes.md`.
3. **Fix the turn-order subsection** to describe the turn bar instead of round-based
   ordering (one paragraph; section 3.2 already describes the bar correctly).
4. **Resolve and record the two effect questions** (Expose Weakness magnitude,
   Burning stacking) in section 3.2.3.
5. **Sweep `Technical_Design_Document.md` for drift** — one error already corrected
   (`Character` extends `RefCounted`, not `Node`); re-verify section 6/7 claims such
   as "templates are duplicated at instantiation" once
   `Plan_Combat_Correctness_Fixes.md` step 1 lands (today that claim is only true for
   player characters).

## Watch for

- Keep the concept document describing *design*, not code paths — formulas belong
  there, file/line references do not (those live in the technical design document).
- Update `Test_Design_Document.md` only if a decision here changes what should be
  tested (e.g. a new minimum-hit-chance rule needs a test).
