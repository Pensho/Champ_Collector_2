class_name CharacterCollection extends Node

var _characters: Dictionary[int, Character] = {}
var _current_max_amount: int = Game_Balance.COLLECTION_START_ROSTER_SIZE
var _collected_types: Dictionary[String, String]
var _used_character_textures: Dictionary[String, Texture]
var _next_ID: int = 0

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

func Serialize() -> Dictionary:
	var character_data: Array = []
	for character : Character in _characters.values():
		character_data.append({
			"preset_UID": character._preset_UID,
			"experience": character._experience,
			"level": character._level,
			"attributes": character._attributes.duplicate(true),
			"held_items": character._held_items.duplicate(true),
			"instance_ID": character._instanceID,
			"attribute_weights": character._attributes_weights._name
			# TODO: get skills when they are no longer defined by a characters preset.
		})
	
	return {"characters": character_data, "max_amount": _current_max_amount, "next_ID": _next_ID}

func Deserialize(p_data: Dictionary) -> void:
	if(not p_data.has("characters")):
		print("No characters found in save slot.")
		return
	
	_next_ID = 0
	_characters.clear()
	if(p_data.has("max_amount")):
		_current_max_amount = p_data["max_amount"]
	
	for character_data in p_data["characters"]:
		var preset: CharacterPreset = load(character_data["preset_UID"]).duplicate(true)
		var new_character: Character = load("uid://s7cyusnkyl53").instantiate()
		new_character.InstantiateNew(preset, character_data["instance_ID"])
		new_character._level = int(character_data["level"])
		new_character._experience = int(character_data["experience"])
		if(character_data.has("attribute_weights")):
			for attribute_weight_type in preset._attribute_weight_types_available:
				if(attribute_weight_type._name == character_data["attribute_weights"]):
					new_character._attributes_weights = attribute_weight_type.duplicate(true)
					break
		
		_next_ID = max(_next_ID, new_character._instanceID)
		
		for attribute in character_data["attributes"].keys():
			new_character._attributes[attribute as int] = character_data["attributes"][attribute] as int
		
		for held_item in character_data["held_items"].keys():
			new_character._held_items[held_item as int] = character_data["held_items"][held_item] as int
		
		_characters[new_character._instanceID] = new_character
	
	LoadTextures()
	print("Calling Deserialize for CharacterCollection")

func LoadTextures() -> void:
	for type in _collected_types.keys():
		if(!_used_character_textures.has(type)):
			_used_character_textures[type] = load(_collected_types[type])

func GetCharacterTexture(p_character_name: String) -> Texture:
	return _used_character_textures[p_character_name]

func Add(preset: CharacterPreset) -> void:
	if(not IsTheCollectionFull()):
		var new_character: Character = load("res://Scenes/Characters/Character.tscn").instantiate()
		new_character.InstantiateNew(preset, CreateNextInstanceID())
		_characters[new_character._instanceID] = new_character
		
		if(!_collected_types.has(new_character._name)):
			_collected_types[new_character._name] = new_character._texture
			_used_character_textures[new_character._name] = load(new_character._texture)

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
	_next_ID += 1
	return _next_ID - 1

func GetCharacter(instanceID: int) -> Character:
	if(_characters.has(instanceID)):
			return _characters[instanceID]
	else:
		print("No character found with ID: ", instanceID)
		return null

func GetAllCharacters() -> Dictionary[int, Character]:
	return _characters.duplicate(true)

func Size() -> int:
	return _characters.size()
