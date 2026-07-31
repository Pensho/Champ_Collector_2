extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const SYMBIOTIC_ANCHOR_PATH: String = "res://Data/Character_Traits/Grafts/Symbiotic_Anchor_Graft.tres"

var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null

func before_each() -> void:
	_main_inst = Main_Instance.new()
	_item_col = ItemCollection.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst

func after_each() -> void:
	_item_col.free()
	_main_inst.free()
	main._instance = null

# BattleResolver.GetEffectiveAttributes is the single source of truth for a combatant's
# current attributes: five ordered, individually-attributable steps applied live on every
# call (base -> gear -> graft -> reagent long-bonus -> active status modifiers). This test
# stacks all five at once and locks in the exact running value at each step, so a change to
# the ordering (which matters, since graft and status percentages read the running total)
# shows up as a precise, explainable failure rather than a vague mismatch.
func test_composes_base_gear_graft_reagent_and_status_in_order() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var character: Character = roster[0]
	character._attributes[Types.Attribute.Defence] = 6  # 1. base

	var weapon: Equipment = Equipment.new()
	weapon._slot = Types.Slot.Weapon
	weapon._attributes[Types.Attribute.Defence] = 4  # 2. gear: running 6 -> 10
	_item_col._items[0] = weapon
	character.EquipItem(0)

	character.ApplyGraft(load(SYMBIOTIC_ANCHOR_PATH))  # 3. graft: -30% of running 10 -> 7

	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	resolver.AdjustLongAttributeBonus(0, Types.Attribute.Defence, 5)  # 4. reagent: running 7 -> 12

	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify).magnitude
	character._active_buffs.append(fortify)  # 5. status: +30% of running 12 -> 16

	assert_eq(resolver.GetEffectiveAttributes(0)[Types.Attribute.Defence], 16,
		"base 6 -> gear +4 -> 10 -> graft -30%% -> 7 -> reagent +5 -> 12 -> status +30%% -> 16")
	weapon.free()

func test_no_contributors_leaves_attributes_at_base() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.Attack] = 42
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	assert_eq(resolver.GetEffectiveAttributes(0)[Types.Attribute.Attack], 42)

func test_each_call_recomputes_live_rather_than_returning_a_cached_snapshot() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var before: int = resolver.GetEffectiveAttributes(0)[Types.Attribute.Defence]
	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify).magnitude
	roster[0]._active_buffs.append(fortify)
	var after: int = resolver.GetEffectiveAttributes(0)[Types.Attribute.Defence]

	assert_gt(after, before,
		"A status applied after an earlier read must show up on the next GetEffectiveAttributes call")
