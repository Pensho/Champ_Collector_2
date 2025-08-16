class_name Collection extends Node

func Save() -> void:
	pass

func Load() -> void:
	pass

func Add(character: CharacterData) -> void:
	if(not IsTheCollectionFull()):
		character._instanceID = CreateNextInstanceID()
		m_Characters[character._instanceID] = character

func Remove(character: CharacterData) -> void:
	if(!m_Characters.erase(character._instanceID)):
		print("There was no such character to be removed! ID: ", character._instanceID)

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

func GetCharacter(instanceID: int) -> CharacterData:
	if(m_Characters.has(instanceID)):
			return m_Characters[instanceID]
	else:
		print("No character found with ID: ", instanceID)
		return null

func GetAllCharacters() -> Dictionary:
	return m_Characters

var m_Characters: Dictionary = {}
var m_CurrentMaxAmount: int = 50

const k_CollectionSizeIncrement: int = 10
const k_CollectionLimit: int = 200
