class_name BurstReachability extends RefCounted

## Given three CharacterPreset instances and nothing else, enumerates every damaging skill
## across the team as a candidate burst resolution, composes
## Scripts/Debug/kit_contribution_manifest.gd's reachable Channel-2/3 contributions at each,
## and returns them ranked by combined_contrast_ratio — every reachable channel counted, sustained
## payload included, so a DoT/zone-charge combo (Plague Doctor's Comorbidity, Unstable Rift's
## remaining charges) competes for Best() on equal footing with a pure single-action combo
## (Tidal Corsair plus Tactician). Which champion bursts and which skill they burst with are
## OUTPUTS: every damaging skill on the team is scored, never assumed in advance.
##
## Four contract quantities. The first two are read straight off the real
## CombinedDamageModifier and Skills.MitigatedDamage for ONE cast — no third mirror of either:
##   Combined modifier product  - CombinedDamageModifier.Product() at the candidate: exactly
##                                 what the real resolver assembles for the candidate's own
##                                 cast, and only that cast — verified live in
##                                 Tests/unit/test_burst_reachability_live.gd.
##   Burst contrast ratio       - final burst damage / final basic-skill damage, split into
##                                 a base term (raw damage_scaling aggregate ratio, no
##                                 mitigation) and a modifier term (what Product() alone
##                                 contributes once run through Skills.MitigatedDamage) so a
##                                 skill cannot pass 1.1.6's rejection test purely by having a
##                                 fatter Channel-1 base. This is the ONE-ACTION figure checked
##                                 against Concept_Document.md 1.1.2's 30-50x burst-band target —
##                                 it never includes sustained_contrast_ratio, so a multi-turn
##                                 payload cannot inflate the "one action" contract number.
## The third feeds into the fourth, which is what this file actually ranks and selects Best() by:
##   Total contrast ratio       - contrast_ratio plus repeat_contrast_ratio: the full
##                                 single-action burst a candidate reaches, a separate-instance
##                                 Channel-3 repeat included. Concept_Document.md 1.1.3 counts
##                                 repetition as part of what a burst is; ranking by contrast_ratio
##                                 alone would silently zero out every Channel-3 repeat mechanic's
##                                 contribution to which candidate is "best", since a repeat
##                                 cannot be folded into the single CombinedDamageModifier
##                                 product/contrast_ratio represent (see the stated simplifications
##                                 below) without breaking their own live-verified contract. This
##                                 file once ranked by contrast_ratio alone — a real bug,
##                                 not a design choice, caught and fixed once a
##                                 separate-instance mechanic (the Sorcerer's repeat) actually
##                                 existed to expose it. Still a one-action figure; still what
##                                 gets checked wherever a candidate's single-action burst matters
##                                 on its own.
##   Combined contrast ratio    - total_contrast_ratio plus sustained_contrast_ratio: what
##                                 TeamResult.Best() and TeamSweep actually rank by. Excluding
##                                 sustained payload from ranking made every DoT/zone-charge combo
##                                 structurally invisible next to a direct-damage combo when
##                                 comparing team compositions — the two are different shapes of
##                                 damage output, not different tiers of it, and a scorer meant to
##                                 answer "what combination reaches what damage output" has to
##                                 compare them on the same footing. total_contrast_ratio (and the
##                                 30-50x contract it's checked against) stays a pure single-action
##                                 figure regardless; combined_contrast_ratio is deliberately a
##                                 separate field so the two questions — "does this fit the burst
##                                 band" and "which team wins" — never collapse into one number.
##   Crit factor                - the caster's own EXPECTED critical-strike multiplier on the
##                                 candidate's scaled aggregate: 1 + (crit_chance / 100) *
##                                 (crit_damage_multiplier - 1), mirroring battle_resolver.gd's
##                                 own _ResolveDamage roll and multiplier formula
##                                 (Concept_Document.md 3.2.1 #4) as an expectation rather than a
##                                 per-roll ceiling — there is no battle here to roll a crit
##                                 against, and an always-crit ceiling would make crit CHANCE
##                                 sources (Flaw Analysis, Keen Edge, the Appraiser's own base 30)
##                                 contribute nothing to any score. Deliberately outside
##                                 CombinedDamageModifier, matching the real resolver: the crit
##                                 roll happens before Product() is applied and is passed to
##                                 Skills.MitigatedDamage as its own argument
##                                 (battle_resolver.gd:698-748), so every Appraiser manifest entry
##                                 keeps its empty bucket_key/magnitude — see
##                                 kit_contribution_manifest.gd's Appraiser block. Blended per
##                                 candidate by DamageEffect.allow_critical share
##                                 (_EffectiveCritFactor) into baseline_crit_factor (basic skill)
##                                 and burst_crit_factor (the burst skill) — a caster's crit
##                                 factor is symmetric between the two, so it mostly cancels out
##                                 of contrast_ratio by construction; it moves a score wherever
##                                 crit chance/damage/allow_critical genuinely differs between the
##                                 burst skill and the basic-skill baseline, exactly where crit
##                                 SHOULD matter. Boss Knowledge (which blunts crit damage) comes
##                                 from BlowoutCalibration.BOSSES[0]'s own 4th element.
##
## Six stated simplifications:
##   - Manifest sources documented as an uncapped per-instance rate (Heap On's ramp,
##     Devour Blessing's bonus_per, an Opportunist debuff-count) are scored at the minimum
##     reachable count: exactly one instance/precondition satisfied. There is no battle
##     simulation here to count real ones; a live-verification pass against the actual
##     resolver, where the true count is whatever the fight produces, is the way to check this.
##   - Caster attributes are each preset's own base values (Character._attributes right after
##     InstantiateNew), plus any manifest "granted_attribute_buff" reaching the caster
##     (_ContributeGrantedAttributeBuffs) — fixed one-shot grants (Empower, Attune, Rush,
##     Fortify, Exhert), scored the same "was the skill cast" way as granted_status. Still
##     excluded: self-accumulated stack mechanics (Arcane Instability's stacks, Hemoclarity's
##     Health-gated bonus), which need a battle-state assumption this function has no basis
##     for — the manifest tags those Channel1 too, but with no granted_attribute_buff entry.
##   - A manifest entry's "gated_bonus" (the Sorcerer's repeat, the Alchemist's team factor,
##     Plague Doctor's Comorbidity retick, Unstable Rift's remaining zone charges) is scored as
##     though its precondition was met — a reagent consumed, a debuff present, a zone charge
##     spent: there is no battle simulation here to know whether it actually was, matching the
##     simplifications above. CandidateResult.assumed_gates names every such precondition this
##     score depended on, generalizing the old reagent-specific axis (Role_Kit_Design.md
##     section 11) rather than leaving these mechanics silently scored at zero.
##   - A "gated_bonus" folds three ways, per the manifest's own "fold" field:
##       - "same_instance" (default): lands in the SAME CombinedDamageModifier as the
##         candidate's own cast (Contribute()'d into buckets/product, same as a granted_status)
##         — the Alchemist's Volatile Mixture buff.
##       - "separate_instance": its own, independent CombinedDamageModifier and damage
##         resolution in the real resolver (the Sorcerer's repeat) — folding it into product
##         would make that field diverge from what the live-verification suite checks against
##         the real resolver, so it is scored into repeat_contrast_ratio / total_contrast_ratio
##         instead, deliberately excluded from product/contrast_ratio but fully counted in
##         total_contrast_ratio (the third contract quantity above) and, downstream,
##         combined_contrast_ratio (the fourth).
##       - "sustained_ticks": damage spread across several of the boss's own future turns
##         (Comorbidity's extra debuff tick, Unstable Rift's un-triggered zone charges) rather
##         than the one action total_contrast_ratio measures — scored into its own
##         sustained_contrast_ratio, excluded from total_contrast_ratio (which stays a pure
##         one-action figure) but included in combined_contrast_ratio, so a multi-turn payload
##         is visible to team-comparison ranking without corrupting the single-action contract
##         number.
##     "separate_instance" and "sustained_ticks" entries may also declare "instances" (default
##     1) and "instance_compounding" (default 1.0, flat): each of the declared instances
##     contributes (1.0 + magnitude) * instance_compounding^i, i 0-based — see
##     _MultiInstanceContrastRatio. A "separate_instance"/"sustained_ticks" entry on a PASSIVE
##     with "reach": "team" (the Chronophage's Time Tithe granting Borrowed Time to an ally)
##     reaches every candidate but the granter's own, via _ExternalGatedContrastRatios.
##   - A skill's damage may live inside a ZoneEffect.on_trigger instead of a top-level
##     DamageEffect (Miasma has none either way; Unstable Rift's enemy-facing hit does). Such a
##     skill is still enumerated as a candidate, scored off its enemy-facing on_trigger
##     DamageEffects only — an ally-facing payload in the same zone is excluded, since this
##     scorer measures damage against the boss, not the caster's own team.
##   - A caster-side crit buff (Keen Edge, Lethal Precision) is excluded from
##     _EnforceStatusCap's shared eight-status contest: its point magnitude (a flat CritChance/
##     CritDamage add) is not commensurable with the fractional CombinedDamageModifier buckets
##     that contest sorts by, and it never lands in `buckets` at all (crit stays outside the
##     modifier, per the crit-factor contract quantity above). A target-side facet debuff
##     (Exposed Facet, Cracked Facet) lives in the boss's own debuff pool, which this scorer does
##     not model — both are scored as though granted regardless of the shared cap or the boss's
##     own state, consistent with this file's other "assume the gate is satisfied" simplifications.

const Manifest = preload("res://Scripts/Debug/kit_contribution_manifest.gd")
const BlowoutCalibration = preload("res://Scripts/Debug/blowout_calibration.gd")

## Below this many Enabler-classed manifest entries (passive + skills, summed across the
## team), a team is marked non-viable and excluded from ranked output — Concept_Document.md
## 1.1.3's Enabler class exists so a kit can spend its whole moveset setting a burst up
## rather than dealing damage itself, and a team with too few enablers has nothing to
## compose. The right floor is a design call made once real teams exist; 0 means nothing
## is excluded yet. Enabler count is reported on every row regardless.
const ENABLER_FLOOR: int = 0

## Governs a Channel3_Cascade entry's own per-cast rate (_MagnitudeFor) and the
## per_debuff_anchored grant path — both a per-cast reachable count, not an instance curve.
## See the header's first stated simplification. A gated_bonus's own instance curve
## ("instances" / "instance_compounding") is separate — see _MultiInstanceContrastRatio.
const ASSUMED_UNCAPPED_INSTANCES: int = 1

## Skill_Target groups that reach a candidate character when a teammate's manifest entry
## grants them a status (self, every-other-ally, everyone, or "anyone" for the single-target
## family, which is scored best-case just like the rest of this file's simplifications — see
## the header's stated simplifications). Mirrors the ally branches of
## Skills.FindSkillTargets (Scripts/Battle/skills.gd) — the runtime function itself needs a
## live Sides and character dictionary this scorer does not have, so the reachability rule is
## re-derived structurally here from the granting SkillEffect's own target instead of assumed.
const _SELF_ONLY_TARGETS: Array[Types.Skill_Target] = [Types.Skill_Target.Self]
const _OTHER_ALLIES_TARGETS: Array[Types.Skill_Target] = [
	Types.Skill_Target.All_Other_Allies, Types.Skill_Target.Ally_Not_Self]
const _ALL_ALLIES_TARGETS: Array[Types.Skill_Target] = [Types.Skill_Target.All_Allies, Types.Skill_Target.All]

## Enemy-facing Skill_Target values a ZoneEffect.on_trigger DamageEffect may carry — the
## targets a zone-trigger payload counts as "damage against the boss" for, as opposed to an
## ally-facing payload in the same zone (Unstable Rift's own 0.15 Mysticism ally hit).
const _ENEMY_FACING_TARGETS: Array[Types.Skill_Target] = [
	Types.Skill_Target.Single_Enemy, Types.Skill_Target.All_Enemies, Types.Skill_Target.Random_Enemy,
	Types.Skill_Target.ZoneAll, Types.Skill_Target.ZoneEnemy, Types.Skill_Target.Left_Most_Enemy,
	Types.Skill_Target.Right_Most_Enemy, Types.Skill_Target.Most_Injured_Enemy]
const _ANYONE_TARGETS: Array[Types.Skill_Target] = [
	Types.Skill_Target.Single_Ally, Types.Skill_Target.Random_Ally,
	Types.Skill_Target.Most_Injured_Ally, Types.Skill_Target.Most_Buffed_Ally]

## One scored damaging skill: a candidate burst resolution.
class CandidateResult:
	var caster_index: int
	var caster_role: Types.Role
	var skill_name: String
	var skill_index: int
	var product: float
	var base_term: float
	var modifier_term: float
	var contrast_ratio: float
	var buckets: Dictionary
	var distinct_key_count: int
	var dropped_statuses: Array[StringName] = []
	var enabler_count: int
	var is_viable: bool
	## Every gate this candidate's score depended on being satisfied (a reagent consumed, a
	## debuff present, a zone charge spent, ...) — the generalized form of the old
	## reagent-specific assumption axis (Role_Kit_Design.md section 11). Empty when nothing
	## gated was assumed.
	var assumed_gates: Array[StringName] = []
	## True when a &"reagent_consumed" gate is among assumed_gates. Kept as its own field
	## since every existing regression fixture already names it; derived, not independently set.
	var reagent_assumed: bool
	## Damage from a "separate_instance" gated_bonus (the Sorcerer's repeat), expressed as its
	## own contrast ratio against the same basic-skill baseline and never folded into
	## product/contrast_ratio — see the manifest's gated_bonus field docs and
	## _MultiInstanceContrastRatio. 0.0 when this candidate has no such contribution.
	var repeat_contrast_ratio: float = 0.0
	## Damage from a "sustained_ticks" gated_bonus (Plague Doctor's Comorbidity retick,
	## Unstable Rift's remaining zone charges) — its own contrast ratio against the same
	## basic-skill baseline, deliberately excluded from total_contrast_ratio: it spans several
	## of the boss's own future turns rather than the one action total_contrast_ratio measures,
	## so folding it in there would mix two different meanings of "burst" into one single-action
	## contract number. Included in combined_contrast_ratio instead, below. 0.0 when this
	## candidate has no such contribution.
	var sustained_contrast_ratio: float = 0.0
	## contrast_ratio + repeat_contrast_ratio: the total single-action burst this candidate's
	## action deals, across both the original cast and its separate-instance repeat, if any. A
	## Channel-3 repeat is part of what "burst" means (Concept_Document.md 1.1.3's cascade
	## definition) and must count toward it the same as Channels 1 and 2, even though it cannot
	## be folded into the single CombinedDamageModifier product/contrast_ratio represent (see
	## repeat_contrast_ratio's own docs). This is the figure checked against 1.1.2's 30-50x
	## burst-band target; it is no longer the ranking key (see combined_contrast_ratio).
	var total_contrast_ratio: float = 0.0
	## total_contrast_ratio + sustained_contrast_ratio: the ranking key Best()/TeamSweep use.
	## Folding sustained payload back in here (after deliberately excluding it from
	## total_contrast_ratio above) is what lets a DoT/zone-charge combo compete against a
	## direct-damage combo for "which team composition wins" — the question TeamSweep exists to
	## answer — without redefining what total_contrast_ratio's own 30-50x contract check means.
	var combined_contrast_ratio: float = 0.0
	## The caster's own reachable Critical Chance, percentage points, after every fraction and
	## point grant reaching this candidate (Full Appraisal's Keen Edge, Flaw Analysis's Exposed
	## Facet, ...) — clamped to [0, 100] the same way the resolver's crit roll saturates.
	var crit_chance: float = 0.0
	## The caster's own reachable Critical Damage multiplier against BlowoutCalibration.BOSSES[0]'s
	## Knowledge, floored at GameBalance.MINIMUM_CRIT_DAMAGE * 0.01 — see _CritFactor.
	var crit_damage_multiplier: float = 1.0
	## Expected-value crit multiplier on a fully crit-eligible aggregate: 1 + (crit_chance/100) *
	## (crit_damage_multiplier - 1). An EXPECTED value, not a per-roll ceiling, because this
	## scorer has no battle to roll a crit against — see _CritFactor's own docs and the file
	## header's crit contract quantity.
	var crit_factor: float = 1.0
	## crit_factor blended by the basic skill's own allow_critical-eligible aggregate share
	## (_EffectiveCritFactor) — what baseline_damage/modifier_only_damage were actually mitigated
	## through. Equal to crit_factor unless the basic skill mixes crit-eligible and
	## crit-ineligible DamageEffects.
	var baseline_crit_factor: float = 1.0
	## crit_factor blended by the BURST skill's own allow_critical-eligible aggregate share —
	## what burst_damage (and contrast_ratio) were actually mitigated through. A skill with
	## allow_critical = false throughout scores burst_crit_factor == 1.0 regardless of how high
	## crit_factor is, and is penalized relative to a crit-eligible skill of the same base power.
	var burst_crit_factor: float = 1.0

## All candidates for one 3-preset team, ranked best (highest combined_contrast_ratio, i.e.
## every reachable channel including a separate-instance repeat and sustained payload) first.
class TeamResult:
	var candidates: Array[CandidateResult] = []
	var enabler_count: int
	var is_viable: bool

	## This team's best reachable damage output, combined_contrast_ratio included — not
	## necessarily the candidate with the highest single-action total_contrast_ratio, if some
	## other candidate's sustained payload (a DoT retick, un-triggered zone charges) pushes its
	## combined total higher.
	func Best() -> CandidateResult:
		return candidates[0] if not candidates.is_empty() else null

	## The one candidate matching p_caster_index and p_skill_name, or null — a comparison
	## affordance for the two regression fixtures, which do name a bursting skill; not the
	## normal path (Best() is).
	func Pinned(p_caster_index: int, p_skill_name: String) -> CandidateResult:
		for candidate in candidates:
			if(p_caster_index == candidate.caster_index and p_skill_name == candidate.skill_name):
				return candidate
		return null


## p_manifest defaults to the real, hand-derived Manifest.MANIFEST. A caller may pass a
## modified copy instead — built by duplicating MANIFEST and overriding specific role
## entries — to model a hypothetical kit change through this same scorer, per
## Concept_Document.md 1.1's prescription work. Nothing here mutates MANIFEST itself.
static func ScoreTeam(
		p_presets: Array[CharacterPreset], p_enabler_floor: int = ENABLER_FLOOR,
		p_manifest: Dictionary = Manifest.MANIFEST) -> TeamResult:
	var characters: Array[Character] = []
	for i in p_presets.size():
		var character: Character = Character.new()
		character.InstantiateNew(p_presets[i], i)
		# The manifest's magnitudes are stated at Legendary rarity (its own header). A Role can
		# be fielded by presets of different rarities (the Lancer's Centaur_Lancer.tres is Epic,
		# Knight.tres is Uncommon), so "the preset's own rarity" is not even well-defined for a
		# Role — pin every candidate to Legendary instead, re-Init'ing the trait since
		# InstantiateNew already Init'd it at the preset's own rarity.
		character._rarity = Types.Rarity.Legendary
		if(null != character._trait):
			character._trait.Init(Types.Rarity.Legendary)
		characters.append(character)

	var result: TeamResult = TeamResult.new()
	result.enabler_count = _TeamEnablerCount(characters, p_manifest)
	result.is_viable = result.enabler_count >= p_enabler_floor

	for i in characters.size():
		var character: Character = characters[i]
		var role_entry: Dictionary = p_manifest.get(character._role, {})
		var skill_entries: Array = role_entry.get("skills", [])
		for skill_index in character._skills.size():
			var skill: Skill = character._skills[skill_index]
			if(not _HasDamageEffect(skill)):
				continue
			var skill_entry: Dictionary = (
					skill_entries[skill_index] if skill_index < skill_entries.size() else {})
			var candidate: CandidateResult = _ScoreCandidate(
					characters, i, skill_index, skill, skill_entry, result.enabler_count, result.is_viable,
					p_manifest)
			if(null != candidate and result.is_viable):
				result.candidates.append(candidate)

	# combined_contrast_ratio, not total_contrast_ratio: a Channel-3 repeat or sustained payload
	# is part of what a team composition's damage output is (Concept_Document.md 1.1.3) and must
	# be able to win Best() like any other channel, even though neither can be folded into the
	# single-hit product/contrast_ratio pair, or the single-action total_contrast_ratio, those
	# fields protect (see CandidateResult.combined_contrast_ratio's own docs).
	result.candidates.sort_custom(
			func(a: CandidateResult, b: CandidateResult) -> bool:
				return a.combined_contrast_ratio > b.combined_contrast_ratio)
	return result


static func _HasDamageEffect(p_skill: Skill) -> bool:
	return not _TopLevelDamageEffects(p_skill).is_empty() or not _ZoneTriggerEnemyDamageEffects(p_skill).is_empty()


static func _TopLevelDamageEffects(p_skill: Skill) -> Array[DamageEffect]:
	var found: Array[DamageEffect] = []
	for effect in p_skill.effects:
		if(effect is DamageEffect and not (effect as DamageEffect).damage_scaling.is_empty()):
			found.append(effect)
	return found


## Enemy-facing DamageEffects nested inside a ZoneEffect.on_trigger — the shape Unstable Rift
## uses instead of a top-level DamageEffect (Role_Kit_Design.md section 11, "Zone-trigger
## damage invisible"). Ally-facing on_trigger payloads (Unstable Rift's own 0.15 Mysticism ally
## hit) are excluded — see _ENEMY_FACING_TARGETS.
static func _ZoneTriggerEnemyDamageEffects(p_skill: Skill) -> Array[DamageEffect]:
	var found: Array[DamageEffect] = []
	for effect in p_skill.effects:
		if(not effect is ZoneEffect):
			continue
		for trigger_effect in (effect as ZoneEffect).on_trigger:
			if(not trigger_effect is DamageEffect
					or (trigger_effect as DamageEffect).damage_scaling.is_empty()):
				continue
			var target: Types.Skill_Target = (
					p_skill.target if Types.Skill_Target.Skill_Default == trigger_effect.target
					else trigger_effect.target)
			if(_ENEMY_FACING_TARGETS.has(target)):
				found.append(trigger_effect)
	return found


## Falls back to the skill's enemy-facing zone-trigger payload only when it carries no
## top-level DamageEffect of its own — a skill authoring both would double-count, but none
## currently do.
static func _EffectsForAggregate(p_skill: Skill) -> Array[DamageEffect]:
	var top_level: Array[DamageEffect] = _TopLevelDamageEffects(p_skill)
	return top_level if not top_level.is_empty() else _ZoneTriggerEnemyDamageEffects(p_skill)


## p_attribute_points (a grant's flat "percentage_point"/"source_attribute" add, see
## kit_contribution_manifest.gd's granted_attribute_buff field docs) is added to the
## attribute's own base value before the fractional bonus multiplies it — no manifest entry
## currently grants a point on a damage_scaling attribute (every points entry targets
## CritChance/CritDamage, which no damage_scaling names), so this is inert today; wired so a
## future point grant on a scaling attribute is not silently dropped.
static func _ScaledAggregate(
		p_skill: Skill, p_character: Character, p_attribute_bonus: Dictionary = {},
		p_attribute_points: Dictionary = {}) -> float:
	var total: float = 0.0
	for damage_effect in _EffectsForAggregate(p_skill):
		for attribute: Types.Attribute in damage_effect.damage_scaling.keys():
			var bonus: float = p_attribute_bonus.get(attribute, 0.0)
			var point: float = p_attribute_points.get(attribute, 0.0)
			total += (damage_effect.damage_scaling[attribute]
					* (float(p_character._attributes[attribute]) + point) * (1.0 + bonus))
	return total


## The portion of _ScaledAggregate's total that comes from DamageEffects with
## allow_critical == true (damage_effect.gd:17) — the share of a candidate's aggregate a
## critical hit actually multiplies. Every current .tres DamageEffect defaults allow_critical
## true, but a skill mixing crit-eligible and crit-ineligible payloads in one cast (or a future
## non-critting effect) must not be scored as if the whole aggregate could crit. See
## _ScaledAggregate's own docs for p_attribute_points.
static func _CritEligibleAggregate(
		p_skill: Skill, p_character: Character, p_attribute_bonus: Dictionary = {},
		p_attribute_points: Dictionary = {}) -> float:
	var total: float = 0.0
	for damage_effect in _EffectsForAggregate(p_skill):
		if(not damage_effect.allow_critical):
			continue
		for attribute: Types.Attribute in damage_effect.damage_scaling.keys():
			var bonus: float = p_attribute_bonus.get(attribute, 0.0)
			var point: float = p_attribute_points.get(attribute, 0.0)
			total += (damage_effect.damage_scaling[attribute]
					* (float(p_character._attributes[attribute]) + point) * (1.0 + bonus))
	return total


## The character's cooldown-0 skill (Concept_Document.md 1.1.2's basic-skill baseline).
static func _BasicSkill(p_character: Character) -> Skill:
	return Skills.BasicSkill(p_character)


static func _TeamEnablerCount(p_characters: Array[Character], p_manifest: Dictionary) -> int:
	var count: int = 0
	for character in p_characters:
		var role_entry: Dictionary = p_manifest.get(character._role, {})
		for entry: Dictionary in role_entry.get("passive", []):
			if(Manifest.Contribution_Class.Enabler == entry.get("class")):
				count += 1
		for entry: Dictionary in role_entry.get("skills", []):
			if(Manifest.Contribution_Class.Enabler == entry.get("class")):
				count += 1
	return count


## The debuff-type bucket the candidate skill's own bonus_per_debuff_on_target already
## keys to (e.g. Cataclysm's "Warped"), if any — the one debuff Opportunist can be
## assumed present on the target without simulating one, per ASSUMED_UNCAPPED_INSTANCES.
## "" when the candidate skill carries no such precondition, in which case a
## per_debuff_anchored grant contributes nothing rather than inventing a target state.
static func _AnchorDebuffKey(p_skill_entry: Dictionary) -> StringName:
	var key: String = String(p_skill_entry.get("bucket_key", ""))
	if("" != key and Types.Debuff_Type.keys().has(key)):
		return StringName(key)
	return &""


## True if the manifest names an enum member exactly matching p_key — the structural test
## for "is this bucket a status effect" the status cap (GameBalance.MAX_STATUS_EFFECTS)
## applies to, as opposed to a skill name, ramp key, or trait-resource key.
static func _IsStatusKey(p_key: StringName) -> bool:
	var key: String = String(p_key)
	return Types.Buff_Type.keys().has(key) or Types.Debuff_Type.keys().has(key)


static func _Contribute(p_buckets: Dictionary, p_key: StringName, p_amount: float) -> void:
	if(&"" == p_key or 0.0 == p_amount):
		return
	p_buckets[p_key] = p_buckets.get(p_key, 0.0) + p_amount


## True for a gated_bonus dict that lands in the SAME CombinedDamageModifier as the
## candidate's own cast ("same_instance", the default) rather than a wholly separate damage
## resolution or multi-turn payload ("separate_instance" / "sustained_ticks") — see the
## manifest's field docs. Only a same_instance entry may ever be Contribute()'d into this
## candidate's own buckets.
static func _IsSameInstanceFold(p_bonus: Dictionary) -> bool:
	return "same_instance" == p_bonus.get("fold", "same_instance")


## The candidate's own skill/passive-scoped gated_bonus (a same_instance fold only) — see the
## header's stated simplifications. Returns the bonus's own "gate" name (StringName, possibly
## &"") if a contribution was made, or &"" if none was, so the caller can surface the
## assumption on CandidateResult.
static func _ContributeGatedSkillBonus(p_buckets: Dictionary, p_entry: Dictionary) -> StringName:
	var bonus: Dictionary = p_entry.get("gated_bonus", {})
	if(bonus.is_empty() or not _IsSameInstanceFold(bonus)):
		return &""
	_Contribute(p_buckets, StringName(String(bonus.get("bucket_key", ""))), _MagnitudeFor(bonus))
	return StringName(String(bonus.get("gate", "")))


## Team-reach gated_bonus entries (the Alchemist's Volatile Mixture factor): read off every
## teammate's own passive, not just the candidate's caster, because the mechanic broadcasts to
## the whole team including its own owner (fresh_batch_trait.gd:58-62's AlliesOf reach).
## Returns the gate name of every contribution made, so the caller can surface the assumption
## on CandidateResult.
static func _ContributeGatedTeamBonuses(
		p_characters: Array[Character], p_buckets: Dictionary, p_manifest: Dictionary) -> Array[StringName]:
	var gates: Array[StringName] = []
	for character in p_characters:
		var role_entry: Dictionary = p_manifest.get(character._role, {})
		for passive_entry: Dictionary in role_entry.get("passive", []):
			var bonus: Dictionary = passive_entry.get("gated_bonus", {})
			if(bonus.is_empty() or not _IsSameInstanceFold(bonus) or "team" != bonus.get("reach", "")):
				continue
			_Contribute(p_buckets, StringName(String(bonus.get("bucket_key", ""))), _MagnitudeFor(bonus))
			gates.append(StringName(String(bonus.get("gate", ""))))
	return gates


## Self-reach gated_bonus on the candidate's OWN passive entries (Chosen Vessel's Devotion): a
## permanent per-Vessel-death factor in its own bucket, distinct from the passive's own
## bucket_key so the two multiply rather than share a bucket. Returns the gate name of every
## contribution made, mirroring _ContributeGatedTeamBonuses's return shape.
static func _ContributeGatedCasterPassiveBonus(
		p_caster: Character, p_buckets: Dictionary, p_manifest: Dictionary) -> Array[StringName]:
	var gates: Array[StringName] = []
	var role_entry: Dictionary = p_manifest.get(p_caster._role, {})
	for passive_entry: Dictionary in role_entry.get("passive", []):
		var bonus: Dictionary = passive_entry.get("gated_bonus", {})
		if(bonus.is_empty() or not _IsSameInstanceFold(bonus) or "self" != bonus.get("reach", "")):
			continue
		_Contribute(p_buckets, StringName(String(bonus.get("bucket_key", ""))), _MagnitudeFor(bonus))
		gates.append(StringName(String(bonus.get("gate", ""))))
	return gates


## Shared curve-walk for a "separate_instance" or "sustained_ticks" gated_bonus: each of the
## declared "instances" (default 1, clamped to CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION)
## contributes (1.0 + magnitude) * instance_compounding^i, i 0-based — flat when
## instance_compounding is omitted (default 1.0), compounding otherwise (an Echo-style curve).
## Mirrors the original repeat approximation's own bucket-factor and mitigation shape: the
## real resolver re-resolves the cast's DamageEffects as their own, independent
## CombinedDamageModifier and ResolveEffectDamage call(s), never folded into the original
## cast's own product — folding it in here would make CandidateResult.product diverge from
## what Tests/unit/test_burst_reachability_live.gd's replay of the real resolver assembles for
## the ORIGINAL cast alone. Deliberately excludes any team/granted factor (Volatile Mixture,
## Opportunist, ...), since those are already contributed to (and, for a DamageMultiplier
## buff, consumed by) the ORIGINAL cast in the real resolver (battle_resolver.gd:739-744's
## per-instance ConsumeDamageMultiplierFactors call) and would double-count here otherwise.
## p_crit_factor is the burst skill's own expected crit factor (BurstReachability._CritFactor,
## blended by allow_critical share) — a separate-instance repeat is its own damage resolution
## in the real resolver and rolls its own crit the same way the original cast does, so it is
## mitigated through the same expected factor rather than 1.0.
static func _MultiInstanceContrastRatio(
		p_skill_entry: Dictionary, p_bonus: Dictionary, p_skill_aggregate: float, p_defence: float,
		p_baseline_damage: float, p_crit_factor: float) -> float:
	var own_bucket_factor: float = 1.0
	if(Manifest.Contribution_Class.Channel2 == p_skill_entry.get("class") \
			or Manifest.Contribution_Class.Channel3_Cascade == p_skill_entry.get("class")):
		own_bucket_factor = 1.0 + _MagnitudeFor(p_skill_entry)
	var magnitude: float = p_bonus.get("magnitude", 0.0)
	var compounding: float = p_bonus.get("instance_compounding", 1.0)
	var instances: int = mini(int(p_bonus.get("instances", 1)), CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION)
	var factor_sum: float = 0.0
	for i in instances:
		factor_sum += (1.0 + magnitude) * pow(compounding, float(i))
	var repeat_damage: float = Skills.MitigatedDamageUnrounded(
			p_defence, p_skill_aggregate * own_bucket_factor * factor_sum, p_crit_factor, 1.0)
	return repeat_damage / p_baseline_damage


## Splits a skill entry's gated_bonus into [repeat_contrast_ratio, sustained_contrast_ratio] —
## mutually exclusive folds, so at most one of the two is ever nonzero.
static func _GatedContrastRatios(
		p_skill_entry: Dictionary, p_skill_aggregate: float, p_defence: float,
		p_baseline_damage: float, p_crit_factor: float) -> Array[float]:
	var bonus: Dictionary = p_skill_entry.get("gated_bonus", {})
	if(bonus.is_empty() or _IsSameInstanceFold(bonus)):
		return [0.0, 0.0]
	var ratio: float = _MultiInstanceContrastRatio(
			p_skill_entry, bonus, p_skill_aggregate, p_defence, p_baseline_damage, p_crit_factor)
	if("separate_instance" == bonus.get("fold", "same_instance")):
		return [ratio, 0.0]
	return [0.0, ratio]


## External gated_bonus entries reaching a candidate from a TEAMMATE's own passive (the
## Chronophage's Time Tithe granting Borrowed Time to an ally) — the counterpart to
## _GatedContrastRatios, which only reads the candidate's own skill entry. Walks every
## character but the candidate's own caster (a granter cannot grant itself the instance),
## taking each granter's passive gated_bonus where the fold is not same_instance and
## reach == "team". The existing _MultiInstanceContrastRatio already splits own_bucket_factor
## (supplied by the CANDIDATE's own skill entry — Borrowed Time re-resolves the ally's whole
## skill, buckets included) from the granter's own magnitude/instances/compounding, so no new
## curve-walk is needed, only routing an external bonus through it. Sums across granters per
## fold and collects every granter's own gate, matching _GatedContrastRatios' two-slot shape.
static func _ExternalGatedContrastRatios(
		p_characters: Array[Character], p_caster_index: int, p_skill_entry: Dictionary,
		p_skill_aggregate: float, p_defence: float, p_baseline_damage: float, p_crit_factor: float,
		p_manifest: Dictionary) -> Dictionary:
	var repeat_ratio: float = 0.0
	var sustained_ratio: float = 0.0
	var gates: Array[StringName] = []
	for granter_index in p_characters.size():
		if(granter_index == p_caster_index):
			continue
		var granter: Character = p_characters[granter_index]
		var role_entry: Dictionary = p_manifest.get(granter._role, {})
		for passive_entry: Dictionary in role_entry.get("passive", []):
			var bonus: Dictionary = passive_entry.get("gated_bonus", {})
			if(bonus.is_empty() or _IsSameInstanceFold(bonus) or "team" != bonus.get("reach", "")):
				continue
			var ratio: float = _MultiInstanceContrastRatio(
					p_skill_entry, bonus, p_skill_aggregate, p_defence, p_baseline_damage, p_crit_factor)
			if("separate_instance" == bonus.get("fold", "same_instance")):
				repeat_ratio += ratio
			else:
				sustained_ratio += ratio
			gates.append(StringName(String(bonus.get("gate", ""))))
	return {"repeat": repeat_ratio, "sustained": sustained_ratio, "gates": gates}


## True if p_passive_entry's own bucket contribution applies when p_skill_index is the skill
## being cast, per its "bucket_applies" field (absent means every cast — most Channel-2
## passives in the manifest apply on any of their owner's casts, but three are gated to one
## specific trigger). Gates only the passive's bucket contribution — defence_ignore and a
## passive's own gated_bonus are per-attack hooks that apply on every cast regardless (see
## chosen_vessel_trait.gd's GetOutgoingDamageBonus).
static func _PassiveBucketApplies(p_passive_entry: Dictionary, p_skill: Skill, p_skill_index: int) -> bool:
	var applies: Dictionary = p_passive_entry.get("bucket_applies", {})
	if(applies.is_empty()):
		return true
	match String(applies.get("kind", "")):
		"non_basic_cast":
			return p_skill.cooldown > 0
		"skill_index":
			return int(applies.get("skill_index", -1)) == p_skill_index
		_:
			push_error("Unrecognised bucket_applies kind: %s" % applies.get("kind"))
			return false


## The caster's expected crit factor against p_boss_knowledge — mirrors
## battle_resolver.gd's own _ResolveDamage roll (chance) and crit-multiplier formula
## (Concept_Document.md 3.2.1 #4) as an EXPECTED VALUE rather than a roll, since this scorer
## has no battle to roll against: crit_factor = 1 + (probability) * (multiplier - 1), so a crit
## CHANCE source (Flaw Analysis, Keen Edge, the Appraiser's own base 30) actually moves the
## score, not just crit damage. p_fractions/p_points are the CritChance/CritDamage entries of
## _ContributeGrantedAttributeBuffs's own return value. p_overflow_rate is the Appraiser's No
## Wasted Margin rate (0.0 = no conversion): chance is left unclamped so the excess above 100
## converts into extra crit-damage points the same way _ResolveDamage's overflow term does,
## while `probability` (the roll's own [0.0, 1.0] chance of landing at all) still saturates at
## 1.0. The damage floor is GameBalance.MINIMUM_CRIT_DAMAGE, same as the runtime.
static func _CritFactor(
		p_caster: Character, p_fractions: Dictionary, p_points: Dictionary, p_boss_knowledge: float,
		p_overflow_rate: float = 0.0) -> Dictionary:
	var base_chance: float = float(p_caster._attributes[Types.Attribute.CritChance])
	var base_damage: float = float(p_caster._attributes[Types.Attribute.CritDamage])
	var chance: float = maxf(0.0,
			base_chance * (1.0 + p_fractions.get(Types.Attribute.CritChance, 0.0))
					+ p_points.get(Types.Attribute.CritChance, 0.0))
	var overflow_crit_damage: float = maxf(0.0, chance - 100.0) * p_overflow_rate
	var probability: float = clampf(chance, 0.0, 100.0) / 100.0
	var damage_multiplier: float = maxf(
			GameBalance.MINIMUM_CRIT_DAMAGE,
			base_damage * (1.0 + p_fractions.get(Types.Attribute.CritDamage, 0.0))
					+ p_points.get(Types.Attribute.CritDamage, 0.0) + overflow_crit_damage - p_boss_knowledge * 0.5
			) * 0.01
	var factor: float = 1.0 + probability * (damage_multiplier - 1.0)
	return {"chance": chance, "damage_multiplier": damage_multiplier, "factor": factor}


## Sums every teammate's passive-level Critical Chance overflow-conversion rate (the
## Appraiser's No Wasted Margin) — team-wide, mirroring Skills.CritChanceOverflowRate's
## runtime counterpart.
static func _CritChanceOverflowRate(p_characters: Array[Character], p_manifest: Dictionary) -> float:
	var rate: float = 0.0
	for character in p_characters:
		var role_entry: Dictionary = p_manifest.get(character._role, {})
		for passive_entry: Dictionary in role_entry.get("passive", []):
			rate += float(passive_entry.get("crit_overflow_rate", 0.0))
	return rate


## Largest team-wide "attribute_amplification" magnitude (the Scholar's Field of Study),
## mirroring Skills.AppliedAttributeAmplification's own highest-wins fold rather than
## _CritChanceOverflowRate's sum — a second amplifying passive adds nothing.
static func _AttributeAmplification(p_characters: Array[Character], p_manifest: Dictionary) -> float:
	var amplification: float = 0.0
	for character in p_characters:
		var role_entry: Dictionary = p_manifest.get(character._role, {})
		for passive_entry: Dictionary in role_entry.get("passive", []):
			amplification = maxf(
					amplification, float(passive_entry.get("attribute_amplification", {}).get("magnitude", 0.0)))
	return amplification


## Blends a skill's expected crit factor by the share of its aggregate that can actually crit
## (_CritEligibleAggregate vs _ScaledAggregate) — a skill mixing crit-eligible and
## crit-ineligible DamageEffects, or one with allow_critical = false outright (eligible share
## 0.0), must not be scored as if the whole aggregate rolled the caster's crit factor.
static func _EffectiveCritFactor(
		p_skill: Skill, p_character: Character, p_attribute_bonus: Dictionary, p_total_aggregate: float,
		p_crit_factor: float, p_attribute_points: Dictionary = {}) -> float:
	if(0.0 == p_total_aggregate):
		return 1.0
	var eligible_share: float = (
			_CritEligibleAggregate(p_skill, p_character, p_attribute_bonus, p_attribute_points)
			/ p_total_aggregate)
	return 1.0 + eligible_share * (p_crit_factor - 1.0)


## Base-referenced Defence-ignore points a candidate's caster carries against p_defence: its
## own declared passive rate (Between the Plates, Role_Kit_Design.md section 9.12), summed
## across every passive row, times the given skill's own declared multiple. p_defence here is
## always the scorer's fixed, debuff-free boss constant, never a shredded value — see
## _EffectiveDefenceForCandidate for why the two references stay separate.
static func _DefenceIgnorePoints(
		p_caster_role_entry: Dictionary, p_skill_entry: Dictionary, p_defence: float) -> float:
	var rate: float = 0.0
	for passive_entry: Dictionary in p_caster_role_entry.get("passive", []):
		rate += float(passive_entry.get("defence_ignore", {}).get("rate", 0.0))
	if(0.0 == rate):
		return 0.0
	var multiple: float = float(p_skill_entry.get("defence_ignore", {}).get("multiple", 0.0))
	return rate * multiple * p_defence


## Team-reach Defence-shred fraction (the Architect's Expose Weakness, Role_Kit_Design.md
## section 9.10): read off every teammate's own skill entries and exported to every candidate
## regardless of caster, mirroring the rider's own reach in the real game. Sources do not
## currently stack, so the largest declared fraction wins rather than summing, avoiding a
## stacking rule this scorer has no battle state to justify. Returns the fraction plus the
## gate name of every contribution.
static func _ContributeDefenceReduction(p_characters: Array[Character], p_manifest: Dictionary) -> Dictionary:
	var fraction: float = 0.0
	var gates: Array[StringName] = []
	for character in p_characters:
		var role_entry: Dictionary = p_manifest.get(character._role, {})
		for skill_entry: Dictionary in role_entry.get("skills", []):
			var reduction: Dictionary = skill_entry.get("defence_reduction", {})
			if(reduction.is_empty() or "team" != reduction.get("reach", "")):
				continue
			fraction = maxf(fraction, float(reduction.get("fraction", 0.0)))
			gates.append(StringName(String(reduction.get("gate", ""))))
	return {"fraction": fraction, "gates": gates}


## Effective Defence after a team-reach shred (fractional, applied to the raw p_defence
## reference) and then a caster-side base-referenced ignore (points, also read off the
## UNSHREDDED p_defence) — the same two-step order battle_resolver.gd's
## _EffectiveDefenceAfterIgnore performs, and the reason route G (Thief + Architect) compounds
## instead of the ignore eating the shred.
static func _EffectiveDefenceForCandidate(
		p_defence: float, p_shred_fraction: float, p_ignore_points: float) -> float:
	var shredded: float = p_defence * (1.0 - p_shred_fraction)
	return maxf(0.0, shredded - p_ignore_points)


static func _ScoreCandidate(
		p_characters: Array[Character],
		p_caster_index: int,
		p_skill_index: int,
		p_skill: Skill,
		p_skill_entry: Dictionary,
		p_enabler_count: int,
		p_is_viable: bool,
		p_manifest: Dictionary) -> CandidateResult:
	var caster: Character = p_characters[p_caster_index]
	var basic_skill: Skill = _BasicSkill(caster)
	var attribute_bonus: Dictionary = _ContributeGrantedAttributeBuffs(p_characters, p_caster_index, p_manifest)
	var fractions: Dictionary = attribute_bonus.get("fractions", {})
	var points: Dictionary = attribute_bonus.get("points", {})
	var basic_aggregate: float = _ScaledAggregate(basic_skill, caster, fractions, points)
	if(0.0 == basic_aggregate):
		return null
	var skill_aggregate: float = _ScaledAggregate(p_skill, caster, fractions, points)

	var buckets: Dictionary = {}
	var caster_role_entry: Dictionary = p_manifest.get(caster._role, {})
	for passive_entry: Dictionary in caster_role_entry.get("passive", []):
		if(_PassiveBucketApplies(passive_entry, p_skill, p_skill_index)):
			_Contribute(buckets, StringName(String(passive_entry.get("bucket_key", ""))),
					_MagnitudeFor(passive_entry))
	if(Manifest.Contribution_Class.Channel2 == p_skill_entry.get("class") \
			or Manifest.Contribution_Class.Channel3_Cascade == p_skill_entry.get("class")):
		_Contribute(buckets, StringName(String(p_skill_entry.get("bucket_key", ""))),
				_MagnitudeFor(p_skill_entry))

	var assumed_gates: Array[StringName] = []
	var skill_gate: StringName = _ContributeGatedSkillBonus(buckets, p_skill_entry)
	if(&"" != skill_gate):
		assumed_gates.append(skill_gate)
	for gate: StringName in _ContributeGatedCasterPassiveBonus(caster, buckets, p_manifest):
		if(&"" != gate):
			assumed_gates.append(gate)
	for gate: StringName in _ContributeGatedTeamBonuses(p_characters, buckets, p_manifest):
		if(&"" != gate):
			assumed_gates.append(gate)
	for gate: StringName in attribute_bonus.get("gates", []):
		assumed_gates.append(gate)

	var anchor_debuff_key: StringName = _AnchorDebuffKey(p_skill_entry)
	_ContributeGrantedStatuses(p_characters, p_caster_index, buckets, anchor_debuff_key, p_manifest)

	var dropped: Array[StringName] = _EnforceStatusCap(buckets)

	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	for key: StringName in buckets:
		modifier.Contribute(key, buckets[key])
	var product: float = modifier.Product()

	var defence: float = BlowoutCalibration.BOSSES[0][2]
	var boss_knowledge: float = BlowoutCalibration.BOSSES[0][3]
	var overflow_rate: float = _CritChanceOverflowRate(p_characters, p_manifest)
	var crit: Dictionary = _CritFactor(caster, fractions, points, boss_knowledge, overflow_rate)
	var baseline_crit_factor: float = _EffectiveCritFactor(
			basic_skill, caster, fractions, basic_aggregate, crit.get("factor"), points)
	var burst_crit_factor: float = _EffectiveCritFactor(
			p_skill, caster, fractions, skill_aggregate, crit.get("factor"), points)

	var caster_skill_entries: Array = caster_role_entry.get("skills", [])
	var basic_skill_index: int = caster._skills.find(basic_skill)
	var basic_skill_entry: Dictionary = (
			caster_skill_entries[basic_skill_index]
			if basic_skill_index >= 0 and basic_skill_index < caster_skill_entries.size() else {})
	var shred: Dictionary = _ContributeDefenceReduction(p_characters, p_manifest)
	var shred_fraction: float = shred.get("fraction", 0.0)
	if(0.0 != shred_fraction):
		for gate: StringName in shred.get("gates", []):
			assumed_gates.append(gate)
	var baseline_defence: float = _EffectiveDefenceForCandidate(
			defence, shred_fraction, _DefenceIgnorePoints(caster_role_entry, basic_skill_entry, defence))
	var burst_defence: float = _EffectiveDefenceForCandidate(
			defence, shred_fraction, _DefenceIgnorePoints(caster_role_entry, p_skill_entry, defence))

	# Unrounded core, not Skills.MitigatedDamage's own int(ceil(...)) — contrast_ratio and
	# modifier_term are ratios of these three, and rounding each one first would introduce a
	# quantization artifact the real single-roll formula does not have.
	var baseline_damage: float = (
			Skills.MitigatedDamageUnrounded(baseline_defence, basic_aggregate, baseline_crit_factor, 1.0))
	var modifier_only_damage: float = Skills.MitigatedDamageUnrounded(
			baseline_defence, basic_aggregate * product, baseline_crit_factor, 1.0)
	var burst_damage: float = Skills.MitigatedDamageUnrounded(
			burst_defence, skill_aggregate * product, burst_crit_factor, 1.0)
	var gated_ratios: Array[float] = _GatedContrastRatios(
			p_skill_entry, skill_aggregate, burst_defence, baseline_damage, burst_crit_factor)
	var repeat_contrast_ratio: float = gated_ratios[0]
	var sustained_contrast_ratio: float = gated_ratios[1]
	if(0.0 != repeat_contrast_ratio or 0.0 != sustained_contrast_ratio):
		var gate: StringName = StringName(String(p_skill_entry.get("gated_bonus", {}).get("gate", "")))
		if(&"" != gate):
			assumed_gates.append(gate)
	var external_ratios: Dictionary = _ExternalGatedContrastRatios(
			p_characters, p_caster_index, p_skill_entry, skill_aggregate, burst_defence, baseline_damage,
			burst_crit_factor, p_manifest)
	repeat_contrast_ratio += float(external_ratios.get("repeat", 0.0))
	sustained_contrast_ratio += float(external_ratios.get("sustained", 0.0))
	for gate: StringName in external_ratios.get("gates", []):
		if(&"" != gate):
			assumed_gates.append(gate)

	var result: CandidateResult = CandidateResult.new()
	result.caster_index = p_caster_index
	result.caster_role = caster._role
	result.skill_name = p_skill.name
	result.skill_index = p_skill_index
	result.product = product
	result.base_term = skill_aggregate / basic_aggregate
	result.modifier_term = modifier_only_damage / baseline_damage
	result.contrast_ratio = burst_damage / baseline_damage
	result.crit_chance = crit.get("chance")
	result.crit_damage_multiplier = crit.get("damage_multiplier")
	result.crit_factor = crit.get("factor")
	result.baseline_crit_factor = baseline_crit_factor
	result.burst_crit_factor = burst_crit_factor
	result.buckets = buckets
	result.distinct_key_count = buckets.size()
	result.dropped_statuses = dropped
	result.enabler_count = p_enabler_count
	result.is_viable = p_is_viable
	result.assumed_gates = assumed_gates
	result.reagent_assumed = assumed_gates.has(&"reagent_consumed")
	result.repeat_contrast_ratio = repeat_contrast_ratio
	result.sustained_contrast_ratio = sustained_contrast_ratio
	result.total_contrast_ratio = result.contrast_ratio + repeat_contrast_ratio
	result.combined_contrast_ratio = result.total_contrast_ratio + sustained_contrast_ratio
	return result


## A Channel-3-Cascade entry repeats per cascade instance, bounded by both cascade caps
## (CascadeResolver.MAX_CASCADE_DEPTH, MAX_CASCADE_INSTANCES_PER_ACTION); every other class
## contributes its magnitude once, already a ceiling per the manifest's own convention.
static func _MagnitudeFor(p_entry: Dictionary) -> float:
	var magnitude: float = p_entry.get("magnitude", 0.0)
	if(Manifest.Contribution_Class.Channel3_Cascade == p_entry.get("class")):
		var instances: int = mini(ASSUMED_UNCAPPED_INSTANCES, CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION)
		return magnitude * float(instances)
	return magnitude


## The granting SkillEffect's own target group, or the skill's own target when the effect
## defers to it (Skill_Default) — the same fallback SkillCastContext.TargetsFor uses at
## runtime. p_buff_type (optional) selects among several ApplyBuffEffects on the same skill
## by their own buff_type — required when a grant dict needs a specific one of them (a skill
## carrying more than one ApplyBuffEffect). Omitted, the first ApplyBuffEffect is the granting
## effect, and every other ApplyBuffEffect on the skill must resolve to the same target group
## or this is ambiguous (push_error) — true today for all three multi-effect skills
## (Full_Appraisal.tres, Brace_for_Impact.tres, Center_Stage.tres).
static func _GrantingEffectTarget(p_skill: Skill, p_buff_type: Variant = null) -> Types.Skill_Target:
	var buff_effects: Array[ApplyBuffEffect] = []
	for effect in p_skill.effects:
		if(effect is ApplyBuffEffect):
			buff_effects.append(effect)
	if(buff_effects.is_empty()):
		return p_skill.target
	var selected: ApplyBuffEffect = buff_effects[0]
	if(null != p_buff_type):
		var matched: ApplyBuffEffect = null
		for buff_effect in buff_effects:
			if(buff_effect.buff_type == p_buff_type):
				matched = buff_effect
				break
		if(null == matched):
			push_error("%s: no ApplyBuffEffect matches declared buff_type %s" % [p_skill.name, p_buff_type])
		else:
			selected = matched
	elif(buff_effects.size() > 1):
		var first_target: Types.Skill_Target = (
				p_skill.target if Types.Skill_Target.Skill_Default == buff_effects[0].target
				else buff_effects[0].target)
		for buff_effect in buff_effects:
			var target: Types.Skill_Target = (
					p_skill.target if Types.Skill_Target.Skill_Default == buff_effect.target else buff_effect.target)
			if(target != first_target):
				push_error(
						"%s: multiple ApplyBuffEffects disagree on target; a grant reading this skill " % p_skill.name +
						"needs an explicit buff_type")
				break
	return p_skill.target if Types.Skill_Target.Skill_Default == selected.target else selected.target


## True if a status granted by p_granter's p_granting_skill reaches p_candidate_index, given
## p_granter is at p_granter_index — derived from the granting effect's own Skill_Target
## rather than assumed. See the _..._TARGETS group constants above for the mapping; the
## single-target-family case (Single_Ally, Random_Ally, Most_Injured_Ally, Most_Buffed_Ally)
## is scored best-case ("anyone"), consistent with this file's other stated simplifications.
## p_buff_type (optional) is the grant dict's own "buff_type", forwarded to
## _GrantingEffectTarget to disambiguate a skill with more than one ApplyBuffEffect.
static func _GrantReachesCandidate(
		p_granting_skill: Skill, p_granter_index: int, p_candidate_index: int,
		p_buff_type: Variant = null) -> bool:
	var target: Types.Skill_Target = _GrantingEffectTarget(p_granting_skill, p_buff_type)
	if(_SELF_ONLY_TARGETS.has(target)):
		return p_granter_index == p_candidate_index
	if(_OTHER_ALLIES_TARGETS.has(target)):
		return p_granter_index != p_candidate_index
	if(_ALL_ALLIES_TARGETS.has(target)):
		return true
	if(_ANYONE_TARGETS.has(target)):
		return true
	return false


static func _ContributeGrantedStatuses(
		p_characters: Array[Character], p_candidate_index: int, p_buckets: Dictionary,
		p_anchor_debuff_key: StringName, p_manifest: Dictionary) -> void:
	for granter_index in p_characters.size():
		var granter: Character = p_characters[granter_index]
		var role_entry: Dictionary = p_manifest.get(granter._role, {})
		var skill_entries: Array = role_entry.get("skills", [])
		for skill_index in skill_entries.size():
			var skill_entry: Dictionary = skill_entries[skill_index]
			var grant: Dictionary = skill_entry.get("granted_status", {})
			if(grant.is_empty() or skill_index >= granter._skills.size()):
				continue
			if("team" != grant.get("reach", "")):
				var granting_skill: Skill = granter._skills[skill_index]
				if(not _GrantReachesCandidate(
						granting_skill, granter_index, p_candidate_index, grant.get("buff_type"))):
					continue
			if(grant.get("per_debuff_anchored", false)):
				if(&"" != p_anchor_debuff_key):
					_Contribute(p_buckets, p_anchor_debuff_key,
							grant.get("magnitude", 0.0) * float(ASSUMED_UNCAPPED_INSTANCES))
			else:
				_Contribute(p_buckets, StringName(String(grant.get("bucket_key", ""))), grant.get("magnitude", 0.0))


## Normalizes a "granted_attribute_buff" field to an Array of grant dicts — the field may hold
## a single dict (every pre-crit entry) or an Array of dicts (a grant applying two different
## magnitudes to two different attributes in one action, e.g. Full Appraisal's Keen Edge +15
## CritChance and Lethal Precision +50 CritDamage). An empty/absent field normalizes to [].
static func _NormalizeGrantList(p_field: Variant) -> Array[Dictionary]:
	if(p_field is Array):
		var grants: Array[Dictionary] = []
		for entry in p_field:
			grants.append(entry)
		return grants
	if(p_field is Dictionary and not (p_field as Dictionary).is_empty()):
		return [p_field]
	return []


## Additive per-attribute bonus reaching p_candidate_index from every teammate's manifest
## "granted_attribute_buff" entries, split into a multiplicative "fractions" dict and a flat
## "points" dict per the field's own "kind" (see kit_contribution_manifest.gd's field docs),
## plus every "gate" named along the way. Skill-scoped grants use the same _GrantReachesCandidate
## reach rule as _ContributeGrantedStatuses, unless the grant itself declares "team" reach
## (Sizing Cut's Exposed Facet sits on the target and buffs every attacker of it, not an
## ally-target grant at all); passive-scoped grants (Tactician's Plan ahead) have no skill
## target to read, so "team" is their only reach.
static func _ContributeGrantedAttributeBuffs(
		p_characters: Array[Character], p_candidate_index: int, p_manifest: Dictionary) -> Dictionary:
	var fractions: Dictionary = {}
	var points: Dictionary = {}
	var gates: Array[StringName] = []
	var amplification: float = _AttributeAmplification(p_characters, p_manifest)
	for granter_index in p_characters.size():
		var granter: Character = p_characters[granter_index]
		var role_entry: Dictionary = p_manifest.get(granter._role, {})
		for passive_entry: Dictionary in role_entry.get("passive", []):
			for grant: Dictionary in _NormalizeGrantList(passive_entry.get("granted_attribute_buff", {})):
				if("team" == grant.get("reach", "")):
					_AccumulateAttributeBuff(fractions, points, grant, granter, amplification)
					_AppendGate(gates, grant)
		var skill_entries: Array = role_entry.get("skills", [])
		for skill_index in skill_entries.size():
			var skill_entry: Dictionary = skill_entries[skill_index]
			if(skill_index >= granter._skills.size()):
				continue
			for grant: Dictionary in _NormalizeGrantList(skill_entry.get("granted_attribute_buff", {})):
				if("team" == grant.get("reach", "")):
					_AccumulateAttributeBuff(fractions, points, grant, granter, amplification)
					_AppendGate(gates, grant)
					continue
				var granting_skill: Skill = granter._skills[skill_index]
				if(_GrantReachesCandidate(
						granting_skill, granter_index, p_candidate_index, grant.get("buff_type"))):
					_AccumulateAttributeBuff(fractions, points, grant, granter, amplification)
					_AppendGate(gates, grant)
	return {"fractions": fractions, "points": points, "gates": gates}


## Routes a grant's magnitude into p_fractions (the default "percentage" kind, a multiplicative
## fraction of the attribute's base value), p_points ("percentage_point", a flat add), or also
## p_points via "source_attribute" (a flat add sized off p_granter's own "source_attribute"
## value — Keen Edge/Lethal Precision/Cracked Facet, consumed the same way
## AttackerCritChanceBonus/AttackerCritDamageBonus consume a flat point value at runtime) per
## the grant's own "kind" field. p_granter is required for "source_attribute" grants only.
## p_amplification (the Scholar's Field of Study, Role_Kit_Design.md 9.14) adds onto a
## "percentage" grant's own magnitude before it lands in p_fractions, the scorer's counterpart
## to Skills.ApplyAttributeModifiers reading the same &"attribute_amplification" rider — every
## crit-attribute grant in the manifest uses "percentage_point"/"source_attribute", so no
## per-attribute exclusion is needed here to keep the crit path unamplified.
static func _AccumulateAttributeBuff(
		p_fractions: Dictionary, p_points: Dictionary, p_grant: Dictionary, p_granter: Character = null,
		p_amplification: float = 0.0) -> void:
	var kind: String = p_grant.get("kind", "percentage")
	var magnitude: float = p_grant.get("magnitude", 0.0)
	var target: Dictionary
	match kind:
		"percentage":
			magnitude += p_amplification
			target = p_fractions
		"percentage_point":
			target = p_points
		"source_attribute":
			if(null != p_granter):
				var source_attribute: Types.Attribute = p_grant.get("source_attribute", Types.Attribute.Health)
				magnitude *= float(p_granter._attributes[source_attribute])
			target = p_points
		_:
			push_error("Unrecognised granted_attribute_buff kind: %s" % kind)
			return
	for attribute: Types.Attribute in p_grant.get("attributes", []):
		target[attribute] = target.get(attribute, 0.0) + magnitude


static func _AppendGate(p_gates: Array[StringName], p_grant: Dictionary) -> void:
	var gate: StringName = StringName(String(p_grant.get("gate", "")))
	if(&"" != gate):
		p_gates.append(gate)


## Drops the lowest-magnitude status buckets past GameBalance.MAX_STATUS_EFFECTS, in place
## on p_buckets, and returns the dropped keys — a team whose entries exceed the shared
## status cap cannot land them all, so the excess must not silently score.
static func _EnforceStatusCap(p_buckets: Dictionary) -> Array[StringName]:
	var status_keys: Array[StringName] = []
	for key: StringName in p_buckets:
		if(_IsStatusKey(key)):
			status_keys.append(key)
	if(status_keys.size() <= GameBalance.MAX_STATUS_EFFECTS):
		return []
	status_keys.sort_custom(func(a: StringName, b: StringName) -> bool: return absf(p_buckets[a]) < absf(p_buckets[b]))
	var dropped: Array[StringName] = []
	var excess: int = status_keys.size() - GameBalance.MAX_STATUS_EFFECTS
	for i in excess:
		var key: StringName = status_keys[i]
		p_buckets.erase(key)
		dropped.append(key)
	return dropped
