extends GutTest

## Character.HookSources() carries the champion's own trait alongside every equipped item's
## Relic effect, and the sum/product/any-style aggregate helpers on Skills each compose
## correctly across them.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

## Counts how many times it fired on a broadcastable event, for asserting every hook
## source on a character (not just its own trait) gets called.
class FakeRelicEventCounter extends RelicEffect:
	var call_count: int = 0

	func _init() -> void:
		_execution_steps[Types.Combat_Event.Start_Turn] = Callable(self, "StartOfTurn")

	func StartOfTurn(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
		call_count += 1

class FakeRelicOutgoingDamageBonus extends RelicEffect:
	var bonus: float = 0.0

	func _init(p_bonus: float) -> void:
		bonus = p_bonus

	func GetOutgoingDamageBonus(_p_owner_ID: int, _p_target_ID: int, _p_resolver: BattleResolver) -> float:
		return bonus

class FakeRelicDamageTakenMultiplier extends RelicEffect:
	var multiplier: float = 1.0

	func _init(p_multiplier: float) -> void:
		multiplier = p_multiplier

	func OnDamageTaken(_p_owner_ID: int, _p_attacker_ID: int, _p_resolver: BattleResolver) -> float:
		return multiplier

class FakeRelicForwardBlocking extends RelicEffect:
	func BlocksForwardTurnBarBump(_p_owner_ID: int) -> bool:
		return true

class FakeRelicAmplification extends RelicEffect:
	var amplification: float = 0.0

	func _init(p_amplification: float) -> void:
		amplification = p_amplification

	func GetAppliedAttributeAmplification() -> float:
		return amplification

var _character: Character = null
var _equipped_IDs: Array[int] = []

func before_each() -> void:
	_character = TestFactory.make_character()
	_character._current_health = _character._attributes[Types.Attribute.Health]
	_equipped_IDs = []

func after_each() -> void:
	for id in _equipped_IDs:
		if(main.GetInstance()._item_collection._items.has(id)):
			main.GetInstance()._item_collection._items[id].free()
			main.GetInstance()._item_collection._items.erase(id)
	_character._held_items.clear()

func _equip_relic(p_character: Character, p_slot: Types.Slot, p_relic_effect: RelicEffect) -> void:
	var equipment: Equipment = Equipment.new()
	equipment._slot = p_slot
	equipment._relic_effect = p_relic_effect
	var id: int = main.GetInstance()._item_collection.CreateNextInstanceID()
	main.GetInstance()._item_collection._items[id] = equipment
	p_character._held_items[p_slot] = id
	_equipped_IDs.append(id)

func test_hook_sources_includes_the_trait_and_every_equipped_relic() -> void:
	_character._trait = FakeRelicEventCounter.new()
	_equip_relic(_character, Types.Slot.Weapon, FakeRelicEventCounter.new())
	_equip_relic(_character, Types.Slot.OffHand, FakeRelicEventCounter.new())

	assert_eq(_character.HookSources().size(), 3,
		"The champion's own trait plus both equipped Relics should all be hook sources")

func test_a_trait_and_two_relics_all_fire_on_one_event() -> void:
	var champion_trait: FakeRelicEventCounter = FakeRelicEventCounter.new()
	var relic_a: FakeRelicEventCounter = FakeRelicEventCounter.new()
	var relic_b: FakeRelicEventCounter = FakeRelicEventCounter.new()
	_character._trait = champion_trait
	_equip_relic(_character, Types.Slot.Weapon, relic_a)
	_equip_relic(_character, Types.Slot.OffHand, relic_b)
	var characters: Dictionary[int, Character] = {0: _character}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], []))

	resolver.BeginTurn(0)

	assert_eq(champion_trait.call_count, 1, "The champion's own trait should fire")
	assert_eq(relic_a.call_count, 1, "The first Relic should fire")
	assert_eq(relic_b.call_count, 1, "The second Relic should fire")

func test_outgoing_damage_bonus_sums_across_sources() -> void:
	_character._trait = FakeRelicOutgoingDamageBonus.new(0.20)
	_equip_relic(_character, Types.Slot.Weapon, FakeRelicOutgoingDamageBonus.new(0.15))

	var bonus: float = Skills.OutgoingDamageBonus(_character, 0, 1, null)

	assert_almost_eq(bonus, 0.35, 0.0001, "Sum-style: the trait's and the Relic's own bonus add")

func test_damage_taken_multiplier_is_product_style() -> void:
	_character._trait = FakeRelicDamageTakenMultiplier.new(0.9)
	_equip_relic(_character, Types.Slot.Weapon, FakeRelicDamageTakenMultiplier.new(0.8))

	var multiplier: float = Skills.DamageTakenMultiplier(_character, 0, 1, null)

	assert_almost_eq(multiplier, 0.72, 0.0001, "Product-style: the trait's and the Relic's own multiplier multiply")

func test_blocks_forward_turn_bar_bump_is_any_style() -> void:
	_equip_relic(_character, Types.Slot.Weapon, FakeRelicForwardBlocking.new())

	assert_true(Skills.BlocksForwardTurnBarBump(_character, 0),
		"Any-style: one Relic saying so is enough, even with no trait")

func test_blocks_forward_turn_bar_bump_is_false_with_no_blocking_source() -> void:
	assert_false(Skills.BlocksForwardTurnBarBump(_character, 0))

func test_a_relics_amplification_adds_to_a_passives() -> void:
	_character._trait = FakeRelicAmplification.new(0.10)
	_equip_relic(_character, Types.Slot.Weapon, FakeRelicAmplification.new(0.05))
	var enemy: Character = TestFactory.make_character()
	var characters: Dictionary[int, Character] = {0: _character, 1: enemy}
	var sides: CombatSides = CombatSides.new([0], [1])

	var amplification: float = Skills.AppliedAttributeAmplification(0, characters, sides)

	assert_almost_eq(amplification, 0.15, 0.0001, "A Relic's own amplification adds to the wearer's own passive's")
