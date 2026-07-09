# Plan: Sorcerer Arcane Instability Passive

Step 4 of 4 of the reagent system. Implements the Sorcerer's Arcane Instability
passive (`Concept_Document.md` 3.1.3), the first consumer of the `Reagent_Consumed`
hook built in `Plan_Reagent_Combat_Application.md`.

## Status

Not started. Depends on `Plan_Reagent_Combat_Application.md` (the hook and potency
plumbing). **Prerequisite gap:** the Sorcerer champion itself is "(Not yet
implemented)" — no preset in `Data/Character_Player_Variants/` and no skills defined
in the concept doc. The trait can be implemented and unit-tested standalone, but
assigning it in-game requires the Sorcerer champion (its own task via the
new-champion flow, including skill design sign-off with the user). The Surge damage
formula's exact numbers also need user sign-off. If `Plan_Headless_Combat_Core.md`
lands first, the trait hooks fire from `BattleResolver` rather than `battle.gd`.

## Design (from Concept_Document.md 3.1.3)

- Using any skill grants **one Instability stack**, maximum 5.
- Per-stack Mysticism bonus by rarity: **+4% Uncommon, +6% Rare, +8% Epic,
  +10% Legendary**.
- Consuming a reagent grants **two stacks** and **amplifies the reagent's effect**
  by rarity: **20% Uncommon, 30% Rare, 40% Epic, 50% Legendary** (an additive
  potency contribution; no effect on binary reagents — enforced by the potency
  plumbing, not by this trait).
- While at maximum stacks, the Sorcerer's **next skill also releases a Surge**:
  magical damage to **all characters, allies included**, scaling with the
  Sorcerer's Mysticism — then all stacks reset.
- Stacks do not persist between combats.

## Target shape

- **`SorcererTrait`**
  (`Scripts/Character/CharacterTraits/CharacterSpecificTraits/sorcerer_trait.gd`,
  `class_name SorcererTrait extends CharacterTrait`), modeled on `lancer_trait.gd`:
  - Rarity-keyed `const Dictionary[Types.Rarity, float]` tables for per-stack
    Mysticism and reagent amplification.
  - Stack counter reset in `StartOfBattle`.
  - `OnSkillCast`: +1 stack; if entering the cast at max stacks, release the Surge
    and reset to 0 after the skill resolves.
  - `OnReagentConsumed`: +2 stacks (clamped at 5), return the amplification
    contribution.
  - Mysticism bonus: stacks × per-stack percent applied to the Sorcerer's
    Mysticism wherever the trait's attribute contribution belongs (follow how
    existing traits modify attributes; do not fork the attribute path).
  - Stack visualization through `CharacterRepresentation.SetTraitElement`, the
    `Tidal_Corsair_Trait.gd` pattern.
- **Surge**: per-target magical damage scaling with Mysticism; **no critical
  hits**; targets mitigate via Resistance/Defence as normal. Must go through the
  shared damage path (`Skills.DamageDealt`) so `Damage_Taken` trait hooks, Jester
  avoidance, and death handling all apply — do not hand-roll damage. Propose the
  formula's coefficients to the user before implementing.
- **`Sorcerer_Trait.tres`** in `Data/Character_Traits/`, assigned to the Sorcerer
  preset once the champion exists.

## Steps

1. **Trait skeleton.** `sorcerer_trait.gd` with rarity tables, stack counter,
   `StartOfBattle` reset, stack display element.
2. **Skill-cast stacks and Surge.** +1 stack per cast; Surge at max through
   `Skills.DamageDealt`, then reset.
3. **Reagent hook.** +2 stacks and amplification via `OnReagentConsumed`.
4. **Authoring.** `Sorcerer_Trait.tres`; assign to the Sorcerer preset if it
   exists by then, otherwise leave assignment to the champion task.
5. **Tests** (GUT, `Tests/unit/test_sorcerer_trait.gd`, pattern: existing trait
   tests): stack accrual per cast capped at 5; +2 stacks on reagent consumption;
   amplification values by rarity; Surge fires only at max stacks, damages all
   living characters including allies, never crits, and resets stacks; per-stack
   Mysticism values by rarity; stacks reset at battle start.

## Watch for

- The Surge hits allies — death of an ally (or the Sorcerer's own team wipe) mid
  Surge must flow through the normal death handling and battle-over check.
- "Until reagents exist, the passive functions on skill-cast stacks alone"
  (`Concept_Document.md` 3.1.3) — after this plan plus the combat plan, that
  interim clause is obsolete; remove it (see Documentation).
- Stacks are trait state, not a `StatusEffects.Buff` — they must be undispellable
  and invisible to buff-counting effects by construction.
- Naming allowlist; `gdlint Scripts/` clean.

## Documentation

On completion: in `Concept_Document.md` 3.1.3 record the final Surge formula, mark
the passive implemented, and remove the interim "until reagents exist" clause; add
the trait to `Technical_Design_Document.md` §9 (trait hook system) if it introduces
anything beyond existing hook usage.
