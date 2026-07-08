extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")
const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Lava zone Burning: Burning stacks by design (Concept_Document.md
# 3.2.3.2), so each trigger adds another independent Burning debuff up to the
# status-effect cap.

var _repr: CharacterRepresentation

func before_each() -> void:
	_repr = double(REPR_SCRIPT).new()
	stub(_repr, "AddStatusEffect").to_return(0)

func after_each() -> void:
	_repr.free()

func _make_lava_zone() -> Zone:
	var zone: Zone = Zone.new()
	zone._type = Types.Skill_Type.Lava_Zone
	zone._target = Types.Skill_Target.ZoneAll
	return zone

func test_lava_zone_stacks_burning() -> void:
	var character: Character = TestFactory.make_character()
	var zone: Zone = _make_lava_zone()

	Skills.ResolveZoneEffect(zone, character, 0, null, _repr)
	Skills.ResolveZoneEffect(zone, character, 0, null, _repr)

	assert_eq(character._active_debuffs.size(), 2,
		"Each Lava-zone trigger should add another stacking Burning debuff")
	for debuff in character._active_debuffs:
		assert_eq(debuff.type, Types.Debuff_Type.Burning, "Every stack should be a Burning debuff")

	zone.free()

func test_lava_zone_respects_status_cap() -> void:
	var character: Character = TestFactory.make_character()
	var zone: Zone = _make_lava_zone()

	for _i in range(GameBalance.MAX_STATUS_EFFECTS + 3):
		Skills.ResolveZoneEffect(zone, character, 0, null, _repr)

	assert_eq(character._active_debuffs.size(), GameBalance.MAX_STATUS_EFFECTS,
		"Stacking Burning must not exceed the status-effect cap")

	zone.free()
