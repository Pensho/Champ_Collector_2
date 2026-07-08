extends GutTest

const REPR_SCRIPT = preload("res://Scripts/Battle/character_battle_repr.gd")
const BATTLE_UI_SCRIPT = preload("res://Scripts/UI/Battle_UI/battle_ui.gd")
const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the two Burning polish fixes: a Burning tick must show combat text
# over the burning character, and must report its damage keyed by the source that
# applied it, so the post-battle screen can credit the applier.

var _repr: CharacterRepresentation
var _battle_ui: BattleUI

func before_each() -> void:
	_repr = double(REPR_SCRIPT).new()
	stub(_repr, "SetStatusEffectDuration").to_return(null)
	stub(_repr, "RemoveStatusEffects").to_return(null)
	_battle_ui = double(BATTLE_UI_SCRIPT).new()
	stub(_battle_ui, "SpawnCombatText").to_return(null)

func after_each() -> void:
	_repr.free()
	_battle_ui.free()

func _make_burning_character(p_max_health: int, p_source_ID: int) -> Character:
	var character: Character = TestFactory.make_character()
	character._attributes[Types.Attribute.Health] = p_max_health
	character._current_health = p_max_health * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Burning
	debuff.duration = 2
	debuff.source_ID = p_source_ID
	character._active_debuffs.append(debuff)
	return character

func _expected_tick(p_max_health: int) -> int:
	return int(floor((p_max_health * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))

func test_burning_tick_spawns_combat_text() -> void:
	var character: Character = _make_burning_character(100, 0)
	Skills.TriggerExistingCasterDebuffs(character, character._attributes, _repr, _battle_ui)
	assert_called(_battle_ui, "SpawnCombatText")

func test_burning_tick_reduces_health_by_expected_amount() -> void:
	var character: Character = _make_burning_character(100, 0)
	var health_before: int = character._current_health
	Skills.TriggerExistingCasterDebuffs(character, character._attributes, _repr, _battle_ui)
	assert_eq(character._current_health, health_before - _expected_tick(100),
		"Burning should reduce health by 4% of max Health")

func test_burning_damage_attributed_to_source() -> void:
	var character: Character = _make_burning_character(100, 1)
	var damage_by_source: Dictionary[int, int] = Skills.TriggerExistingCasterDebuffs(
		character, character._attributes, _repr, _battle_ui)
	assert_true(damage_by_source.has(1), "Damage should be keyed by the applying source ID")
	assert_eq(damage_by_source[1], _expected_tick(100),
		"The source should be credited with the full Burning tick damage")

func test_stacked_burning_from_same_source_accumulates() -> void:
	var character: Character = _make_burning_character(100, 2)
	var second_stack: StatusEffects.Debuff = StatusEffects.Debuff.new()
	second_stack.type = Types.Debuff_Type.Burning
	second_stack.duration = 2
	second_stack.source_ID = 2
	character._active_debuffs.append(second_stack)

	var damage_by_source: Dictionary[int, int] = Skills.TriggerExistingCasterDebuffs(
		character, character._attributes, _repr, _battle_ui)
	assert_eq(damage_by_source[2], _expected_tick(100) * 2,
		"Two Burning stacks from one source should sum in that source's attribution")

func test_stacked_burning_from_different_sources_kept_separate() -> void:
	var character: Character = _make_burning_character(100, 0)
	var other_stack: StatusEffects.Debuff = StatusEffects.Debuff.new()
	other_stack.type = Types.Debuff_Type.Burning
	other_stack.duration = 2
	other_stack.source_ID = 1
	character._active_debuffs.append(other_stack)

	var damage_by_source: Dictionary[int, int] = Skills.TriggerExistingCasterDebuffs(
		character, character._attributes, _repr, _battle_ui)
	assert_eq(damage_by_source[0], _expected_tick(100), "Source 0 credited with its own stack")
	assert_eq(damage_by_source[1], _expected_tick(100), "Source 1 credited with its own stack")

func test_non_damaging_debuff_reports_no_damage_and_no_combat_text() -> void:
	var character: Character = TestFactory.make_character()
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Enfeeble
	debuff.duration = 2
	character._active_debuffs.append(debuff)

	var damage_by_source: Dictionary[int, int] = Skills.TriggerExistingCasterDebuffs(
		character, character._attributes.duplicate(true), _repr, _battle_ui)
	assert_eq(damage_by_source.size(), 0, "A non-damaging debuff should report no Burning damage")
	assert_not_called(_battle_ui, "SpawnCombatText")
