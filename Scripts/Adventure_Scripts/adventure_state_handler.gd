class_name AdventureStateHandler extends Node

var _state: AdventureState = AdventureState.new()

func Serialize() -> Dictionary:
	if not _state.is_active:
		return {}
	return _state.Serialize()

func Deserialize(p_data: Dictionary) -> void:
	if p_data.is_empty():
		return
	_state.Deserialize(p_data)
