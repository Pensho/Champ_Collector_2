extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally_a: Character = null
var _ally_b: Character = null
var _enemy: Character = null
var _trait: OnTheHouseTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func _make_ally(p_health: int) -> Character:
	var character: Character = Character.new()
	character._attributes[Types.Attribute.Health] = p_health
	character._current_health = p_health * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	return character

func _make_buff_template() -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Vigor
	buff.duration = 2
	buff.name = "Vigor"
	return buff

func before_each() -> void:
	_owner = _make_ally(10)
	_ally_a = _make_ally(20)
	_ally_b = _make_ally(10)
	_enemy = _make_ally(10)
	_trait = OnTheHouseTrait.new()
	_owner._trait = _trait
	_characters = {0: _owner, 1: _ally_a, 2: _ally_b, 3: _enemy}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1, 2], [3]))

func _InitTrait(p_rarity: Types.Rarity) -> void:
	_trait.Init(p_rarity)

# --- Gaining a buff heals the whole living team, each off its own max Health ---

func test_gaining_a_buff_heals_owner_and_every_living_ally_by_their_own_max_health() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_owner._current_health = 1
	_ally_a._current_health = 1
	_ally_b._current_health = 1

	_resolver.GetStatusResolver().ApplyBuff(0, _make_buff_template())

	# Max Health = Health attribute x 4; 6% of that, rounded.
	# Owner: Vigor (the triggering buff) also raises the owner's own max Health by 30%
	# before the heal is computed: Health 10 -> base max 40 -> +30% = 52 -> 6% = 3
	# (round(3.12) = 3)
	assert_eq(_owner._current_health, 4, "Owner should heal 6%% of its own (Vigor-boosted) max Health")
	# Ally A: unaffected by the owner's Vigor; Health 20 -> max 80 -> 6% = 5 (round(4.8) = 5)
	assert_eq(_ally_a._current_health, 6, "Ally A should heal 6%% of its own (larger) max Health")
	# Ally B: same as ally A's baseline, smaller Health: Health 10 -> max 40 -> 6% = 2 (round(2.4) = 2)
	assert_eq(_ally_b._current_health, 3, "Ally B should heal 6%% of own max Health")

func test_gaining_a_buff_does_not_heal_the_enemy() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_enemy._current_health = 1

	_resolver.GetStatusResolver().ApplyBuff(0, _make_buff_template())

	assert_eq(_enemy._current_health, 1, "Enemies must not be healed by the Bar Brawler's passive")

func test_dead_allies_are_skipped() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_ally_a._current_health = 0

	_resolver.GetStatusResolver().ApplyBuff(0, _make_buff_template())

	assert_eq(_ally_a._current_health, 0, "A dead ally must not be healed")

# --- At most once between the Bar Brawler's turns ---

func test_a_second_buff_in_the_same_cycle_does_not_heal_again() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_owner._current_health = 1
	_resolver.GetStatusResolver().ApplyBuff(0, _make_buff_template())
	var health_after_first_pour: int = _owner._current_health

	var second_buff: StatusEffects.Buff = StatusEffects.Buff.new()
	second_buff.type = Types.Buff_Type.Attune
	second_buff.duration = 3
	second_buff.name = "Attune"
	_resolver.GetStatusResolver().ApplyBuff(0, second_buff)

	assert_eq(_owner._current_health, health_after_first_pour,
		"A second buff before his next turn must not pour again")

func test_start_of_turn_reopens_the_pour_window() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_owner._current_health = 1
	_resolver.GetStatusResolver().ApplyBuff(0, _make_buff_template())
	var health_after_first_pour: int = _owner._current_health

	_trait.StartOfTurn(0, _resolver)
	var second_buff: StatusEffects.Buff = StatusEffects.Buff.new()
	second_buff.type = Types.Buff_Type.Attune
	second_buff.duration = 3
	second_buff.name = "Attune"
	_resolver.GetStatusResolver().ApplyBuff(0, second_buff)

	assert_true(_owner._current_health > health_after_first_pour,
		"After his turn starts, the next buff gained should pour again")

# --- Refreshing an existing non-stackable buff must not trigger a pour ---

func test_refreshing_an_existing_buff_does_not_trigger_a_pour() -> void:
	_InitTrait(Types.Rarity.Uncommon)
	_resolver.GetStatusResolver().ApplyBuff(0, _make_buff_template())
	_trait.StartOfTurn(0, _resolver)
	_owner._current_health = 1

	# Vigor is non-stackable/overwritable: applying it again on an already-buffed
	# target refreshes duration instead of appending a new buff.
	_resolver.GetStatusResolver().ApplyBuff(0, _make_buff_template())

	assert_eq(_owner._current_health, 1, "Refreshing an existing buff must not pour a heal")
