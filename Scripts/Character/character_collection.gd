class_name Collection extends Node

const Types = preload("res://Scripts/common_enums.gd")

const COLLECTION_SIZE_INCREMENT: int = 10
const COLLECTION_LIMIT: int = 200

var m_characters: Dictionary[int, Character] = {}
var m_current_max_amount: int = 50
var m_collected_types: Array[Types.Role]

func Save() -> void:
	pass

func Load() -> void:
	pass

func Add(preset: CharacterPreset) -> void:
	if(not IsTheCollectionFull()):
		var new_character: Character = load("res://Scenes/Characters/Character.tscn").instantiate()
		new_character.InstantiateNew(preset, CreateNextInstanceID())
		m_characters[new_character._instanceID] = new_character
		
		if(!m_collected_types.has(new_character._role)):
			m_collected_types.append(new_character._role)

func Remove(instanceID: int) -> void:
	if(!m_characters.erase(instanceID)):
		print("There was no such character to be removed! ID: ", instanceID)
	# TODO: If there no longer is a type of role in the collection, remove it from m_collected_types.

func IncreaseCollectionSize() -> void:
	if(m_current_max_amount <= (COLLECTION_LIMIT - COLLECTION_SIZE_INCREMENT)):
		m_current_max_amount += COLLECTION_SIZE_INCREMENT
	else:
		print("The maximum size of a collection has been reached.")

func IsTheCollectionFull() -> bool:
	if (m_characters.size() >= m_current_max_amount):
		print("You've reached the current max amount of characters.")
		return true
	else:
		return false

func CreateNextInstanceID() -> int:
	var nextID: int = 0
	if(m_characters.size() == 0):
		return nextID

	while m_characters.has(nextID):
		nextID += 1

	return nextID

func GetCharacter(instanceID: int) -> Character:
	if(m_characters.has(instanceID)):
			return m_characters[instanceID]
	else:
		print("No character found with ID: ", instanceID)
		return null

func GetAllCharacters() -> Dictionary[int, Character]:
	return m_characters.duplicate(true)

func GetCollectedTypes() -> Array[Types.Role]:
	return m_collected_types

func Size() -> int:
	return m_characters.size()
