class_name TurnPositions extends RefCounted

## The positional turn-order queries combat resolution needs. The turn bar is both
## view and state today; this interface keeps BattleResolver free of nodes until the
## positions move into the core. The base class doubles as the headless default:
## no character overlaps a zone and nobody is behind anyone.


func IsCharacterInZone(_p_character_ID: int, _p_zone_ID: int) -> bool:
	return false


## Characters within `p_bar_percent` of the bar behind p_owner_ID; characters at or
## ahead of the owner are excluded.
func GetCharactersBehindBy(_p_owner_ID: int, _p_bar_percent: float) -> Array[int]:
	return []
