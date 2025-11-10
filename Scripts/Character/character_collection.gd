class_name CharacterCollection extends Node

const Types = preload("res://Scripts/common_enums.gd")

var _characters: Dictionary[int, Character] = {}
var _current_max_amount: int = Game_Balance.COLLECTION_START_ROSTER_SIZE
var _collected_types: Dictionary[Types.Role, String]
var _used_character_textures: Dictionary[Types.Role, Texture]

func Save() -> void:
	pass

func Load() -> void:
	pass

func LoadTextures() -> void:
	for type in _collected_types.keys():
		_used_character_textures[type] = load(_collected_types[type])

func GetCharacterTexture(p_character_role: Types.Role) -> Texture:
	match p_character_role:
		Types.Role.Emissary:
			return _used_character_textures[Types.Role.Emissary]
		Types.Role.Cleric:
			return _used_character_textures[Types.Role.Cleric]
		Types.Role.Thief:
			return _used_character_textures[Types.Role.Thief]
		Types.Role.Knight:
			return _used_character_textures[Types.Role.Knight]
		Types.Role.Alchemist:
			return _used_character_textures[Types.Role.Alchemist]
		Types.Role.Sorcerer:
			return _used_character_textures[Types.Role.Sorcerer]
		Types.Role.Scholar:
			return _used_character_textures[Types.Role.Scholar]
		Types.Role.Diviner:
			return _used_character_textures[Types.Role.Diviner]
		Types.Role.Appraiser:
			return _used_character_textures[Types.Role.Appraiser]
		Types.Role.Tactician:
			return _used_character_textures[Types.Role.Tactician]
		Types.Role.Symbiote:
			return _used_character_textures[Types.Role.Symbiote]
		Types.Role.Jester:
			return _used_character_textures[Types.Role.Jester]
		Types.Role.Cultist:
			return _used_character_textures[Types.Role.Cultist]
		Types.Role.Bar_Brawler:
			return _used_character_textures[Types.Role.Bar_Brawler]
		Types.Role.Bloodmage:
			return _used_character_textures[Types.Role.Bloodmage]
		Types.Role.Herald_of_the_loom:
			return _used_character_textures[Types.Role.Herald_of_the_loom]
		_:
			print("pre_battle_menu.gd/GetCharacterTexture() Unspecified character role!")
	return null

func Add(preset: CharacterPreset) -> void:
	if(not IsTheCollectionFull()):
		var new_character: Character = load("res://Scenes/Characters/Character.tscn").instantiate()
		new_character.InstantiateNew(preset, CreateNextInstanceID())
		_characters[new_character._instanceID] = new_character
		
		if(!_collected_types.has(new_character._role)):
			_collected_types[new_character._role] = new_character._texture
			_used_character_textures[new_character._role] = load(new_character._texture)

func Remove(instanceID: int) -> void:
	if(!_characters.erase(instanceID)):
		print("There was no such character to be removed! ID: ", instanceID)
	# TODO: If there no longer is a type of role in the collection, remove it from _collected_types.

func IncreaseCollectionSize() -> void:
	if(_current_max_amount <= (Game_Balance.COLLECTION_LIMIT - Game_Balance.COLLECTION_SIZE_INCREMENT)):
		_current_max_amount += Game_Balance.COLLECTION_SIZE_INCREMENT
	else:
		print("The maximum size of a collection has been reached.")

func IsTheCollectionFull() -> bool:
	if (_characters.size() >= _current_max_amount):
		print("You've reached the current max amount of characters.")
		return true
	else:
		return false

func CreateNextInstanceID() -> int:
	var nextID: int = 0
	if(_characters.size() == 0):
		return nextID

	while _characters.has(nextID):
		nextID += 1

	return nextID

func GetCharacter(instanceID: int) -> Character:
	if(_characters.has(instanceID)):
			return _characters[instanceID]
	else:
		print("No character found with ID: ", instanceID)
		return null

func GetAllCharacters() -> Dictionary[int, Character]:
	return _characters.duplicate(true)

func GetCollectedTypes() -> Dictionary[Types.Role, String]:
	return _collected_types

func Size() -> int:
	return _characters.size()
