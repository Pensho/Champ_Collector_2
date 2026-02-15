extends Control

const Types = preload("res://Scripts/common_enums.gd")

#const BATTLE_TROLL = preload("res://Data/Battle_Variants/Battle_Troll.tres")
#const BATTLE_MILITIA = preload("res://Data/Battle_Variants/Battle_Militia.tres")
const BATTLE_OBSIDIAN_STALLION = preload("uid://dbc3pmbr82wcc")

const NR_OF_CHARACTERS_IN_BATTLE: int = 3
const CHARACTER_CHOSEN_COLOR: Color = Color(0.1, 0.1, 0.1)

@export var _chosen_char_texture: Array[TextureRect]
@export var _available_char_texture: Array[TextureRect]

var _chosen_characters: Dictionary[int, Character]
var _character_collection: Array[Character]
var _used_character_textures: Dictionary[Types.Role, Texture]
var _available_to_chosen_IDs: Dictionary[int, int] = {0: -1, 1: -1, 2: -1}

func Init(_p_context_container: ContextContainer) -> void:
	_character_collection = main.GetInstance()._character_collection.GetAllCharacters().values()
	var collected_types := main.GetInstance()._character_collection.GetCollectedTypes()
	for type in collected_types.keys():
		_used_character_textures[type] = load(collected_types[type])
	SetTextures()

func SetTextures() -> void:
	for slot in _available_char_texture.size():
		if (_character_collection.size() <= slot):
			return
		match _character_collection[slot]._role:
			Types.Role.Emissary:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Emissary]
			Types.Role.Cleric:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Cleric]
			Types.Role.Thief:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Thief]
			Types.Role.Knight:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Knight]
			Types.Role.Alchemist:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Alchemist]
			Types.Role.Sorcerer:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Sorcerer]
			Types.Role.Scholar:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Scholar]
			Types.Role.Diviner:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Diviner]
			Types.Role.Appraiser:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Appraiser]
			Types.Role.Tactician:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Tactician]
			Types.Role.Symbiote:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Symbiote]
			Types.Role.Jester:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Jester]
			Types.Role.Cultist:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Cultist]
			Types.Role.Bar_Brawler:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Bar_Brawler]
			Types.Role.Bloodmage:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Bloodmage]
			Types.Role.Herald_of_the_loom:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Herald_of_the_loom]
			Types.Role.Chronophage:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Chronophage]
			Types.Role.Tidal_Corsair:
				_available_char_texture[slot].texture = _used_character_textures[Types.Role.Tidal_Corsair]
			_:
				print("pre_battle_menu.gd/SetTextures() Unspecified character role!")

func _on_exit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)

func _on_start_button_up() -> void:
	if (_chosen_characters.size() <= 0):
		print("Trying to start a battle without any selected characters.")
		return
	
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = BATTLE_OBSIDIAN_STALLION
	context_container._scene = "res://Scenes/battle.tscn"
	context_container._player_battle_characters = _chosen_characters.values()
	
	main.GetInstance().change_scene(context_container)
	hide()

func _on_remove_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.has(p_char_slot)):
		_chosen_characters.erase(p_char_slot)
		_chosen_char_texture[p_char_slot].texture = null
		_available_char_texture[_available_to_chosen_IDs[p_char_slot]].self_modulate = Color(1,1,1)
	else:
		print("trying to remove a character from an empty slot nr: ", p_char_slot)

func _on_add_char_button_up(p_char_slot: int) -> void:
	if (_chosen_characters.size() >= NR_OF_CHARACTERS_IN_BATTLE):
		print("Trying to add a character when the roster is full.")
		return
	if (_character_collection.size() <= p_char_slot):
		print("Trying to add a character from an empty slot.")
		return
	for i in _chosen_characters.keys():
		if (_chosen_characters[i]._instanceID == _character_collection[p_char_slot]._instanceID):
			print("Trying to add a character already in the chosen roster.")
			return
	for i in NR_OF_CHARACTERS_IN_BATTLE:
		if (!_chosen_characters.has(i)):
			_chosen_characters[i] = _character_collection[p_char_slot]
			_chosen_char_texture[i].texture = _available_char_texture[p_char_slot].texture
			_available_char_texture[p_char_slot].self_modulate = CHARACTER_CHOSEN_COLOR
			_available_to_chosen_IDs[i] = p_char_slot
			return
