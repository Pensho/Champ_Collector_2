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

## Batch 1 — complete

Wretched Conscript, Spreading Rot, Reactive Plating, and Strength in Numbers are
implemented, reviewed, and folded into `Technical_Design_Document.md` section 9.2. Suite
green (604/604), `gdlint Scripts/` clean on the graft scripts. Two notes for future
batches, so they aren't re-litigated per batch:

- The graft attribute layer (`GraftEffect`/`Character.GetTotalAttribute`) stores
  **percent-of-base** deltas, not flat ints — `GetAttributeDelta` computes the flat amount
  live against the attribute's current base value (`ceilf`, sign applied after, matching
  `Skills.ApplyAttributeModifiers`'s convention). Author `_BonusForRarity`/`_Drawback` in
  the design doc's literal percentages.
- A graft's own scaling (e.g. stack-based or ally-count-based bonuses) is a mutation of
  `_attribute_percent_delta` recomputed by the relevant hooks, not `StatusEffects.Buff` —
  it is an inherent property of the graft, not a battle-applied status effect, so it never
  goes through the Buff/Debuff system.

## Roadmap — deferred batches (separate plan files)

Each is its own `Plans/*.md`, building one shared primitive first (with tests), then the
grafts that fall out. None blocks Batch 1.

**Healing primitives batch — complete.** Hollow Hunger, Carrion Bloom, and Overgrowth are
implemented and folded into `Technical_Design_Document.md` section 9.2 (`ResolveTraitHeal`'s
`p_raw_amount` for lifesteal; `CharacterTrait.GetIncomingHealMultiplier` for Carrion Bloom's
permanent self heal-reduction). `battle_resolver.gd` is now at its `gdlintrc`
`max-file-lines`/`max-public-methods` ceiling ([Section 15.10](../Technical_Design_Document.md#1510-battle_resolvergd-is-at-its-gdlintrc-budget-ceiling))
— extend an existing public method rather than adding a new one where possible, or expect to
split the file, before the remaining batches below land their own primitives.

| Plan file | Primitive to build | Grafts |
| --- | --- | --- |
| `Plan_Graft_Tether.md` | Persistent random-ally tether with cross-character attribute sharing + re-tether on death | Symbiotic Anchor |

**Turn-bar-control batch — complete.** Caravan Cadence, Gravitic Rot, and Contagion Bond are
implemented and folded into `Technical_Design_Document.md` section 9.2.

**Retaliation batch — complete.** Glass Refraction, Undertow, and Glamour are implemented and
folded into `Technical_Design_Document.md` section 9.2.

**On-kill and conditional-damage batch — complete.** Bloodscent is implemented and folded into
`Technical_Design_Document.md` section 9.2.

**Zone extensions batch — complete.** Living Bloom and Rootfeeder are implemented and folded into
`Technical_Design_Document.md` section 9.2. `CharacterTrait` is now at its `gdlintrc`
`max-public-methods` ceiling (with headroom, unlike `battle_resolver.gd` it cannot be split into a
subsystem — see section 9.2's note) — expect the next new hook to either use that headroom or
prompt a rethink of the hook-interface shape.

**Event-triggers batch — complete.** Detritivore is implemented and folded into
`Technical_Design_Document.md` section 9.2.

Coverage: Batch 1 (4) + healing (3) + turn-bar control (3) + retaliation (3) + on-kill/conditional (1)
+ zone extensions (2) + event triggers (1) + 1 = **18**.

### Build order and shared primitives

Turn-bar push/pull + ordering (`Plan_Graft_Turn_Bar_Control.md`) and the attacker-aware
`Damage_Taken` hook (`Plan_Graft_Retaliation.md`) have both landed; Undertow's retaliatory
turn-bar pull reused the former, as planned. Rootfeeder (`Plan_Graft_Zone_Extensions.md`) and
Detritivore (`Plan_Graft_Event_Triggers.md`) depended on the landed `ResolveTraitHeal`/
`p_raw_amount` primitive rather than adding their own heal path.

The remaining batch (tether) is otherwise independent.

Manual play-testing after Batch 1 landed surfaced three further bugs, since fixed: the
Inspect Collection graft label showing by default before any character was selected; the
ungrafted tooltip not reusing `SymbioteTrait`'s placeholder text; and the in-battle
graft-target-selection window showing the un-`Init()`'d resource's default "Title"/"Body"
instead of the real graft text (`Battle._OnGraftTargetSelected` now previews with a
duplicated, `Init()`'d instance scaled to the Symbiote's own rarity).
