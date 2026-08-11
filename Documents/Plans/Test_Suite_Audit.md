# Test Suite Audit (Phase 0 of Plan_Test_Suite_Consolidation.md)

One row per test file (134 total). `Verdict` is one of: `keep`, `keep-trimmed` (delete
named functions, keep the rest), `fold-and-delete` (fold named functions into a target
file, delete the rest), `delete`. Nothing in this document has been applied yet —
Phase 3 executes these verdicts in reviewable batches after this audit is approved.

Two planned Tier 2 sweeps are referenced below before they exist
(`test_trait_contract.gd`, `test_skill_content_sweep.gd`) — they are written in Phase 2.
Any verdict that folds into one of them is deferred until that file exists; until then,
the tautology test can be deleted outright since Tier 2 will re-derive the same fact
generically (rarity monotonicity, "no attribute bonus/drawback" for content with none).

## Traits (22 files)

| File | Tier | Verdict | Reason |
|---|---|---|---|
| test_ash_offering_trait.gd | 3 | keep | Husk-death-stacks-into-next-Sermon mechanic; no rarity table. |
| test_calibration_trait.gd | 3 | keep-trimmed | Delete `test_per_charge_potency_table` (tautology). Keep charge accrual/cap, Final Calculation's charge-to-multiplier conversion, Expose Weakness threshold, construction-zone re-erect/upgrade. |
| test_chosen_vessel_trait.gd | 3 | keep-trimmed | Delete `test_power_bonus_table` (tautology). Keep vessel-marking/drain-on-death mechanics. |
| test_comorbidity_trait.gd | 3 | keep | Distinct-debuff-type tick-multiplication mechanism, uncapped, recomputed between ticks; no rarity table. |
| test_double_the_fun_trait.gd | 3 | keep-trimmed | Delete `test_avoidance_increment_table` (tautology). Keep avoid-chance ramp/cap, stack reset on death/battle-start, targeting-priority multiplier. |
| test_field_of_study_trait.gd | 3 | keep-trimmed | Delete `test_weakness_reduction_table` (tautology). Keep weakness-identification (highest non-Speed attribute, tie-break, dead exclusion) and weakness-rider compounding. |
| test_foresight_trait.gd | 3 | keep-trimmed | Delete `test_percent_behind_threshold_table` (tautology). Keep turn-bar-behind enemy-enfeeble logic and ally-exclusion. |
| test_fresh_batch_trait.gd | 3 | keep-trimmed | Delete `test_potency_bonus_table`, `test_team_damage_bonus_table` (tautologies). Keep brew-pool draws, team-wide Volatile Mixture propagation, damage-bucket-key collision guard. |
| test_hemoclarity_trait.gd | 3 | keep-trimmed | Delete `test_mysticism_bonus_table` (tautology) and `test_rarity_scaling_uncommon_vs_epic` (generic "scales by rarity", folds into `test_trait_contract.gd`). Keep health-threshold trigger tests incl. zero-max-health guard. |
| test_lancer_trait.gd | 3 | keep-trimmed | Delete `test_momentum_per_stack_table`, `test_phalanx_guard_defense_table` (tautologies). Keep Momentum accrual/cap, attack-bonus-from-stacks, Defend-time penalty, Phalanx Guard buff. |
| test_lien_trait.gd | 3 | keep | Empower-on-first-unbuffed-turn gated by 4-turn cooldown; no rarity table. |
| test_on_the_house_trait.gd | 3 | keep-trimmed | Delete `test_heal_fraction_table` (tautology). Keep team-heal-on-buff-gain, dead-ally skip, once-per-cycle pour window. |
| test_pilfer_trait.gd | — | delete | `test_steal_chance_table` is a tautology; the other two tests exercise `BattleResolver.RemoveBuff` generically and never touch Pilfer's own hooks — misfiled, belongs in a Tier 1 buff-manipulation test (`test_buff_manipulation.gd`), not here. |
| test_plan_trait.gd | 3 | keep-trimmed | Delete `test_percent_behind_threshold_table` (tautology). Keep owner-never-self-buffs rule and ally-within-threshold empower (Plan is the ally-buff mirror of Foresight). |
| test_shield_wall_trait.gd | 3 | keep-trimmed | Delete `test_redirect_fraction_table` (tautology). Keep everything else — plan's own Tier 3 exemplar for damage-redirect split. |
| test_sorcerer_trait.gd | 3 | keep-trimmed | Delete `test_mysticism_per_stack_table`, `test_reagent_amplification_table` (tautologies). Keep Instability accrual, Surge-only-at-max-stacks, Surge-never-crits, reagent-triggered repeat-cascade. |
| test_standing_record_trait.gd | 3 | keep-trimmed | Delete `test_rate_per_infraction_table` (tautology). Keep everything else — plan's own Tier 3 exemplar for counter source (enemy-only infraction sources). |
| test_strike_the_flaw_trait.gd | 3 | keep-trimmed | Delete `test_cracked_facet_duration_table` (tautology). Keep crit-triggered debuff application and the crit-disallowed guard. |
| test_symbiote_trait.gd | — | delete | All 3 tests are cosmetic: non-empty-body check, texture-not-null check, and a trivial "registers no hooks" check on a placeholder trait. No combat behavior. |
| test_tidal_corsair_trait.gd | 3 | keep-trimmed | Delete `test_damage_per_steel_stack_table`, `test_turn_bar_per_sea_stack_table` (tautologies) and the two description-wording tests (out of scope). Keep stack accumulation, leftmost-fill order, Reckoning consumption. |
| test_time_tithe_trait.gd | 3 | keep-trimmed | Delete `test_tithe_fraction_table` (tautology). Keep tithe-on-turn-bar-reduction hook, resolver-seam integration, and the recursion guard (`no_tithe_without_a_source...cannot_recurse`). |
| test_wardens_failsafe_trait.gd | 3 | keep | Ally-death-triggers-permanent-Frenzy-once mechanic; fixed rarity, no table. |

## Grafts and per-champion skill kits (13 files)

| File | Tier | Verdict | Reason |
|---|---|---|---|
| test_bloodscent_graft.gd | 1+3 | keep-trimmed | Fold `test_on_kill_*` and `test_outgoing_damage_bonus_*`/`test_default_trait_leaves_damage_unchanged` (they use a generic `FakeOutgoingDamageTrait`, not Bloodscent) into `test_graft.gd`'s hook-dispatch coverage; delete `test_bloodscent_has_no_attribute_bonus_or_drawback` (folds into `test_trait_contract.gd`). Keep the lowest-enemy-at-or-below-half-health bonus/penalty tests — novel to this graft. |
| test_detritivore_graft.gd | 3 | keep-trimmed | Plan's own Tier 3 exemplar (uncapped scrap stacks, global buff-expiry hook wiring). Delete `test_has_no_attribute_bonus` (folds into `test_trait_contract.gd`). |
| test_graft.gd | 1 | keep | Plan's own Tier 1 exemplar; fold target for other files' generic attribute-delta/dispatch tests. |
| test_living_bloom_graft.gd | 3 | keep-trimmed | Delete `test_knowledge_bonus_scales_by_rarity`, `test_has_no_attribute_drawback` (fold into `test_trait_contract.gd`). Keep zone-seeding and charge-topping tests — novel. |
| test_retaliation_grafts.gd | 3 | keep-trimmed | Delete the five rarity/no-drawback tests across Glass Refraction/Undertow/Glamour (fold into `test_trait_contract.gd`). Keep the three distinct retaliation shapes (mysticism-scaled backlash, pull-plus-self-reduce, redirect/multiplier/damage-bonus trio). |
| test_rootfeeder_graft.gd | 3 | keep-trimmed | Delete `test_has_no_attribute_bonus_or_drawback` (fold into `test_trait_contract.gd`). Keep ownership-conditional zone-effect multiplier and heal-on-contact. |
| test_symbiote_graft_pool.gd | 3 | keep-trimmed | Delete the six rarity/no-drawback tests across the 7 grafts (fold into `test_trait_contract.gd`); delete `test_wretched_conscript_total_attribute_includes_bonus_and_stays_pristine` (duplicates `test_graft.gd`). Keep the five grafts' genuinely unique mechanisms (stack cap, living-ally-count recompute, lifesteal, lowest-Health-including-self halved heal, stack-scaled heal with 6-stack reset). |
| test_symbiotic_anchor_graft.gd | 3 | keep-trimmed | Delete `test_resistance_bonus_scales_by_rarity`, `test_drawback_reduces_defence_and_crit_damage_by_30_percent` (fold into `test_trait_contract.gd`). Keep the tether-sharing/re-tether/snapshot-not-live tests — novel. |
| test_turn_bar_control_grafts.gd | 3 | keep-trimmed | Delete the three rarity-table checks (fold into `test_trait_contract.gd`). Keep Caravan Cadence's forward-block-and-push, Gravitic Rot's drain-behind, Contagion Bond's copy-with-resist-and-reentrancy-guard — all novel. |
| test_emissary_skills.gd | — | fold-and-delete | Fold `test_signed_writ_escalation_makes_only_one_debuff_attempt` into `test_skill_effects.gd` (condition mutual-exclusion case). Keep verbatim as regression tests: `test_citation_deals_no_infraction_bonus_without_bonus_per`, `test_signed_writ_escalation_threshold_is_rarity_independent` (both carry explicit regression comments). Delete the remaining 9 tests — content coverage moves to `test_skill_content_sweep.gd`. |
| test_jester_skills.gd | — | fold-and-delete | Fold `test_pratfall_sting_deals_no_bonus_without_a_trait` into `test_skill_effects.gd` (a `bonus_per: Trait_Condition` source with no matching trait resolves to no bonus). No regression comments present, so nothing else is preserved. Delete the remaining 3 tests — content coverage moves to `test_skill_content_sweep.gd`. |
| test_skills.gd | 1 | keep | Not a per-champion file — `FindSkillTargets`/`RollsCritical`/`CorrectZoneTarget`/`Barrier`/`MostBuffed` mechanism coverage. |
| test_zone_skills.gd | 1 | keep | Not a per-champion file — general zone-placement/trigger mechanism through the real pipeline against shipped multi-champion `.tres` skills. |

## Remaining files, batch A (50 files)

| File | Tier | Verdict | Reason |
|---|---|---|---|
| test_adjust_long_attribute_bonus.gd | 1 | keep | `AdjustLongAttributeBonus` mechanism coverage, independent per-attribute accumulation. |
| test_adventure_background_generator.gd | 1 | keep | Parameterized generator mechanism (determinism, node avoidance, region coherence, edge clamping). |
| test_adventure_effects.gd | 3 | keep-trimmed | `test_buff_decays_over_four_combats`/`test_debuff_decays_over_two_combats` duplicate `test_adventure_state.gd`'s decay coverage — fold into that file and delete this one. |
| test_adventure_generator.gd | 1 | keep | Node-graph generation mechanism sweep (boss placement, branching, uniqueness, loot fallback). |
| test_adventure_interaction_panel.gd | 3 | keep | Escalate-node reagent-granting UI integration behavior, not covered elsewhere. |
| test_adventure_road_generator.gd | 1 | keep | Road-point generation mechanism (determinism, endpoint matching, sway-cap bound). |
| test_adventure_state.gd | 1/2 | keep | Thorough `AdventureState` coverage; absorbs `test_adventure_effects.gd`'s decay tests. |
| test_android_export_safety.gd | 1 | keep | Static scan guard against two named packed-export defects — code/API usage check, not cosmetic. |
| test_barrier.gd | 1 | keep | Barrier Health-loss-pool primitive mechanism. |
| test_barrier_zone.gd | 3 | keep | Architect's zone integration: Calibration charge grant, charge-scaled Barrier, expiry. |
| test_battle_over.gd | 3 | keep-trimmed | Trim `test_01_ready_calls_focus_button`/`test_02_visibility_changed_calls_focus_button` (near-cosmetic UI-focus checks). Keep `test_03_init_sets_loss_screen`/`test_10_init_populates_character_result_UI_calls` and the rest (real Init/data-population behavior). |
| test_battle_resolver.gd | 1 | keep | Second Tier 1 exemplar; full seeded-battle regression net plus explicit per-resolver-state regression test. |
| test_bleed_plague_ticks.gd | 1 | keep | CasterAttributeSnapshotPercent self-tick mechanism (attribute snapshot at application, stacking). |
| test_blight_regeneration.gd | 3 | keep | Shared `_ApplyHeal` application point: Regeneration heal, Blight halving both regen and reagent heals. |
| test_broadcast_event.gd | 1 | keep | `BroadcastEvent` mechanism and its three wiring sites. |
| test_buff_count_damage.gd | 3 | keep | `damage_bonus_per_buff` for two distinct skills (consume-and-scale vs. read-without-consuming). |
| test_buff_manipulation.gd | 1 | keep | Buff-manipulation primitives (ReduceBuffDurations, ConsumeBuffs, StealBuff incl. Severance block). |
| test_burning_damage.gd | 1 | keep | Burning tick mechanism: reporting, amount, per-source attribution, lethal tick. |
| test_burst_pacing.gd | 1 | keep | Pure-function escalation-curve coverage (monotonicity, bounds, summed-delay cap). |
| test_burst_reachability_crit.gd | 1 | keep | Parameterized crit-factor coverage plus an explicit regression pin; no overlap with the other burst-reachability files. |
| test_burst_reachability.gd | 1 | keep | Broad scorer-algebra sweep (bucket math, status cap, enabler floor, cascade bounds). |
| test_burst_reachability_live.gd | 3 | keep | Only file replaying manifest predictions against the real resolver; includes a scope-leak regression guard. |
| test_cascade_resolution.gd | 1 | keep | `CascadeResolver`'s own architecture (depth cap, fan-out cap, dedup) — explicitly scoped away from per-effect content. |
| test_character.gd | 1 | keep | `Character`'s equipment/attribute pipeline mechanism. |
| test_character_preset_skill_invariant.gd | 2 | keep | Plan's own Tier 2 exemplar. |
| test_character_skill_isolation.gd | 3 | keep | Explicit regression file (shared-Skill-resource defect); named in the plan's preserved-regression list. |
| test_collection_serialization.gd | 1 | keep | `ItemCollection`/`CharacterCollection` round-trip incl. legacy-key compatibility. |
| test_combat_team.gd | 1 | keep | `CombatTeam`/`CombatSides` mechanism (membership, alive-filtering, seeded selection). |
| test_combined_damage_modifier.gd | 1 | keep | `CombinedDamageModifier` grouping rule, unit-level. |
| test_combined_damage_modifier_resolution.gd | 1 | keep | Integration companion; Daunting Strength banking/expiry across turns. Only superficial overlap with the unit-level file. |
| test_consumed_status_effects.gd | 1 | keep | Four consume-on-trigger buffs (Premonition, Deathward, Aegis, Rehearsed), each with a distinct trigger plus the shared consume pattern. |
| test_creature_placeholder_table.gd | — | delete | Every test is a static-content/shape check on a debug data table (hardcoded row count, folder uniqueness) — the same pattern flagged in `test_skill_icon_table.gd`. |
| test_debug_actions.gd | 3 | keep | Debug-tool-specific behavior (preset building, battle-context assembly, level-set semantics). |
| test_encounter_assembly.gd | 2 | keep | Genuine contract sweep over `Battle_Variants` composition rule; explicitly disclaims description/icon checks. |
| test_enemy_turn_targeting.gd | 3 | keep | Explicit regression comment (Statue_Shield/Statue_Weapon soft-lock). |
| test_equipment.gd | 3 | keep | `Equipment.Upgrade`/`CanUpgrade` mechanics (level-gated upgrade, slot-pool fallback). |
| test_exhert_self_cost.gd | 3 | keep | `self_tick_max_health_cost_percent` independent of `magnitude_kind`, plus dual own-turn-damage/always-on buff. |
| test_exposed_cracked_facet.gd | 3 | keep | Inverted-ownership crit bonuses read from the target's own debuffs. |
| test_get_effective_attributes.gd | 1 | keep | `GetEffectiveAttributes`'s five-step ordered composition and live-recompute invariant. |
| test_health_result_ordering.gd | 1 | keep | Explicit regression file (emit-before-apply ordering bug); named in the plan's preserved-regression list. |
| test_hollow_ledger_window.gd | 2 | keep | Boundary test of the pure `DescribeWeight` threshold function — semantic classification, not cosmetic. |
| test_lava_zone_burning.gd | 3 | keep | Stacking Burning per zone visit up to the status cap, charge-based expiry, Aegis blocking a zone debuff. |
| test_level_system.gd | 2 | keep | Contract sweep over `LevelSystem`'s public API. |
| test_live_combat_reads.gd | 3 | keep | Explicit regression header (attributes never folded stale into `GetEffectiveAttributes`); four distinct call sites. |
| test_loot_manager.gd | 1 | keep | `LootManager` formula mechanism (distribution, tier thresholds, upgrade cost). |
| test_luck_hexed_rolls.gd | 3 | keep | Luck's better-of-two roll and confirmation of variance-roll exclusion; top comment documents a design correction. |
| test_mana_burn.gd | 3 | keep | Damage scaled by holder's own Mysticism, gated to non-basic casts. |
| test_mirror_coat.gd | 3 | keep | Two-roll mirror mechanic, each test isolating a distinct branch. |
| test_most_injured_ally_targeting.gd | 1/3 | keep | `Skills.MostInjured` ratio/tie-break/dead-exclusion logic, plus real dual-target resolver wiring — not covered by `test_targeting_order.gd`. |
| test_opportunist_damage.gd | 3 | keep | Per-debuff-type bucketing regardless of stack count, with a bucket-sharing rule against double-counting. |
| test_overflow_wanderlust.gd | 3 | keep | Two distinct behaviors: Overflow's expiry-triggered AoE, Wanderlust's non-persisting random self-tick. |

## Remaining files, batch B (51 files)

| File | Tier | Verdict | Reason |
|---|---|---|---|
| test_reagent_collection.gd | 1 | keep | `ReagentCollection` mechanism coverage. |
| test_reagent_loadout.gd | 1 | keep | `ReagentLoadout` once-per-battle and brewed-slot semantics. |
| test_reagent_loot.gd | 1 | keep | Reagent-specific loot/sell-value logic, distinct from generic loot-table tests. |
| test_reagent_registry.gd | 2 | keep | Contract sweep over `ReagentRegistry.REAGENTS`. |
| test_reagent_resolution.gd | 1 | keep | Large parameterized `ReagentResolver` suite (potency stacking, Catalyst additivity). |
| test_recruitment_manager.gd | 1 | keep | Reward-building/rarity-picking mechanism; tier-resource tests check functional data (reward_count, tier_type), not cosmetics. |
| test_refracted_targeting.gd | 3 | keep | Novel single-enemy targeting-override behavior. |
| test_refutation.gd | 3 | keep | Novel dual-branch zone-clear behavior (enemy-placed vs. ally-placed). |
| test_reliquary_ward.gd | 1 | fold-and-delete | Hand-assembled replica re-proving `AlternatingEffect`'s cycle-by-use-count, already in `test_skill_effects.gd`. Fold `test_alternation_is_independent_per_resolver` there; delete the rest. |
| test_resource_handler.gd | 1 | keep | `ResourceHandler` spend/regen/Fortune's-Favor mechanism incl. a save-migration case. |
| test_retaliation_primitives.gd | 1 | keep | Three distinct primitives (attacker-ID-carrying hook, redirect chance, public multiplier aggregate). |
| test_rush.gd | 3 | keep | Novel expiry-triggered unresistable Stun. |
| test_sequence_lock.gd | 3 | keep | Novel blanket rule blocking all Speed-touching statuses, exercised through two paths. |
| test_settings.gd | 1 | keep | `Settings` resource mechanism (defaults, reset, round-trip, audio mute). |
| test_signed_writ_severance.gd | 3 | keep | Two distinct blanket rules interacting with Mirror Coat and skill-cast respectively. |
| test_skill_effect_order.gd | 1 | keep | Named `test_turn_bar_*`-family exemplar; locks in authored effect order for shipped skills. |
| test_skill_effects.gd | 1 | keep | The canonical Tier 1 exemplar; fold target for Phase 1 and several files above. |
| test_skill_health_change.gd | 1 | keep | Full-pipeline `Skill.health_change` coverage (barrier absorption, blight, Vigor ordering) — distinct from `test_skill_effects.gd`'s direct-injection tests. |
| test_skill_icon_table.gd | 2 | keep-trimmed | Delete `test_expected_row_count` (hardcoded count, no behavior — static-content violation). Keep `test_rows_have_valid_shape`, `test_folders_are_unique`, `test_base_names_are_unique`, `test_folders_use_ability_subfolder_and_match_base_name` (real structural invariants). |
| test_skill_multi_target_status_groups.gd | 1 | keep | `Skill.buffs/debuffs` as multi-target-group dictionary; not covered by `test_skill_effects.gd`. |
| test_skill_resources.gd | 2 | keep | Plan's own Tier 2 exemplar. |
| test_skills_mitigation.gd | 1 | keep | `Skills.MitigatedDamageUnrounded` Defence formula incl. a pinned regression case. |
| test_spore_zone.gd | 3 | keep | Dual-faction (regen ally / blight enemy) zone behavior, Knowledge-scaled — integration-level, distinct from the raw-function tests in `test_zone_knowledge_scaling.gd`. |
| test_spotlight.gd | 3 | keep | Novel damage-reduction behavior. |
| test_status_effect_cap.gd | 1 | keep | `MAX_STATUS_EFFECTS` pool-blocking mechanism. |
| test_status_effect_hooks.gd | 1 | keep | Named Tier 1 exemplar; fold target for Phase 1's "neutral value for dead owner" contract. |
| test_status_effect_multi_attribute.gd | 1 | keep | Multi-attribute `StatusEffectData` and flat-vs-percent modifiers; complements rather than duplicates `test_status_effect_ticks.gd`. |
| test_status_effect_names.gd | 1 | keep | `BuffName`/`DebuffName` transform — a real function test, not a content assertion. |
| test_status_effect_registry.gd | 2 | keep | Contract sweep asserting every implemented Buff/Debuff type resolves to registry data. |
| test_status_effect_ticks.gd | 1 | keep | Registry-driven status application across live-read and resolver-self-tick paths. |
| test_stun_fatigue.gd | 3 | keep | Stun's turn-skip and Fatigue's cooldown freeze, two distinct behaviors. |
| test_target_debuff_count_damage.gd | 1 | fold-and-delete | A single new `bonus_per` source (`Target_Debuff_Count`) via a hand-built skill — the same mechanism is already parameterized for five other sources in `test_skill_effects.gd`. Fold the case there; delete the file. |
| test_targeting_order.gd | 1 | keep | Explicit regression comment; named in the plan's preserved-regression list. |
| test_team_corpus.gd | 2 | keep | Contract sweep over `TeamCorpus.PROVISIONAL_ROWS` plus two named pinned-regression fixtures. |
| test_team_sweep.gd | 1 | keep | `TeamSweep.DedupeByRole` mechanism, small but real. |
| test_temporal_leak.gd | 3 | keep | Turn-bar-movement-accumulation trigger, unique mechanism. |
| test_transfusion_barrier.gd | 1 | keep | Full-pipeline `barrier_from_health_paid` incl. partial-absorption cascading — distinct from `test_skill_effects.gd`'s direct `BarrierEffect` test. |
| test_turn_bar_gating.gd | 1 | keep | Named `test_turn_bar_*`-family member; Anchor/Steadfast gating plus reaction routing. |
| test_turn_bar_ordering.gd | 1 | keep | Named `test_turn_bar_*`-family member; direct ordering-function coverage. |
| test_turn_bar_speed.gd | 1 | keep | Explicit regression coverage; named in the plan's preserved-regression list. |
| test_vigor_max_health.gd | 3 | keep | Vigor read directly in `_MaxHealth`, reclamps on expiry — novel. |
| test_warped_damage.gd | 3 | keep | Novel damage-scaling-attribute redirection to the lower Mysticism. |
| test_writ_of_seizure_ward.gd | 3 | keep | Encounter-specific wiring test using real shipped presets, not replicas — steal-buff routing to a third party, not covered by generic `StealBuffEffect` tests. |
| test_zone_affected_hook.gd | 1 | keep | Generic `OnAffectedByZone`/`GetIncomingZoneEffectMultiplier` dispatch, independent of any one zone type. |
| test_zone_charge_replenishment.gd | 1 | keep | `ReplenishZoneCharge` mechanism (cap, no-op above cap, missing zone ID). |
| test_zone_charges_and_visits.gd | 1 | keep | Broad exemplar-quality coverage of visit-triggering, expiry, placement blocking, and all three section-resolution modes. |
| test_zone_knowledge_scaling.gd | 1 | keep | Direct unit-level `Skills.ZoneMagnitude` formula and `Zone.CreateNew` snapshot — distinct from the integration-level assertions elsewhere. |
| test_zone_slipstream_resonance.gd | 3 | keep | Two distinct novel zone-trigger-time behaviors (pass-through, doubling). |

## Summary

| Verdict | File count | Notes |
|---|---|---|
| `keep` (unchanged) | 87 | Includes all Tier 1/2 exemplars and files with no shared-mechanism overlap. |
| `keep-trimmed` | 26 | Trait/graft files losing only their tautology/generic-rarity functions; a few UI/content files losing specific static-content or duplicate functions. |
| `fold-and-delete` | 4 | `test_emissary_skills.gd`, `test_jester_skills.gd`, `test_reliquary_ward.gd`, `test_target_debuff_count_damage.gd` — real assertions move to `test_skill_effects.gd` (or the Phase 2 sweeps), file then deleted. |
| `delete` (whole file) | 3 | `test_pilfer_trait.gd` (misfiled generic mechanism, no Pilfer-specific behavior), `test_symbiote_trait.gd` (pure cosmetic checks), `test_creature_placeholder_table.gd` (pure static-content checks). |

**134 files audited, 0 unclassified.** Total individual tautology/cosmetic test functions
marked for deletion across all `keep-trimmed`/`fold-and-delete`/`delete` verdicts: 44
(matches the plan's Phase-0 estimate) plus `test_expected_row_count`,
`test_creature_placeholder_table.gd`'s 4 functions, `test_symbiote_trait.gd`'s 3
functions, and `test_pilfer_trait.gd`'s 3 functions.

**Two open judgment calls for review before Phase 3 executes:**

1. `test_pilfer_trait.gd`'s two `RemoveBuff` tests test real `BattleResolver` behavior
   generically, just misfiled — recommend moving them into `test_buff_manipulation.gd`
   rather than deleting them outright, since `RemoveBuff` doesn't otherwise have direct
   unit coverage there today (worth a Phase 1 check before Phase 3 deletes this file).
2. `test_battle_over.gd`'s two UI-focus tests (`test_01_ready_calls_focus_button`,
   `test_02_visibility_changed_calls_focus_button`) are borderline — they test that a
   method is called, not game logic, but the Test Design Document currently excludes all
   of `Scripts/UI/` from unit testing and `battle_over.gd` is a documented exception.
   Confirm whether `Test_Design_Document.md`'s exception for this file extends to
   focus-wiring checks before trimming.
