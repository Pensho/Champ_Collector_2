class_name TurnBarPositions extends TurnPositions

## Adapts the live TurnBar node to the TurnPositions queries BattleResolver makes.

var _turn_bar: TurnBar


func _init(p_turn_bar: TurnBar) -> void:
	_turn_bar = p_turn_bar


func IsCharacterInZone(p_character_ID: int, p_zone_ID: int) -> bool:
	return _turn_bar.IsCharacterInZone(p_character_ID, p_zone_ID)


func GetCharactersBehindBy(p_owner_ID: int, p_bar_percent: float) -> Array[int]:
	return _turn_bar.GetCharactersBehindBy(p_owner_ID, p_bar_percent)
