class_name Collection extends Node

func Save() -> void:
	pass

func Load() -> void:
	pass

func Add(preset: CharacterPreset) -> void:
	if(not IsTheCollectionFull()):
		var new_character: Character = load("res://Scenes/Characters/Character.tscn").instantiate()
		new_character.InstantiateNew(preset, CreateNextInstanceID())
		m_Characters[new_character._instanceID] = new_character

func Remove(instanceID: int) -> void:
	if(!m_Characters.erase(instanceID)):
		print("There was no such character to be removed! ID: ", instanceID)

func IncreaseCollectionSize() -> void:
	if(m_CurrentMaxAmount <= (k_CollectionLimit - k_CollectionSizeIncrement)):
		m_CurrentMaxAmount += k_CollectionSizeIncrement
	else:
		print("The maximum size of a collection has been reached.")

func IsTheCollectionFull() -> bool:
	if (m_Characters.size() >= m_CurrentMaxAmount):
		print("You've reached the current max amount of characters.")
		return true
	else:
		return false

func CreateNextInstanceID() -> int:
	var nextID: int = 0
	if(m_Characters.size() == 0):
		return nextID

	while m_Characters.has(nextID):
		nextID += 1

	return nextID

func GetCharacter(instanceID: int) -> Character:
	if(m_Characters.has(instanceID)):
			return m_Characters[instanceID]
	else:
		print("No character found with ID: ", instanceID)
		return null

func GetAllCharacters() -> Dictionary:
	return m_Characters

func Size() -> int:
	return m_Characters.size()

var m_Characters: Dictionary = {}
var m_CurrentMaxAmount: int = 50

const k_CollectionSizeIncrement: int = 10
const k_CollectionLimit: int = 200
