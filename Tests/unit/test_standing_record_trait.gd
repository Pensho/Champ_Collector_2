extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

var _owner: Character = null
var _ally: Character = null
var _enemy_a: Character = null
var _enemy_b: Character = null
var _trait: StandingRecordTrait = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_owner = TestFactory.make_character()
	_ally = TestFactory.make_character()
	_enemy_a = TestFactory.make_character()
	_enemy_b = TestFactory.make_character()
	var characters: Dictionary[int, Character] = {0: _owner, 1: _ally, 2: _enemy_a, 3: _enemy_b}
	_resolver = TestFactory.make_resolver(characters, CombatSides.new([0, 1], [2, 3]))
	_trait = StandingRecordTrait.new()
	_trait.Init(Types.Rarity.Uncommon)
	_trait.StartOfBattle(0, _resolver)

# --- Rarity table ---

func test_rate_per_infraction_table() -> void:
	var expected: Dictionary[Types.Rarity, float] = {
		Types.Rarity.Uncommon: 0.025,
		Types.Rarity.Rare: 0.03,
		Types.Rarity.Epic: 0.035,
		Types.Rarity.Legendary: 0.04,
	}
	for rarity: Types.Rarity in expected:
		assert_eq(StandingRecordTrait.GetRatePerInfraction(rarity), expected[rarity],
			"RATE_PER_INFRACTION at %s" % Types.RarityName(rarity))

# --- Increment sources ---

func test_enemy_gaining_a_buff_adds_an_infraction() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 1
	_resolver.ApplyBuff(2, buff)

	assert_eq(_trait.GetInfractions(2), 1)

func test_enemy_landing_a_debuff_on_an_owner_side_ally_adds_an_infraction() -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.duration = 1
	debuff.source_ID = 2
	_resolver.ApplyDebuff(1, debuff)

	assert_eq(_trait.GetInfractions(2), 1)

func test_enemy_placing_a_zone_adds_an_infraction() -> void:
	_resolver.PlaceZone(0, 2, TestFactory.make_lava_zone_skill())

	assert_eq(_trait.GetInfractions(2), 1)

# --- Ally-side events are excluded ---

func test_ally_gaining_a_buff_does_not_add_an_infraction() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 1
	_resolver.ApplyBuff(1, buff)

	assert_eq(_trait.GetInfractions(1), 0)

func test_ally_landing_a_debuff_on_an_owner_side_ally_does_not_add_an_infraction() -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.duration = 1
	debuff.source_ID = 1
	_resolver.ApplyDebuff(0, debuff)

	assert_eq(_trait.GetInfractions(1), 0)

func test_enemy_landing_a_debuff_on_another_enemy_does_not_add_an_infraction() -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.duration = 1
	debuff.source_ID = 2
	_resolver.ApplyDebuff(3, debuff)

	assert_eq(_trait.GetInfractions(2), 0)

# --- Cap ---

func test_infractions_cap_at_nine() -> void:
	for i in 15:
		_trait._AddInfraction(2)

	assert_eq(_trait.GetInfractions(2), StandingRecordTrait.INFRACTION_CAP)

# --- Reset ---

func test_start_of_battle_resets_the_tally() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 1
	_resolver.ApplyBuff(2, buff)
	assert_eq(_trait.GetInfractions(2), 1)

	_trait.StartOfBattle(0, _resolver)

	assert_eq(_trait.GetInfractions(2), 0)
