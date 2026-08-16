extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const APPRAISER = preload("res://Data/Character_Player_Variants/Appraiser.tres")

# Full Appraisal (Appraiser skill index 2): consigns the caster's own crit attributes to an
# ally (Keen Edge, Lethal Precision, both applier-scaled) and applies Consigned to the caster
# itself, zeroing the same attributes there for the duration.

func _appraiser_character(p_index: int = 0) -> Character:
	var character: Character = Character.new()
	character.InstantiateNew(APPRAISER, p_index)
	character._current_health = character._attributes[Types.Attribute.Health]
	return character

func _make_roster() -> Dictionary[int, Character]:
	var ally: Character = TestFactory.make_character()
	ally._current_health = ally._attributes[Types.Attribute.Health]
	var roster: Dictionary[int, Character] = {0: _appraiser_character(0), 1: ally}
	roster[0]._attributes[Types.Attribute.CritChance] = 60
	roster[0]._attributes[Types.Attribute.CritDamage] = 250
	return roster

func test_full_appraisal_grants_the_ally_the_casters_crit_attributes() -> void:
	var roster: Dictionary[int, Character] = _make_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0, 1], []))

	resolver.ResolveSkill(0, [1], 2)

	var keen_edge: Array = roster[1]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Keen_Edge)
	var lethal_precision: Array = roster[1]._active_buffs.filter(
			func(b): return b.type == Types.Buff_Type.Lethal_Precision)
	assert_eq(keen_edge.size(), 1, "The target ally should gain Keen Edge")
	assert_almost_eq(keen_edge[0].value, 60.0, 0.0001, "Keen Edge should carry the caster's own Critical Chance")
	assert_eq(lethal_precision.size(), 1, "The target ally should gain Lethal Precision")
	assert_almost_eq(lethal_precision[0].value, 250.0, 0.0001,
		"Lethal Precision should carry the caster's own Critical Damage")

func test_full_appraisal_zeroes_the_casters_own_crit_attributes() -> void:
	var roster: Dictionary[int, Character] = _make_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0, 1], []))

	resolver.ResolveSkill(0, [1], 2)

	var consigned: Array = roster[0]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Consigned)
	assert_eq(consigned.size(), 1, "The caster should gain Consigned")
	assert_eq(consigned[0].duration, 3)
	var effective: Dictionary[Types.Attribute, int] = resolver.GetEffectiveAttributes(0)
	assert_eq(effective[Types.Attribute.CritChance], 0, "The caster's own effective Critical Chance should be zeroed")
	assert_eq(effective[Types.Attribute.CritDamage], 0, "The caster's own effective Critical Damage should be zeroed")

func test_full_appraisal_does_not_grant_keen_edge_to_the_caster() -> void:
	var roster: Dictionary[int, Character] = _make_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0, 1], []))

	resolver.ResolveSkill(0, [1], 2)

	var self_keen_edge: Array = roster[0]._active_buffs.filter(func(b): return b.type == Types.Buff_Type.Keen_Edge)
	assert_eq(self_keen_edge.size(), 0, "Full Appraisal targets Ally_Not_Self and must not also buff the caster")
