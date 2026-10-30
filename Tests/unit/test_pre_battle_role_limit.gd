extends GutTest

func _character(p_role: Types.Role) -> Character:
	var character: Character = Character.new()
	character._role = p_role
	autofree(character)
	return character

func test_role_already_chosen_rejects_a_second_character_of_that_role() -> void:
	var chosen: Dictionary[int, Character] = {0: _character(Types.Role.Lancer)}
	assert_true(PreBattleMenu.RoleAlreadyChosen(chosen, _character(Types.Role.Lancer)))

func test_role_already_chosen_allows_a_different_role() -> void:
	var chosen: Dictionary[int, Character] = {0: _character(Types.Role.Lancer)}
	assert_false(PreBattleMenu.RoleAlreadyChosen(chosen, _character(Types.Role.Thief)))

func test_role_already_chosen_allows_any_role_on_an_empty_team() -> void:
	var chosen: Dictionary[int, Character] = {}
	assert_false(PreBattleMenu.RoleAlreadyChosen(chosen, _character(Types.Role.Lancer)))
