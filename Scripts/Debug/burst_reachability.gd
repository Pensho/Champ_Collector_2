class_name BurstReachability extends RefCounted

## Given three CharacterPreset instances and nothing else, enumerates every damaging skill
## across the team as a candidate burst resolution, composes
## Scripts/Debug/kit_contribution_manifest.gd's reachable Channel-2/3 contributions at each,
## and returns them ranked by total_contrast_ratio — every reachable channel counted, Channel 3
## included. Which champion bursts and which skill they burst with are OUTPUTS: every damaging
## skill on the team is scored, never assumed in advance.
##
## Three contract quantities. The first two are read straight off the real
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
##                                 fatter Channel-1 base.
## The third is what this file actually ranks and selects Best() by:
##   Total contrast ratio       - contrast_ratio plus repeat_contrast_ratio (Phase 5): the full
##                                 burst a candidate reaches, a separate-instance Channel-3
##                                 repeat included. Concept_Document.md 1.1.3 counts repetition
##                                 as part of what a burst is; ranking by contrast_ratio alone
##                                 would silently zero out every Channel-3 repeat mechanic's
##                                 contribution to which candidate is "best", since a repeat
##                                 cannot be folded into the single CombinedDamageModifier
##                                 product/contrast_ratio represent (see the third simplification
##                                 below) without breaking their own live-verified contract. This
##                                 file ranked by contrast_ratio alone through the end of
##                                 Plan_Itemization_Channels.md Phase 5's first pass — a real bug,
##                                 not a design choice, caught and fixed once a
##                                 separate-instance mechanic (the Sorcerer's repeat) actually
##                                 existed to expose it.
##
## Three stated simplifications:
##   - Manifest sources documented as an uncapped per-instance rate (Heap On's ramp,
##     Devour Blessing's bonus_per, an Opportunist debuff-count) are scored at the minimum
##     reachable count: exactly one instance/precondition satisfied. There is no battle
##     simulation here to count real ones; a live-verification pass against the actual
##     resolver, where the true count is whatever the fight produces, is the way to check this.
##   - Caster attributes are each preset's own base values (Character._attributes right
##     after InstantiateNew, no trait delta) — Channel-1 trait mutations (Arcane
##     Instability's stacks, Hemoclarity's Health-gated bonus) require an accumulated-stack
##     or battle-state assumption this function has no basis for, and the manifest already
##     tags them Channel1 precisely because they move an attribute rather than the modifier
##     product this function scores.
##   - A manifest entry's "reagent_gated_bonus" (the Sorcerer's repeat, the Alchemist's team
##     factor — Plan_Itemization_Channels.md Phase 3/4) is scored as though a reagent was
##     available to consume: there is no battle simulation here to know whether one actually
##     was, matching the two simplifications above. CandidateResult.reagent_assumed reports
##     whether this assumption was load-bearing for the score, per Phase 5's "reagent assumed
##     available" precondition axis — recording the assumption rather than leaving these
##     mechanics silently scored at zero. The two mechanics fold differently, per the
##     manifest's own "fold" field: the Alchemist's team factor lands in the SAME
##     CombinedDamageModifier as the candidate's own cast (Contribute()'d into
##     buckets/product, same as a granted_status); the Sorcerer's repeat is its own,
##     independent CombinedDamageModifier and damage resolution in the real resolver, so
##     folding it into product would make that field diverge from what the live-verification
##     suite checks against the real resolver — it is scored into repeat_contrast_ratio /
##     total_contrast_ratio instead, deliberately excluded from product/contrast_ratio but
##     fully counted in total_contrast_ratio, which is what Best()'s own ranking uses (see the
##     third contract quantity above).

const Manifest = preload("res://Scripts/Debug/kit_contribution_manifest.gd")
const BlowoutCalibration = preload("res://Scripts/Debug/blowout_calibration.gd")

## Below this many Enabler-classed manifest entries (passive + skills, summed across the
## team), a team is marked non-viable and excluded from ranked output — Concept_Document.md
## 1.1.3's Enabler class exists so a kit can spend its whole moveset setting a burst up
## rather than dealing damage itself, and a team with too few enablers has nothing to
## compose. The right floor is a design call made once real teams exist; 0 means nothing
## is excluded yet. Enabler count is reported on every row regardless.
const ENABLER_FLOOR: int = 0

## See "Two simplifications" above.
const ASSUMED_UNCAPPED_INSTANCES: int = 1

## Skill_Target groups that reach a candidate character when a teammate's manifest entry
## grants them a status (self, every-other-ally, everyone, or "anyone" for the single-target
## family, which is scored best-case just like the rest of this file's simplifications — see
## the header's "Two stated simplifications"). Mirrors the ally branches of
## Skills.FindSkillTargets (Scripts/Battle/skills.gd) — the runtime function itself needs a
## live Sides and character dictionary this scorer does not have, so the reachability rule is
## re-derived structurally here from the granting SkillEffect's own target instead of assumed.
const _SELF_ONLY_TARGETS: Array[Types.Skill_Target] = [Types.Skill_Target.Self]
const _OTHER_ALLIES_TARGETS: Array[Types.Skill_Target] = [
	Types.Skill_Target.All_Other_Allies, Types.Skill_Target.Ally_Not_Self]
const _ALL_ALLIES_TARGETS: Array[Types.Skill_Target] = [Types.Skill_Target.All_Allies, Types.Skill_Target.All]
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
	var reagent_assumed: bool
	## Damage from a "separate_instance" reagent-gated mechanic (the Sorcerer's repeat),
	## expressed as its own contrast ratio against the same basic-skill baseline and never
	## folded into product/contrast_ratio — see the manifest's reagent_gated_bonus field docs.
	## 0.0 when this candidate has no such contribution.
	var repeat_contrast_ratio: float = 0.0
	## contrast_ratio + repeat_contrast_ratio: the total burst this candidate's action deals
	## across both the original cast and its reagent-gated repeat, if any — the ranking key
	## Best()/candidate sorting uses (see TeamResult below). A Channel-3 repeat is part of what
	## "burst" means (Concept_Document.md 1.1.3's cascade definition) and must count toward it
	## the same as Channels 1 and 2, even though it cannot be folded into the single
	## CombinedDamageModifier product/contrast_ratio represent (see repeat_contrast_ratio's own
	## docs) — total_contrast_ratio is what puts it back in.
	var total_contrast_ratio: float = 0.0

## All candidates for one 3-preset team, ranked best (highest total_contrast_ratio, i.e. every
## reachable channel including a separate-instance repeat) first.
class TeamResult:
	var candidates: Array[CandidateResult] = []
	var enabler_count: int
	var is_viable: bool

	## This team's best reachable burst, total_contrast_ratio included — not necessarily the
	## candidate with the highest single-hit contrast_ratio, if some other candidate's
	## reagent-gated repeat pushes its total higher.
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

	# total_contrast_ratio, not contrast_ratio: a Channel-3 repeat is part of what "burst" means
	# (Concept_Document.md 1.1.3) and must be able to win Best() like any other channel, even
	# though it cannot be folded into the single-hit product/contrast_ratio pair those two
	# fields protect (see CandidateResult.total_contrast_ratio's own docs).
	result.candidates.sort_custom(
			func(a: CandidateResult, b: CandidateResult) -> bool: return a.total_contrast_ratio > b.total_contrast_ratio)
	return result


static func _HasDamageEffect(p_skill: Skill) -> bool:
	for effect in p_skill.effects:
		if(effect is DamageEffect and not (effect as DamageEffect).damage_scaling.is_empty()):
			return true
	return false


static func _ScaledAggregate(p_skill: Skill, p_character: Character) -> float:
	var total: float = 0.0
	for effect in p_skill.effects:
		if(effect is DamageEffect):
			var damage_effect: DamageEffect = effect
			for attribute: Types.Attribute in damage_effect.damage_scaling.keys():
				total += damage_effect.damage_scaling[attribute] * float(p_character._attributes[attribute])
	return total


## The character's cooldown-0 skill (Concept_Document.md 1.1.2's basic-skill baseline).
## Falls back to the first skill if the kit has no cooldown-0 entry — none currently do.
static func _BasicSkill(p_character: Character) -> Skill:
	for skill: Skill in p_character._skills:
		if(0 == skill.cooldown):
			return skill
	return p_character._skills[0] if not p_character._skills.is_empty() else null


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
## keys to (e.g. Cataclysmic Surge's "Warped"), if any — the one debuff Opportunist can be
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


## True for a reagent_gated_bonus dict that lands in the SAME CombinedDamageModifier as the
## candidate's own cast ("same_instance", the default) rather than a wholly separate damage
## resolution ("separate_instance", the Sorcerer's repeat) — see the manifest's field docs.
## Only a same_instance entry may ever be Contribute()'d into this candidate's own buckets.
static func _IsSameInstanceFold(p_bonus: Dictionary) -> bool:
	return "separate_instance" != p_bonus.get("fold", "same_instance")


## The candidate's own skill/passive-scoped reagent_gated_bonus (a same_instance fold only) —
## see the header's third stated simplification. Returns whether a contribution was made, so
## the caller can surface the assumption on CandidateResult.
static func _ContributeReagentGatedSkillBonus(p_buckets: Dictionary, p_entry: Dictionary) -> bool:
	var bonus: Dictionary = p_entry.get("reagent_gated_bonus", {})
	if(bonus.is_empty() or not _IsSameInstanceFold(bonus)):
		return false
	_Contribute(p_buckets, StringName(String(bonus.get("bucket_key", ""))), _MagnitudeFor(bonus))
	return true


## Team-reach reagent_gated_bonus entries (the Alchemist's Volatile Mixture factor): read off
## every teammate's own passive, not just the candidate's caster, because the mechanic
## broadcasts to the whole team including its own owner (fresh_batch_trait.gd:58-62's AlliesOf
## reach). Returns whether a contribution was made, so the caller can surface the assumption on
## CandidateResult.
static func _ContributeReagentGatedTeamBonuses(
		p_characters: Array[Character], p_buckets: Dictionary, p_manifest: Dictionary) -> bool:
	var contributed: bool = false
	for character in p_characters:
		var role_entry: Dictionary = p_manifest.get(character._role, {})
		var passive_entries: Array = role_entry.get("passive", [])
		if(passive_entries.is_empty()):
			continue
		var bonus: Dictionary = passive_entries[0].get("reagent_gated_bonus", {})
		if(bonus.is_empty() or not _IsSameInstanceFold(bonus) or "team" != bonus.get("reach", "")):
			continue
		_Contribute(p_buckets, StringName(String(bonus.get("bucket_key", ""))), _MagnitudeFor(bonus))
		contributed = true
	return contributed


## A "separate_instance" reagent_gated_bonus (the Sorcerer's repeat): the real resolver
## re-resolves the cast skill's DamageEffects as their own, independent CombinedDamageModifier
## and ResolveEffectDamage call, never folded into the original cast's own product — folding it
## in here would make CandidateResult.product diverge from what
## Tests/unit/test_burst_reachability_live.gd's replay of the real resolver assembles for the
## ORIGINAL cast alone. Approximated as the skill's own authored Channel2/3 bucket (if any)
## composed with the repeat's own factor, mitigated independently against the same baseline —
## deliberately excluding any team/granted factor (Volatile Mixture, Opportunist, ...), since
## those are already contributed to (and, for a DamageMultiplier buff, consumed by) the
## ORIGINAL cast in the real resolver (battle_resolver.gd:739-744's per-instance
## ConsumeDamageMultiplierFactors call) and would double-count here otherwise.
static func _ReagentGatedRepeatContrastRatio(
		p_skill_entry: Dictionary, p_skill_aggregate: float, p_defence: float, p_baseline_damage: float) -> float:
	var bonus: Dictionary = p_skill_entry.get("reagent_gated_bonus", {})
	if(bonus.is_empty() or _IsSameInstanceFold(bonus)):
		return 0.0
	var own_bucket_factor: float = 1.0
	if(Manifest.Contribution_Class.Channel2 == p_skill_entry.get("class") \
			or Manifest.Contribution_Class.Channel3_Cascade == p_skill_entry.get("class")):
		own_bucket_factor = 1.0 + _MagnitudeFor(p_skill_entry)
	var repeat_factor: float = 1.0 + _MagnitudeFor(bonus)
	var repeat_damage: float = Skills.MitigatedDamageUnrounded(
			p_defence, p_skill_aggregate * own_bucket_factor * repeat_factor, 1.0, 1.0)
	return repeat_damage / p_baseline_damage


## True if p_role's passive contribution actually applies when p_skill_index is the skill
## being cast — most Channel-2 passives in the manifest apply on any of their owner's
## casts, but three are gated to one specific trigger, per their own precondition text.
static func _PassiveApplies(p_role: Types.Role, p_skill: Skill, p_skill_index: int) -> bool:
	match p_role:
		# Chosen Vessel: "on any non-basic (cooldown > 0) Skill_Cast" (chosen_vessel_trait.gd:3-11).
		Types.Role.Cultist:
			return p_skill.cooldown > 0
		# Calibration: "Final Calculation consumes all charges" (calibration_trait.gd:67-75) —
		# skills[2] in the manifest's own Architect entry.
		Types.Role.Architect:
			return 2 == p_skill_index
		# Wrangle the Sea: "Corsairs Reckoning consumes all 3" (tidal_corsair_trait.gd:79-105) —
		# skills[2] in the manifest's own Tidal_Corsair entry.
		Types.Role.Tidal_Corsair:
			return 2 == p_skill_index
		_:
			return true


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
	var basic_aggregate: float = _ScaledAggregate(basic_skill, caster)
	if(0.0 == basic_aggregate):
		return null
	var skill_aggregate: float = _ScaledAggregate(p_skill, caster)

	var buckets: Dictionary = {}
	var caster_role_entry: Dictionary = p_manifest.get(caster._role, {})
	var caster_passive_entries: Array = caster_role_entry.get("passive", [])
	if(not caster_passive_entries.is_empty()):
		var passive_entry: Dictionary = caster_passive_entries[0]
		if(_PassiveApplies(caster._role, p_skill, p_skill_index)):
			_Contribute(buckets, StringName(String(passive_entry.get("bucket_key", ""))),
					_MagnitudeFor(passive_entry))
	if(Manifest.Contribution_Class.Channel2 == p_skill_entry.get("class") \
			or Manifest.Contribution_Class.Channel3_Cascade == p_skill_entry.get("class")):
		_Contribute(buckets, StringName(String(p_skill_entry.get("bucket_key", ""))),
				_MagnitudeFor(p_skill_entry))

	var reagent_assumed: bool = _ContributeReagentGatedSkillBonus(buckets, p_skill_entry)
	if(_ContributeReagentGatedTeamBonuses(p_characters, buckets, p_manifest)):
		reagent_assumed = true

	var anchor_debuff_key: StringName = _AnchorDebuffKey(p_skill_entry)
	_ContributeGrantedStatuses(p_characters, p_caster_index, buckets, anchor_debuff_key, p_manifest)

	var dropped: Array[StringName] = _EnforceStatusCap(buckets)

	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	for key: StringName in buckets:
		modifier.Contribute(key, buckets[key])
	var product: float = modifier.Product()

	var defence: float = BlowoutCalibration.BOSSES[0][2]
	# Unrounded core, not Skills.MitigatedDamage's own int(ceil(...)) — contrast_ratio and
	# modifier_term are ratios of these three, and rounding each one first would introduce a
	# quantization artifact the real single-roll formula does not have.
	var baseline_damage: float = Skills.MitigatedDamageUnrounded(defence, basic_aggregate, 1.0, 1.0)
	var modifier_only_damage: float = Skills.MitigatedDamageUnrounded(defence, basic_aggregate * product, 1.0, 1.0)
	var burst_damage: float = Skills.MitigatedDamageUnrounded(defence, skill_aggregate * product, 1.0, 1.0)
	var repeat_contrast_ratio: float = _ReagentGatedRepeatContrastRatio(
			p_skill_entry, skill_aggregate, defence, baseline_damage)
	if(0.0 != repeat_contrast_ratio):
		reagent_assumed = true

	var result: CandidateResult = CandidateResult.new()
	result.caster_index = p_caster_index
	result.caster_role = caster._role
	result.skill_name = p_skill.name
	result.skill_index = p_skill_index
	result.product = product
	result.base_term = skill_aggregate / basic_aggregate
	result.modifier_term = modifier_only_damage / baseline_damage
	result.contrast_ratio = burst_damage / baseline_damage
	result.buckets = buckets
	result.distinct_key_count = buckets.size()
	result.dropped_statuses = dropped
	result.enabler_count = p_enabler_count
	result.is_viable = p_is_viable
	result.reagent_assumed = reagent_assumed
	result.repeat_contrast_ratio = repeat_contrast_ratio
	result.total_contrast_ratio = result.contrast_ratio + repeat_contrast_ratio
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
## runtime. The first ApplyBuffEffect on the skill is the granting effect for all three
## manifest entries that carry a granted_status today; a skill with more than one ApplyBuffEffect
## would need a more specific selector than "first" here.
static func _GrantingEffectTarget(p_skill: Skill) -> Types.Skill_Target:
	for effect in p_skill.effects:
		if(effect is ApplyBuffEffect):
			var buff_effect: ApplyBuffEffect = effect
			return p_skill.target if Types.Skill_Target.Skill_Default == buff_effect.target else buff_effect.target
	return p_skill.target


## True if a status granted by p_granter's p_granting_skill reaches p_candidate_index, given
## p_granter is at p_granter_index — derived from the granting effect's own Skill_Target
## rather than assumed. See the _..._TARGETS group constants above for the mapping; the
## single-target-family case (Single_Ally, Random_Ally, Most_Injured_Ally, Most_Buffed_Ally)
## is scored best-case ("anyone"), consistent with this file's other stated simplifications.
static func _GrantReachesCandidate(
		p_granting_skill: Skill, p_granter_index: int, p_candidate_index: int) -> bool:
	var target: Types.Skill_Target = _GrantingEffectTarget(p_granting_skill)
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
			var granting_skill: Skill = granter._skills[skill_index]
			if(not _GrantReachesCandidate(granting_skill, granter_index, p_candidate_index)):
				continue
			if(grant.get("per_debuff_anchored", false)):
				if(&"" != p_anchor_debuff_key):
					_Contribute(p_buckets, p_anchor_debuff_key,
							grant.get("magnitude", 0.0) * float(ASSUMED_UNCAPPED_INSTANCES))
			else:
				_Contribute(p_buckets, StringName(String(grant.get("bucket_key", ""))), grant.get("magnitude", 0.0))


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
