class_name KitContributionManifest extends RefCounted

## What each of the game's 20 Roles can put on the table by burst time (Concept_Document.md
## 1.1.3-1.1.4): one entry per Role passive plus its 3 skills, derived by reading the code —
## not Concept_Document.md 3.1.3/3.2.4.2 — where the two disagree. Disagreements are recorded
## in the offending entry's precondition text rather than silently resolved, per section 1.1's
## precedence rule. Consumed by the burst-reachability scorer; this file has no other
## dependents yet.
##
## A Role passive is not the same thing as a champion preset: several presets can share one
## Role (its skills and trait), and a preset is not necessarily named after its Role — the
## Lancer Role is fielded by both `Centaur_Lancer.tres` and `Knight.tres`; the Scholar Role has
## no `Scholar.tres` preset at all, it is fielded by `Centaur_Archivist.tres`. Each entry below
## cites whichever preset actually carries the Role's skills and trait.
##
## Contribution fields:
##   name          - flavor name, for readable output only.
##   bucket_key    - the CombinedDamageModifier bucket this contribution lands in, exactly as
##                    the runtime forms it (a skill's own name, "<skill> (ramp)", a buff/debuff
##                    type name, or CombinedDamageModifier.TRAIT_RESOURCE_KEY). "" when the
##                    contribution never reaches a CombinedDamageModifier bucket at all —
##                    Channel 1 (it moves an attribute instead), or a pure Enabler.
##   magnitude     - the bucket's fractional contribution at Legendary rarity. For an uncapped,
##                    per-instance contribution (Heap On's ramp, Devour Blessing's per-buff
##                    bonus) this is the per-instance rate, not a ceiling — see precondition.
##   stack_cap     - hard ceiling on repeated stacking of this specific mechanic (0 = no
##                    stacking of its own; the shared 8-status cap in GameBalance still applies
##                    to anything that is itself a status effect).
##   class         - Contribution_Class tag(s), per Concept_Document.md 1.1.3 and the tags
##                    already carried by 3.1.3/3.2.3.2/3.2.4.2 (kept where the code agrees).
##   precondition  - what must be true for the contribution to land, and any known code trap.
##   citation      - file:line for the mechanic.
##   granted_status - optional. Present only on an Enabler entry that grants a teammate a
##                    modifier-bearing status (Tactician's Fatal Flaw, Thief's Weigh the Mark,
##                    Scholar's Expose Fallacy): the magnitude the granted status itself
##                    contributes once it lands on whichever character consumes it, resolved
##                    by burst_reachability.gd's own target-scope predicate rather than fixed
##                    here. Shape: {bucket_key, magnitude, per_debuff_anchored, citation} — see
##                    burst_reachability.gd's _ContributeGrantedStatuses for how each field is
##                    read.
##   gated_bonus   - optional. Present on a skill or passive entry whose contribution is
##                    conditioned on some precondition being met (a reagent consumed — Plan_
##                    Itemization_Channels.md Phase 3's Sorcerer repeat, Phase 4's Alchemist
##                    team factor; a debuff present — Plague Doctor's Comorbidity retick; a
##                    zone charge consumed — Unstable Rift's remaining triggers) — the
##                    manifest's "assumed satisfied" precondition axis (Role_Kit_Design.md
##                    section 11). There is no battle simulation here to know whether the
##                    precondition was actually met, so it is modeled as always satisfied
##                    rather than scored as zero, and surfaced on the result
##                    (BurstReachability.CandidateResult.assumed_gates) instead of being
##                    silently baked in. Shape: {bucket_key, magnitude, class, fold, reach, gate,
##                    instances, instance_compounding, precondition, citation}.
##                    `fold` distinguishes three shapes, because not every gated mechanic lands
##                    in the SAME CombinedDamageModifier the candidate's own cast assembles:
##                      - "same_instance" (default, omit the field): the bonus lands in the same
##                        modifier as the candidate's own cast, so it is Contribute()'d straight
##                        into the scored `buckets`/`product` — the Alchemist's Volatile Mixture
##                        buff, consumed like any other granted DamageMultiplier factor.
##                      - "separate_instance": the bonus is its own, independent
##                        CombinedDamageModifier and damage resolution within the SAME action
##                        (the Sorcerer's repeat) — folding it into the candidate's own
##                        `product` would make that field diverge from what
##                        Tests/unit/test_burst_reachability_live.gd's replay of the real
##                        resolver actually assembles for the ORIGINAL cast, so it is scored
##                        separately into CandidateResult.repeat_contrast_ratio instead.
##                      - "sustained_ticks": damage spread across several of the boss's own
##                        future turns rather than the one action being scored (Comorbidity's
##                        extra debuff tick, Unstable Rift's un-triggered zone charges) —
##                        scored into CandidateResult.sustained_contrast_ratio, never folded into
##                        the single-action total_contrast_ratio, but counted in
##                        combined_contrast_ratio — the field TeamResult.Best() and TeamSweep
##                        actually rank by, so a sustained payload competes with a direct-damage
##                        combo rather than being invisible to that ranking.
##                    `reach` ("team" reaches every candidate on the roster the way
##                    Ally_Reagent_Consumed's own broadcast does; absent/anything else means
##                    "only this entry's own skill/caster") only applies to same_instance
##                    entries. `gate` (StringName) names the precondition axis itself —
##                    &"reagent_consumed", &"debuff_count", &"zone_charges_consumed", etc. —
##                    surfaced verbatim on CandidateResult.assumed_gates. `instances` (int,
##                    default 1) and `instance_compounding` (float, default 1.0, flat) apply
##                    only to "separate_instance"/"sustained_ticks": each of the declared
##                    instances contributes (1.0 + magnitude) * instance_compounding^i, i
##                    0-based. See burst_reachability.gd's _ContributeGatedSkillBonus,
##                    _ContributeGatedTeamBonuses, and _MultiInstanceContrastRatio.
##   granted_attribute_buff - optional. A Channel1 entry's fixed one-shot buff (Empower, Attune,
##                    Rush, Fortify, Exhert — not a self-accumulated stack), read by
##                    burst_reachability.gd's _ContributeGrantedAttributeBuffs. Shape:
##                    {attributes, magnitude, kind, reach, gate}, plus reach: "team" on a passive
##                    entry (no skill target to derive reach from — see Tactician's Plan ahead).
##                    `kind` distinguishes how `magnitude` combines with the attribute's base
##                    value, mirroring the runtime's own StatusEffectData.magnitude_kind shapes:
##                      - "percentage" (default, omit the field): a multiplicative fraction of
##                        the base value — Empower, Rush, Exhert.
##                      - "percentage_point": a flat point add, independent of the base value —
##                        every crit status (Keen Edge, Lethal Precision, Exposed Facet, Cracked
##                        Facet all use MagnitudeKind.AttributePercentagePointAdd /
##                        AttackerCritChanceBonus / AttackerCritDamageBonus at runtime, never a
##                        fraction of CritChance/CritDamage's own base value).
##                    `gate` (StringName, optional) names a precondition this grant depends on
##                    beyond "was the granting skill/passive triggered" — Strike the Flaw's
##                    Cracked Facet only exists after a crit has already landed — surfaced on
##                    CandidateResult.assumed_gates the same way a skill's own gated_bonus is.
##                    A field may hold a single dict or an Array of dicts, for a grant that
##                    applies two different magnitudes to two different attributes in one grant
##                    (Full Appraisal's Keen Edge +15 CritChance and Lethal Precision +50
##                    CritDamage are not the same magnitude, so they cannot share one dict).

enum Contribution_Class
{
	Channel1,
	Channel2,
	Channel3_Cascade,
	Enabler,
}

## Rush.tres / Exhert.tres both grant every primary attribute but Health.
const ALL_ATTRIBUTES_EXCEPT_HEALTH: Array[Types.Attribute] = [
	Types.Attribute.Speed, Types.Attribute.Attack, Types.Attribute.Defence,
	Types.Attribute.Accuracy, Types.Attribute.Resistance, Types.Attribute.Mysticism,
	Types.Attribute.Knowledge, Types.Attribute.CritChance, Types.Attribute.CritDamage,
]

const MANIFEST: Dictionary = {
	Types.Role.Emissary: {
		"preset": "Data/Character_Player_Variants/Emissary.tres",
		"passive": [
			{"name": "Standing Record", "bucket_key": "", "magnitude": 0.0, "stack_cap": 9,
					"class": Contribution_Class.Enabler,
					"precondition": "Counter engine, not a damage source itself: an enemy gains 1 " +
							"Infraction (cap 9) whenever it gains a buff, places a zone, or lands a debuff " +
							"on an Emissary ally. Rate 0.04/Infraction at Legendary, read by Citation and " +
							"Levied Sanction.",
					"citation": "standing_record_trait.gd:3-10,42-53"},
		],
		"skills": [
			{"name": "Citation", "bucket_key": "Citation", "magnitude": 0.36, "stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "+0.04 per target Infraction (0-9, linear); magnitude shown is the " +
							"ceiling at 9 Infractions.",
					"citation": "Citation.tres:6-12; damage_effect.gd:47,52-58; standing_record_trait.gd:65-66"},
			{"name": "Signed Writ", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Reduces target buff durations by 1 turn (2 if raw Infractions >= 6) " +
							"and applies Signed Writ (1-2 turns, unresistable). No damage.",
					"citation": "Signed_Writ.tres:6-42; standing_record_trait.gd:67-68"},
			{"name": "Levied Sanction", "bucket_key": "", "magnitude": 0.36, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Applies Sanction (2 turns): reduces every primary attribute but " +
							"Health by target Infractions * 0.04 (Legendary, ceiling 0.36), set at " +
							"application via GetAppliedStatusValue. A raw attribute reduction, not a " +
							"CombinedDamageModifier bucket.",
					"citation": "Levied_Sanction.tres:6-11; standing_record_trait.gd:73-77"},
		],
	},
	Types.Role.Thief: {
		"preset": "Data/Character_Player_Variants/Thief.tres",
		"passive": [
			{"name": "Pilfer", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "50% chance (Legendary) on any Skill_Cast to steal a buff from the " +
							"primary target. No damage.",
					"citation": "pilfer_trait.gd:3-8,24-45"},
		],
		"skills": [
			{"name": "Stab", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Basic skill: damage_scaling Attack 0.7, no bonus_per — pure " +
							"scaled-attribute damage.",
					"citation": "Stab.tres:6-10"},
			{"name": "Pierce Weakness", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Attack 1.1, defense_ignore_factor 0.7. The ignore " +
							"factor scales effective Defence directly, not a CombinedDamageModifier " +
							"bucket, and per 1.1.4 stops mattering at burst scale.",
					"citation": "Pierce_Weakness.tres:6-11"},
			{"name": "Weigh the Mark", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Grants self (target Self) Opportunist for 3 turns. " +
							"Concept_Document.md 3.2.4.2 documents this skill as 'Case the Target' at 2 " +
							"turns; the shipped resource is Weigh_the_Mark.tres at 3 turns — a known " +
							"doc/code conflict, not rewritten here. Opportunist itself contributes +0.1 " +
							"per distinct debuff type on whatever target Thief later attacks, keyed to " +
							"that debuff's own name — the magnitude now lives in granted_status on this " +
							"same entry, gated to the granter (Self-scoped) rather than any teammate.",
					"citation": "Weigh_the_Mark.tres:6-11; Opportunist.tres; status_effect_resolver.gd:616-636",
					"granted_status": {"bucket_key": "", "magnitude": 0.1, "per_debuff_anchored": true,
							"citation": "Data/Status_Effects/Opportunist.tres:8-9 (magnitude_kind " +
									"PerTargetDebuffDamagePercent); status_effect_resolver.gd:616-636"}},
		],
	},
	Types.Role.Lancer: {
		"preset": "Data/Character_Player_Variants/Centaur_Lancer.tres (also Knight.tres — both " +
				"share Lancer_Trait.tres and the same 3 skills)",
		"passive": [
			{"name": "Reckless Momentum", "bucket_key": "", "magnitude": 0.0, "stack_cap": 5,
					"class": Contribution_Class.Channel1,
					"precondition": "TRAP: OFFENSIVE_SKILL_NAMES = {'Stab', 'Disarm'} — 'Stab' is a " +
							"Thief skill, not Lancer's own 'Lance Thrust', so only Disarm actually " +
							"grants Momentum among Lancer's 3 skills. defensive_skill_names is a var " +
							"initialized empty and never populated by any preset, so Phalanx Guard is " +
							"unreachable — stacks accrue (max 5, +10% Attack/stack at Legendary via " +
							"OnSkillCast) but are never spent. -5% Defence/stack applied via OnDefend.",
					"citation": "lancer_trait.gd:3-27,54-88 — code, not Concept_Document.md 3.1.3, " +
							"which assumes Lance Thrust grants Momentum and Phalanx Guard is reachable"},
		],
		"skills": [
			{"name": "Lance Thrust", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Attack 0.9, no bonus_per. Despite being Lancer's " +
							"actual offensive basic skill, does NOT grant Momentum (name mismatch above).",
					"citation": "Lance_Thrust.tres:6-11; lancer_trait.gd:20-23"},
			{"name": "Disarm", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Attack 0.8, no bonus_per, plus Enfeeble (2 turns). " +
							"The one skill whose literal name matches OFFENSIVE_SKILL_NAMES, so this is " +
							"Lancer's actual Momentum trigger.",
					"citation": "Disarm.tres:6-19; lancer_trait.gd:21"},
			{"name": "Rending Charge", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Attack 1.3, no bonus_per, plus Bleed (2 turns). " +
							"Does not match OFFENSIVE_SKILL_NAMES despite being Lancer's heaviest " +
							"offensive skill — grants no Momentum.",
					"citation": "Rending_Charge.tres:6-19; lancer_trait.gd:20-23"},
		],
	},
	Types.Role.Alchemist: {
		"preset": "Data/Character_Player_Variants/Alchemist.tres",
		"passive": [
			{"name": "Fresh Batch", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Brews one random reagent at combat start; +20% brew potency at " +
							"Legendary. Whenever any ally (the Alchemist included) consumes a reagent, the " +
							"whole team gains a Volatile Mixture damage-multiplier buff — see " +
							"gated_bonus below, Plan_Itemization_Channels.md Phase 4.",
					"citation": "fresh_batch_trait.gd:3-33,41,58-62",
					"gated_bonus": {"bucket_key": "Volatile_Mixture", "magnitude": 0.29,
							"class": Contribution_Class.Channel2, "reach": "team", "gate": &"reagent_consumed",
							"precondition": "TEAM_DAMAGE_BONUS at Legendary (0.29); lands under the " +
									"Volatile_Mixture buff-type key on every teammate, the Alchemist's own " +
									"casts included, consumed on the holder's next attack via " +
									"ConsumeDamageMultiplierFactors. Distinct from Fractured Idol's shared " +
									"'reagent_damage_bonus' key by hard requirement, so the two multiply " +
									"rather than add. Costs one slot against the shared 8-status cap " +
									"(GameBalance.MAX_STATUS_EFFECTS) like any other granted buff.",
							"citation": "fresh_batch_trait.gd:10-15,41-47,58-62; " +
									"status_effect_resolver.gd:163-174"}},
		],
		"skills": [
			{"name": "Acrid Splash", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Knowledge 0.7, no bonus_per.",
					"citation": "Acrid_Splash.tres:6-11"},
			{"name": "Catalyst Cloud", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Zone, 4 charges; grants Catalyst (2 turns) to affected allies — " +
							"amplifies the next reagent each holder consumes by +50% potency, consumed " +
							"as a `potency` add-on in ResolveReagentEffect, not a CombinedDamageModifier " +
							"bucket.",
					"citation": "Catalyst_Cloud.tres:6-21; status_effect_resolver.gd:177-184"},
			{"name": "Dissolving Agent", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Applies Unravel (2 turns, -30% Resistance). No damage of its own.",
					"citation": "Dissolving_Agent.tres:6-11"},
		],
	},
	Types.Role.Sorcerer: {
		"preset": "Data/Character_Player_Variants/Sorcerer.tres",
		"passive": [
			{"name": "Arcane Instability", "bucket_key": "", "magnitude": 0.0, "stack_cap": 5,
					"class": Contribution_Class.Channel1,
					"precondition": "TRAP: on every Skill_Cast gains 1 stack (max 5, +10% " +
							"Mysticism/stack at Legendary, a Channel-1 attribute mutation applied before " +
							"the cast's own DamageEffect reads it). At 5 stacks the NEXT cast instead " +
							"fires a Surge via ResolveTraitDamage(..., CombinedDamageModifier.new()) — " +
							"an empty modifier, so the Surge hit contributes to NO CombinedDamageModifier " +
							"bucket at all (no reagent bonus, no Opportunist, no trait_resource), even " +
							"though the boosted Mysticism from the same OnSkillCast call still applies to " +
							"its raw magnitude (1.5x Mysticism, hits all characters, no crit). Stacks " +
							"reset to 0 after the Surge.",
					"citation": "sorcerer_trait.gd:3-20,51-84; battle_resolver.gd:390-404 " +
							"(ResolveTraitDamage's empty modifier)"},
		],
		"skills": [
			{"name": "Arc Lash", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Mysticism 1.0, no bonus_per.",
					"citation": "Arc_Lash.tres:6-11",
					"gated_bonus": {"bucket_key": "Arc Lash (repeat)", "magnitude": -0.5,
							"class": Contribution_Class.Channel3_Cascade, "fold": "separate_instance",
							"gate": &"reagent_consumed",
							"precondition": "Only if the Sorcerer consumed a reagent since their last cast " +
									"(Plan_Itemization_Channels.md Phase 3). The real resolver re-resolves " +
									"Arc Lash's DamageEffects as a SECOND, independent CombinedDamageModifier " +
									"and ResolveEffectDamage call at REPEAT_BONUS (-0.5, i.e. 50% damage) — " +
									"never folded into the original cast's own product (verified live in " +
									"test_burst_reachability_live.gd), so this entry is 'fold: " +
									"separate_instance' and is scored into CandidateResult.repeat_contrast_ratio " +
									"instead of the shared buckets/product. Magnitude mirrors REPEAT_BONUS " +
									"exactly, not REPEAT_FRACTION. Exactly one repeat per cast (the " +
									"consumed-reagent flag clears when it fires), so " +
									"ASSUMED_UNCAPPED_INSTANCES' cap of 1 already matches the real mechanic " +
									"here rather than only approximating it.",
							"citation": "sorcerer_trait.gd:22-25,95-119; skill_cast_context.gd:38; " +
									"damage_effect.gd:28-29,54-55; battle_resolver.gd:739-744"}},
			{"name": "Cataclysmic Surge", "bucket_key": "Warped", "magnitude": 0.3, "stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "+30% (fixed, not rarity-scaled) only against targets currently " +
							"carrying the Warped debuff, via bonus_per_debuff_on_target. Targets All " +
							"Enemies. A normal DamageEffect cast (not ResolveTraitDamage), so it does get " +
							"the full CombinedDamageModifier treatment.",
					"citation": "Cataclysmic_Surge.tres:6-17; damage_effect.gd:60-65",
					"gated_bonus": {"bucket_key": "Cataclysmic Surge (repeat)", "magnitude": -0.5,
							"class": Contribution_Class.Channel3_Cascade, "fold": "separate_instance",
							"gate": &"reagent_consumed",
							"precondition": "Same reagent-gated repeat as Arc Lash (see that entry), " +
									"re-resolving Cataclysmic Surge's own DamageEffect (its own Warped bonus " +
									"included, since the repeat replays the whole effect against the same " +
									"target) as its own separate instance at REPEAT_BONUS.",
							"citation": "sorcerer_trait.gd:22-25,95-119; skill_cast_context.gd:38; " +
									"damage_effect.gd:28-29,54-55; battle_resolver.gd:739-744"}},
			{"name": "Unstable Rift", "bucket_key": "Zone: Unstable Rift", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Zone, 5 charges. On trigger: applies Warped (2 turns) and deals " +
							"damage scaling Mysticism 0.3 (enemies) / 0.15 (allies) — both DamageEffects " +
							"share one zone-trigger bucket keyed to the zone's own name; neither has a " +
							"bonus_per, so the shared bucket contributes 0.0. The skill's own top-level " +
							"effects is a single ZoneEffect, no top-level DamageEffect — the scorer now " +
							"enumerates this skill as a candidate off the enemy-facing on_trigger " +
							"DamageEffect (0.3 Mysticism) directly, excluding the 0.15 ally-facing one (see " +
							"burst_reachability.gd's _ZoneTriggerEnemyDamageEffects). Still a structural " +
							"no-op for the Sorcerer's reagent-gated repeat, which only re-resolves " +
							"cast_skill.effects filtered to top-level DamageEffect — no gate: " +
							"&\"reagent_consumed\" gated_bonus modeled here for that reason, not an oversight.",
					"citation": "Unstable_Rift.tres:6-29,32-42; damage_effect.gd:43-46; zone_effect.gd:17-19; " +
							"sorcerer_trait.gd:101-119",
					"gated_bonus": {"bucket_key": "", "magnitude": 0.0, "class": Contribution_Class.Channel1,
							"fold": "sustained_ticks", "gate": &"zone_charges_consumed", "instances": 4,
							"precondition": "The candidate's own contrast_ratio already counts one trigger " +
									"(the enumeration above); the zone's 4 remaining charges (5 total) each " +
									"deal the same enemy-facing hit again on a future turn as the zone is " +
									"walked into — scored into sustained_contrast_ratio, not product, since it " +
									"spans several of the boss's own turns rather than the one action " +
									"total_contrast_ratio measures (still counted in combined_contrast_ratio, " +
									"the ranking key).",
							"citation": "Unstable_Rift.tres:6-29; zone_resolver.gd"}},
		],
	},
	Types.Role.Scholar: {
		"preset": "Data/Character_Player_Variants/Centaur_Archivist.tres — no Scholar.tres exists; " +
				"this is the only preset referencing Field_of_Study_Trait.tres",
		"passive": [
			{"name": "Field of Study", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "At Start_Combat, profiles each enemy's highest primary attribute. " +
							"On any debuff the Scholar applies to a profiled enemy, additionally reduces " +
							"that identified attribute by 0.10 (Legendary) for the debuff's duration — " +
							"rides on the debuff instance as a second Channel-1 reduction, not a " +
							"CombinedDamageModifier bucket.",
					"citation": "field_of_study_trait.gd:3-8,43-65"},
		],
		"skills": [
			{"name": "Sharp Rebuttal", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Knowledge 0.7, no bonus_per.",
					"citation": "Sharp_Rebuttal.tres:6-11"},
			{"name": "Expose Fallacy", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Grants All Allies (target All_Allies, reaches the granter too) " +
							"Opportunist (2 turns — see Thief's Weigh the Mark; the magnitude lives in " +
							"granted_status on this same entry) and applies Confound (2 turns, -30% " +
							"Knowledge) to one enemy. No direct damage.",
					"citation": "Expose_Fallacy.tres:6-19",
					"granted_status": {"bucket_key": "", "magnitude": 0.1, "per_debuff_anchored": true,
							"citation": "Data/Status_Effects/Opportunist.tres:8-9; " +
									"status_effect_resolver.gd:616-636"}},
			{"name": "Refutation", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "ClearZoneEffect — removes one zone from the turn bar. Its own " +
							"code path reads trait_result._damage_multiplier into the shared " +
							"trait_resource bucket, but Field of Study never sets _damage_multiplier " +
							"(no OnSkillCast override), so that bucket is always 0.0 here. No exported " +
							"damage parameters on this .tres.",
					"citation": "Refutation.tres:6-11; clear_zone_effect.gd"},
		],
	},
	Types.Role.Diviner: {
		"preset": "Data/Character_Player_Variants/Diviner.tres",
		"passive": [
			{"name": "Foresight", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "At Start_Turn, applies a fixed 1-turn Enfeeble (not rarity-scaled " +
							"by the trait) to any enemy within 25% turn-bar-behind range (Legendary " +
							"threshold) that is a valid Single_Enemy target.",
					"citation": "foresight_trait.gd:3-8,30-41"},
		],
		"skills": [
			{"name": "Fateful Glimpse", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Mysticism 0.6 (no bonus_per) plus a heal scaling " +
							"Mysticism 0.1 to the most injured ally. The heal is Channel 1, outside " +
							"CombinedDamageModifier.",
					"citation": "Fateful_Glimpse.tres:6-17"},
			{"name": "Premonition", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Grants one ally Premonition (1 turn): next attack against them " +
							"auto-misses, consumed via ConsumePremonitionIfPresent. No damage.",
					"citation": "Premonition.tres:6-11; battle_resolver.gd:725-726"},
			{"name": "Ill Omen", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Mysticism 1.2 (no bonus_per) plus Hexed (2 turns, " +
							"reroll-worse Enabler, no magnitude_kind).",
					"citation": "Ill_Omen.tres:6-19"},
		],
	},
	Types.Role.Appraiser: {
		"preset": "Data/Character_Player_Variants/Appraiser.tres",
		"passive": [
			{"name": "Strike the Flaw", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "On Critical_Hit, applies Cracked Facet (2 turns at Legendary) to " +
							"the target — grants attackers +25 CritDamage percentage points against it, " +
							"folded into crit math in _ResolveDamage, not a CombinedDamageModifier bucket. " +
							"Gated on a critical hit already having landed, so it is scored as though " +
							"satisfied like this file's other gated_bonus assumptions.",
					"citation": "strike_the_flaw_trait.gd:3-8,28-30; battle_resolver.gd:735",
					"granted_attribute_buff": {"attributes": [Types.Attribute.CritDamage], "kind": "percentage_point",
							"magnitude": 25.0, "reach": "team", "gate": &"prior_critical_hit"}},
		],
		"skills": [
			{"name": "Sizing Cut", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Knowledge 0.7, no bonus_per.",
					"citation": "Sizing_Cut.tres:6-11"},
			{"name": "Flaw Analysis", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Applies Exposed Facet (2 turns): +15 CritChance percentage points " +
							"to attackers of the target, consumed in _AttackerCritChanceBonus. No damage " +
							"of its own. Sits on the target and buffs every attacker of it, not an " +
							"ally-target grant, so it is modeled with team reach.",
					"citation": "Flaw_Analysis.tres:6-11; status_effect_resolver.gd:598-604",
					"granted_attribute_buff": {"attributes": [Types.Attribute.CritChance], "kind": "percentage_point",
							"magnitude": 15.0, "reach": "team"}},
			{"name": "Full Appraisal", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Grants one ally Keen Edge (+15 CritChance, 2 turns) and Lethal " +
							"Precision (+50 CritDamage, 2 turns) — both flat attribute-percentage-point " +
							"adds, no CombinedDamageModifier bucket.",
					"citation": "Full_Appraisal.tres:6-16",
					"granted_attribute_buff": [
						{"attributes": [Types.Attribute.CritChance], "kind": "percentage_point", "magnitude": 15.0},
						{"attributes": [Types.Attribute.CritDamage], "kind": "percentage_point", "magnitude": 50.0},
					]},
		],
	},
	Types.Role.Tactician: {
		"preset": "Data/Character_Player_Variants/Tactician.tres",
		"passive": [
			{"name": "Plan ahead", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "At Start_Turn, casts a fixed non-stackable 1-turn Empower (+30% " +
							"Attack, not rarity-scaled by the trait) on allies within 25% " +
							"turn-bar-behind range (Legendary threshold).",
					"citation": "plan_trait.gd:3-8,35-48",
					"granted_attribute_buff": {"attributes": [Types.Attribute.Attack], "magnitude": 0.3, "reach": "team"}},
		],
		"skills": [
			{"name": "Signal Strike", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Knowledge 0.7, no bonus_per.",
					"citation": "Signal_Strike.tres:6-11"},
			{"name": "Fatal Flaw", "bucket_key": "", "magnitude": 1.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Grants All_Other_Allies (target 12 — every ally but the caster, " +
							"not 'one ally') Daunting Strength (1 turn): doubles their next attack. " +
							"Consumed via ConsumeDamageMultiplierFactors into a bucket keyed " +
							"'Daunting_Strength' at value (2.0-1.0)=1.0 on whichever attack consumes it " +
							"— the magnitude now lives in granted_status on this same entry.",
					"citation": "Fatal_Flaw.tres:6-11; status_effect_resolver.gd:163-174",
					"granted_status": {"bucket_key": "Daunting_Strength", "magnitude": 1.0,
							"per_debuff_anchored": false,
							"citation": "Data/Status_Effects/Daunting_Strength.tres:8-9 (magnitude_kind " +
									"DamageMultiplier, magnitude 2.0 -> +1.0); " +
									"status_effect_resolver.gd:163-174"}},
			{"name": "Battle Orders", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Grants one ally the Battle Orders turn-bar buff (2 turns): +5% " +
							"ally turn bar whenever the holder takes damage. A turn-bar mechanic, not a " +
							"CombinedDamageModifier bucket.",
					"citation": "Battle_Orders.tres:6-11"},
		],
	},
	Types.Role.Symbiote: {
		"preset": "Data/Character_Player_Variants/Symbiote.tres",
		"passive": [
			{"name": "Graft", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Base SymbioteTrait is a placeholder with no execution steps and " +
							"no numeric mechanic — grafting overwrites _trait entirely with one of 17 " +
							"Graft resources (Data/Character_Traits/Grafts/*.tres), chosen at the " +
							"meta/collection layer. No single Legendary magnitude exists for 'the " +
							"Symbiote passive'; enumerating all 17 Grafts is out of Phase 1 scope — each " +
							"would need its own manifest treatment if fielded in the team corpus.",
					"citation": "symbiote_trait.gd:1-13; character.gd:121"},
		],
		"skills": [
			{"name": "Spore Lash", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Resistance 0.8, no bonus_per.",
					"citation": "Spore_Lash.tres:6-11"},
			{"name": "Symbiotic Overdrive", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Grants self Exhert (4 turns): +20% all primary attributes except " +
							"Health, 5% max-Health self-tick cost. A flat attribute add, no " +
							"CombinedDamageModifier bucket.",
					"citation": "Symbiotic_Overdrive.tres:6-11",
					"granted_attribute_buff": {"attributes": ALL_ATTRIBUTES_EXCEPT_HEALTH, "magnitude": 0.2}},
			{"name": "Grafted Flesh", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Self-costs 10% max Health; grants one ally Regeneration (4 turns, " +
							"4% max-Health heal/turn). No damage.",
					"citation": "Grafted_Flesh.tres:6-16"},
		],
	},
	Types.Role.Jester: {
		"preset": "Data/Character_Player_Variants/Jester.tres",
		"passive": [
			{"name": "Double the fun!", "bucket_key": "", "magnitude": 0.0, "stack_cap": 3,
					"class": Contribution_Class.Enabler,
					"precondition": "5% base dodge + 6%/stack (Legendary, cap 3 stacks) = up to 23%. " +
							"On a hit landing successfully avoided, returns damage multiplier 0.0 (full " +
							"avoid) via OnDamageTaken, independent of CombinedDamageModifier; on a hit " +
							"that lands, increments stacks instead. Exposes " +
							"GetConditionCount(Trait_Condition)=1.0 if avoided since last turn, read by " +
							"Pratfall Sting.",
					"citation": "double_the_fun_trait.gd:3-13,60-73"},
		],
		"skills": [
			{"name": "Pratfall Sting", "bucket_key": "Pratfall Sting", "magnitude": 0.3, "stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "+30% (fixed, not rarity-scaled) if the Jester avoided an attack " +
							"(via its own passive) since its last turn; 0 otherwise.",
					"citation": "Pratfall_Sting.tres:6-13; double_the_fun_trait.gd:43-50"},
			{"name": "Center Stage", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Grants self Spotlight (2 turns: -10% incoming damage, 1.5x " +
							"targeting weight) and Luck (1 turn: reroll-better). Neither is a " +
							"CombinedDamageModifier bucket — Spotlight applies to final incoming damage " +
							"by design (1.1.4).",
					"citation": "Center_Stage.tres:6-16"},
			{"name": "Burning Bolas", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Attack 0.8 (no bonus_per) plus Burning (2 turns, " +
							"stackable DoT, 4%-max-Health tick). Skill's own name field is 'Burning " +
							"bolas' (lowercase b).",
					"citation": "Burning_Bolas.tres:6-19"},
		],
	},
	Types.Role.Cultist: {
		"preset": "Data/Character_Player_Variants/Cultist.tres",
		"passive": [
			{"name": "Chosen Vessel", "bucket_key": CombinedDamageModifier.TRAIT_RESOURCE_KEY,
					"magnitude": 0.3, "stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "TRAP (shared bucket): on any non-basic (cooldown > 0) Skill_Cast " +
							"with a living Vessel, drains 5% of the Vessel's max Health and sets " +
							"_damage_multiplier=1.30 (Legendary) — lands in the SHARED trait_resource " +
							"key, the same bucket used by Calibration's Final Calculation and Tidal " +
							"Corsair's Corsairs Reckoning; only actually collides if two such traits' " +
							"casts ever fed one CombinedDamageModifier instance, which the current " +
							"per-caster/per-cast architecture does not allow. If the Vessel dies, " +
							"Cultist gains Attune (3 turns, +30% Mysticism, Channel 1) and a new Vessel " +
							"is marked.",
					"citation": "chosen_vessel_trait.gd:3-11,49-77; damage_effect.gd:25-27"},
		],
		"skills": [
			{"name": "Profane Bolt", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Mysticism 0.9, no bonus_per. Basic skill (no " +
							"cooldown) — does not trigger Chosen Vessel.",
					"citation": "Profane_Bolt.tres:6-11"},
			{"name": "Devour Blessing", "bucket_key": "Devour Blessing", "magnitude": 0.25, "stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "Consumes the ally holding the most buffs, then damage_scaling " +
							"Mysticism 1.3 with bonus_per Buffs_Consumed=0.25 (fixed, not rarity-scaled) " +
							"per buff consumed — magnitude shown is per-instance, uncapped by this skill. " +
							"Non-basic (cooldown 3) — also triggers Chosen Vessel's shared trait_resource " +
							"bucket (+30% Legendary) on the same cast.",
					"citation": "Devour_Blessing.tres:6-20; damage_effect.gd:52-58"},
			{"name": "Rite of Severance", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Mysticism 1.2 (no bonus_per) plus Severance (2 " +
							"turns, blocks new buffs). Non-basic (cooldown 4) — also triggers Chosen " +
							"Vessel's shared trait_resource bucket (+30% Legendary) on the same cast.",
					"citation": "Rite_of_Severance.tres:6-19"},
		],
	},
	Types.Role.Bar_Brawler: {
		"preset": "Data/Character_Player_Variants/Bar_Brawler.tres",
		"passive": [
			{"name": "On the House!", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "On gaining any buff, heals all living allies 9% max Health " +
							"(Legendary) — at most once between the Bar Brawler's own turns. No " +
							"CombinedDamageModifier bucket.",
					"citation": "on_the_house_trait.gd:3-8,33-39"},
		],
		"skills": [
			{"name": "Heap On", "bucket_key": "Heap On (ramp)", "magnitude": 0.2, "stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "The one Uses_This_Battle (ramp) source among all 20 Roles' " +
							"skills: ramp_multiplier = 1 + 0.2 * use_count (fixed, not rarity-scaled), " +
							"use_count 0-indexed. Magnitude shown is the per-use rate, not a ceiling — no " +
							"coded stack cap; grows unbounded with repeated casts across the battle.",
					"citation": "Heap_On.tres:6-13; damage_effect.gd:33-37,49-50; battle_resolver.gd:672-676"},
			{"name": "Headbutt", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Health 0.9 (no bonus_per) plus Dead Weight (2 " +
							"turns: -3% turn bar on taking damage).",
					"citation": "Headbutt.tres:6-19"},
			{"name": "Liquid Courage", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Grants self Vigor (2 turns, +30% max Health) and heals self 15% " +
							"max Health.",
					"citation": "Liquid_Courage.tres:6-16"},
		],
	},
	Types.Role.Bloodmage: {
		"preset": "Data/Character_Player_Variants/Bloodmage.tres",
		"passive": [
			{"name": "Hemoclarity", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "On any Skill_Cast while current/max Health < 50%, adds +40% " +
							"(Legendary) to Mysticism before that cast's own DamageEffect reads it.",
					"citation": "hemoclarity_trait.gd:3-10,26-44"},
		],
		"skills": [
			{"name": "Blood Bolt", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Self-costs 3% max Health; damage_scaling Mysticism 1.0, no " +
							"bonus_per.",
					"citation": "Blood_Bolt.tres:6-17"},
			{"name": "Transfusion", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Self-costs 15% max Health; grants one ally a Barrier (2 turns) " +
							"absorbing 200% of the Health sacrificed. No damage.",
					"citation": "Transfusion.tres:6-17"},
			{"name": "Tithe of Vitality", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Costs living allies (excl. caster) 10% max Health each; " +
							"damage_scaling Mysticism 1.5 (no bonus_per) plus Mana Burn (2 turns: " +
							"bespoke damage-on-non-basic-cast punish, outside CombinedDamageModifier).",
					"citation": "Tithe_of_Vitality.tres:6-24"},
		],
	},
	Types.Role.Herald_Of_The_Loom: {
		"preset": "Data/Character_Player_Variants/Herald_of_the_loom.tres",
		"passive": [
			{"name": "Weft and Warp", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel3_Cascade,
					"precondition": "Always holds exactly one of three threads, freely switchable " +
							"during the Herald's own turn (persistent trait state, not a status effect). " +
							"Golden: +1 Tension (capped at 7) whenever a cascade instance resolves on an " +
							"enemy, via the generic Cascade_Instance_Resolved hook. Silver: this Herald's " +
							"own applied debuffs cannot be resisted and last 1 turn longer " +
							"(GetOutgoingDebuffDurationBonus/DebuffsCannotBeResisted). Black: the cascade " +
							"instance produced by the Herald's own action resolves one additional time, " +
							"via CascadeResolver.SubscribeInstanceModifier — new plumbing this kit added. " +
							"Cascade instances this Herald produces (i.e. Cut the Cloth's own repeats) " +
							"deal +20% damage (Legendary), scored on Cut the Cloth's own entry below.",
					"citation": "weft_and_warp_trait.gd; cascade_resolver.gd " +
							"(SubscribeInstanceModifier, Cascade_Instance_Resolved)"},
		],
		"skills": [
			{"name": "Thread Snap", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Mysticism 0.9, no bonus_per, plus Suppress (1 turn " +
							"— moved off the retired Thread Lash, halved from 2 turns).",
					"citation": "Thread_Snap.tres:6-19"},
			{"name": "Pull the Thread", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "damage_scaling Mysticism 0.9, no bonus_per; pushes the target " +
							"backward 15% on the turn bar (TurnBarEffect, this class's first .tres " +
							"consumer) and applies Temporal Leak (3 turns). Grants the Herald 2 Tension, " +
							"stance-independent (trait-side, not a skill-data field).",
					"citation": "Pull_the_Thread.tres:6-24; weft_and_warp_trait.gd (OnSkillCast)"},
			{"name": "Cut the Cloth", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel3_Cascade,
					"precondition": "damage_scaling Mysticism 0.9 (90% strength), no bonus_per, no " +
							"debuff. Resolves once for the base cast plus once per Tension held (Tension: " +
							"0 Uncommon/Rare start, 1 Epic/Legendary, max 7 flat every rarity), then " +
							"consumes all Tension — up to 8 total resolves at max Tension. Resolved as a " +
							"local loop inside the trait that never calls CascadeResolver.Post, so these " +
							"repeats cannot feed this Herald's own Golden Thread.",
					"citation": "Cut_the_Cloth.tres:6-16; weft_and_warp_trait.gd " +
							"(OnSkillCast, OnSkillEffectsResolved, _ResolveExtraCutTheClothInstances)",
					"gated_bonus": {"bucket_key": "", "magnitude": 0.08,
							"class": Contribution_Class.Channel3_Cascade, "fold": "separate_instance",
							"gate": &"tension_spent", "instances": 8,
							"precondition": "Net per-instance multiplier folding both dials into one: 90% " +
									"base strength times the passive's own +20% (Legendary) self-bonus on " +
									"every cascade instance this Herald produces, 0.9*1.20-1 = +0.08. At " +
									"Uncommon (5% self-bonus): 0.9*1.05-1 = -0.055. Flat across all 8 " +
									"instances (no instance_compounding) — reproduces Role_Kit_Design.md " +
									"section 9.2's own worked figures (8*1.08=8.64 -> ~47.5x at Legendary " +
									"against an illustrative 5.5 team product).",
							"citation": "weft_and_warp_trait.gd (SELF_BONUS_BY_RARITY, " +
									"_ResolveExtraCutTheClothInstances)"}},
		],
	},
	Types.Role.Chronophage: {
		"preset": "Data/Character_Player_Variants/Chronophage.tres",
		"passive": [
			{"name": "Time Tithe", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "On Enemy_Turn_Bar_Reduced by the Chronophage's own effects, " +
							"converts 55% (Legendary) of the stolen amount into its own turn-bar " +
							"progress. A turn-bar mechanic, no CombinedDamageModifier bucket.",
					"citation": "chronophage_trait.gd:3-8,23-28"},
		],
		"skills": [
			{"name": "Zap", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Speed 0.6, no bonus_per.",
					"citation": "Zap.tres:6-11"},
			{"name": "Temporal Sinkhole", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Zone, 4 charges; drains enemy turn bar 15%/trigger — the input " +
							"Time Tithe converts. No damage.",
					"citation": "Temporal_Sinkhole.tres:6-18"},
			{"name": "Flicker Zone", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Zone, 5 charges; bumps allies 15% turn bar/trigger. No damage.",
					"citation": "Flicker_Zone.tres:6-18"},
		],
	},
	Types.Role.Architect: {
		"preset": "Data/Character_Player_Variants/Architect.tres",
		"passive": [
			{"name": "Calibration", "bucket_key": CombinedDamageModifier.TRAIT_RESOURCE_KEY,
					"magnitude": 0.84, "stack_cap": 12,
					"class": Contribution_Class.Channel2,
					"precondition": "TRAP (doc disagreement): real code constants are MAX_CHARGES=12, " +
							"EXPOSE_WEAKNESS_THRESHOLD=5, ZONE_RE_ERECT_THRESHOLD=9 " +
							"(Concept_Document.md 3.1.3 claims tiers 1-3/4-6/7-10, cap 10). +1 charge " +
							"per Cornerstone cast or Zone_Used event, capped at 12. Final Calculation " +
							"consumes all charges into the shared trait_resource bucket at 0.07/charge " +
							"(Legendary), up to +84% at 12 charges; >=5 charges also applies Expose " +
							"Weakness (2 turns); >=9 charges re-erects/upgrades the Raise the Frame zone " +
							"for free. Raise the Frame separately banks min(charges,3) into " +
							"GetZoneChargeBonus (up to +21% Legendary), read by the zone's own Barrier " +
							"sizing outside CombinedDamageModifier.",
					"citation": "calibration_trait.gd:3-16,55-110 — code, not Concept_Document.md 3.1.3"},
		],
		"skills": [
			{"name": "Cornerstone", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Knowledge 0.7, no bonus_per. Also grants +1 " +
							"Calibration charge.",
					"citation": "Cornerstone.tres:6-11; calibration_trait.gd:63-64"},
			{"name": "Raise the Frame", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Zone, 5 charges; grants Barrier sized by Knowledge and " +
							"GetZoneChargeBonus (up to +21% Legendary from up to 3 invested Calibration " +
							"charges). No damage.",
					"citation": "Raise_the_Frame.tres:6-19; calibration_trait.gd:65-66,91-92"},
			{"name": "Final Calculation", "bucket_key": "Final Calculation", "magnitude": 0.0,
					"stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "damage_scaling Knowledge 1.3 (no bonus_per, own bucket " +
							"contributes 0.0), plus the shared trait_resource bucket from Calibration " +
							"(see passive, up to +84% Legendary) — consumes ALL held charges (0-12).",
					"citation": "Final_Calculation.tres:6-11; calibration_trait.gd:67-75"},
		],
	},
	Types.Role.Tidal_Corsair: {
		"preset": "Data/Character_Player_Variants/Tidal_Corsair.tres",
		"passive": [
			{"name": "Wrangle the Sea", "bucket_key": CombinedDamageModifier.TRAIT_RESOURCE_KEY,
					"magnitude": 1.8, "stack_cap": 3,
					"class": Contribution_Class.Channel2,
					"precondition": "No trap found: all three skill-name string matches ('Boarding " +
							"Strike', 'Saltwater Shot', 'Corsairs Reckoning', no apostrophe throughout) " +
							"are consistent between tidal_corsair_trait.gd and the shipped .tres name " +
							"fields — the design doc's claimed apostrophe bug does not reproduce. 3 " +
							"stack slots, filled left-to-right on the matching cast; Corsairs Reckoning " +
							"consumes all 3: each Steel stack adds 0.60 (Legendary) to the shared " +
							"trait_resource bucket (up to +180% at 3 Steel), each Sea stack instead " +
							"reduces target turn bar by 0.14 (Legendary, up to -0.42 at 3 Sea) via a " +
							"separate _turn_bar_bump field outside CombinedDamageModifier. Slots reset " +
							"to Empty after Reckoning.",
					"citation": "tidal_corsair_trait.gd:1-24,79-105"},
		],
		"skills": [
			{"name": "Boarding Strike", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Attack 1.0, no bonus_per. Fills a Steel stack slot.",
					"citation": "Boarding_Strike.tres:6-11"},
			{"name": "Saltwater Shot", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Attack 1.0, no bonus_per (bonus_per_debuff_on_target " +
							"explicitly null). Fills a Sea stack slot.",
					"citation": "Saltwater_Shot.tres:6-12"},
			{"name": "Corsairs Reckoning", "bucket_key": "Corsairs Reckoning", "magnitude": 0.0,
					"stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "damage_scaling Attack 1.3 (own bucket contributes 0.0), plus the " +
							"shared trait_resource bucket from consumed Steel stacks (see passive) and a " +
							"target turn-bar reduction from consumed Sea stacks, outside " +
							"CombinedDamageModifier.",
					"citation": "Corsairs_Reckoning.tres:6-11"},
		],
	},
	Types.Role.Plague_Doctor: {
		"preset": "Data/Character_Player_Variants/Plague_Doctor.tres",
		"passive": [
			{"name": "Comorbidity", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel3_Cascade,
					"precondition": "Flags every debuff this Role casts to trigger a cascading extra " +
							"tick (Types.Cascade_Trigger.Debuff_Ticked) once per other distinct debuff " +
							"type on the holder (any source, uncapped, bounded by the shared cascade " +
							"fan-out cap) whenever it ticks — Plague Doctor's Channel-3 claim " +
							"(Role_Kit_Design.md section 1's 'comparable channel contribution', not a " +
							"bucket key). Each repeat is a real cascade instance, not a multiplier on " +
							"one aggregated number. Scored on Outbreak's own entry below (the skill that " +
							"actually places the debuff the tick rides on), not here — see Outbreak's " +
							"gated_bonus.",
					"citation": "comorbidity_trait.gd; status_effect_resolver.gd " +
							"(_ComputeDebuffTickDamage, _PostComorbidityCascadeIfAny, " +
							"_CascadeComorbidityRetick, ForceExtraDebuffTick)"},
		],
		"skills": [
			{"name": "Septic Lance", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Mysticism 0.9, no bonus_per; no debuff applied, so " +
							"Comorbidity's tick flag is set on this cast but never consumed.",
					"citation": "Septic_Lance.tres:6-11"},
			{"name": "Outbreak", "bucket_key": "Outbreak", "magnitude": 0.08, "stack_cap": 0,
					"class": Contribution_Class.Channel2,
					"precondition": "damage_scaling Mysticism 1.2, bonus_per Target_Debuff_Count 0.08 " +
							"per distinct debuff on the target (any source, uncapped — an uncapped " +
							"per-instance rate, not a ceiling, per this manifest's own convention), plus " +
							"a fresh stack of Plague (3 turns, self-ticking DoT scaling Mysticism 0.3, " +
							"snapshotted at application, now stackable). Comorbidity's tick flag threads " +
							"onto the new Plague stack correctly here.",
					"citation": "Outbreak.tres:6-24",
					"gated_bonus": {"bucket_key": "", "magnitude": -0.75,
							"class": Contribution_Class.Channel3_Cascade, "fold": "sustained_ticks",
							"gate": &"debuff_count", "instances": 3,
							"precondition": "Comorbidity's own retick (see the passive entry above), " +
									"approximated relative to Outbreak's own cast: each of Plague's 3 turns " +
									"retriggers once at the minimum reachable distinct-debuff-type count (1 — " +
									"Plague itself), each retick dealing Plague's own DoT magnitude " +
									"(Mysticism 0.3) rather than Outbreak's cast magnitude (Mysticism 1.2), " +
									"i.e. 0.3/1.2 = 25% per instance (magnitude -0.75). A different damage " +
									"instance from Outbreak's own cast, approximated against the same " +
									"skill_aggregate baseline for lack of a separate DoT-scaling model in this " +
									"scorer — see sustained_contrast_ratio.",
							"citation": "comorbidity_trait.gd; status_effect_resolver.gd " +
									"(_ComputeDebuffTickDamage); Plague.tres"}},
			{"name": "Miasma", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "Zone, 4 charges; on trigger forces every active debuff on the " +
							"caught enemy to tick again immediately without losing duration (via " +
							"ForceExtraDebuffTick — sustained pressure layered on top of whatever " +
							"Comorbidity's own retick already scores on Outbreak, not modeled again " +
							"separately here since Miasma carries no DamageEffect of its own, top-level " +
							"or zone-trigger, to attach a gated_bonus to), and applies Blight (2 turns: " +
							"-50% healing received).",
					"citation": "Miasma.tres:9-22"},
		],
	},
	Types.Role.Warlord: {
		"preset": "Data/Character_Player_Variants/Warlord.tres",
		"passive": [
			{"name": "Shield Wall", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Enabler,
					"precondition": "On Ally_Damage_Taken within 15% turn-bar proximity (fixed, not " +
							"rarity-scaled), redirects 30% (Legendary) of that ally's incoming attack " +
							"damage to the Warlord, re-mitigated against the Warlord's own Defence. No " +
							"CombinedDamageModifier bucket.",
					"citation": "shield_wall_trait.gd:3-10,20-21,34-42; battle_resolver.gd:750-763"},
		],
		"skills": [
			{"name": "Shield Slam", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "damage_scaling Defence 0.7, no bonus_per.",
					"citation": "Shield_Slam.tres:6-11"},
			{"name": "Hold the Line", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Grants All Allies Fortify (2 turns, +30% Defence). No damage.",
					"citation": "Hold_the_Line.tres:6-11",
					"granted_attribute_buff": {"attributes": [Types.Attribute.Defence], "magnitude": 0.3}},
			{"name": "Brace for Impact", "bucket_key": "", "magnitude": 0.0, "stack_cap": 0,
					"class": Contribution_Class.Channel1,
					"precondition": "Grants self Rush (1 turn: +30% all primary attributes except " +
							"Health, then an unresistable Stun on expiry) and Aegis (1 turn: blocks the " +
							"next debuff).",
					"citation": "Brace_for_Impact.tres:6-16",
					"granted_attribute_buff": {"attributes": ALL_ATTRIBUTES_EXCEPT_HEALTH, "magnitude": 0.3}},
		],
	},
}
