extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

const DETRITIVORE_PATH: String = "res://Data/Character_Traits/Grafts/Detritivore_Graft.tres"

func _make_detritivore(p_rarity: Types.Rarity) -> DetritivoreGraft:
	var graft: DetritivoreGraft = load(DETRITIVORE_PATH).duplicate(true)
	graft.Init(p_rarity)
	return graft

func test_starts_at_twenty_percent_resistance_penalty_before_any_scavenge() -> void:
	for rarity: Types.Rarity in DetritivoreGraft.SCRAP_PER_RARITY:
		var graft: DetritivoreGraft = _make_detritivore(rarity)
		var expected: int = -int(ceilf(100 * 0.20))
		assert_eq(graft.GetAttributeDelta(Types.Attribute.Resistance, 100), expected,
				"Should start at -20%% Resistance for rarity %s" % Types.RarityName(rarity))

func test_start_of_battle_resets_stacks_and_restores_the_starting_penalty() -> void:
	var graft: DetritivoreGraft = _make_detritivore(Types.Rarity.Rare)
	var roster: Dictionary = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	graft.OnScavenge(0, resolver)
	graft.OnScavenge(0, resolver)
	graft.StartOfBattle(0, resolver)

	var expected: int = -int(ceilf(100 * 0.20))
	assert_eq(graft.GetAttributeDelta(Types.Attribute.Resistance, 100), expected,
			"StartOfBattle must restore -20%, not clear the drawback to 0")

func test_each_scavenge_adds_one_uncapped_scrap_stack() -> void:
	for rarity: Types.Rarity in DetritivoreGraft.SCRAP_PER_RARITY:
		var graft: DetritivoreGraft = _make_detritivore(rarity)
		var roster: Dictionary = TestFactory.make_full_roster()
		var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
		var per_stack: float = DetritivoreGraft.SCRAP_PER_RARITY[rarity]

		for n in 3:
			graft.OnScavenge(0, resolver)
			var expected_percent: float = -0.20 + per_stack * (n + 1)
			# Mirrors GraftEffect.GetAttributeDelta's own rounding convention: ceil the
			# magnitude, then negate — not ceilf() on the negative value directly, which
			# rounds the opposite way on the float dust these sums pick up.
			var expected: int = -int(ceilf(100 * absf(expected_percent)))
			assert_eq(graft.GetAttributeDelta(Types.Attribute.Resistance, 100), expected,
					"Stack %d should scale Resistance for rarity %s" % [n + 1, Types.RarityName(rarity)])

func test_scavenge_heals_two_percent_of_max_health() -> void:
	var graft: DetritivoreGraft = _make_detritivore(Types.Rarity.Uncommon)
	var roster: Dictionary = TestFactory.make_full_roster()
	roster[0]._current_health = 1
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	graft.OnScavenge(0, resolver)

	var max_health: int = resolver.GetMaxHealth(0)
	var expected_heal: int = int(round(max_health * 0.02))
	assert_eq(roster[0]._current_health, mini(1 + expected_heal, max_health))

func test_grafted_symbiote_scavenges_when_another_characters_buff_expires() -> void:
	var symbiote: Character = Character.new()
	symbiote.InstantiateNew(load("res://Data/Character_Player_Variants/Symbiote.tres"), 0)
	symbiote._current_health = 1
	symbiote.ApplyGraft(load(DETRITIVORE_PATH))
	var ally: Character = TestFactory.make_character()
	ally._current_health = ally._attributes[Types.Attribute.Health]
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 1
	ally._active_buffs.append(buff)
	var roster: Dictionary[int, Character] = {0: symbiote, 1: ally}
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [1]))
	var attrs: Dictionary[Types.Attribute, int] = resolver.GetEffectiveAttributes(1)

	resolver.GetStatusResolver()._TriggerExistingCasterBuffs(1, attrs)

	assert_gt(symbiote._current_health, 1, "Detritivore should heal when any buff expires, anywhere")
	assert_eq((symbiote._trait as DetritivoreGraft)._stacks, 1)
