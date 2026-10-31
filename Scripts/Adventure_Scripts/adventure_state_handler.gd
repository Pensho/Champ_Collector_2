class_name AdventureStateHandler extends Node

var _state: AdventureState = AdventureState.new()

func Serialize() -> Dictionary:
	if not _state.is_active:
		return {}
	return _state.Serialize()

## A fresh state on every load: a slot with no run must not inherit the one in memory.
func Deserialize(p_data: Dictionary) -> void:
	_state = AdventureState.new()
	if p_data.is_empty():
		return
	_state.Deserialize(p_data)

func Reset() -> void:
	_state = AdventureState.new()
