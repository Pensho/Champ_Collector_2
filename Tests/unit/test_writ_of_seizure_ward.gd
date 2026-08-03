extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const NOTARY_PRESET_PATH: String = "res://Data/Character_Enemy_Variants/Warded_Notary.tres"
const COLLECTOR_PRESET_PATH: String = "res://Data/Character_Enemy_Variants/Collector_of_Debts.tres"

## Wiring test for the Collector-of-Debts encounter's Writ of Seizure ward: with the real
## Warded_Notary and Collector_of_Debts presets in play, the Notary's steal_buff_to target
## (Ally_Not_Self) must route the stolen buff to the Collector, not back onto itself or the
## champion it was stolen from.

func test_writ_of_seizure_steals_the_champions_buff_onto_the_collector() -> void:
	var roster: Dictionary[int, Character] = {}
	var champion: Character = TestFactory.make_character()
	champion._current_health = champion._attributes[Types.Attribute.Health]
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 3
	champion._active_buffs.append(buff)
	roster[0] = champion

	var notary: Character = Character.new()
	notary.InstantiateNew(load(NOTARY_PRESET_PATH), 3)
	roster[3] = notary

	var collector: Character = Character.new()
	collector.InstantiateNew(load(COLLECTOR_PRESET_PATH), 4)
	roster[4] = collector

	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [3, 4]))

	resolver.ResolveSkill(3, [0], 0)

	assert_eq(roster[0]._active_buffs.size(), 0, "The champion should lose the stolen buff")
	assert_eq(roster[4]._active_buffs.size(), 1, "The Collector should receive the stolen buff")
	if(roster[4]._active_buffs.size() > 0):
		assert_eq(roster[4]._active_buffs[0].type, Types.Buff_Type.Empower)
		assert_eq(roster[4]._active_buffs[0].duration, 2, "Writ of Seizure grants a fresh 2-turn duration")
	assert_eq(roster[3]._active_buffs.size(), 0, "The Notary itself must never receive its own steal")
