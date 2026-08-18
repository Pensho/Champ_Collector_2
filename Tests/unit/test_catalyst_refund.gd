extends GutTest

## Coverage for BattleResolver.TryRefundBrew (Scripts/Battle/battle_resolver.gd): Catalyst
## Cloud's payload, refunding an Alchemist brew-pool reagent when its holder consumes a
## non-brew reagent. Kept off the Battle scene node per Test_Design_Document.md.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const A_REAGENT_KEY: String = "Tincture_Speed_Uncommon"

var _collection: ReagentCollection = null

func before_each() -> void:
	_collection = ReagentCollection.new()

func after_each() -> void:
	_collection.free()

func _make_alchemist() -> Character:
	var alchemist: Character = TestFactory.make_character()
	alchemist._current_health = alchemist._attributes[Types.Attribute.Health]
	var alchemist_trait: FreshBatchTrait = FreshBatchTrait.new()
	alchemist_trait.Init(Types.Rarity.Epic)
	alchemist._trait = alchemist_trait
	return alchemist

func _spent_loadout() -> ReagentLoadout:
	var loadout: ReagentLoadout = ReagentLoadout.new([A_REAGENT_KEY])
	loadout.TryConsume(0, _collection)
	return loadout

func test_refund_lands_when_catalyst_present_and_slot_not_brewed() -> void:
	var alchemist: Character = _make_alchemist()
	var characters: Dictionary[int, Character] = {0: alchemist}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], []))
	var loadout: ReagentLoadout = _spent_loadout()

	var refunded: bool = resolver.TryRefundBrew(loadout, 0, 0, true, false)

	assert_true(refunded)
	assert_true(loadout.IsBrewed(0))
	assert_false(loadout.IsSpent(0))

func test_no_refund_without_catalyst() -> void:
	var alchemist: Character = _make_alchemist()
	var characters: Dictionary[int, Character] = {0: alchemist}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], []))
	var loadout: ReagentLoadout = _spent_loadout()

	var refunded: bool = resolver.TryRefundBrew(loadout, 0, 0, false, false)

	assert_false(refunded)
	assert_false(loadout.IsBrewed(0))

func test_no_refund_when_the_spent_slot_was_itself_brewed() -> void:
	var alchemist: Character = _make_alchemist()
	var characters: Dictionary[int, Character] = {0: alchemist}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], []))
	var loadout: ReagentLoadout = ReagentLoadout.new([])
	loadout.AddBrewed("Lesser_Restorative_Brew", 0.0)
	loadout.TryConsume(0, _collection)

	var refunded: bool = resolver.TryRefundBrew(loadout, 0, 0, true, true)

	assert_false(refunded, "A brewed slot refunding itself would never terminate")

func test_no_refund_without_a_living_brewer() -> void:
	var non_alchemist: Character = TestFactory.make_character()
	non_alchemist._current_health = non_alchemist._attributes[Types.Attribute.Health]
	var characters: Dictionary[int, Character] = {0: non_alchemist}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0], []))
	var loadout: ReagentLoadout = _spent_loadout()

	var refunded: bool = resolver.TryRefundBrew(loadout, 0, 0, true, false)

	assert_false(refunded)
	assert_false(loadout.IsBrewed(0))

func test_no_refund_for_a_dead_ally_alchemist() -> void:
	var alchemist: Character = _make_alchemist()
	alchemist._current_health = 0
	var consumer: Character = TestFactory.make_character()
	consumer._current_health = consumer._attributes[Types.Attribute.Health]
	var characters: Dictionary[int, Character] = {0: alchemist, 1: consumer}
	var resolver: BattleResolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], []))
	var loadout: ReagentLoadout = _spent_loadout()

	var refunded: bool = resolver.TryRefundBrew(loadout, 0, 1, true, false)

	assert_false(refunded, "A dead Alchemist must not be able to brew a refund")
