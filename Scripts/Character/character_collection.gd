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
			"preset_path": character._preset_path,
			"experience": character._experience,
			"level": character._level,
			"attributes": character._attributes.duplicate(true),
			"held_items": character._held_items.duplicate(true),
			"instance_ID": character._instance_ID,
			"attribute_weights": character._attributes_weights._name,
			"graft": character._graft_UID
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
		var preset_path: String = character_data.get("preset_path", character_data.get("preset_UID", ""))
		if preset_path.is_empty():
			push_error("Skipping character with empty preset_path (instance_ID: %d)" % character_data.get("instance_ID", -1))
			continue
		var preset_resource: Resource = load(preset_path)
		if preset_resource == null:
			push_error("Skipping character with unresolvable preset_path '%s' (instance_ID: %d)" %
				[preset_path, character_data.get("instance_ID", -1)])
			continue
		var preset: CharacterPreset = preset_resource.duplicate(true)
		var new_character: Character = Character.new()
		new_character.InstantiateNew(preset, character_data["instance_ID"])
		new_character._level = int(character_data["level"])
		new_character._experience = int(character_data["experience"])
		if(character_data.has("attribute_weights")):
			for attribute_weight_type in preset._attribute_weight_types_available:
				if(attribute_weight_type._name == character_data["attribute_weights"]):
					new_character._attributes_weights = attribute_weight_type.duplicate(true)
					break
		
		_next_ID = max(_next_ID, new_character._instance_ID)
		
		for attribute in character_data["attributes"].keys():
			new_character._attributes[attribute as int] = character_data["attributes"][attribute] as int
		
		for held_item in character_data["held_items"].keys():
			new_character._held_items[held_item as int] = character_data["held_items"][held_item] as int

		if(character_data.has("graft") and not (character_data["graft"] as String).is_empty()):
			var graft_effect: GraftEffect = load(character_data["graft"])
			new_character.ApplyGraft(graft_effect)

		_characters[new_character._instance_ID] = new_character
	
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
		var new_character: Character = Character.new()
		new_character.InstantiateNew(preset, CreateNextInstanceID())
		_characters[new_character._instance_ID] = new_character
		
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
	print("The maximum size of a collection has been reached.")

func IsTheCollectionFull() -> bool:
	if (_characters.size() >= _current_max_amount):
		print("You've reached the current max amount of characters.")
		return true
	return false

func CreateNextInstanceID() -> int:
	_next_ID += 1
	return _next_ID - 1

func GetCharacter(instanceID: int) -> Character:
	if(_characters.has(instanceID)):
		return _characters[instanceID]
	print("No character found with ID: ", instanceID)
	return null

func GetAllCharacters() -> Dictionary[int, Character]:
	return _characters.duplicate(true)

func Size() -> int:
	return _characters.size()

func GetCollectedTypeCount() -> int:
	return _collected_types.size()

func GetOwnedChampionNames() -> Dictionary[String, bool]:
	var owned_names: Dictionary[String, bool] = {}
	for character : Character in _characters.values():
		owned_names[character._name] = true
	return owned_names

func GetHighestCharacterLevel() -> int:
	var highest_level: int = 0
	for character : Character in _characters.values():
		highest_level = max(highest_level, character._level)
	return highest_level
