class_name CombatTeam extends RefCounted

## One side of a battle: the ordered slot IDs of its members. Membership is fixed at
## battle start; aliveness is always evaluated against the characters dictionary, so a
## dead or never-filled slot can never be selected.

var members: Array[int] = []


func _init(p_members: Array[int] = []) -> void:
	members = p_members.duplicate()


func Has(p_character_ID: int) -> bool:
	return members.has(p_character_ID)


func AliveMembers(p_characters: Dictionary[int, Character]) -> Array[int]:
	var alive_IDs: Array[int] = []
	for character_ID in members:
		if(p_characters.has(character_ID) and p_characters[character_ID]._current_health > 0):
			alive_IDs.append(character_ID)
	return alive_IDs


## Returns -1 when no member is alive. Pass a RandomNumberGenerator for a
## deterministic pick; without one the global random number generator is used.
func RandomAliveMember(
		p_characters: Dictionary[int, Character],
		p_random_generator: RandomNumberGenerator = null) -> int:
	var alive_IDs: Array[int] = AliveMembers(p_characters)
	if(alive_IDs.is_empty()):
		return -1
	if(null == p_random_generator):
		return alive_IDs.pick_random()
	return alive_IDs[p_random_generator.randi_range(0, alive_IDs.size() - 1)]
