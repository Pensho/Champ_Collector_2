class_name Collection extends Node

const Types = preload("res://Scripts/common_enums.gd")

const COLLECTION_SIZE_INCREMENT: int = 10
const COLLECTION_LIMIT: int = 200

var _characters: Dictionary[int, Character] = {}
var _current_max_amount: int = 50
var _collected_types: Dictionary[Types.Role, String]

func Save() -> void:
	pass

func Load() -> void:
	pass

func Add(preset: CharacterPreset) -> void:
	if(not IsTheCollectionFull()):
		var new_character: Character = load("res://Scenes/Characters/Character.tscn").instantiate()
		new_character.InstantiateNew(preset, CreateNextInstanceID())
		_characters[new_character._instanceID] = new_character
		
		if(!_collected_types.has(new_character._role)):
			_collected_types[new_character._role] = new_character._texture

func Remove(instanceID: int) -> void:
	if(!_characters.erase(instanceID)):
		print("There was no such character to be removed! ID: ", instanceID)
	# TODO: If there no longer is a type of role in the collection, remove it from _collected_types.

func IncreaseCollectionSize() -> void:
	if(_current_max_amount <= (COLLECTION_LIMIT - COLLECTION_SIZE_INCREMENT)):
		_current_max_amount += COLLECTION_SIZE_INCREMENT
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
