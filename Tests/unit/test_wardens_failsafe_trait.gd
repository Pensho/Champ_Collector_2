extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally_a: Character = null
var _ally_b: Character = null
var _enemy: Character = null
var _trait: WardensFailsafeTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func _make_character() -> Character:
	var character: Character = Character.new()
	character._current_health = 10
	character._attributes[Types.Attribute.Health] = 10
	return character

func before_each() -> void:
	_owner = _make_character()
	_ally_a = _make_character()
	_ally_b = _make_character()
	_enemy = _make_character()
	_trait = WardensFailsafeTrait.new()
	_trait.Init(Types.Rarity.Epic)
	_owner._trait = _trait
	_characters = {0: _owner, 1: _ally_a, 2: _ally_b, 3: _enemy}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0, 1, 2], [3]))

func _frenzy_count() -> int:
	var count: int = 0
	for buff: StatusEffects.Buff in _owner._active_buffs:
		if(Types.Buff_Type.Frenzy == buff.type):
			count += 1
	return count

func test_an_ally_death_grants_frenzy_for_the_rest_of_the_battle() -> void:
	_trait.OnAllyDeath(0, 1, _resolver)

	assert_eq(_frenzy_count(), 1, "An ally death should grant Frenzy exactly once")
	var frenzy_buff: StatusEffects.Buff = null
	for buff: StatusEffects.Buff in _owner._active_buffs:
		if(Types.Buff_Type.Frenzy == buff.type):
			frenzy_buff = buff
	assert_eq(frenzy_buff.duration, GameBalance.BATTLE_PERMANENT_EFFECT,
		"Frenzy from Warden's Failsafe should last the rest of the battle")

func test_a_second_ally_death_does_not_stack_a_second_frenzy() -> void:
	_trait.OnAllyDeath(0, 1, _resolver)

	_trait.OnAllyDeath(0, 2, _resolver)

	assert_eq(_frenzy_count(), 1, "Frenzy from Warden's Failsafe must not be granted twice")
