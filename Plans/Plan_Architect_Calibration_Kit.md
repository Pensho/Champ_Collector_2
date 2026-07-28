# Plan: Architect Calibration Kit

Design and implement the Architect's skill kit around the Calibration passive defined in
`Concept_Document.md` 3.1.3. The passive owns the charge economy (gain rules, cap of 10,
consumption scaling, rarity scaling); this plan captures the three-skill kit that drives
that economy and the numbers still to be decided.

## Status

**Implemented.** The Calibration passive, all three skills (Cornerstone, Raise the Frame,
Final Calculation), zone-based charge generation, and the finisher's tier-3 zone re-erect /
upgrade are landed — see Implementation below. Only balance numbers and a real passive icon
remain open (see Open questions).

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
- The zone grants the **Barrier buff** (catalogued in `Concept_Document.md` 3.2.3.2;
  supersedes the "Sound Structure" working name): a health buffer that absorbs damage
  before Health is touched, scaling with **both** the owner's Knowledge and the charges
  invested in the construction. It lasts around 2 turns (up for future balancing).
- Any time an ally lands on the zone, the Barrier is applied; per the catalog rule,
  Barriers do not stack and the new one replaces the prior only if larger.
- "Using" the zone means an ally stopping on it when someones turn starts, reusing the
  existing zone targeting and resolution (`Skill_Target.ZoneAlly` and
  `ResolveZoneEffect` in `Scripts/Battle/Skills.gd`, the Chronophage zone pattern).
- The shield's size is a flat base value plus a Knowledge-scaled modifier, following
  the existing `AllyZoneMagnitude` pattern. Fine values are left for balancing.
- The zone holds 5 charges (zones expire by charge consumption, not time — see the
  zone rules in `Concept_Document.md` 3.2.4.1); the construction skill has a 2-turn
  cooldown. Multiple zones may stand at once.
- The finisher has no minimum charge requirement — cooldown is the only restriction on
  casting it.

## Kit sketch

- **Basic skill** — deals damage and generates 1 Calibration charge.
- **Zone construction skill** — erects a zone effect that generates 1 charge for the
  Architect per character that uses it and applies the Barrier buff to
  allies landing on it, sized by the charges consumed to construct the zone.
- **Finisher** — consumes all held charges; the outcome resolves by tier:
  - **1–3 charges (Demolition):** damage only, scaling per charge. The early cash-out.
  - **4–6 charges (Structural Shift):** damage plus Expose Weakness applied to the
    target.
  - **7–10 charges (The Solution):** damage plus the tier-two effect, and the Architect's
    construction zone is re-erected (or upgraded if standing) for free — solving the
    encounter perfects the machine rather than scrapping it, and generation resumes
    immediately.

## Implementation

Calibration passive, all three skills, and the full charge economy (including zone-based
generation, charge-sized Barrier, Raise the Frame's own consumption, and the tier-3
re-erect/upgrade) are landed.

- `Scripts/Character/character_traits/CharacterSpecificTraits/calibration_trait.gd` —
  `CalibrationTrait`: integer charge count clamped to `MAX_CHARGES = 10`, reset on
  `Start_Combat`. Keys on skill name in `OnSkillCast` (the Tidal Corsair / Wrangle the Sea
  pattern): Cornerstone grants one charge; Raise the Frame consumes `min(held,
  RAISE_THE_FRAME_CONSUME_CAP = 3)` charges; Final Calculation reads and consumes all charges,
  returning a `TraitSkillResult._damage_multiplier` of `1.0 + PER_CHARGE_POTENCY[rarity] *
  charges`, and applies Expose Weakness (2 turns, via `p_resolver.ApplyDebuff`) once charges
  reach `EXPOSE_WEAKNESS_THRESHOLD = 4`. `PER_CHARGE_POTENCY` is the shared per-charge
  consumable rate driving both the finisher's damage bonus and the Barrier's charge-size
  bonus. Also registers the `Zone_Used` hook (`OnZoneUsed`), granting a charge whenever the
  owner's construction zone is triggered, and the `Zone_Constructed` hook
  (`OnZoneConstructed`), which — guarded to `Barrier_Zone` — records
  `_charges_invested_per_zone[zone_ID] = min(_charges, RAISE_THE_FRAME_CONSUME_CAP)` without
  consuming; this fires before `OnSkillCast` for both a player-cast Raise the Frame and the
  free tier-3 re-erect, so the re-erect records an amount but Raise the Frame's own
  `OnSkillCast` case is what actually consumes (skipped for the re-erect, since it's cast
  under Final Calculation). `GetZoneChargeBonus(zone_ID)` returns
  `_charges_invested_per_zone.get(zone_ID, 0) * _per_charge_potency`, read by the resolver
  when a Barrier zone triggers. The per-zone dictionary is cleared in `StartOfBattle`. At
  `ZONE_RE_ERECT_THRESHOLD = 7`, `_ReErectZone` either sets an existing owned zone's remaining
  charges to `ZONE_UPGRADE_CHARGES = 8` ("upgrade" — see the FeatureIdeas.md brainstorm note
  below) or, if none is standing, places a new one for free via `p_resolver.PlaceZone`.
- `Data/Character_Traits/Calibration_Trait.tres`, `Data/Character_Skill_Variants/Attack_Skills/Cornerstone.tres`,
  `Final_Calculation.tres`, and `Data/Character_Skill_Variants/Zone_Skills/Raise_the_Frame.tres`
  — data resources binding the above.
- `Data/Character_Player_Variants/Architect.tres` — wired to Cornerstone (slot 0), Raise the
  Frame (slot 1), and Final Calculation (slot 2); trait set to Calibration.
- Engine additions to support the zone: `Types.Skill_Type.Barrier_Zone`,
  `Types.Combat_Event.Zone_Used`, and `Types.Combat_Event.Zone_Constructed` (all appended at
  the enum end so no existing `.tres` numeric values shifted, `Scripts/common_enums.gd`);
  `GameBalance.RAISE_THE_FRAME_BASE_BARRIER` (`Scripts/game_balance.gd`);
  `Skills.MakeBarrierZoneBuff` (now takes a charge-bonus fraction alongside Knowledge),
  `Skills.TriggerZoneUsedHook`, `Skills.TriggerZoneConstructedHook`, and
  `Skills.ApplyBarrierZone` (an orchestrator that queries `GetZoneChargeBonus`, builds and
  applies the Barrier buff, then fires the Zone_Used hook — keeps the resolver's
  `Barrier_Zone` case a single call) (`Scripts/Battle/skills.gd`, kept stateless per that
  script's convention); `BattleResolver.PlaceZone` fires `Skills.TriggerZoneConstructedHook`
  right after placing the zone; `_ResolveZoneEffect` now threads the triggering `zone_ID`
  through so its `Barrier_Zone` case can call `Skills.ApplyBarrierZone`
  (`Scripts/Battle/battle_resolver.gd`); new base-class hooks `CharacterTrait.OnZoneUsed`,
  `CharacterTrait.OnZoneConstructed`, and `CharacterTrait.GetZoneChargeBonus`
  (`Scripts/Character/character_traits/character_trait.gd`) — an enemy Raise the Frame
  without the Calibration trait degrades gracefully to `0.0`, i.e. Barrier = base +
  Knowledge only. The player-facing zone-slot selection flow (`battle.gd`, the turn bar UI)
  already handles any `Skill_Target.ZoneAlly` skill generically — no UI changes were needed.
- `gdlintrc`'s `max-file-lines` raised from 1300 to 1310: `battle_resolver.gd` was already at
  the cap before this change; the `Barrier_Zone` case delegating to `Skills.ApplyBarrierZone`
  kept the file at 1303 lines after the charge-sized Barrier work.
- `Tests/unit/test_calibration_trait.gd` — charge accumulation/cap (including via zone use),
  reset on combat start, finisher damage scaling and rarity table, Expose Weakness threshold
  behavior, charge consumption, the tier-3 zone re-erect/upgrade behavior, Raise the Frame's
  own capped consumption, `OnZoneConstructed`'s recording (capped, non-consuming, Barrier-only),
  `GetZoneChargeBonus`, and the per-zone record being cleared on `StartOfBattle`.
- `Tests/unit/test_barrier_zone.gd` — resolver-level coverage: triggering a Barrier zone
  applies the Barrier buff to the ally standing in it, grants the owner's Calibration trait a
  charge, the zone expires after its charges are spent, and the Barrier's value scales with
  the owner's invested charges (vs. a zero-charge baseline of Knowledge only).
- No Calibration passive icon exists yet; the trait temporarily reuses the Barrier status
  icon (`Assets/Champ_Collector/Icons/Status_Effects/Barrier/Barrier.png`) as a placeholder.

## Open questions

- All damage and shield numbers (the shield's flat base and Knowledge modifier, finisher
  damage, how per-charge potency applies to each tier) — left for later balancing. Landed
  with placeholder `damage_scaling` values on Cornerstone (1.0x Knowledge) and Final
  Calculation (1.3x Knowledge), matching the Tidal Corsair kit's basic/finisher ratio, and a
  placeholder `RAISE_THE_FRAME_BASE_BARRIER` of 15.0.
- The tier-3 "upgrade" of an existing zone is currently just setting its charges to 8 — a
  flavorless placeholder. See the brainstorm note in `FeatureIdeas.md` ("Calibration Zone
  Upgrade Feel") for a more distinct effect.
- A real Calibration passive icon, replacing the Barrier placeholder.
