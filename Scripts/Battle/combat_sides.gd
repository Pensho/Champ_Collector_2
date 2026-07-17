class_name CombatSides extends RefCounted

## Groups the two teams of a battle and answers every ally/enemy membership question,
## replacing the fixed PLAYER_IDS/ENEMY_IDS slot ranges. Built once in Battle.Init from
## the actual roster sizes and passed to whatever needs side information.

var player: CombatTeam
var enemy: CombatTeam


func _init(p_player_IDs: Array[int] = [], p_enemy_IDs: Array[int] = []) -> void:
	player = CombatTeam.new(p_player_IDs)
	enemy = CombatTeam.new(p_enemy_IDs)


func Has(p_character_ID: int) -> bool:
	return player.Has(p_character_ID) or enemy.Has(p_character_ID)


## Returns null for an ID that is on neither team.
func SideOf(p_character_ID: int) -> CombatTeam:
	if(player.Has(p_character_ID)):
		return player
	if(enemy.Has(p_character_ID)):
		return enemy
	return null


## Returns null for an ID that is on neither team.
func AlliesOf(p_character_ID: int) -> CombatTeam:
	return SideOf(p_character_ID)


## Returns null for an ID that is on neither team.
func EnemiesOf(p_character_ID: int) -> CombatTeam:
	var side: CombatTeam = SideOf(p_character_ID)
	if(side == player):
		return enemy
	if(side == enemy):
		return player
	return null


## True only when both IDs are on the same team; a character counts as its own ally.
func AreAllies(p_character_ID_a: int, p_character_ID_b: int) -> bool:
	var side_a: CombatTeam = SideOf(p_character_ID_a)
	return null != side_a and side_a == SideOf(p_character_ID_b)


## True only when both IDs are known and on opposing teams.
func AreEnemies(p_character_ID_a: int, p_character_ID_b: int) -> bool:
	var side_a: CombatTeam = SideOf(p_character_ID_a)
	var side_b: CombatTeam = SideOf(p_character_ID_b)
	return null != side_a and null != side_b and side_a != side_b


## Every combatant slot ID across both teams, players first.
func AllMembers() -> Array[int]:
	var all_IDs: Array[int] = []
	all_IDs.append_array(player.members)
	all_IDs.append_array(enemy.members)
	return all_IDs


## Random living combatant from either team, -1 when everyone is dead.
func RandomAliveMember(
		p_characters: Dictionary[int, Character],
		p_random_generator: RandomNumberGenerator = null) -> int:
	return CombatTeam.new(AllMembers()).RandomAliveMember(p_characters, p_random_generator)
