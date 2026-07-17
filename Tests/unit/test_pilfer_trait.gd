extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_character = Character.new()
	_character._current_health = 10
	var roster: Dictionary[int, Character] = {0: _character}
	_resolver = TestFactory.make_resolver(roster, CombatSides.new([0], []))

# --- STEAL_CHANCE table ---

func test_steal_chance_uncommon() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Uncommon, 0.0), 0.20,
		"Uncommon Thief should have 20% steal chance")

func test_steal_chance_rare() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Rare, 0.0), 0.30,
		"Rare Thief should have 30% steal chance")

func test_steal_chance_epic() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Epic, 0.0), 0.40,
		"Epic Thief should have 40% steal chance")

func test_steal_chance_legendary() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Legendary, 0.0), 0.50,
		"Legendary Thief should have 50% steal chance")

func test_steal_chance_common_is_zero() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Common, 0.0), 0.0,
		"Common rarity should default to 0% steal chance")

func test_steal_chance_relic_is_zero() -> void:
	assert_eq(PilferTrait.STEAL_CHANCE.get(Types.Rarity.Relic, 0.0), 0.0,
		"Relic rarity should default to 0% steal chance")

# --- BattleResolver.RemoveBuff ---

func test_remove_buff_erases_from_active_buffs() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 2
	buff.ID = 0
	_character._active_buffs.append(buff)

	assert_eq(_character._active_buffs.size(), 1, "Buff should be present before removal")

	var results: Array[CombatResult] = _resolver.RemoveBuff(0, buff)

	assert_eq(_character._active_buffs.size(), 0, "Buff should be erased after RemoveBuff")
	assert_eq(results.size(), 1, "Removal should be reported")
	assert_eq(results[0].kind, CombatResult.Kind.Statuses_Removed)
	assert_eq(results[0].status_IDs, [0] as Array[int], "The removed buff's status ID should be reported")

func test_remove_buff_only_erases_target_buff() -> void:
	var buff_a: StatusEffects.Buff = StatusEffects.Buff.new()
	buff_a.type = Types.Buff_Type.Empower
	buff_a.duration = 2
	buff_a.ID = 0

	var buff_b: StatusEffects.Buff = StatusEffects.Buff.new()
	buff_b.type = Types.Buff_Type.Fortify
	buff_b.duration = 3
	buff_b.ID = 1

	_character._active_buffs.append(buff_a)
	_character._active_buffs.append(buff_b)

	_resolver.RemoveBuff(0, buff_a)

	assert_eq(_character._active_buffs.size(), 1, "Only the targeted buff should be removed")
	assert_eq(_character._active_buffs[0].type, Types.Buff_Type.Fortify,
		"Remaining buff should be the one that was not removed")
