extends GutTest

## Live verification of Scripts/Debug/kit_contribution_manifest.gd. The manifest is
## hand-derived; every number Scripts/Debug/burst_reachability.gd produces rests on it
## being right. These tests replay a representative team through the REAL BattleResolver
## (no formula reproduced here — the same pattern
## Tests/unit/test_combined_damage_modifier_resolution.gd uses: state is placed directly
## rather than simulated turn-by-turn) and compare the CombinedDamageModifier the resolver
## actually assembles against what the manifest predicts. A divergence here is a manifest
## bug, to be fixed in the manifest — not explained away in this file.
##
## Row-driven: LIVE_CASES names each case and the setup method (by name, since GDScript
## cannot hold a Callable in a const) that exercises it. GUT reports a loop as one test, so
## every assert inside a case method carries its own case name in the message — otherwise a
## failure would be unattributable to which row broke.

const SORCERER = preload("res://Data/Character_Player_Variants/Sorcerer.tres")
const TIDAL_CORSAIR = preload("res://Data/Character_Player_Variants/Tidal_Corsair.tres")
const BAR_BRAWLER = preload("res://Data/Character_Player_Variants/Bar_Brawler.tres")
const THIEF = preload("res://Data/Character_Player_Variants/Thief.tres")
const WARLORD = preload("res://Data/Character_Player_Variants/Warlord.tres")
const TACTICIAN = preload("res://Data/Character_Player_Variants/Tactician.tres")
const CHRONOPHAGE = preload("res://Data/Character_Player_Variants/Chronophage.tres")
const EMISSARY = preload("res://Data/Character_Player_Variants/Emissary.tres")
const CENTAUR_LANCER = preload("res://Data/Character_Player_Variants/Centaur_Lancer.tres")
const ALCHEMIST = preload("res://Data/Character_Player_Variants/Alchemist.tres")
const JESTER = preload("res://Data/Character_Player_Variants/Jester.tres")
const CULTIST = preload("res://Data/Character_Player_Variants/Cultist.tres")
const BLOODMAGE = preload("res://Data/Character_Player_Variants/Bloodmage.tres")
const ARCHITECT = preload("res://Data/Character_Player_Variants/Architect.tres")
const PLAGUE_DOCTOR = preload("res://Data/Character_Player_Variants/Plague_Doctor.tres")
const HERALD = preload("res://Data/Character_Player_Variants/Herald_of_the_loom.tres")
const CENTAUR_ARCHIVIST = preload("res://Data/Character_Player_Variants/Centaur_Archivist.tres")
const DIVINER = preload("res://Data/Character_Player_Variants/Diviner.tres")
const APPRAISER = preload("res://Data/Character_Player_Variants/Appraiser.tres")
const SYMBIOTE = preload("res://Data/Character_Player_Variants/Symbiote.tres")

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

## Each row names the case (surfaced in every assert message inside its setup method, since
## GUT folds this whole loop into one test) and the setup method's name — GDScript cannot
## hold a Callable in a const, so it is bound at call time via Callable(self, row["setup"]).
const LIVE_CASES: Array[Dictionary] = [
	{"name": "Sorcerer Cataclysm (bonus_per_debuff bucket + anchored granted status + distinct-key grant)",
			"setup": "_case_cataclysm"},
	{"name": "Tidal Corsair Corsairs Reckoning (shared trait_resource key)", "setup": "_case_corsairs_reckoning"},
	{"name": "Bar Brawler Heap On (ramp key, real battle use count)", "setup": "_case_heap_on"},
	{"name": "Thief Cut Purse (Self-scoped grant must not reach a different caster)",
			"setup": "_case_thief_self_scope"},
	{"name": "Tactician Fatal Flaw (All_Other_Allies grant must not reach the granter)",
			"setup": "_case_tactician_all_other_allies"},
	# --- Tier 1: the remaining bucket-bearing Roles (12 total; Sorcerer, Tidal Corsair,
	# Bar Brawler and Tactician already covered above) ---
	{"name": "Emissary Citation (Standing Record's 9-Infraction ceiling)", "setup": "_case_emissary_citation"},
	{"name": "Lancer Rending Charge (Couched Lance turn-bar span)", "setup": "_case_lancer_rending_charge"},
	{"name": "Alchemist Fresh Batch (Volatile Mixture from a real reagent consumption)",
			"setup": "_case_alchemist_volatile_mixture"},
	{"name": "Jester Pratfall Sting (avoidance-flagged bonus)", "setup": "_case_jester_pratfall_sting"},
	{"name": "Cultist Chosen Vessel and Devotion (living-Vessel bucket, then a Vessel's death)",
			"setup": "_case_cultist_chosen_vessel_and_devotion"},
	{"name": "Bloodmage Tithe of Vitality (Wounded_Allies bonus_per)", "setup": "_case_bloodmage_tithe_of_vitality"},
	{"name": "Architect Calibration (12 Cornerstone casts into Final Calculation)",
			"setup": "_case_architect_calibration"},
	{"name": "Plague Doctor Outbreak (Target_Debuff_Count bonus_per at the minimum reachable count)",
			"setup": "_case_plague_doctor_outbreak"},
	# --- Tier 2: instance counts (a repeat mechanic's real resolution count) ---
	{"name": "Herald of the Loom Cut the Cloth (7 Tension into 8 total resolutions)",
			"setup": "_case_herald_cut_the_cloth_instances"},
	{"name": "Sorcerer Arc Lash (one Echo charge into 2 total resolutions)",
			"setup": "_case_sorcerer_echo_instances"},
	{"name": "Chronophage Borrowed Time (an ally alone in its section gains a second resolution)",
			"setup": "_case_chronophage_borrowed_time_instances"},
	# --- Tier 3: the bucketless Roles ---
	{"name": "Thief Stab (no phantom bucket; defence_ignore.rate matches the real trait)",
			"setup": "_case_thief_no_phantom_bucket"},
	{"name": "Scholar Sharp Rebuttal (no phantom bucket; attribute_amplification matches the real trait)",
			"setup": "_case_scholar_no_phantom_bucket"},
	{"name": "Diviner Fateful Glimpse (no phantom bucket)", "setup": "_case_diviner_no_phantom_bucket"},
	{"name": "Appraiser Sizing Cut (no phantom bucket; crit_overflow_rate matches the real trait)",
			"setup": "_case_appraiser_no_phantom_bucket"},
	{"name": "Warlord Shield Slam (no phantom bucket; granted_attribute_buff magnitudes match the real statuses)",
			"setup": "_case_warlord_no_phantom_bucket"},
	{"name": "Symbiote Spore Lash (no phantom bucket; base trait is still a placeholder)",
			"setup": "_case_symbiote_no_phantom_bucket"},
]

func test_live_cases_match_the_real_resolver() -> void:
	for row: Dictionary in LIVE_CASES:
		Callable(self, String(row["setup"])).call(String(row["name"]))

func _sorcerer_scholar_tactician() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = [
		SORCERER,
		preload("res://Data/Character_Player_Variants/Centaur_Archivist.tres"),
		preload("res://Data/Character_Player_Variants/Tactician.tres"),
	]
	return presets

func _corsair_cultist_warlord() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = [
		TIDAL_CORSAIR,
		preload("res://Data/Character_Player_Variants/Cultist.tres"),
		preload("res://Data/Character_Player_Variants/Warlord.tres"),
	]
	return presets

func _sorcerer_thief_warlord() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = [SORCERER, THIEF, WARLORD]
	return presets

func _tactician_warlord_chronophage() -> Array[CharacterPreset]:
	var presets: Array[CharacterPreset] = [TACTICIAN, WARLORD, CHRONOPHAGE]
	return presets

func _high_health_target() -> Character:
	var target: Character = TestFactory.make_character()
	target._attributes[Types.Attribute.Health] = 100000
	target._current_health = 100000
	target._attributes[Types.Attribute.Defence] = 50
	return target

## The first REAL attack's Damage result — skips a Damage-kind CombatResult with no
## modifier at all, the shape a side-effect health loss (Chosen Vessel's own-Vessel drain,
## Tithe of Vitality's ally cost) posts ahead of the skill's actual DamageEffect resolution.
func _first_damage_modifier(p_results: Array[CombatResult]) -> CombinedDamageModifier:
	for result in p_results:
		if(CombatResult.Kind.Damage == result.kind and null != result.combined_damage_modifier):
			return result.combined_damage_modifier
	return null

func _skill_index(p_character: Character, p_skill_name: String) -> int:
	for i in p_character._skills.size():
		if(p_skill_name == p_character._skills[i].name):
			return i
	return -1

## Shared roster wiring: one Character per preset (Critical Chance zeroed so crit does not
## perturb a product comparison) plus a fixed high-health target at index 3, so no case row
## repeats this setup.
func _build_roster(p_presets_by_index: Dictionary[int, CharacterPreset]) -> Dictionary[int, Character]:
	var roster: Dictionary[int, Character] = {}
	for index: int in p_presets_by_index:
		var character: Character = Character.new()
		character.InstantiateNew(p_presets_by_index[index], index)
		character._attributes[Types.Attribute.CritChance] = 0
		roster[index] = character
	roster[3] = _high_health_target()
	return roster

func _resolver_for(p_roster: Dictionary[int, Character], p_attacker_indices: Array[int]) -> BattleResolver:
	return TestFactory.make_resolver(p_roster, CombatSides.new(p_attacker_indices, [3]))

# --- Shape 1: skill's own bonus_per_debuff_on_target bucket, a per-debuff-anchored granted
# status landing in that SAME bucket, and a granted DamageMultiplier bucket in a distinct key ---

func _case_cataclysm(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: SORCERER})
	var sorcerer: Character = roster[0]
	# Scholar's Expose Fallacy grants All Allies Opportunist; Tactician's Fatal Flaw grants
	# one ally Daunting Strength — both land on the Sorcerer directly here rather than being
	# produced by actually casting those two skills first, per this file's stated pattern.
	var opportunist: StatusEffects.Buff = StatusEffects.Buff.new()
	opportunist.type = Types.Buff_Type.Opportunist
	opportunist.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Opportunist).magnitude
	opportunist.duration = 2
	sorcerer._active_buffs.append(opportunist)
	var daunting_strength: StatusEffects.Buff = StatusEffects.Buff.new()
	daunting_strength.type = Types.Buff_Type.Daunting_Strength
	daunting_strength.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Daunting_Strength).magnitude
	daunting_strength.duration = 1
	sorcerer._active_buffs.append(daunting_strength)

	var target: Character = roster[3]
	var warped: StatusEffects.Debuff = StatusEffects.Debuff.new()
	warped.type = Types.Debuff_Type.Warped
	warped.duration = 2
	target._active_debuffs.append(warped)

	var resolver: BattleResolver = _resolver_for(roster, [0])
	var cataclysm_index: int = _skill_index(sorcerer, "Cataclysm")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], cataclysm_index))
	assert_not_null(modifier, "%s: Cataclysm against a living target must produce a Damage result" % p_name)

	var predicted: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(
			_sorcerer_scholar_tactician()).Pinned(0, "Cataclysm")
	assert_not_null(predicted, "%s: The scorer must produce a pinned Cataclysm candidate to compare against" % p_name)
	assert_almost_eq(modifier.Product(), predicted.product, 0.0001,
			"%s: The real resolver's composed product must match the manifest-derived prediction " %
			p_name + "for this precondition set")
	assert_almost_eq(modifier.Product(), 2.8, 0.01,
			"%s: Regression guard: this is the same 2.8x pinned in test_burst_reachability.gd" % p_name)

# --- Shape 2: the shared trait_resource key, fed by internal trait stack state rather than
# a StatusEffects buff/debuff ---

func _case_corsairs_reckoning(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: TIDAL_CORSAIR})
	var tidal_corsair: Character = roster[0]
	# The manifest's magnitudes are stated at Legendary; the shipped preset is Uncommon, so
	# the trait is re-initialized at Legendary before any cast fills a stack, the same way a
	# Legendary-rarity copy of this champion would behave.
	tidal_corsair._rarity = Types.Rarity.Legendary
	tidal_corsair._trait.Init(Types.Rarity.Legendary)

	var resolver: BattleResolver = _resolver_for(roster, [0])
	var boarding_strike_index: int = _skill_index(tidal_corsair, "Boarding Strike")
	var corsairs_reckoning_index: int = _skill_index(tidal_corsair, "Corsairs Reckoning")
	for i in 3:
		resolver.ResolveSkill(0, [3], boarding_strike_index)
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], corsairs_reckoning_index))
	assert_not_null(modifier, "%s: Corsairs Reckoning against a living target must produce a Damage result" % p_name)

	var predicted: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(
			_corsair_cultist_warlord()).Pinned(0, "Corsairs Reckoning")
	assert_not_null(predicted,
			"%s: The scorer must produce a pinned Corsairs Reckoning candidate to compare against" % p_name)
	assert_almost_eq(modifier.Product(), predicted.product, 0.0001,
			"%s: The real resolver's composed product must match the manifest-derived prediction " %
			p_name + "for three filled Steel stacks")
	assert_almost_eq(modifier.Product(), 2.8, 0.01,
			"%s: Regression guard: this is the same 2.8x pinned in test_burst_reachability.gd" % p_name)

# --- Shape 3: the ramp key, 0-indexed by actual battle use count ---

func _case_heap_on(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: BAR_BRAWLER})
	var bar_brawler: Character = roster[0]

	var resolver: BattleResolver = _resolver_for(roster, [0])
	var heap_on_index: int = _skill_index(bar_brawler, "Heap On")
	# First cast: use_count 0, ramp_multiplier 1.0, contributes nothing to the bucket. Second
	# cast: use_count 1, the "one instance satisfied" state burst_reachability.gd's manifest
	# reading assumes as the minimum reachable count.
	resolver.ResolveSkill(0, [3], heap_on_index)
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], heap_on_index))
	assert_not_null(modifier, "%s: Heap On against a living target must produce a Damage result" % p_name)

	var bar_brawler_skills: Array = KitContributionManifest.MANIFEST[Types.Role.Bar_Brawler]["skills"]
	var declared_rate: float = bar_brawler_skills[heap_on_index]["magnitude"]
	assert_almost_eq(modifier.Buckets()[&"Heap On (ramp)"], declared_rate, 0.0001,
			"%s: The manifest's declared per-instance ramp rate must match what one prior use " %
			p_name + "actually contributes to the ramp bucket")

# --- Shape 4: a granted status's real target scope (Skill_Target), replaying the actual
# granting skill through the resolver rather than placing the buff directly on whichever
# character is convenient — the only way to catch a scope bug like the one that shipped:
# neither a Self grant (Thief's Cut Purse) nor an All_Other_Allies grant (Tactician's Fatal
# Flaw) previously excluded the granter's own resolution when the scorer composed them ---

func _case_thief_self_scope(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: SORCERER, 1: THIEF, 2: WARLORD})
	var sorcerer: Character = roster[0]
	var thief: Character = roster[1]

	var target: Character = roster[3]
	var warped: StatusEffects.Debuff = StatusEffects.Debuff.new()
	warped.type = Types.Debuff_Type.Warped
	warped.duration = 2
	target._active_debuffs.append(warped)

	var resolver: BattleResolver = _resolver_for(roster, [0, 1, 2])

	# Cut Purse's Opportunist grant targets Self, independent of the skill's own enemy
	# target — cast it against the living boss exactly as a real cast would, via the same
	# caster-relative resolution burst_reachability.gd's own _GrantReachesCandidate mirrors.
	var cut_purse_index: int = _skill_index(thief, "Cut Purse")
	resolver.ResolveSkill(1, [3], cut_purse_index)
	assert_true(
			thief._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Opportunist == b.type),
			"%s: Cut Purse must actually grant the Thief itself Opportunist" % p_name)

	var cataclysm_index: int = _skill_index(sorcerer, "Cataclysm")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], cataclysm_index))
	assert_not_null(modifier, "%s: Cataclysm against a living target must produce a Damage result" % p_name)

	var predicted: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(
			_sorcerer_thief_warlord()).Pinned(0, "Cataclysm")
	assert_not_null(predicted, "%s: The scorer must produce a pinned Cataclysm candidate to compare against" % p_name)
	assert_almost_eq(modifier.Product(), predicted.product, 0.0001,
			"%s: The real resolver's composed product must match the manifest-derived prediction" % p_name)
	assert_almost_eq(modifier.Product(), 1.3, 0.0001,
			"%s: Only Cataclysm's own Warped bucket (0.3) must land: the Thief's Self-scoped " %
			p_name + "Opportunist must NOT reach the Sorcerer, a different character")


func _case_tactician_all_other_allies(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: TACTICIAN, 1: WARLORD, 2: CHRONOPHAGE})
	var tactician: Character = roster[0]
	var warlord: Character = roster[1]

	var sides: CombatSides = CombatSides.new([0, 1, 2], [3])
	var resolver: BattleResolver = TestFactory.make_resolver(roster, sides)

	# Fatal Flaw's own target is All_Other_Allies — grant it exactly as a real cast would,
	# via the same caster-relative resolution (every ally but the caster).
	var fatal_flaw_index: int = _skill_index(tactician, "Fatal Flaw")
	var other_ally_targets: Array[int] = Skills.FindSkillTargets(
			0, 0, Types.Skill_Target.All_Other_Allies, resolver.GetCharacters(), sides)
	resolver.ResolveSkill(0, other_ally_targets, fatal_flaw_index)
	assert_true(
			warlord._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Daunting_Strength == b.type),
			"%s: Fatal Flaw must grant a teammate (Warlord) Daunting Strength" % p_name)
	assert_false(
			tactician._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Daunting_Strength == b.type),
			"%s: Fatal Flaw's All_Other_Allies target must NOT grant the Tactician itself Daunting Strength" % p_name)

	var signal_strike_index: int = _skill_index(tactician, "Signal Strike")
	var tactician_modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], signal_strike_index))
	assert_not_null(tactician_modifier, "%s: Signal Strike against a living target must produce a Damage result" % p_name)

	var shield_slam_index: int = _skill_index(warlord, "Shield Slam")
	var warlord_modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(1, [3], shield_slam_index))
	assert_not_null(warlord_modifier, "%s: Shield Slam against a living target must produce a Damage result" % p_name)

	var predicted: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_tactician_warlord_chronophage())
	var predicted_tactician: BurstReachability.CandidateResult = predicted.Pinned(0, "Signal Strike")
	var predicted_warlord: BurstReachability.CandidateResult = predicted.Pinned(1, "Shield Slam")
	assert_not_null(predicted_tactician, "%s: The scorer must produce a pinned Signal Strike candidate" % p_name)
	assert_not_null(predicted_warlord, "%s: The scorer must produce a pinned Shield Slam candidate" % p_name)

	assert_almost_eq(tactician_modifier.Product(), predicted_tactician.product, 0.0001,
			"%s: The real resolver's Tactician-own product must match the manifest-derived prediction" % p_name)
	assert_almost_eq(tactician_modifier.Product(), 1.0, 0.0001,
			"%s: The Tactician's own resolution must be untouched by its own All_Other_Allies grant" % p_name)
	assert_almost_eq(warlord_modifier.Product(), predicted_warlord.product, 0.0001,
			"%s: The real resolver's Warlord product must match the manifest-derived prediction" % p_name)
	assert_almost_eq(warlord_modifier.Product(), 2.0, 0.0001,
			"%s: A teammate other than the granter must actually receive Daunting Strength (1.0 -> 2.0x)" % p_name)

# --- Shared helpers for the rows below ---

## Re-Inits p_character's trait at Legendary — needed only for a role whose declared
## manifest magnitude is itself rarity-scaled (looked up from the trait's own dictionary
## constants), as opposed to a fixed value authored directly on a .tres. InstantiateNew
## already Init'd the trait at the preset's own (possibly lower) rarity.
func _pin_legendary(p_character: Character) -> void:
	p_character._rarity = Types.Rarity.Legendary
	p_character._trait.Init(Types.Rarity.Legendary)

## True if every bucket in p_modifier carries a 0.0 magnitude — the real resolver's own
## CombinedDamageModifier.Contribute stores a zero contribution rather than skipping it (the
## skill's own name key, BetweenThePlatesTrait, reagent_damage_bonus are always present),
## unlike the scorer's own _Contribute, which filters 0.0 out. Product() == 1.0 alone does not
## rule out a phantom NONZERO bucket if a second nonzero bucket cancelled it, so this checks
## the buckets themselves rather than relying on the product alone.
func _all_bucket_values_zero(p_modifier: CombinedDamageModifier) -> bool:
	for key: StringName in p_modifier.Buckets():
		if(0.0 != p_modifier.Buckets()[key]):
			return false
	return true

## A generic ally at p_health_fraction of its own max Health — Bloodmage's Wounded_Allies
## count needs teammates below 50%, not any specific Role's kit.
func _wounded_ally(p_health_fraction: float) -> Character:
	var ally: Character = TestFactory.make_character()
	ally._current_health = int(float(ally._attributes[Types.Attribute.Health]) * p_health_fraction)
	return ally

# --- Tier 1: Emissary — Standing Record's Infraction ceiling on Citation ---

func _case_emissary_citation(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: EMISSARY})
	var emissary: Character = roster[0]
	_pin_legendary(emissary)
	var standing_record: StandingRecordTrait = emissary._trait as StandingRecordTrait
	var resolver: BattleResolver = _resolver_for(roster, [0])
	standing_record.StartOfBattle(0, resolver)

	# 8 distinct buffs (MAX_STATUS_EFFECTS is 8, so a 9th application to the same target
	# would collide with the shared cap) plus one zone placement — both count toward the
	# Infraction tally, per standing_record_trait.gd's own _OnResultProduced.
	var buff_types: Array[Types.Buff_Type] = [
		Types.Buff_Type.Empower, Types.Buff_Type.Fortify, Types.Buff_Type.Daunting_Strength,
		Types.Buff_Type.Phalanx_Guard, Types.Buff_Type.Attune, Types.Buff_Type.Haste,
		Types.Buff_Type.True_Aim, Types.Buff_Type.Clarity,
	]
	for buff_type: Types.Buff_Type in buff_types:
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = buff_type
		buff.duration = 2
		resolver.GetStatusResolver().ApplyBuff(3, buff)
	TestFactory.place_zone(
			resolver, 0, 3, TestFactory.make_zone_effect(1), Types.Skill_Target.ZoneEnemy, "Test Zone")
	assert_eq(standing_record.GetInfractions(3), 9,
			"%s: 8 distinct buffs plus one zone placement must reach the 9-Infraction ceiling" % p_name)

	var citation_index: int = _skill_index(emissary, "Citation")
	var modifier: CombinedDamageModifier = _first_damage_modifier(resolver.ResolveSkill(0, [3], citation_index))
	assert_not_null(modifier, "%s: Citation against a living target must produce a Damage result" % p_name)
	var declared: float = KitContributionManifest.MANIFEST[Types.Role.Emissary]["skills"][0]["magnitude"]
	assert_almost_eq(modifier.Buckets().get(&"Citation", 0.0), declared, 0.001,
			"%s: the real Citation bucket at 9 Infractions must match the manifest's declared ceiling" % p_name)

# --- Tier 1: Lancer — Couched Lance's turn-bar span, driven through FakeTurnPositions ---

func _case_lancer_rending_charge(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: CENTAUR_LANCER})
	var lancer: Character = roster[0]
	_pin_legendary(lancer)

	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	# Span = |owner_section - target_section| + 1 (lancer_trait.gd): sections 0 and 2
	# give a 3-section span, matching step 5's pinned 0.54 (3 * 0.18 at Legendary).
	positions.sections_by_character = {0: 0, 3: 2}
	var resolver: BattleResolver = TestFactory.make_resolver(
			{0: lancer, 3: _high_health_target()}, CombatSides.new([0], [3]), positions)

	var rending_charge_index: int = _skill_index(lancer, "Rending Charge")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], rending_charge_index))
	assert_not_null(modifier, "%s: Rending Charge against a living target must produce a Damage result" % p_name)
	var declared: float = (
			KitContributionManifest.MANIFEST[Types.Role.Lancer]["skills"][2]["gated_bonus"]["magnitude"])
	assert_almost_eq(modifier.Buckets().get(&"Rending Charge", 0.0), declared, 0.001,
			"%s: a real 3-section span must reproduce step 5's pinned 0.54 magnitude" % p_name)

# --- Tier 1: Alchemist — Volatile Mixture from an actual reagent consumption ---

func _case_alchemist_volatile_mixture(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: ALCHEMIST})
	var alchemist: Character = roster[0]
	_pin_legendary(alchemist)
	var resolver: BattleResolver = _resolver_for(roster, [0])

	resolver.ResolveReagent(0, "Restorative_Draught_Rare", 0)
	assert_true(
			alchemist._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Volatile_Mixture == b.type),
			"%s: consuming a reagent must grant the Alchemist itself Volatile Mixture" % p_name)

	var acrid_splash_index: int = _skill_index(alchemist, "Acrid Splash")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], acrid_splash_index))
	assert_not_null(modifier, "%s: Acrid Splash against a living target must produce a Damage result" % p_name)
	var declared: float = (
			KitContributionManifest.MANIFEST[Types.Role.Alchemist]["passive"][0]["gated_bonus"]["magnitude"])
	assert_almost_eq(modifier.Buckets().get(&"Volatile_Mixture", 0.0), declared, 0.001,
			"%s: a real reagent consumption's Volatile Mixture bucket must match the manifest's Legendary rate" %
			p_name)

# --- Tier 1: Jester — Pratfall Sting's avoidance-flagged bonus ---

func _case_jester_pratfall_sting(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: JESTER})
	var jester: Character = roster[0]
	var resolver: BattleResolver = _resolver_for(roster, [0])
	# The avoidance roll itself is covered by test_double_the_fun_trait.gd; this row only
	## needs the flag set, per the plan's own guidance on driving this case.
	(jester._trait as DoubleTheFunTrait)._avoided_since_last_turn = true

	var pratfall_sting_index: int = _skill_index(jester, "Pratfall Sting")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], pratfall_sting_index))
	assert_not_null(modifier, "%s: Pratfall Sting against a living target must produce a Damage result" % p_name)
	var declared: float = KitContributionManifest.MANIFEST[Types.Role.Jester]["skills"][0]["magnitude"]
	assert_almost_eq(modifier.Buckets().get(&"Pratfall Sting", 0.0), declared, 0.001,
			"%s: an avoidance-flagged cast must reproduce the manifest's declared +30%%" % p_name)

# --- Tier 1: Cultist — Chosen Vessel's living-Vessel bucket, then Devotion after a death ---

func _case_cultist_chosen_vessel_and_devotion(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: CULTIST, 1: WARLORD})
	var cultist: Character = roster[0]
	_pin_legendary(cultist)
	var chosen_vessel: ChosenVesselTrait = cultist._trait as ChosenVesselTrait
	var resolver: BattleResolver = _resolver_for(roster, [0, 1])
	# The sole living ally becomes the Vessel — Chosen Vessel's own StartOfBattle, not run
	# by InstantiateNew, must be driven explicitly (standing_record_trait.gd's own tests
	# follow the same pattern).
	chosen_vessel.StartOfBattle(0, resolver)

	var rite_of_severance_index: int = _skill_index(cultist, "Rite of Severance")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], rite_of_severance_index))
	assert_not_null(modifier, "%s: Rite of Severance against a living target must produce a Damage result" % p_name)
	var declared_trait_resource: float = (
			KitContributionManifest.MANIFEST[Types.Role.Cultist]["passive"][0]["magnitude"])
	assert_almost_eq(modifier.Buckets().get(CombinedDamageModifier.TRAIT_RESOURCE_KEY, 0.0),
			declared_trait_resource, 0.001,
			"%s: a non-basic cast with a living Vessel must land the manifest's declared trait_resource bonus" %
			p_name)

	resolver.SetCurrentHealth(1, 0)
	var declared_devotion: float = (
			KitContributionManifest.MANIFEST[Types.Role.Cultist]["passive"][0]["gated_bonus"]["magnitude"])
	assert_almost_eq(chosen_vessel.GetOutgoingDamageBonus(0, 3, resolver), declared_devotion, 0.001,
			"%s: a real Vessel death must grant Devotion's declared permanent bonus" % p_name)

# --- Tier 1: Bloodmage — Tithe of Vitality's Wounded_Allies bonus_per ---

func _case_bloodmage_tithe_of_vitality(p_name: String) -> void:
	var bloodmage: Character = Character.new()
	bloodmage.InstantiateNew(BLOODMAGE, 0)
	bloodmage._attributes[Types.Attribute.CritChance] = 0
	var wounded_1: Character = _wounded_ally(0.3)
	var wounded_2: Character = _wounded_ally(0.4)
	var roster: Dictionary[int, Character] = {0: bloodmage, 1: wounded_1, 2: wounded_2, 3: _high_health_target()}
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0, 1, 2], [3]))

	var tithe_index: int = _skill_index(bloodmage, "Tithe of Vitality")
	var modifier: CombinedDamageModifier = _first_damage_modifier(resolver.ResolveSkill(0, [3], tithe_index))
	assert_not_null(modifier, "%s: Tithe of Vitality against a living target must produce a Damage result" % p_name)
	var declared: float = KitContributionManifest.MANIFEST[Types.Role.Bloodmage]["skills"][2]["magnitude"]
	assert_almost_eq(modifier.Buckets().get(&"Tithe of Vitality", 0.0), declared, 0.001,
			"%s: two wounded allies must reproduce the manifest's declared 0.70 (2 * 0.35)" % p_name)

# --- Tier 1: Architect — 12 Cornerstone casts feeding Final Calculation's Calibration charge ---

func _case_architect_calibration(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: ARCHITECT})
	var architect: Character = roster[0]
	_pin_legendary(architect)
	var resolver: BattleResolver = _resolver_for(roster, [0])

	var cornerstone_index: int = _skill_index(architect, "Cornerstone")
	for i in 12:
		resolver.ResolveSkill(0, [3], cornerstone_index)

	var final_calculation_index: int = _skill_index(architect, "Final Calculation")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], final_calculation_index))
	assert_not_null(modifier, "%s: Final Calculation against a living target must produce a Damage result" % p_name)
	var declared: float = (
			KitContributionManifest.MANIFEST[Types.Role.Architect]["passive"][0]["magnitude"])
	assert_almost_eq(modifier.Buckets().get(CombinedDamageModifier.TRAIT_RESOURCE_KEY, 0.0), declared, 0.001,
			"%s: 12 real basic casts must reproduce the manifest's declared 12-charge ceiling (0.84)" % p_name)

# --- Tier 1: Plague Doctor — Outbreak's Target_Debuff_Count bonus_per at the minimum count ---

func _case_plague_doctor_outbreak(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: PLAGUE_DOCTOR})
	var plague_doctor: Character = roster[0]
	var resolver: BattleResolver = _resolver_for(roster, [0])

	# Against a target with no pre-existing debuff, Outbreak's own newly-applied Plague
	# stack (its debuff effect resolves before its damage effect) is the one distinct
	# debuff counted — the "assume the minimum reachable count" shape burst_reachability.gd's
	# header names, reproduced here rather than assumed.
	var outbreak_index: int = _skill_index(plague_doctor, "Outbreak")
	var modifier: CombinedDamageModifier = _first_damage_modifier(resolver.ResolveSkill(0, [3], outbreak_index))
	assert_not_null(modifier, "%s: Outbreak against a living target must produce a Damage result" % p_name)
	var declared: float = KitContributionManifest.MANIFEST[Types.Role.Plague_Doctor]["skills"][1]["magnitude"]
	assert_almost_eq(modifier.Buckets().get(&"Outbreak", 0.0), declared, 0.001,
			"%s: Outbreak's own freshly-applied Plague stack must be the one counted debuff" % p_name)

# --- Tier 2: Herald of the Loom — Cut the Cloth's Tension-driven instance count ---

func _case_herald_cut_the_cloth_instances(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: HERALD})
	var herald: Character = roster[0]
	_pin_legendary(herald)
	var weft_and_warp: WeftAndWarpTrait = herald._trait as WeftAndWarpTrait
	var resolver: BattleResolver = _resolver_for(roster, [0])
	weft_and_warp.StartOfBattle(0, resolver)

	# Legendary starts at 1 Tension; three Pull the Thread casts (+2 each) reach the
	# TENSION_MAX of 7, matching test_cut_the_cloth_manifest_entry_reproduces_its_
	# projected_legendary_curve's own 8-instance ceiling (1 base cast + 7 Tension).
	var pull_the_thread_index: int = _skill_index(herald, "Pull the Thread")
	for i in 3:
		resolver.ResolveSkill(0, [3], pull_the_thread_index)

	var cut_the_cloth_index: int = _skill_index(herald, "Cut the Cloth")
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], cut_the_cloth_index)
	var damage_count: int = 0
	for result: CombatResult in results:
		if(CombatResult.Kind.Damage == result.kind):
			damage_count += 1
	assert_eq(damage_count, 8,
			"%s: 7 Tension must produce 8 total resolutions (1 base cast + 7), the manifest's declared ceiling" %
			p_name)

# --- Tier 2: Sorcerer — one Echo charge doubling Arc Lash's resolution count ---

func _case_sorcerer_echo_instances(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: SORCERER})
	var sorcerer: Character = roster[0]
	var resolver: BattleResolver = _resolver_for(roster, [0])
	# The Echo repeat's own cascade listener is registered in StartOfBattle, not
	# InstantiateNew — without this, Skill_Resolved has no subscriber and the repeat
	# never fires regardless of how many charges are banked.
	(sorcerer._trait as SorcererTrait).StartOfBattle(0, resolver)

	# One reagent consumption grants exactly one Echo charge (sorcerer_trait.gd's
	# OnReagentConsumed) without also crossing the 5-stack Surge threshold — a reduced,
	# structurally faithful proof of the repeat mechanism (N charges -> N+1 resolutions)
	# rather than a reproduction of Role_Kit_Design.md 9.3's full 4-charge figure, which
	# would also trigger a Surge and complicate the resolution count.
	resolver.ResolveReagent(0, "Restorative_Draught_Rare", 0)

	var arc_lash_index: int = _skill_index(sorcerer, "Arc Lash")
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], arc_lash_index)
	var damage_count: int = 0
	for result: CombatResult in results:
		if(CombatResult.Kind.Damage == result.kind):
			damage_count += 1
	assert_eq(damage_count, 2,
			"%s: one banked Echo charge must produce 2 total resolutions (1 original + 1 Echo)" % p_name)

# --- Tier 2: Chronophage — Borrowed Time's external repeat, driven through FakeTurnPositions ---

func _case_chronophage_borrowed_time_instances(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: TACTICIAN, 1: WARLORD, 2: CHRONOPHAGE})
	var tactician: Character = roster[0]

	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	# Every character in a distinct section: the Tactician (the boosted ally) shares its
	# section with no other ally, satisfying time_tithe_trait.gd's "alone" clause.
	positions.sections_by_character = {0: 0, 1: 1, 2: 2, 3: 3}
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0, 1, 2], [3]), positions)

	resolver.BumpTurnBar(0, 0.1, 2)
	assert_true(
			tactician._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Borrowed_Time == b.type),
			"%s: moving an ally alone in its section must grant Borrowed Time" % p_name)

	var signal_strike_index: int = _skill_index(tactician, "Signal Strike")
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], signal_strike_index)
	var damage_count: int = 0
	for result: CombatResult in results:
		if(CombatResult.Kind.Damage == result.kind):
			damage_count += 1
	assert_eq(damage_count, 2,
			"%s: Borrowed Time must produce 2 total resolutions (1 original + 1 repeat) for a non-Chronophage " %
			p_name + "candidate, the live proof of step 6's _ExternalGatedContrastRatios")

# --- Tier 3: the bucketless Roles — no phantom bucket, and a declared scalar checked
# against its real source where one is cheap to call directly ---

func _case_thief_no_phantom_bucket(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: THIEF})
	var thief: Character = roster[0]
	_pin_legendary(thief)
	var resolver: BattleResolver = _resolver_for(roster, [0])

	var stab_index: int = _skill_index(thief, "Stab")
	var modifier: CombinedDamageModifier = _first_damage_modifier(resolver.ResolveSkill(0, [3], stab_index))
	assert_not_null(modifier, "%s: Stab against a living target must produce a Damage result" % p_name)
	assert_almost_eq(modifier.Product(), 1.0, 0.0001,
			"%s: a bucketless Role's basic cast must compose to a neutral product" % p_name)
	assert_true(_all_bucket_values_zero(modifier),
			"%s: a bucketless Role's basic cast must reach no nonzero CombinedDamageModifier bucket " % p_name +
			"(structural zero-value keys — the skill's own name, BetweenThePlatesTrait, reagent_damage_bonus — " +
			"are always present on the real resolver's own modifier and are not phantom buckets)")

	var declared_rate: float = (
			KitContributionManifest.MANIFEST[Types.Role.Thief]["passive"][0]["defence_ignore"]["rate"])
	assert_almost_eq((thief._trait as BetweenThePlatesTrait).GetBaseDefenceIgnoreRate(0), declared_rate, 0.0001,
			"%s: Between the Plates' real Legendary rate must match the manifest's declared 0.20" % p_name)

func _case_scholar_no_phantom_bucket(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: CENTAUR_ARCHIVIST})
	var scholar: Character = roster[0]
	_pin_legendary(scholar)
	var resolver: BattleResolver = _resolver_for(roster, [0])

	var sharp_rebuttal_index: int = _skill_index(scholar, "Sharp Rebuttal")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], sharp_rebuttal_index))
	assert_not_null(modifier, "%s: Sharp Rebuttal against a living target must produce a Damage result" % p_name)
	assert_almost_eq(modifier.Product(), 1.0, 0.0001,
			"%s: a bucketless Role's basic cast must compose to a neutral product" % p_name)
	assert_true(_all_bucket_values_zero(modifier),
			"%s: a bucketless Role's basic cast must reach no nonzero CombinedDamageModifier bucket " % p_name +
			"(structural zero-value keys — the skill's own name, BetweenThePlatesTrait, reagent_damage_bonus — " +
			"are always present on the real resolver's own modifier and are not phantom buckets)")

	var declared_amplification: float = (
			KitContributionManifest.MANIFEST[Types.Role.Scholar]["passive"][0]["attribute_amplification"]["magnitude"])
	assert_almost_eq((scholar._trait as FieldOfStudyTrait).GetAppliedAttributeAmplification(),
			declared_amplification, 0.0001,
			"%s: Field of Study's real Legendary amplification must match the manifest's declared 0.11" % p_name)

func _case_diviner_no_phantom_bucket(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: DIVINER})
	var diviner: Character = roster[0]
	var resolver: BattleResolver = _resolver_for(roster, [0])

	var fateful_glimpse_index: int = _skill_index(diviner, "Fateful Glimpse")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], fateful_glimpse_index))
	assert_not_null(modifier, "%s: Fateful Glimpse against a living target must produce a Damage result" % p_name)
	assert_almost_eq(modifier.Product(), 1.0, 0.0001,
			"%s: a bucketless Role's basic cast must compose to a neutral product" % p_name)
	assert_true(_all_bucket_values_zero(modifier),
			"%s: a bucketless Role's basic cast must reach no nonzero CombinedDamageModifier bucket " % p_name +
			"(structural zero-value keys — the skill's own name, BetweenThePlatesTrait, reagent_damage_bonus — " +
			"are always present on the real resolver's own modifier and are not phantom buckets)")

func _case_appraiser_no_phantom_bucket(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: APPRAISER})
	var appraiser: Character = roster[0]
	_pin_legendary(appraiser)
	var resolver: BattleResolver = _resolver_for(roster, [0])

	var sizing_cut_index: int = _skill_index(appraiser, "Sizing Cut")
	var modifier: CombinedDamageModifier = _first_damage_modifier(resolver.ResolveSkill(0, [3], sizing_cut_index))
	assert_not_null(modifier, "%s: Sizing Cut against a living target must produce a Damage result" % p_name)
	assert_almost_eq(modifier.Product(), 1.0, 0.0001,
			"%s: a bucketless Role's basic cast must compose to a neutral product" % p_name)
	assert_true(_all_bucket_values_zero(modifier),
			"%s: a bucketless Role's basic cast must reach no nonzero CombinedDamageModifier bucket " % p_name +
			"(structural zero-value keys — the skill's own name, BetweenThePlatesTrait, reagent_damage_bonus — " +
			"are always present on the real resolver's own modifier and are not phantom buckets)")

	var declared_overflow: float = (
			KitContributionManifest.MANIFEST[Types.Role.Appraiser]["passive"][0]["crit_overflow_rate"])
	assert_almost_eq((appraiser._trait as NoWastedMarginTrait).GetCritChanceOverflowRate(), declared_overflow, 0.0001,
			"%s: No Wasted Margin's real Legendary overflow rate must match the manifest's declared 5.0" % p_name)

func _case_warlord_no_phantom_bucket(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: WARLORD})
	var warlord: Character = roster[0]
	var resolver: BattleResolver = _resolver_for(roster, [0])

	var shield_slam_index: int = _skill_index(warlord, "Shield Slam")
	var modifier: CombinedDamageModifier = _first_damage_modifier(resolver.ResolveSkill(0, [3], shield_slam_index))
	assert_not_null(modifier, "%s: Shield Slam against a living target must produce a Damage result" % p_name)
	assert_almost_eq(modifier.Product(), 1.0, 0.0001,
			"%s: a bucketless Role's basic cast must compose to a neutral product" % p_name)
	assert_true(_all_bucket_values_zero(modifier),
			"%s: a bucketless Role's basic cast must reach no nonzero CombinedDamageModifier bucket " % p_name +
			"(structural zero-value keys — the skill's own name, BetweenThePlatesTrait, reagent_damage_bonus — " +
			"are always present on the real resolver's own modifier and are not phantom buckets)")

	var hold_the_line: Dictionary = KitContributionManifest.MANIFEST[Types.Role.Warlord]["skills"][1]
	var declared_fortify: float = hold_the_line["granted_attribute_buff"]["magnitude"]
	# Fortify.tres's own magnitude is already the additive fraction (+30%), unlike
	# Volatile_Mixture's own "1.0 + bonus" damage-multiplier convention — no -1.0 here.
	assert_almost_eq(StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify).magnitude, declared_fortify, 0.0001,
			"%s: Fortify.tres's real magnitude must match Hold the Line's manifest-declared 0.3" % p_name)

func _case_symbiote_no_phantom_bucket(p_name: String) -> void:
	var roster: Dictionary[int, Character] = _build_roster({0: SYMBIOTE})
	var symbiote: Character = roster[0]
	var resolver: BattleResolver = _resolver_for(roster, [0])

	var spore_lash_index: int = _skill_index(symbiote, "Spore Lash")
	var modifier: CombinedDamageModifier = _first_damage_modifier(resolver.ResolveSkill(0, [3], spore_lash_index))
	assert_not_null(modifier, "%s: Spore Lash against a living target must produce a Damage result" % p_name)
	assert_almost_eq(modifier.Product(), 1.0, 0.0001,
			"%s: a bucketless Role's basic cast must compose to a neutral product" % p_name)
	assert_true(_all_bucket_values_zero(modifier),
			"%s: a bucketless Role's basic cast must reach no nonzero CombinedDamageModifier bucket " % p_name +
			"(structural zero-value keys — the skill's own name, BetweenThePlatesTrait, reagent_damage_bonus — " +
			"are always present on the real resolver's own modifier and are not phantom buckets)")

	assert_true((symbiote._trait as SymbioteTrait)._execution_steps.is_empty(),
			"%s: the base Symbiote trait must still be a placeholder with no execution steps — this row must " %
			p_name + "fail the day a Graft is fielded instead")
