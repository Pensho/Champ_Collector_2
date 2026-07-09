# Plan: Reagent Combat Application

Step 3 of 4 of the reagent system (`Concept_Document.md` 3.3.3). Brings reagents
into battle: pre-battle loadout selection, the in-battle reagent tray, free-action
consumption with targeting, potency-modifier plumbing, and the `Reagent_Consumed`
trait hook. The Sorcerer passive that consumes that hook is
`Plan_Sorcerer_Arcane_Instability.md`.

## Status

Not started. Depends on `Plan_Reagent_Data_And_Catalog.md` and
`Plan_Reagent_Inventory_And_Storage_UI.md`. Touches `battle.gd` and `Skills.gd`
areas that `Plan_Headless_Combat_Core.md` will later refactor — whichever of the
two lands second adapts to the other (if the combat core extraction lands first,
reagent resolution and the `Reagent_Consumed` hook go through `BattleResolver`
instead of `battle.gd`/`Skills.gd` directly).

## Design (from Concept_Document.md 3.3.3)

- Before a battle the player selects **up to 3** reagents from the inventory.
- Each brought reagent is consumable **exactly once per battle**, by any champion,
  **strictly on the consumer's own turn** (never reactively), as a **free action**
  that does not consume the turn.
- A consumed reagent is **permanently deleted** from the inventory; unused brought
  reagents return. On defeat, consumed stays consumed; unused still returns.
- **Potency modifiers stack additively** on one consumption (Sorcerer
  amplification, the Catalyst buff, Alchemist brew potency — only the hook plumbing
  is built here). Binary reagents are never affected by potency modifiers.
- Targeting is per reagent: self, one ally, one enemy, or one zone section.
- Enemies never use reagents.

## Target shape

- **Trait hook**: new `Reagent_Consumed` value in `Types.Combat_Event`
  (`Scripts/common_enums.gd`) and a matching virtual on `CharacterTrait`
  (`Scripts/Character/CharacterTraits/character_trait.gd`), e.g.
  `OnReagentConsumed(p_consumer_ID, p_reagent, …) -> float` returning an additive
  potency contribution (0.0 base). `battle.gd` fires it for the consumer's trait
  and sums contributions; the sum is ignored for binary reagents. If a richer
  result is ever needed, add a type under `TraitHookResults/` instead of widening
  the float.
- **Loadout selection**: `Scripts/UI/Battle_UI/pre_battle_menu.gd` gains a
  pick-up-to-3-reagents step (reagent list from
  `main.GetInstance()` `ReagentCollection`, reusing the `MenuItemSlot` add/remove
  idiom already used for characters). Selection rides into battle on a new
  `_battle_reagents` field on `Scripts/Worldview/Context_Container.gd`.
  `Scripts/Debug/debug_actions.gd` assembles battle contexts the same way and must
  stay in parity (debug loadout for testing without owning reagents).
- **Reagent tray**: `Scripts/UI/Battle_UI/battle_ui.gd` gets up-to-3 reagent
  buttons alongside the skill buttons — enabled only on player turns, disabled
  individually once spent, tooltip/description including the binary "not affected
  by potency modifiers" note.
- **Resolution**: in `battle.gd`, parallel to `ResolveSkill` but *without* the
  end-of-turn block (no cooldown tick, no `TurnCompleteForCharacter`):
  1. Selecting a tray button enters a target-selection state analogous to the
     pending-skill flow (`_on_character_battle_target_selected` /
     `_on_turn_bar_zone_selected` for `Zone_Section` reagents); self-targeted
     reagents resolve immediately. Rewinding Grit targets a *skill*
     (`One_Skill`), which needs its own selection step — e.g. picking one of the
     skill buttons after choosing the reagent.
  2. Fire `Reagent_Consumed`, compute the additive potency multiplier
     (`1.0 + sum`), apply it to scalar magnitudes only.
  3. Apply the effect through existing paths — heal via the shared health
     handling, debuff/buff removal via the `Skills.RemoveBuff`-style helpers,
     cooldown tick on `cooldown_left`, zone clear by erasing from `_zones` (with
     turn-bar visual update), turn-bar reset near `TurnCompleteForCharacter`,
     Fractured Idol self-damage via the shared damage path (floor at 1 Health).
  4. New small mechanisms this step owns: battle-long attribute increase
     (Tinctures — undispellable, unstealable, invisible to buff-counting effects,
     so *not* a `StatusEffects.Buff`) and battle-long damage-dealt bonus
     (Fractured Idol, applied in `Skills.DamageDealt`).
  5. Mark the loadout entry spent and `Consume()` it from the `ReagentCollection`
     immediately (so defeat keeps it consumed).
- **Effect dispatch** should live in a dedicated helper (e.g.
  `Scripts/Battle/reagent_resolver.gd` with static functions, mirroring
  `Skills.gd`'s style) so the future `BattleResolver` extraction can lift it
  wholesale.

## Steps

1. **Hook plumbing.** `Reagent_Consumed` enum value, `CharacterTrait` virtual,
   summation in `battle.gd`.
2. **Context and loadout.** `ContextContainer._battle_reagents`,
   `pre_battle_menu.gd` selection step, `debug_actions.gd` parity.
3. **Resolution core.** `reagent_resolver.gd` effect dispatch for every feasible
   effect kind, including the two new battle-long mechanisms; free-action
   semantics in `battle.gd`.
4. **Reagent tray UI.** Buttons, spent-state, target selection wiring.
5. **Tests** (GUT, `Tests/unit/test_reagent_resolution.gd` and extensions to the
   collection tests): consumption applies the effect exactly once and deletes from
   the inventory; free action leaves the turn active (no cooldown tick, no turn
   completion); once-per-battle enforcement; scalar magnitudes scale with the
   summed potency modifier, binary effects don't; each effect kind resolves
   correctly (heal amount, debuff/buff counts by rarity, cooldown floor at 0,
   1-Health floor for Fractured Idol); Fractured Idol's potency scaling raises
   both the Health cost and the damage bonus (`Concept_Document.md` 3.3.3);
   unused loadout entries return on both win and loss.

## Watch for

- Reagent effects never scale with the consumer's attributes — rarity and potency
  modifiers only.
- The tray must be dead on enemy turns and during animations/target selection for
  skills — reuse whatever gating the skill buttons use.
- Zone clearing is one of exactly two dedicated zone-removal effects
  (`Concept_Document.md` 3.2.4.1, with the Scholar) — do not generalize it.
- Turn-bar reset (Second Wind Phial) applies *after the current turn ends*, not on
  consumption — it needs a pending flag consulted where the turn bar resets.
- Losing a battle: consumed stays consumed, unused returns — test both.
- `gdlint Scripts/` clean; naming allowlist respected.

## Documentation

On completion: update `Concept_Document.md` 3.3.3 (mark rules implemented, record
any semantics settled during implementation) and `Technical_Design_Document.md`
§9 (trait hook system — `Reagent_Consumed`) plus the battle-flow section for the
free-action path.
