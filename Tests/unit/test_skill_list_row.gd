extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func test_cooldown_text_empty_when_zero() -> void:
	assert_eq(SkillListRow.CooldownText(0), "")

func test_cooldown_text_shows_value_when_nonzero() -> void:
	assert_eq(SkillListRow.CooldownText(3), "CD 3")

func test_passive_label_ungrafted_symbiote() -> void:
	var character: Character = TestFactory.make_character()
	character._role = Types.Role.Symbiote
	character._trait = CharacterTrait.new()
	character._trait._title = "Placeholder"
	character._graft = null

	assert_eq(SkillListRow.PassiveLabel(character), "Ungrafted")

func test_passive_label_grafted_symbiote_shows_graft_title() -> void:
	var character: Character = TestFactory.make_character()
	character._role = Types.Role.Symbiote
	character.ApplyGraft(GraftEffect.new())
	character._trait._title = "Spreading Rot"

	assert_eq(SkillListRow.PassiveLabel(character), "Spreading Rot")

func test_passive_label_non_symbiote_shows_trait_title() -> void:
	var character: Character = TestFactory.make_character()
	character._role = Types.Role.Lancer
	character._trait = CharacterTrait.new()
	character._trait._title = "Ash Offering"

	assert_eq(SkillListRow.PassiveLabel(character), "Ash Offering")
