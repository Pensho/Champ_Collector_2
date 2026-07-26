extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const TEST_GRAFT_EFFECT_PATH: String = "res://Tests/unit/helpers/Test_Graft_Effect.tres"
const SYMBIOTE_PRESET = preload("res://Data/Character_Player_Variants/Symbiote.tres")

func _make_graft_effect(p_rarity: Types.Rarity) -> TestGraftEffect:
	var graft_effect: TestGraftEffect = load(TEST_GRAFT_EFFECT_PATH).duplicate(true)
	graft_effect.Init(p_rarity)
	return graft_effect

# --- Attribute delta ---

func test_attribute_delta_scales_bonus_by_rarity() -> void:
	for rarity: Types.Rarity in TestGraftEffect.HEALTH_BONUS_PER_RARITY:
		var graft_effect: TestGraftEffect = _make_graft_effect(rarity)
		var expected: int = int(ceilf(100 * TestGraftEffect.HEALTH_BONUS_PER_RARITY[rarity]))
		assert_eq(graft_effect.GetAttributeDelta(Types.Attribute.Health, 100), expected,
				"Health bonus should scale with rarity %s" % Types.RarityName(rarity))

func test_attribute_delta_drawback_stays_flat_across_rarities() -> void:
	var expected: int = -int(ceilf(100 * absf(TestGraftEffect.SPEED_DRAWBACK)))
	for rarity: Types.Rarity in TestGraftEffect.HEALTH_BONUS_PER_RARITY:
		var graft_effect: TestGraftEffect = _make_graft_effect(rarity)
		assert_eq(graft_effect.GetAttributeDelta(Types.Attribute.Speed, 100), expected,
				"Drawback must not scale with rarity %s" % Types.RarityName(rarity))

func test_attribute_delta_defaults_to_zero_for_unlisted_attributes() -> void:
	var graft_effect: TestGraftEffect = _make_graft_effect(Types.Rarity.Epic)
	assert_eq(graft_effect.GetAttributeDelta(Types.Attribute.Attack, 100), 0)

# --- Character layering ---

func test_total_attribute_includes_graft_layer() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Epic
	var base_health: int = character._attributes[Types.Attribute.Health]
	var expected_delta: int = int(ceilf(base_health * TestGraftEffect.HEALTH_BONUS_PER_RARITY[Types.Rarity.Epic]))

	character.ApplyGraft(load(TEST_GRAFT_EFFECT_PATH))

	assert_eq(character.GetTotalAttribute(Types.Attribute.Health), base_health + expected_delta)

func test_total_attribute_includes_graft_drawback() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Rare
	var base_speed: int = character._attributes[Types.Attribute.Speed]
	var expected_delta: int = -int(ceilf(base_speed * absf(TestGraftEffect.SPEED_DRAWBACK)))

	character.ApplyGraft(load(TEST_GRAFT_EFFECT_PATH))

	assert_eq(character.GetTotalAttribute(Types.Attribute.Speed), base_speed + expected_delta)

func test_pristine_attributes_unchanged_by_graft() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Epic
	var base_health: int = character._attributes[Types.Attribute.Health]

	character.ApplyGraft(load(TEST_GRAFT_EFFECT_PATH))

	assert_eq(character._attributes[Types.Attribute.Health], base_health,
			"_attributes must stay the pristine ungrafted base")

func test_get_total_attributes_includes_graft_layer_for_every_attribute() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Epic
	var base_health: int = character._attributes[Types.Attribute.Health]
	var expected_delta: int = int(ceilf(base_health * TestGraftEffect.HEALTH_BONUS_PER_RARITY[Types.Rarity.Epic]))

	character.ApplyGraft(load(TEST_GRAFT_EFFECT_PATH))

	var totals: Dictionary[Types.Attribute, int] = character.GetTotalAttributes()
	assert_eq(totals[Types.Attribute.Health], base_health + expected_delta)

# --- ApplyGraft identity and dispatch ---

func test_apply_graft_sets_graft_and_UID() -> void:
	var character: Character = TestFactory.make_character()
	character._rarity = Types.Rarity.Rare
	var graft_effect: GraftEffect = load(TEST_GRAFT_EFFECT_PATH)

	character.ApplyGraft(graft_effect)

	assert_not_null(character._graft)
	assert_eq(character._graft_UID, graft_effect.resource_path)

func test_apply_graft_makes_trait_dispatch_the_grafts_hook() -> void:
	var character: Character = TestFactory.make_character()
	character._current_health = character._attributes[Types.Attribute.Health]
	character._rarity = Types.Rarity.Epic
	var resolver: BattleResolver = TestFactory.make_resolver({0: character}, CombatSides.new([0], []))

	character.ApplyGraft(load(TEST_GRAFT_EFFECT_PATH))
	character._trait.StartOfBattle(0, resolver)

	assert_true((character._trait as TestGraftEffect).start_of_battle_called)
	assert_eq(character._active_buffs.size(), 1, "The graft's Start_Combat hook should have applied a buff")

# --- Placeholder trait (pre-graft passive display) ---

func test_ungrafted_symbiote_shows_the_placeholder_trait() -> void:
	var character: Character = Character.new()
	character.InstantiateNew(SYMBIOTE_PRESET, 0)

	assert_true(character._trait is SymbioteTrait,
			"An ungrafted Symbiote should show the Graft placeholder trait, not go traitless")

func test_apply_graft_replaces_the_placeholder_trait() -> void:
	var character: Character = Character.new()
	character.InstantiateNew(SYMBIOTE_PRESET, 0)

	character.ApplyGraft(load(TEST_GRAFT_EFFECT_PATH))

	assert_false(character._trait is SymbioteTrait,
			"Grafting should replace the placeholder trait with the acquired GraftEffect")
	assert_true(character._trait is TestGraftEffect)

# --- Persistence round trip ---

func test_collection_serialize_deserialize_round_trips_graft() -> void:
	var collection: CharacterCollection = CharacterCollection.new()
	collection.Add(SYMBIOTE_PRESET)
	var instance_ID: int = collection.GetAllCharacters().keys()[0]
	var graft_effect: GraftEffect = load(TEST_GRAFT_EFFECT_PATH)
	collection.GetCharacter(instance_ID).ApplyGraft(graft_effect)

	var saved_data: Dictionary = collection.Serialize()

	var reloaded_collection: CharacterCollection = CharacterCollection.new()
	reloaded_collection.Deserialize(saved_data)
	var reloaded: Character = reloaded_collection.GetCharacter(instance_ID)

	assert_not_null(reloaded._graft, "Graft identity should be re-hydrated on load")
	assert_eq(reloaded._graft_UID, graft_effect.resource_path)
	assert_eq(reloaded.GetTotalAttribute(Types.Attribute.Health),
			collection.GetCharacter(instance_ID).GetTotalAttribute(Types.Attribute.Health),
			"The attribute layer should be restored")
	collection.free()
	reloaded_collection.free()

func test_save_without_graft_key_loads_as_ungrafted() -> void:
	var collection: CharacterCollection = CharacterCollection.new()
	collection.Add(SYMBIOTE_PRESET)
	var instance_ID: int = collection.GetAllCharacters().keys()[0]

	var saved_data: Dictionary = collection.Serialize()
	saved_data["characters"][0].erase("graft")

	var reloaded_collection: CharacterCollection = CharacterCollection.new()
	reloaded_collection.Deserialize(saved_data)
	var reloaded: Character = reloaded_collection.GetCharacter(instance_ID)

	assert_null(reloaded._graft, "A save without a graft key should load as ungrafted")
	collection.free()
	reloaded_collection.free()
