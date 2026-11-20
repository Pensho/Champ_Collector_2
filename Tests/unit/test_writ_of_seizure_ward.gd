extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const WRIT_OF_SEIZURE_PATH: String = "res://Data/Character_Skill_Variants/Attack_Skills/Writ_of_Seizure.tres"

## Wiring test for the Writ of Seizure skill: its steal_buff_to target (Ally_Not_Self)
## must route the stolen buff to the caster's ally, not back onto the caster or the
## champion it was stolen from.

func _make_alive_character() -> Character:
	var character: Character = TestFactory.make_character()
	character._current_health = character._attributes[Types.Attribute.Health]
	return character

func test_writ_of_seizure_steals_the_champions_buff_onto_the_casters_ally() -> void:
	var roster: Dictionary[int, Character] = {}
	var champion: Character = _make_alive_character()
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Empower
	buff.duration = 3
	champion._active_buffs.append(buff)
	roster[0] = champion

	var caster: Character = _make_alive_character()
	caster._skills.append((load(WRIT_OF_SEIZURE_PATH) as Skill).duplicate(true))
	roster[3] = caster

	var ally: Character = _make_alive_character()
	roster[4] = ally

	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [3, 4]))

	resolver.ResolveSkill(3, [0], 0)

	assert_eq(roster[0]._active_buffs.size(), 0, "The champion should lose the stolen buff")
	assert_eq(roster[4]._active_buffs.size(), 1, "The caster's ally should receive the stolen buff")
	if(roster[4]._active_buffs.size() > 0):
		assert_eq(roster[4]._active_buffs[0].type, Types.Buff_Type.Empower)
		assert_eq(roster[4]._active_buffs[0].duration, 2, "Writ of Seizure grants a fresh 2-turn duration")
	assert_eq(roster[3]._active_buffs.size(), 0, "The caster must never receive its own steal")
