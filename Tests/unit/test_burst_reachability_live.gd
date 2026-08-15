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
## Four distinct shapes are covered, chosen to span the manifest's structure rather than its
## roles (kit_contribution_manifest.gd's own field docs, lines 16-32):
##   - A skill's own bonus_per_debuff_on_target bucket, a per-debuff-anchored granted-status
##     bucket landing in that SAME key, and a granted DamageMultiplier bucket in a distinct
##     key — Sorcerer's Cataclysm, matching test_burst_reachability.gd's own 2.8x pin.
##   - The shared trait_resource key fed by internal trait stack state (not a StatusEffects
##     buff/debuff at all) — Tidal Corsair's Wrangle the Sea, matching the other 2.8x pin.
##   - The ramp key, whose per-instance rate is 0-indexed by actual battle use count — a
##     shape burst_reachability.gd's own header (lines 20-25) flags as scored only at the
##     minimum reachable count, precisely because no simulated battle exists to count a real
##     one. This test supplies that real count directly against Bar Brawler's Heap On.
##   - A granted status's real target scope (`Skill_Target`), replaying the actual granting
##     skill through the resolver rather than placing the buff directly on whichever character
##     is convenient — the only way to catch a scope bug like the one that shipped: neither a
##     `Self` grant (Thief's Weigh the Mark) nor an `All_Other_Allies` grant (Tactician's Fatal
##     Flaw) previously excluded the granter's own resolution when the scorer composed them,
##     and this shape is exactly what a granted-status-carrying team with a `Self`- or
##     `All_Other_Allies`-scoped grant needs covered.

const SORCERER = preload("res://Data/Character_Player_Variants/Sorcerer.tres")
const TIDAL_CORSAIR = preload("res://Data/Character_Player_Variants/Tidal_Corsair.tres")
const BAR_BRAWLER = preload("res://Data/Character_Player_Variants/Bar_Brawler.tres")
const THIEF = preload("res://Data/Character_Player_Variants/Thief.tres")
const WARLORD = preload("res://Data/Character_Player_Variants/Warlord.tres")
const TACTICIAN = preload("res://Data/Character_Player_Variants/Tactician.tres")
const CHRONOPHAGE = preload("res://Data/Character_Player_Variants/Chronophage.tres")

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

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

func _first_damage_modifier(p_results: Array[CombatResult]) -> CombinedDamageModifier:
	for result in p_results:
		if(CombatResult.Kind.Damage == result.kind):
			return result.combined_damage_modifier
	return null

func _skill_index(p_character: Character, p_skill_name: String) -> int:
	for i in p_character._skills.size():
		if(p_skill_name == p_character._skills[i].name):
			return i
	return -1

# --- Shape 1: skill's own bonus_per_debuff_on_target bucket, a per-debuff-anchored granted
# status landing in that same bucket, and a granted DamageMultiplier bucket in a distinct key ---

func test_cataclysm_measured_product_matches_the_scored_prediction() -> void:
	var roster: Dictionary[int, Character] = {}
	var sorcerer: Character = Character.new()
	sorcerer.InstantiateNew(SORCERER, 0)
	sorcerer._attributes[Types.Attribute.CritChance] = 0
	# Scholar's Expose Fallacy grants All Allies Opportunist; Tactician's Fatal Flaw grants
	# one ally Daunting Strength — both land on the Sorcerer directly here rather than being
	# produced by actually casting those two skills first, per the header's stated pattern.
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
	roster[0] = sorcerer

	var target: Character = _high_health_target()
	var warped: StatusEffects.Debuff = StatusEffects.Debuff.new()
	warped.type = Types.Debuff_Type.Warped
	warped.duration = 2
	target._active_debuffs.append(warped)
	roster[3] = target

	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [3]))
	var cataclysm_index: int = _skill_index(sorcerer, "Cataclysm")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], cataclysm_index))
	assert_not_null(modifier, "Cataclysm against a living target must produce a Damage result")

	var predicted: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(
			_sorcerer_scholar_tactician()).Pinned(0, "Cataclysm")
	assert_not_null(predicted, "The scorer must produce a pinned Cataclysm candidate to compare against")
	assert_almost_eq(modifier.Product(), predicted.product, 0.0001,
			"The real resolver's composed product must match the manifest-derived prediction " +
			"for this precondition set")
	assert_almost_eq(modifier.Product(), 2.8, 0.01,
			"Regression guard: this is the same 2.8x pinned in test_burst_reachability.gd")

# --- Shape 2: the shared trait_resource key, fed by internal trait stack state rather than
# a StatusEffects buff/debuff ---

func test_corsairs_reckoning_measured_product_matches_the_scored_prediction() -> void:
	var roster: Dictionary[int, Character] = {}
	var tidal_corsair: Character = Character.new()
	tidal_corsair.InstantiateNew(TIDAL_CORSAIR, 0)
	tidal_corsair._attributes[Types.Attribute.CritChance] = 0
	# The manifest's magnitudes are stated at Legendary; the shipped preset is Uncommon, so
	# the trait is re-initialized at Legendary before any cast fills a stack, the same way a
	# Legendary-rarity copy of this champion would behave.
	tidal_corsair._rarity = Types.Rarity.Legendary
	tidal_corsair._trait.Init(Types.Rarity.Legendary)
	roster[0] = tidal_corsair
	roster[3] = _high_health_target()

	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [3]))
	var boarding_strike_index: int = _skill_index(tidal_corsair, "Boarding Strike")
	var corsairs_reckoning_index: int = _skill_index(tidal_corsair, "Corsairs Reckoning")
	for i in 3:
		resolver.ResolveSkill(0, [3], boarding_strike_index)
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], corsairs_reckoning_index))
	assert_not_null(modifier, "Corsairs Reckoning against a living target must produce a Damage result")

	var predicted: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(
			_corsair_cultist_warlord()).Pinned(0, "Corsairs Reckoning")
	assert_not_null(predicted, "The scorer must produce a pinned Corsairs Reckoning candidate to compare against")
	assert_almost_eq(modifier.Product(), predicted.product, 0.0001,
			"The real resolver's composed product must match the manifest-derived prediction " +
			"for three filled Steel stacks")
	assert_almost_eq(modifier.Product(), 2.8, 0.01,
			"Regression guard: this is the same 2.8x pinned in test_burst_reachability.gd")

# --- Shape 3: the ramp key, 0-indexed by actual battle use count ---

func test_heap_on_ramp_bucket_matches_the_manifests_declared_per_instance_rate() -> void:
	var roster: Dictionary[int, Character] = {}
	var bar_brawler: Character = Character.new()
	bar_brawler.InstantiateNew(BAR_BRAWLER, 0)
	bar_brawler._attributes[Types.Attribute.CritChance] = 0
	roster[0] = bar_brawler
	roster[3] = _high_health_target()

	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [3]))
	var heap_on_index: int = _skill_index(bar_brawler, "Heap On")
	# First cast: use_count 0, ramp_multiplier 1.0, contributes nothing to the bucket. Second
	# cast: use_count 1, the "one instance satisfied" state burst_reachability.gd's manifest
	# reading assumes as the minimum reachable count.
	resolver.ResolveSkill(0, [3], heap_on_index)
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], heap_on_index))
	assert_not_null(modifier, "Heap On against a living target must produce a Damage result")

	var bar_brawler_skills: Array = KitContributionManifest.MANIFEST[Types.Role.Bar_Brawler]["skills"]
	var declared_rate: float = bar_brawler_skills[heap_on_index]["magnitude"]
	assert_almost_eq(modifier.Buckets()[&"Heap On (ramp)"], declared_rate, 0.0001,
			"The manifest's declared per-instance ramp rate must match what one prior use " +
			"actually contributes to the ramp bucket")

# --- Shape 4: a granted status's real target scope — Self and All_Other_Allies must not
# reach the granter's own resolution, replaying the granting skill itself through the
# resolver so the real Skills.FindSkillTargets-equivalent group resolution is exercised ---

func test_thief_self_scoped_opportunist_does_not_reach_a_non_thief_caster() -> void:
	var roster: Dictionary[int, Character] = {}
	var sorcerer: Character = Character.new()
	sorcerer.InstantiateNew(SORCERER, 0)
	sorcerer._attributes[Types.Attribute.CritChance] = 0
	roster[0] = sorcerer
	var thief: Character = Character.new()
	thief.InstantiateNew(THIEF, 1)
	roster[1] = thief
	var warlord: Character = Character.new()
	warlord.InstantiateNew(WARLORD, 2)
	roster[2] = warlord

	var target: Character = _high_health_target()
	var warped: StatusEffects.Debuff = StatusEffects.Debuff.new()
	warped.type = Types.Debuff_Type.Warped
	warped.duration = 2
	target._active_debuffs.append(warped)
	roster[3] = target

	var sides: CombatSides = CombatSides.new([0, 1, 2], [3])
	var resolver: BattleResolver = TestFactory.make_resolver(roster, sides)

	# Weigh the Mark's own target is Self — grant it to the Thief exactly as a real cast
	# would, via the same caster-relative resolution burst_reachability.gd's own
	# _GrantReachesCandidate predicate mirrors.
	var weigh_the_mark_index: int = _skill_index(thief, "Weigh the Mark")
	var self_targets: Array[int] = Skills.FindSkillTargets(
			1, 1, Types.Skill_Target.Self, resolver.GetCharacters(), sides)
	resolver.ResolveSkill(1, self_targets, weigh_the_mark_index)
	assert_true(thief._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Opportunist == b.type),
			"Weigh the Mark must actually grant the Thief itself Opportunist")

	var cataclysm_index: int = _skill_index(sorcerer, "Cataclysm")
	var modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], cataclysm_index))
	assert_not_null(modifier, "Cataclysm against a living target must produce a Damage result")

	var predicted: BurstReachability.CandidateResult = BurstReachability.ScoreTeam(
			_sorcerer_thief_warlord()).Pinned(0, "Cataclysm")
	assert_not_null(predicted, "The scorer must produce a pinned Cataclysm candidate to compare against")
	assert_almost_eq(modifier.Product(), predicted.product, 0.0001,
			"The real resolver's composed product must match the manifest-derived prediction")
	assert_almost_eq(modifier.Product(), 1.3, 0.0001,
			"Only Cataclysm's own Warped bucket (0.3) must land: the Thief's Self-scoped " +
			"Opportunist must NOT reach the Sorcerer, a different character")


func test_tactician_all_other_allies_daunting_strength_does_not_reach_the_tacticians_own_resolution() -> void:
	var roster: Dictionary[int, Character] = {}
	var tactician: Character = Character.new()
	tactician.InstantiateNew(TACTICIAN, 0)
	tactician._attributes[Types.Attribute.CritChance] = 0
	roster[0] = tactician
	var warlord: Character = Character.new()
	warlord.InstantiateNew(WARLORD, 1)
	warlord._attributes[Types.Attribute.CritChance] = 0
	roster[1] = warlord
	var chronophage: Character = Character.new()
	chronophage.InstantiateNew(CHRONOPHAGE, 2)
	roster[2] = chronophage
	roster[3] = _high_health_target()

	var sides: CombatSides = CombatSides.new([0, 1, 2], [3])
	var resolver: BattleResolver = TestFactory.make_resolver(roster, sides)

	# Fatal Flaw's own target is All_Other_Allies — grant it exactly as a real cast would,
	# via the same caster-relative resolution (every ally but the caster).
	var fatal_flaw_index: int = _skill_index(tactician, "Fatal Flaw")
	var other_ally_targets: Array[int] = Skills.FindSkillTargets(
			0, 0, Types.Skill_Target.All_Other_Allies, resolver.GetCharacters(), sides)
	resolver.ResolveSkill(0, other_ally_targets, fatal_flaw_index)
	assert_true(warlord._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Daunting_Strength == b.type),
			"Fatal Flaw must grant a teammate (Warlord) Daunting Strength")
	assert_false(tactician._active_buffs.any(func(b: StatusEffects.Buff) -> bool: return Types.Buff_Type.Daunting_Strength == b.type),
			"Fatal Flaw's All_Other_Allies target must NOT grant the Tactician itself Daunting Strength")

	var signal_strike_index: int = _skill_index(tactician, "Signal Strike")
	var tactician_modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(0, [3], signal_strike_index))
	assert_not_null(tactician_modifier, "Signal Strike against a living target must produce a Damage result")

	var shield_slam_index: int = _skill_index(warlord, "Shield Slam")
	var warlord_modifier: CombinedDamageModifier = _first_damage_modifier(
			resolver.ResolveSkill(1, [3], shield_slam_index))
	assert_not_null(warlord_modifier, "Shield Slam against a living target must produce a Damage result")

	var predicted: BurstReachability.TeamResult = BurstReachability.ScoreTeam(_tactician_warlord_chronophage())
	var predicted_tactician: BurstReachability.CandidateResult = predicted.Pinned(0, "Signal Strike")
	var predicted_warlord: BurstReachability.CandidateResult = predicted.Pinned(1, "Shield Slam")
	assert_not_null(predicted_tactician, "The scorer must produce a pinned Signal Strike candidate")
	assert_not_null(predicted_warlord, "The scorer must produce a pinned Shield Slam candidate")

	assert_almost_eq(tactician_modifier.Product(), predicted_tactician.product, 0.0001,
			"The real resolver's Tactician-own product must match the manifest-derived prediction")
	assert_almost_eq(tactician_modifier.Product(), 1.0, 0.0001,
			"The Tactician's own resolution must be untouched by its own All_Other_Allies grant")
	assert_almost_eq(warlord_modifier.Product(), predicted_warlord.product, 0.0001,
			"The real resolver's Warlord product must match the manifest-derived prediction")
	assert_almost_eq(warlord_modifier.Product(), 2.0, 0.0001,
			"A teammate other than the granter must actually receive Daunting Strength (1.0 -> 2.0x)")
