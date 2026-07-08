# Plan: Data-Driven Status Effects

Move buff/debuff behavior out of hardcoded `match` statements into resource-defined
data, mirroring how `Skill` already works. This is a prerequisite for the many status
effects the concept document lists as "Not yet implemented" (Anchor, Temporal Leak,
Mana Burn, Sequence Lock, Frenzy, Rush, Exhert, Luck).

## Status

Not started. Independent of the other plans; can run before or after
`Plan_Headless_Combat_Core.md` (if after, the registry hooks into `BattleResolver`
instead of `Skills`).

## Problem

Effect magnitudes and behavior are duplicated across at least three `match` blocks in
`Scripts/Battle/Skills.gd`:

- `TriggerExistingCasterDebuffs` — Burning 4% max health, Enfeeble -30% Attack,
  Expose Weakness -30% Defence (note: -30% here).
- `TriggerExistingCasterBuffs` — Empower +30% Attack, Fortify +30% Defence,
  Daunting Strength x2 damage.
- `TriggerTargetBuffs` / `TriggerTargetDebuffs` — Expose Weakness Defence reduction, now
  aligned at -30% in both places per `Concept_Document.md` 3.2.3.2 (previously the
  target-side snapshot used -50%).

Adding one new effect today means editing every block plus the icon maps, with nothing
enforcing consistency.

## Target shape

```
StatusEffectData (Resource)
├── effect_type: Types.Buff_Type / Types.Debuff_Type (or one unified enum)
├── affected_attribute: Types.Attribute
├── magnitude: float                 # +0.3, -0.5, 0.04-of-max-health, etc.
├── magnitude_kind: enum             # AttributePercent, MaxHealthPercent, DamageMultiplier, TurnBarBump
├── duration_default: int
├── overwritable: bool               # replaces OverwritableBuff/OverwritableDebuff matches
├── stackable: bool                  # resolves the Lava-zone Burning question explicitly
└── icon: Texture
```

One `.tres` per effect under `Data/Status_Effects/`, a registry keyed by effect type,
and a single generic apply/tick routine replacing the match blocks.

## Steps

1. ~~Decide the Expose Weakness magnitude (30% vs 50%) against the concept document
   and record the answer there.~~ Resolved: 30%.
2. **Create `StatusEffectData`** (`Scripts/Battle/status_effect_data.gd`) and author
   `.tres` files for the seven implemented effects (Empower, Fortify,
   Daunting Strength, Phalanx Guard, Burning, Enfeeble, Expose Weakness).
   Keep filenames full-word per the naming convention.
3. **Build a registry** (preload-based, not `DirAccess`-based — follow the
   `biome_data.gd` precedent for Android export safety) mapping effect type to data.
4. **Replace the match blocks** in `Skills.gd` with generic routines driven by
   `magnitude_kind`. `OverwritableBuff`/`OverwritableDebuff` and the
   `Statuses.BUFF_ICONS`/`DEBUFF_ICONS` maps in `status_effects.gd` collapse into the
   resource fields.
5. **Route zone effects through the same data.** The Lava zone currently hardcodes
   Burning with `duration = 2` and two TODO comments asking for exactly this change
   (`Scripts/Battle/Skills.gd:37-38`); give `Zone` a `StatusEffectData` (or effect
   type + duration) instead. Note `Zone` now also carries caster Knowledge to scale
   ally turn-bar effects (commit `1dbe29f`) — keep that scaling intact when routing
   zones through resource data.
6. **Tests:** a data-integrity test that every enum value has a corresponding resource
   (same pattern as `test_character_preset_skill_invariant.gd`), plus behavior tests
   that the generic tick produces the same numbers the hardcoded blocks did (write
   these against the current behavior *before* step 4, then keep them green through
   the swap).

## Watch for

- `StatusEffects.Buff.value` is already used ad hoc by Phalanx Guard — fold it into
  the new model rather than keeping a parallel channel.
- Adventure-spanning effects (`Battle.ApplyAdventureEffects`) construct
  buffs/debuffs manually with `GameBalance.ADVENTURE_BUFF_COMBAT_DURATION`; migrate
  them to the registry so they cannot drift from combat-applied effects.
- Do not implement any of the not-yet-implemented effects in this plan; land the
  mechanism first, add content separately.

## Documentation

On completion: update `Concept_Document.md` 3.2.3 with the resolved magnitudes, and
add the status-effect resource model to `Technical_Design_Document.md` section 6.
