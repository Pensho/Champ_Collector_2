# Plan — Symbiote Graft Pool (content)

## Context

The Symbiote's `Graft` passive **machinery** is implemented: `GraftEffect extends
CharacterTrait` (`Scripts/Character/character_traits/graft_effect.gd`) with a per-rarity
`_BonusForRarity` / flat `_Drawback` attribute layer and full trait-hook dispatch;
`Character.ApplyGraft`, the derived-attribute getters, persistence by graft UID, the
in-battle free-action Graft flow, and the Inspect Collection display. It ships **no graft
content**.

`Symbiote_Graft_Pool.md` authors the 18 concrete grafts (effects + per-rarity numbers).
A codebase feasibility sweep found only **4 of the 18** are authorable with today's engine;
the other 14 each pull in a new engine primitive the machinery plan did not build. So this
is not a pure content pass — it is phased.

- **This plan (Batch 1)** implements the four buildable-now grafts, needing no new engine
  code. It is a self-contained, reviewable body of work.
- **Batches 2–8** are separate plan files (see the roadmap below), each building one shared
  primitive and then the grafts that fall out. Scheduled and reviewed individually.

**Enemy-to-graft sourcing stays deferred** (per `Symbiote_Graft_Pool.md` and the machinery
plan): author subclasses + `.tres`, unit-test them, leave every enemy `_graft_effect` null.
Grafts become reachable in-game only once enemy sources are assigned in a future pass.

All attribute names use the engine spelling: `Defence`, `CritDamage`, `CritChance`
(`Types.Attribute`, `Scripts/common_enums.gd`). Rarity order everywhere is
Uncommon / Rare / Epic / Legendary.

## Conventions every concrete graft follows

Established by the machinery and the existing role traits
(`Scripts/Character/character_traits/CharacterSpecificTraits/`, e.g. `sorcerer_trait.gd`,
`strike_the_flaw_trait.gd`, `foresight_trait.gd`):

- One script per graft: `class_name <Name>Graft extends GraftEffect` in a new
  `Scripts/Character/character_traits/Grafts/` subfolder (domain subfolder, mirroring how
  role traits sit under `CharacterSpecificTraits/`).
- Per-rarity numbers as `const X_PER_RARITY: Dictionary[Types.Rarity, float]` keyed by the
  four rarities, resolved with `.get(p_rarity, …)`.
- Attribute layer: override `_BonusForRarity(rarity)` (scaled) and `_Drawback()` (flat);
  both return `Dictionary[Types.Attribute, int]`.
- Active effects: override `Init(rarity)` calling `super.Init(rarity)`, set `_title`/`_body`,
  register hooks in `_execution_steps[Types.Combat_Event.X] = Callable(...)`. The base `Init`
  already sets the shared Graft `_trait_texture`; do **not** override it.
- One `.tres` per graft in a new `Data/Character_Traits/Grafts/` subfolder, mirroring
  `Data/Character_Traits/Foresight_Trait.tres` (`script_class`, one `ExtResource` for the
  `.gd`, `script = ExtResource(...)`). No numbers in the `.tres`.
- Rarity-scaled buff/debuff magnitudes are set on the runtime `StatusEffects.Buff`/`Debuff`
  instance at apply time (per-rarity constant → the instance's `value`), following
  `plan_trait.gd`/`lancer_trait.gd`; set `.source_ID = p_owner_ID`.

## Batch 1 steps

**Status: implemented.** All four grafts, their `.tres`, and
`Tests/unit/test_symbiote_graft_pool.gd` are in. Two deviations from the steps below,
found during implementation and review:

- The graft attribute layer (`GraftEffect`/`Character.GetTotalAttribute`) turned out to
  only support flat-int deltas, not the design doc's percentages. Rather than bake
  percentages into guessed flat numbers, `GraftEffect._attribute_percent_delta` and
  `GetAttributeDelta` were changed to store percentages and compute the flat delta
  live against the attribute's current base value (`ceilf`, sign applied after,
  matching `Skills.ApplyAttributeModifiers`'s convention). This is a small machinery
  change beyond the "no new engine code" framing below, made because it was the only
  way to honor the design doc's literal percentages without guessing.
- Reactive Plating's Hardened stacks and Strength in Numbers' living-ally scaling are
  both implemented as mutations of that same `_attribute_percent_delta` (recomputed by
  the relevant hooks), not `StatusEffects.Buff` — a graft's bonus is an inherent
  property of the graft, not a battle-applied status effect, so it should never go
  through the Buff/Debuff system. Worth stating explicitly in future graft-batch plans
  so it isn't re-litigated per batch.

### 1. Wretched Conscript — pure stat
- **New:** `Scripts/Character/character_traits/Grafts/wretched_conscript_graft.gd` + a
  `.tres` in `Data/Character_Traits/Grafts/`.
- `_BonusForRarity`: `Defence +8% / 10% / 12% / 14%`. No effect, no drawback, no hooks.
- **Watch for:** the bonus is a *percent* of base Defence but `GetAttributeDelta` returns an
  `int`; confirm whether the attribute layer stores percent-of-base or flat points by reading
  how `_attribute_delta` is consumed in `Character.GetTotalAttribute` and match that
  convention — do not invent a second one.

### 2. Spreading Rot — attack-applied Blight + self-rot
- **New:** `Grafts/spreading_rot_graft.gd` + `.tres`.
- `_BonusForRarity`: `Health +12% / 16% / 20% / 24%`. No stat drawback (rot is a hook).
- `Skill_Cast` hook (`OnSkillCast`): apply **Blight** (`Types.Debuff_Type.Blight`,
  `Data/Status_Effects/Blight.tres`) to the skill's **enemy** targets — duration 1/1/2/2 —
  via `p_resolver.ApplyDebuff`.
- `Start_Turn` hook: self rot damage = 3% of max Health via
  `p_resolver.SetCurrentHealth(owner, current - int(0.03 * GetMaxHealth(owner)))`.
- **Watch for:** there is no per-hit "on attack" hook; `OnSkillCast` fires for every skill,
  so gate the Blight to targets that are enemies of the owner (`GetSides`). This approximates
  "attacks"; if a true per-hit gate is needed it becomes a machinery item and moves to a
  later batch. Reuse Blight for now — the dedicated Rot debuff is an open decision in
  `Symbiote_Graft_Pool.md` and is not built here.

### 3. Reactive Plating — Hardened stacks on damage taken
- **New:** `Grafts/reactive_plating_graft.gd` + `.tres`; **new** `StatusEffectData`
  `Data/Status_Effects/Hardened.tres` (buff, `AttributePercent` on `Defence`,
  `stackable = true`, rest-of-battle duration).
- `_Drawback`: `Speed -15%`. No attribute bonus.
- `Damage_Taken` hook (`OnDamageTaken`, returns `1.0` unchanged): apply one Hardened stack
  via `p_resolver.ApplyBuff` with per-stack magnitude `+2% / 3% / 4% / 5%`, **capped at 9
  stacks** (read the current stack count from `character._active_buffs` first and skip past
  the cap).
- **Watch for:** confirm whether `AttributePercent` magnitude comes from the runtime
  `Buff.value` or the `StatusEffectData` magnitude (read the apply path in
  `battle_resolver.gd` `ApplyBuff`) and set the per-rarity value accordingly.

### 4. Strength in Numbers — per-living-ally scaling
- **New:** `Grafts/strength_in_numbers_graft.gd` + `.tres`; reuse a percent
  Resistance/Defence buff, or add a `StatusEffectData` if none in `Data/Status_Effects/`
  fits.
- Effect: `+8% / 10% / 12% / 14%` Resistance **and** the same Defence per *other* living
  ally, up to two others. Drawback: while the Symbiote has no living allies, `-25%`
  Resistance.
- Recompute on `Start_Combat`, `Start_Turn`, and `Ally_Death`: count other living allies
  (`GetSides` + current health), remove the prior scaling buff, apply the new one (or the
  no-ally penalty). Model it as a recomputed buff, not a static `_attribute_delta`, because
  the payoff is dynamic battle state.
- **Watch for:** clear the previous instance before reapplying so the buff never
  double-stacks across turns; re-run on `Ally_Death` so a death mid-round updates it.

### 5. Tests
- **New:** `Tests/unit/test_symbiote_graft_pool.gd` (GUT, pure logic; extends the
  `test_graft.gd` / `TestFactory` patterns). Per graft:
  - Attribute deltas scale by rarity and drawbacks stay flat (`GetAttributeDelta`).
  - Spreading Rot: `OnSkillCast` applies Blight to an enemy target and not to an ally target;
    `Start_Turn` reduces the owner's health by ~3% max.
  - Reactive Plating: `OnDamageTaken` adds a Hardened stack and stops at 9.
  - Strength in Numbers: the buff scales with the number of living allies and applies the
    no-ally penalty when alone.
  - Wretched Conscript: `GetTotalAttribute(Defence)` includes the rarity-scaled bonus and
    `_attributes` stays pristine.
- Do **not** test UI/node wiring (per `Test_Design_Document.md`).

## Roadmap — deferred batches (separate plan files)

Each is its own `Plans/*.md`, building one shared primitive first (with tests), then the
grafts that fall out. None blocks Batch 1.

| Plan file | Primitive to build | Grafts |
| --- | --- | --- |
| `Plan_Graft_Healing_Primitives.md` | Public `ResolveTraitHeal` (`Heal` `CombatResult`, respects `IncomingHealReduction`) + lifesteal feeding `_ResolveDamage` back to the caster | Hollow Hunger, Carrion Bloom, Overgrowth |
| `Plan_Graft_Turn_Bar_Control.md` | Resolver-side turn-bar ordering/position queries (today only in `turn_bar.gd`) + public push/pull wrapping `_EmitTurnBarBump` | Caravan Cadence, Gravitic Rot, Contagion Bond |
| `Plan_Graft_Retaliation.md` | Attacker-aware `Damage_Taken` hook (or in-resolver plumbing like `_TriggerMirrorCoat`) | Glass Refraction, Undertow, Glamour |
| `Plan_Graft_On_Kill_And_Conditional_Damage.md` | Killing-blow hook fired on the *killer* + target-Health-conditional damage modifier | Bloodscent |
| `Plan_Graft_Zone_Extensions.md` | Dual-faction zone (buff allies + debuff enemies), zone charge replenishment/cap, affected-by-zone hook | Living Bloom, Rootfeeder |
| `Plan_Graft_Event_Triggers.md` | Buff-expired + zone-dissipated triggers (+ a zone-dissipation `CombatResult`) + broadened `Reagent_Consumed` | Detritivore |
| `Plan_Graft_Tether.md` | Persistent random-ally tether with cross-character attribute sharing + re-tether on death | Symbiotic Anchor |

Coverage: Batch 1 (4) + 3 + 3 + 3 + 1 + 2 + 1 + 1 = **18**.

### Build order and shared primitives

Most primitives are 1:1 with their batch. Two are shared and must be built **once** and then
depended on — do not reimplement them per batch:

- **Public heal (`ResolveTraitHeal`)** is built in `Plan_Graft_Healing_Primitives.md` and
  reused by the on-kill (Bloodscent), zone (Rootfeeder), and event-trigger (Detritivore)
  heals. **Schedule `Plan_Graft_Healing_Primitives.md` first** among the effect batches; the
  three consumers hard-depend on its `ResolveTraitHeal` rather than adding their own heal.
- **Turn-bar push/pull + ordering** is built in `Plan_Graft_Turn_Bar_Control.md` and reused
  by Undertow (`Plan_Graft_Retaliation.md`). Schedule turn-bar control before retaliation, or
  land the primitive with whichever runs first and have the other depend on it.

The remaining batches (retaliation-proper, on-kill hook, zone extensions, event triggers,
tether) are otherwise independent and may run in any order once their prerequisite above is
in place.

## Verification (Batch 1)

1. **Tests:** run the GUT suite headlessly (per project `CLAUDE.md`); confirm
   `test_symbiote_graft_pool.gd`, the existing `test_graft.gd`, and the rest are green.
2. **Lint:** `gdlint Scripts/` clean.
3. **Runtime (temporary wiring, removed before finishing):** temporarily set one enemy's
   `_graft_effect` to each Batch-1 graft in turn, enter a battle with a Symbiote, graft it,
   and confirm each behaves (Wretched Conscript raises Defence by the rarity-scaled amount;
   Spreading Rot's attacks apply Blight and the Symbiote self-rots each turn; Reactive Plating
   stacks Hardened to a cap of 9 as it is hit; Strength in Numbers tracks living-ally count
   and drops to the penalty when alone). Save/reload; confirm each graft persists (effect +
   attribute delta) and Inspect Collection shows "Graft: <name>" with the tooltip. **Remove
   the temporary wiring** — sourcing stays deferred.

**Results:** suite green (535/536; the one failure is pre-existing and unrelated, in
`test_reagent_registry.gd`), `gdlint Scripts/` clean. Runtime verification ran headlessly
through `BattleResolver`/`CharacterCollection` (no windowed Godot available in this
environment) rather than a manual in-editor battle; all four grafts behaved and persisted
correctly. Manual play-testing by the user surfaced three further bugs, since fixed:
the Inspect Collection graft label showing by default before any character was selected;
the ungrafted tooltip not reusing `SymbioteTrait`'s placeholder text; and the in-battle
graft-target-selection window showing the un-`Init()`'d resource's default "Title"/"Body"
instead of the real graft text (`Battle._OnGraftTargetSelected` now previews with a
duplicated, `Init()`'d instance scaled to the Symbiote's own rarity).
