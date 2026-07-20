extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally_a: Character = null
var _ally_b: Character = null
var _enemy: Character = null
var _trait: ChosenVesselTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func _make_skill(p_name: String, p_cooldown: int) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = p_name
	skill.cooldown = p_cooldown
	return skill

func _make_ally() -> Character:
	var character: Character = Character.new()
	character._current_health = 10
	character._attributes[Types.Attribute.Health] = 10
	return character

func before_each() -> void:
	_owner = _make_ally()
	_owner._skills = [_make_skill("Zap", 0), _make_skill("Burning Bolas", 2)]
	_ally_a = _make_ally()
	_ally_b = _make_ally()
	_enemy = _make_ally()
	_trait = ChosenVesselTrait.new()
	_owner._trait = _trait
	_characters = {0: _owner, 1: _ally_a, 2: _ally_b, 3: _enemy}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1, 2], [3]))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

# --- Rarity table ---

func test_power_bonus_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.15,
		Types.Rarity.Rare: 0.20,
		Types.Rarity.Epic: 0.25,
		Types.Rarity.Legendary: 0.30,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(ChosenVesselTrait.GetPowerBonus(rarity), expected[rarity],
			"POWER_BONUS at %s" % Types.RarityName(rarity))

# --- Marking ---

func test_start_of_battle_marks_a_living_ally_excluding_self() -> void:
	_InitTrait(Types.Rarity.Uncommon)

	_trait.StartOfBattle(0, _resolver)

	assert_true([1, 2].has(_trait._vessel_ID), "Vessel must be one of the Cultist's living allies")

func test_start_of_battle_never_marks_no_allies_as_negative_one_when_allies_exist() -> void:
	_InitTrait(Types.Rarity.Uncommon)

	_trait.StartOfBattle(0, _resolver)

	assert_ne(_trait._vessel_ID, -1)

# --- Basic skills have no effect ---

func test_basic_skill_does_not_drain_the_vessel() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._vessel_ID = 1

	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Zap", {}, _resolver)

	assert_eq(_ally_a._current_health, 10, "A basic skill must not drain the Vessel")
	assert_eq(result._damage_multiplier, 1.0)

# --- Non-basic skills drain and empower ---

func test_non_basic_skill_drains_five_percent_of_the_vessels_max_health() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._vessel_ID = 1

	_trait.OnSkillCast(0, [], "Burning Bolas", {}, _resolver)

	# Max Health = 10 (Health attribute) x 4 (ATTRIBUTE_HEALTH_MULTIPLIER) = 40; 5% = 2.
	assert_eq(_ally_a._current_health, 8)

func test_non_basic_skill_reports_trait_text_on_the_vessel() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._vessel_ID = 1
	var received: Array[CombatResult] = []
	_resolver.result_produced.connect(func(p_result): received.append(p_result))

	_trait.OnSkillCast(0, [], "Burning Bolas", {}, _resolver)

	var trait_texts: Array[CombatResult] = received.filter(
		func(p_result): return p_result.kind == CombatResult.Kind.Trait_Text)
	assert_eq(trait_texts.size(), 1, "The drain should be reported exactly once")
	assert_eq(trait_texts[0].target_ID, 1, "The text should be reported on the Vessel")
	assert_eq(trait_texts[0].text, "Sacrificed")

func test_non_basic_skill_returns_the_rarity_power_bonus() -> void:
	_InitTrait(Types.Rarity.Epic)
	_trait._vessel_ID = 1

	var result: TraitSkillResult = _trait.OnSkillCast(0, [], "Burning Bolas", {}, _resolver)

	assert_eq(result._damage_multiplier, 1.25)

# --- Drain can kill the Vessel ---

func test_drain_killing_the_vessel_grants_attune_and_re_marks() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._vessel_ID = 1
	_ally_a._current_health = 1

	_trait.OnSkillCast(0, [], "Burning Bolas", {}, _resolver)

	assert_true(_ally_a._current_health <= 0, "The Vessel should have died from the drain")
	assert_eq(_owner._active_buffs.size(), 1)
	assert_eq(_owner._active_buffs[0].type, Types.Buff_Type.Attune)
	assert_eq(_owner._active_buffs[0].duration, 3)
	assert_eq(_trait._vessel_ID, 2, "The only other living ally should be re-marked as the Vessel")

# --- Death from any source triggers the same handling ---

func test_enemy_kill_of_the_vessel_also_triggers_re_marking() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_trait._vessel_ID = 1

	_resolver.SetCurrentHealth(1, 0)

	assert_eq(_owner._active_buffs.size(), 1, "Attune should be granted even when another source kills the Vessel")
	assert_eq(_trait._vessel_ID, 2)

# --- No living allies ---

func test_no_living_allies_leaves_the_vessel_unmarked() -> void:
	_characters = {0: _owner, 1: _ally_a}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1], []))
	_InitTrait(Types.Rarity.Uncommon)
	_trait._vessel_ID = 1

	_resolver.SetCurrentHealth(1, 0)

	assert_eq(_trait._vessel_ID, -1, "With no living allies left, the Vessel should stay unmarked")
