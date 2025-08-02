class_name Collection extends Node

func Save() -> void:
	pass

func Load() -> void:
	pass

func Add(character: Character) -> void:
	#if(there is no character already with the parameter ones instanceID)
		#Add the new character unless we meet the limit
	#else
		#Warn that we already had a character with that instanceID
	pass

func Remove(character: Character) -> void:
	#if(there is a character using the instanceID of the parameter)
		#Remove the character
	#else
		#Warn that there was no such character
	pass

func IncreaseCollectionSize() -> void:
	if(m_CurrentMaxAmount <= (k_CollectionLimit - k_CollectionSizeIncrement)):
		m_CurrentMaxAmount += k_CollectionSizeIncrement
	else:
		print("The maximum size of a collection has been reached.")

func IsTheCollectionFull() -> bool:
	return (m_Characters.size() >= m_CurrentMaxAmount)

func CreateNextInstanceID() -> int:
	var nextID: int = 0
	if(m_Characters.size() == 0):
		return nextID
	
	#for i in range(0, m_Characters.size()):
		#if(no character is using the instanceID "i"):
			#nextID = i
			#break

	return nextID

func GetCharacter(instanceID: int) -> Character:
	return m_Characters[m_Characters.find(instanceID)]

func GetAllCharacters() -> Array[Character]:
	return m_Characters

var m_Characters: Array[Character] = []
var m_CurrentMaxAmount: int = 50

const k_CollectionSizeIncrement: int = 10
const k_CollectionLimit: int = 200
