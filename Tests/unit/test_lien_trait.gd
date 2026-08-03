extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _enemy: Character = null
var _trait: LienTrait = null
var _characters: Dictionary[int, Character]
var _resolver: BattleResolver = null

func _make_character() -> Character:
	var character: Character = Character.new()
	character._current_health = 10
	character._attributes[Types.Attribute.Health] = 10
	return character

func before_each() -> void:
	_owner = _make_character()
	_enemy = _make_character()
	_trait = LienTrait.new()
	_trait.Init(Types.Rarity.Epic)
	_owner._trait = _trait
	_characters = {0: _owner, 1: _enemy}
	_resolver = TestFactory.make_resolver(_characters, CombatSides.new([0], [1]))

func _has_empower() -> bool:
	for buff: StatusEffects.Buff in _owner._active_buffs:
		if(Types.Buff_Type.Empower == buff.type):
			return true
	return false

func test_start_of_battle_resets_the_cooldown_so_the_first_turn_can_trigger() -> void:
	_trait.StartOfBattle(0, _resolver)

	_trait.StartOfTurn(0, _resolver)

	assert_true(_has_empower(), "An unbuffed user should gain Empower on its first turn")
	var empower_buff: StatusEffects.Buff = null
	for buff: StatusEffects.Buff in _owner._active_buffs:
		if(Types.Buff_Type.Empower == buff.type):
			empower_buff = buff
	assert_eq(empower_buff.duration, LienTrait.EMPOWER_DURATION,
		"Lien's Empower should last exactly 2 turns")

func test_a_buffed_owner_does_not_gain_empower() -> void:
	_trait.StartOfBattle(0, _resolver)
	var vigor: StatusEffects.Buff = StatusEffects.Buff.new()
	vigor.type = Types.Buff_Type.Vigor
	vigor.duration = 2
	vigor.name = "Vigor"
	_resolver.GetStatusResolver().ApplyBuff(0, vigor)

	_trait.StartOfTurn(0, _resolver)

	assert_false(_has_empower(), "A buffed user must not gain Empower from Lien")

func test_the_trigger_does_not_repeat_within_the_four_turn_cooldown() -> void:
	_trait.StartOfBattle(0, _resolver)
	_trait.StartOfTurn(0, _resolver)
	_owner._active_buffs.clear()

	_trait.StartOfTurn(0, _resolver)
	_trait.StartOfTurn(0, _resolver)
	_trait.StartOfTurn(0, _resolver)

	assert_false(_has_empower(), "Lien must not trigger again before its 4-turn cooldown elapses")

func test_the_trigger_is_available_again_after_the_cooldown_elapses() -> void:
	_trait.StartOfBattle(0, _resolver)
	_trait.StartOfTurn(0, _resolver)
	_owner._active_buffs.clear()

	_trait.StartOfTurn(0, _resolver)
	_trait.StartOfTurn(0, _resolver)
	_trait.StartOfTurn(0, _resolver)
	_trait.StartOfTurn(0, _resolver)

	assert_true(_has_empower(), "Lien should be able to trigger again once its cooldown has elapsed")
