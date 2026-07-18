class_name ReagentLoadout extends RefCounted

var _reagent_keys: Array[String] = []
var _spent: Array[bool] = []


func _init(p_reagent_keys: Array[String]) -> void:
	_reagent_keys = p_reagent_keys.duplicate()
	_spent.resize(_reagent_keys.size())
	_spent.fill(false)


func Size() -> int:
	return _reagent_keys.size()


func KeyAt(p_index: int) -> String:
	return _reagent_keys[p_index]


func IsSpent(p_index: int) -> bool:
	return _spent[p_index]


func TryConsume(p_index: int, p_reagent_collection: ReagentCollection) -> bool:
	if(p_index < 0 or p_index >= _spent.size() or _spent[p_index]):
		return false
	_spent[p_index] = true
	p_reagent_collection.Consume(_reagent_keys[p_index])
	return true
