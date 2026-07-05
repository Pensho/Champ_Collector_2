# Plan: Architect Calibration Kit

Design and implement the Architect's skill kit around the Calibration passive defined in
`Concept_Document.md` 3.1.3. The passive owns the charge economy (gain rules, cap of 10,
consumption scaling, rarity scaling); this plan captures the three-skill kit that drives
that economy and the numbers still to be decided.

## Status

Not started — design sketch only. The passive's dependency note in `Concept_Document.md`
points at this plan. Until the construction-zone skill exists, the passive functions on
basic-skill charge generation alone.

## Design (confirmed decisions)

- **Calibration is the passive**, following the Lancer (Reckless Momentum) and Tidal
  Corsair precedent of the resource economy living in the passive slot. The role blurb
  only describes intent.
- Charges cap at 10 and do not persist between combats.
- The player composition is **up to 3 playable characters**, which naturally bounds the
  zone's charge generation rate — no additional generation cap is needed.
- The finisher resolves in **tiers with fixed thresholds across rarities**; rarity scales
  per-charge potency (4/6/8/10%), not the thresholds. Lowering thresholds per rarity was
  considered and rejected: it would diminish the build-up feeling that defines the role.
- The zone grants a role-specific **shield buff** (working name "Sound Structure"): a
  health buffer that absorbs damage before Health is touched, scaling with the charges
  invested in the construction. It lasts around 2 turns (up for future balancing).
- Any time an ally lands on the zone, the shield is applied, overwriting the prior
  shield only if the new one is larger.
- "Using" the zone means an ally stopping on it when someones turn starts, reusing the
  existing zone targeting and resolution (`Skill_Target.ZoneAlly` and
  `ResolveZoneEffect` in `Scripts/Battle/Skills.gd`, the Chronophage zone pattern).
- The shield's size is a flat base value plus a Knowledge-scaled modifier, following
  the existing `AllyZoneMagnitude` pattern. Fine values are left for balancing.
- The zone lasts 5 turns; the construction skill has a 2-turn cooldown. Multiple zones
  may stand at once.
- The finisher has no minimum charge requirement — cooldown is the only restriction on
  casting it.

## Kit sketch

- **Basic skill** — deals damage and generates 1 Calibration charge.
- **Zone construction skill** — erects a zone effect that generates 1 charge for the
  Architect per character that uses it and applies the Sound Structure shield buff to
  allies landing on it, sized by the charges consumed to construct the zone.
- **Finisher** — consumes all held charges; the outcome resolves by tier:
  - **1–3 charges (Demolition):** damage only, scaling per charge. The early cash-out.
  - **4–6 charges (Structural Shift):** damage plus Expose Weakness applied to the
    target.
  - **7–10 charges (The Solution):** damage plus the tier-two effect, and the Architect's
    construction zone is re-erected (or upgraded if standing) for free — solving the
    encounter perfects the machine rather than scrapping it, and generation resumes
    immediately.

## Open questions

- All damage and shield numbers (the shield's flat base and Knowledge modifier, finisher
  damage, how per-charge potency applies to each tier) — left for later balancing.
