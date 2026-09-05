extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _character: Character = null
var _main_inst: Main_Instance = null
var _item_col: ItemCollection = null

func before_each():
	_character = Character.new()
	_main_inst = Main_Instance.new()
	_item_col = ItemCollection.new()
	_main_inst._item_collection = _item_col
	main._instance = _main_inst

func after_each():
	_item_col.free()
	_main_inst.free()
	main._instance = null

func test_one_rank_grants_six_percent_of_base() -> void:
	_character._attributes[Types.Attribute.Attack] = 100
	_character.AddRenown(Types.Attribute.Attack)
	assert_eq(_character.GetBaseAttributes()[Types.Attribute.Attack], 106)

func test_speed_rank_grants_three_percent_of_base() -> void:
	_character._attributes[Types.Attribute.Speed] = 100
	_character.AddRenown(Types.Attribute.Speed)
	assert_eq(_character.GetBaseAttributes()[Types.Attribute.Speed], 103)

func test_five_ranks_in_one_attribute_stack_uncapped() -> void:
	_character._attributes[Types.Attribute.Attack] = 100
	for i in range(5):
		_character.AddRenown(Types.Attribute.Attack)
	assert_eq(_character.GetRenownRank(), 5)
	assert_eq(_character.GetBaseAttributes()[Types.Attribute.Attack], 130)

func test_sixth_rank_is_refused() -> void:
	_character._attributes[Types.Attribute.Attack] = 100
	for i in range(6):
		_character.AddRenown(Types.Attribute.Attack)
	assert_eq(_character.GetRenownRank(), 5)
	assert_false(_character.CanGainRenown())

func test_attribute_outside_renown_set_is_refused() -> void:
	_character.AddRenown(Types.Attribute.CritChance)
	_character.AddRenown(Types.Attribute.CritDamage)
	assert_eq(_character.GetRenownRank(), 0)

func test_bonus_grows_after_level_up_with_no_reapplication_call() -> void:
	_character._attributes[Types.Attribute.Attack] = 100
	_character.AddRenown(Types.Attribute.Attack)
	assert_eq(_character.GetBaseAttributes()[Types.Attribute.Attack], 106)
	_character._attributes[Types.Attribute.Attack] = 200
	assert_eq(_character.GetBaseAttributes()[Types.Attribute.Attack], 212)

func test_truncation_applies_to_the_total_not_per_rank() -> void:
	# base=9, 6%: floor(9*3*6/100) = floor(1.62) = 1. A naive per-rank truncation
	# (floor(9*6/100)=0, times 3 ranks) would wrongly give 0.
	_character._attributes[Types.Attribute.Attack] = 9
	for i in range(3):
		_character.AddRenown(Types.Attribute.Attack)
	assert_eq(_character.GetBaseAttributes()[Types.Attribute.Attack], 10)

func test_renown_rank_for_tracks_each_attribute_independently() -> void:
	_character.AddRenown(Types.Attribute.Attack)
	_character.AddRenown(Types.Attribute.Attack)
	_character.AddRenown(Types.Attribute.Speed)
	assert_eq(_character.GetRenownRankFor(Types.Attribute.Attack), 2)
	assert_eq(_character.GetRenownRankFor(Types.Attribute.Speed), 1)
	assert_eq(_character.GetRenownRankFor(Types.Attribute.Defence), 0)

func test_renown_bonus_does_not_scale_off_equipped_gear() -> void:
	_character._attributes[Types.Attribute.Attack] = 100
	_character.AddRenown(Types.Attribute.Attack)
	var weapon: Equipment = Equipment.new()
	weapon._slot = Types.Slot.Weapon
	weapon._attributes[Types.Attribute.Attack] = 50
	_item_col._items[0] = weapon
	_character.EquipItem(0)
	assert_eq(_character.GetTotalAttribute(Types.Attribute.Attack), 106 + 50)
	weapon.free()

func test_renown_percent_bonus_is_independent_of_level() -> void:
	# The percentage is the number that stays true across level-ups; the absolute
	# attribute value is not. Two ranks in Attack always reads as +12%, regardless
	# of the raw base value behind it.
	_character._attributes[Types.Attribute.Attack] = 50
	_character.AddRenown(Types.Attribute.Attack)
	_character.AddRenown(Types.Attribute.Attack)
	assert_eq(_character.GetRenownPercentBonus(Types.Attribute.Attack), 12)
	_character._attributes[Types.Attribute.Attack] = 300
	assert_eq(_character.GetRenownPercentBonus(Types.Attribute.Attack), 12)

func test_renown_percent_per_rank_matches_speed_and_other_attributes() -> void:
	assert_eq(_character.GetRenownPercentPerRank(Types.Attribute.Speed), 3)
	assert_eq(_character.GetRenownPercentPerRank(Types.Attribute.Attack), 6)

func test_duplicate_candidates_share_name_and_exclude_self() -> void:
	var ascending: Character = TestFactory.make_character()
	var duplicate_character: Character = TestFactory.make_character()
	var other_name: Character = TestFactory.make_character()
	other_name._name = "SomeoneElse"
	var collection: Dictionary[int, Character] = {0: ascending, 1: duplicate_character, 2: other_name}

	var candidates: Array[int] = InspectCollectionMenu.GetDuplicateCandidateIDs(collection, 0)

	assert_eq(candidates, [1])

func test_no_duplicates_returns_empty_candidate_list() -> void:
	var ascending: Character = TestFactory.make_character()
	var other_name: Character = TestFactory.make_character()
	other_name._name = "SomeoneElse"
	var collection: Dictionary[int, Character] = {0: ascending, 1: other_name}

	var candidates: Array[int] = InspectCollectionMenu.GetDuplicateCandidateIDs(collection, 0)

	assert_eq(candidates.size(), 0, "An empty candidate list is what disables the Ascend picker")
