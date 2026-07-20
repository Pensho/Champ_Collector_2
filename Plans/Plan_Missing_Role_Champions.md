# Plan: Missing Role Champions

Bring the nine roles without a playable champion into the game: Emissary, Alchemist,
Sorcerer, Diviner, Appraiser, Symbiote, Cultist, Plague Doctor, Warlord
(`Concept_Document.md` section 3.1.3). Each gets a champion preset with its role
passive implemented as a trait; skill kits and art are placeholders.

## Status

Batch 1 (Role enum entries + Sorcerer and Symbiote presets), Batch 2
(`StartOfBattle` signature extension), Batch 3 (Diviner), and Batch 4 (Appraiser) are
done. Batch 5 (Emissary) is next.

## Decided scope

- **All nine roles**, including Appraiser (the doc's "may postpone" note is
  overridden by this decision).
- **Minimal placeholder skill kits** — reuse existing skill resources from
  `Data/Character_Skill_Variants/`; no bespoke new skills. These kits are interim:
  `Plan_Skill_Implementation.md` builds the real Role kits
  (`Concept_Document.md` 3.2.4.2) and supersedes the placeholders when its champion
  kit batches land.
- **Placeholder art** — reuse existing textures. Emissary, Symbiote, and Alchemist
  have their own unused folders in `Assets/Champ_Collector/Creatures/`; the unused
  `Cleric` folder serves the Diviner; the rest borrow an existing champion's texture.
- **Symbiote ships without a passive** (blank in the doc; Herald of the loom
  precedent). Preset with no trait.
- **Diviner's Foresight applies Enfeeble, duration 1 turn**, no resist roll
  (symmetric to Tactician's Plan applying Empower). Record in the Concept Document.
- **Alchemist brew pool numbers decided**: Lesser Restorative Brew 10% heal, Lesser
  Tincture +4% random attribute, Lesser Barrier Brew flat absorb ~40, Lesser Purging
  Brew removes 1 debuff (Epic/Legendary pool only); brew potency bonus
  −10% / 0 / +10% / +20% by rarity. Record in the Concept Document.

## Established patterns to reuse

- Preset schema: `Scripts/Character/character_preset.gd`; exemplar
  `Data/Character_Player_Variants/Tidal_Corsair.tres`. Slot-0 skill must have
  cooldown 0 (`Tests/unit/test_character_preset_skill_invariant.gd`).
- Trait pattern: base hooks in
  `Scripts/Character/character_traits/character_trait.gd`; concrete traits in
  `CharacterSpecificTraits/`; resources in `Data/Character_Traits/`; rarity tables as
  `const Dictionary[Types.Rarity, float]` + `Init(p_rarity)` (see `plan_trait.gd`,
  `pilfer_trait.gd`, `sorcerer_trait.gd`). Traits are `duplicate(true)`d per
  character (`character.gd`); player characters persist across battles, so every
  stateful trait resets in its start-of-battle hook.
- Preset registration: append to `recruitable_champions` in
  `Data/Recruitment/Bone_Tier.tres`, `Brass_Tier.tres`, `Parchment_Tier.tres`, and
  to `Scripts/Debug/debug_catalog.gd` `PLAYER_CHARACTER_PRESETS`. Also add each new
  champion to the `main_instance.gd` starter roster so it is playable immediately.
- Existing status effects reused: `Attune.tres` (Cultist), `Cracked_Facet.tres`
  (Appraiser), `Enfeeble.tres` (Diviner), `Barrier.tres` (Alchemist brew).
- Scaffolding checklist: `.claude/skills/new-champion/SKILL.md`.
- All nine presets: Uncommon rarity; attribute blocks copied from the closest
  existing preset of the same purpose, skewed toward the doc's primary attributes.

## Interpretations to surface at review

1. **Cultist "power bonus"** is implemented as
   `TraitSkillResult._damage_multiplier = 1.0 + bonus` — it boosts damage skills
   only; a pure debuff skill has no power representation in the pipeline.
2. **Warlord "attack damage"** means any direct damage resolved through
   `_ResolveDamage` where the attacker is an enemy of the damaged ally (AoE
   per-target; debuff ticks and self-costs excluded). The redirected share is
   recomputed with the Warlord's Defence; crit and random multipliers are inherited
   from the ally-side roll.
3. **Emissary infractions keep accruing while the Emissary is dead** (it is a
   record, not an aura).
4. Concept Document bookkeeping: each batch removes its role's "(Not yet
   implemented)" marker; the Alchemist's "inactive until reagents exist" clause is
   obsolete (the reagent system landed) and is updated in Batch 9.

## Batches (one commit each, simplest to most complex)

### Batch 1 — Role enum entries + Sorcerer and Symbiote presets (data only)

- `Scripts/common_enums.gd`: append `Plague_Doctor = 20`, `Warlord = 21` to
  `enum Role`. Do not reuse the unused gap at value 1 — presets serialize `_role`
  as a bare integer, so existing values must never change meaning.
- New `Data/Character_Player_Variants/Sorcerer.tres` — role 5, trait
  `Sorcerer_Trait.tres` (already implemented); skills `Zap.tres`,
  `Attack_Skills/Burning_Bolas.tres`, `Zone_Skills/Flicker_Zone.tres`; weights
  Arcane/Conjurer/Learned; art: reuse Herald of the loom texture.
- New `Symbiote.tres` — role 10, no trait; skills `Heap_On.tres` (Health-scaling
  basic), `Attack_Skills/Crush.tres`, `Support_Skills/Stalwart_Hymn.tres`; weights
  Sturdy/Resilient/Gluttonous; art: own `Symbiote` folder.
- Register both (three recruitment tiers + debug catalog); Concept Document markers
  including the Sorcerer's pending-champion note.

### Batch 2 — `StartOfBattle` signature extension (infrastructure)

Extend to `StartOfBattle(p_owner_ID: int, p_resolver: BattleResolver)` in
`character_trait.gd`; pass `i, _resolver` at the dispatch site in
`Scripts/Battle/battle.gd`; mechanically update the eight existing overrides and
test call sites (`grep -rn "StartOfBattle("`). Needed so the Emissary can subscribe
to resolver events and the Cultist can mark its Vessel at battle start — lazy
initialization at first turn would miss events before the champion's first turn.

### Batch 3 — Diviner (Foresight)

- New `foresight_trait.gd` (`ForesightTrait`), mirroring `PlanTrait`: thresholds
  0.10/0.15/0.20/0.25; on start of turn, `GetCharactersBehindBy(owner, threshold)`
  intersected with enemies → `ApplyDebuff` Enfeeble, duration 1,
  `source_ID = owner`.
- New `Data/Character_Traits/Foresight_Trait.tres`, `Diviner.tres` — role 7; skills
  `Zap.tres`, `Support_Skills/Fatal_Flaw.tres`, `Support_Skills/Stalwart_Hymn.tres`;
  weights Arcane/Conjurer/Learned; art: `Cleric` folder.
- Test `Tests/unit/test_foresight_trait.gd` (pattern: `test_sorcerer_trait.gd` +
  `FakeTurnPositions.behind_IDs` in `helpers/test_factory.gd`): debuff lands only on
  enemies behind within threshold; allies excluded; rarity table.
- Register + Concept Document marker (record the Enfeeble decision).

### Batch 4 — Appraiser (Strike the Flaw; new Critical_Hit hook)

- `common_enums.gd`: add `Critical_Hit` to `Combat_Event`; `character_trait.gd`:
  add `OnCriticalHit(p_owner_ID, p_target_ID, p_resolver)`.
- `Scripts/Battle/battle_resolver.gd` `_ResolveDamage`: after a critical hit lands,
  invoke the caster's trait hook.
- New `strike_the_flaw_trait.gd`: on critical hit, apply `Cracked_Facet` with rarity
  duration {1/1/2/2}, no resist roll (the doc says crits "apply" the debuff).
- New `Strike_The_Flaw_Trait.tres`, `Appraiser.tres` — role 8; skills
  `Attack_Skills/Stab.tres`, `Attack_Skills/Pierce_Weakness.tres`,
  `Support_Skills/Fatal_Flaw.tres`; weights Marksman/Calculating/Learned; art:
  reuse Thief.
- Test: crit applies Cracked Facet with correct duration; non-crit applies nothing;
  hook does not fire when critical hits are disallowed.
- Register + Concept Document marker.

### Batch 5 — Emissary (Standing Record)

- `battle_resolver.gd` `_EmitDebuffApplied`: set
  `result.source_ID = p_debuff.source_ID` (field exists on `CombatResult`; verify
  no UI regression on Status_Applied handling).
- New `standing_record_trait.gd`: rate table constant {0.025/0.03/0.035/0.04}
  (skills reading it are out of scope for this plan); cap 9;
  `_infractions: Dictionary[int, int]`; on `StartOfBattle` clear the tally and
  connect to `p_resolver.result_produced`. Increment on: enemy gains a buff
  (target +1); enemy lands a debuff on an owner-side ally (source +1); enemy places
  a zone (source +1). Public `GetInfractions(p_enemy_ID) -> int`.
- New `Standing_Record_Trait.tres`, `Emissary.tres` — role 0, faction
  The_Iron_Ledger; skills `Bash.tres`, `Attack_Skills/Disarm.tres`,
  `Attack_Skills/Break_Guard.tres`; weights Marksman/Calculating/Learned; art:
  own `Emissary` folder.
- Test: each increment source; ally-side events do not count; cap at 9; reset on a
  new battle.
- Register + Concept Document marker.

### Batch 6 — Cultist (Chosen Vessel; new Ally_Death hook)

- `common_enums.gd`: add `Ally_Death`; `character_trait.gd`:
  `OnAllyDeath(p_owner_ID, p_dead_ally_ID, p_resolver)`.
- `battle_resolver.gd` `_HandleDeath`: invoke the hook on living allies of the dead
  character. Add public `GetMaxHealth(p_character_ID) -> int` (traits need max
  health including max-health buffs for the drain).
- New `chosen_vessel_trait.gd`: power table {0.15/0.20/0.25/0.30}, drain 5%.
  `StartOfBattle` marks a random living ally (self excluded). `OnSkillCast`:
  non-basic (skill `cooldown > 0`, same definition as `ResolveSkill`) → drain the
  Vessel via `SetCurrentHealth` (routes clamping and death handling) and return
  damage multiplier `1.0 + bonus`. `OnAllyDeath`: if the Vessel died → `ApplyBuff`
  Attune for 3 turns, re-mark among living allies (none → `_vessel_ID = -1`).
- New `Chosen_Vessel_Trait.tres`, `Cultist.tres` — role 12; skills `Zap.tres`,
  `Attack_Skills/Burning_Bolas.tres`, `Attack_Skills/Break_Guard.tres`; weights
  Arcane/Conjurer/Learned; art: reuse Bloodmage.
- Test: marking excludes the Cultist; basic skill has no effect; non-basic drains
  5% with the rarity multiplier; drain can kill the Vessel → Attune + re-mark;
  enemy kill of the Vessel also triggers; all allies dead → `-1`, no loop.
- Register + Concept Document marker.

### Batch 7 — Plague Doctor (Comorbidity)

- `Scripts/Battle/status_effects.gd` `Debuff`: add
  `tick_bonus_per_debuff: float = 0.0`. `TraitSkillResult`: add a matching field.
  `battle_resolver.gd`: `_CastDebuff` stamps the bonus onto new debuffs; in
  `_TriggerExistingCasterDebuffs`, multiply tick damage by
  `1.0 + bonus * mini(target's active debuff count, 5)` — counted at tick time,
  ticking debuff included, debuffs from any source.
- New `comorbidity_trait.gd`: table {0.05/0.07/0.09/0.11}; `OnSkillCast` returns
  the per-debuff fraction. Spell out `damage_over_time` in identifiers.
- New `Comorbidity_Trait.tres`, `Plague_Doctor.tres` — role 20; skills `Zap.tres`,
  `Attack_Skills/Burning_Bolas.tres`, `Zone_Skills/Lava_Zone.tres` (Miasma
  stand-in); weights Arcane/Resilient/Conjurer; art: reuse Jester.
- Test: tick scales with the target's debuff count at tick time; cap 5; other
  casters' debuffs unaffected; recomputes between ticks; rarity table.
- Register + Concept Document marker.

### Batch 8 — Warlord (Shield Wall; new Ally_Damage_Taken hook + proximity query)

- `Scripts/Battle/turn_positions.gd`: add
  `GetCharactersWithinProximity(p_owner_ID, p_bar_percent)` (both directions,
  absolute distance, mirror of `GetCharactersBehindBy` in `turn_bar.gd`); delegate
  through `turn_bar_positions.gd`; extend `FakeTurnPositions` in
  `helpers/test_factory.gd`.
- `common_enums.gd`: add `Ally_Damage_Taken`; `character_trait.gd`:
  `OnAllyDamageTaken(...) -> float` returning the redirect fraction (default 0.0).
- `battle_resolver.gd` `_ResolveDamage`: extract the mitigation formula into a
  helper; when the attacker is an enemy of the target, poll the target's living
  allies for a redirect fraction; the ally takes `(1 − fraction)` of its damage,
  the redirected share is recomputed through the helper with the soaker's Defence
  and applied via `_ApplyHealthLoss` plus its own `Damage` result. First
  redirecting ally wins.
- New `shield_wall_trait.gd`: table {0.15/0.20/0.25/0.30}, proximity window 0.15
  checked at damage time; a dead Warlord never soaks.
- New `Shield_Wall_Trait.tres`, `Warlord.tres` — role 21; skills `Bash.tres`,
  `Support_Skills/Stalwart_Hymn.tres`, `Attack_Skills/Crush.tres`; weights
  Sturdy/Resilient/Fierce; art: reuse Knight.
- Test: in-window split with Warlord-Defence mitigation; out-of-window full damage;
  the Warlord's own damage is never redirected; dead Warlord; AoE hitting two
  allies → two separate soaks; rarity table.
- Register + Concept Document marker.

### Batch 9 — Alchemist (Fresh Batch; reagent plumbing)

- `Scripts/Battle/reagent_data.gd`: add `EffectKind.Barrier` and
  `@export var brew_only: bool = false`. `reagent_registry.gd`: exclude `brew_only`
  entries from `GetRandomKeyForRarity`; register the four new keys.
- New `Data/Reagents/Alchemist_Brews/`: `Lesser_Restorative_Brew.tres`,
  `Lesser_Tincture.tres`, `Lesser_Barrier_Brew.tres`, `Lesser_Purging_Brew.tres` —
  all `brew_only`, magnitudes per the decided numbers above.
- `battle_resolver.gd`: `_ResolveReagentEffect` Barrier branch → `ApplyBuff`
  Barrier with `value = magnitude × potency`; `ResolveReagent` gains
  `p_extra_potency: float = 0.0` (additive).
- `Scripts/Battle/reagent_loadout.gd`: `AddBrewed(p_key, p_potency_bonus)`; brewed
  entries never touch `ReagentCollection.Consume` and are dropped with the loadout
  at battle end ("lost if unconsumed").
- New `fresh_batch_trait.gd`: potency table {−0.10/0.0/+0.10/+0.20}; pool of three
  brews at Uncommon/Rare, plus Purging at Epic/Legendary;
  `BrewReagentKey(p_random)` and `GetBrewPotencyBonus()` (base `CharacterTrait`
  returns `""`/`0.0` so `battle.gd` stays polymorphic).
- `Scripts/Battle/battle.gd`: after the loadout is created, each fielded champion's
  trait may add a brewed slot; pass per-slot potency into
  `_ResolveReagentConsumption`. Verify the `_battle_ui._reagent_buttons` count —
  if fixed at three, add a fourth button to the battle UI scene and
  `Scripts/UI/Battle_UI/battle_ui.gd`.
- New `Fresh_Batch_Trait.tres`, `Alchemist.tres` — role 4; skills `Zap.tres`,
  `Support_Skills/Power_Tide.tres`, `Support_Skills/Stalwart_Hymn.tres`; weights
  Learned/Arcane/Calculating; art: own `Alchemist` folder.
- Tests: pool per rarity; brew key always valid in the registry; potency table;
  brewed slot consumable once and never touches the inventory; random-key rolls
  never return `brew_only` keys; Barrier effect applies a Barrier buff. Check
  `test_android_export_safety.gd` expectations for new preloads.
- Register + Concept Document markers; record the brew numbers; update the
  obsolete "inactive until reagents exist" clause.

### Wrap-up

Update `Technical_Design_Document.md` once for the new trait hooks
(`Critical_Hit`, `Ally_Death`, `Ally_Damage_Taken`), the extended `StartOfBattle`
signature, the brewed-reagent slot, and the nine new champions.

## Verification (every batch)

- Full GUT suite headless, iterated to green before the batch is done:
  ```
  /home/jonas/Documents/Godot_v4.7.1-stable_linux.x86_64 \
    --headless -s addons/gut/gut_cmdln.gd \
    -gdir=res://Tests/unit/ -gprefix=test_ -gsuffix=.gd -gexit
  ```
- `gdlint Scripts/` clean whenever a `.gd` file changed.
- `test_character_preset_skill_invariant.gd` validates each new preset.
- Conventions: type hints everywhere; acronym allowlist respected; never
  hand-write `.uid` files; unique `_preset_UID` per preset.
- Git: stage per batch, present a summary, wait for explicit approval before each
  commit.
- End-to-end check after Batch 9: launch a debug battle with an Alchemist fielded
  and confirm the brewed fourth reagent slot appears and consumes correctly.
