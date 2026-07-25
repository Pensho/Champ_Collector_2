class_name ReagentLoadout extends RefCounted

var _reagent_keys: Array[String] = []
var _spent: Array[bool] = []
var _brewed: Array[bool] = []
var _potency_bonus: Array[float] = []


func _init(p_reagent_keys: Array[String]) -> void:
	_reagent_keys = p_reagent_keys.duplicate()
	_spent.resize(_reagent_keys.size())
	_spent.fill(false)
	_brewed.resize(_reagent_keys.size())
	_brewed.fill(false)
	_potency_bonus.resize(_reagent_keys.size())
	_potency_bonus.fill(0.0)


func Size() -> int:
	return _reagent_keys.size()


func KeyAt(p_index: int) -> String:
	return _reagent_keys[p_index]


func IsSpent(p_index: int) -> bool:
	return _spent[p_index]


func PotencyBonusAt(p_index: int) -> float:
	return _potency_bonus[p_index]


func AddBrewed(p_key: String, p_potency_bonus: float) -> void:
	_reagent_keys.append(p_key)
	_spent.append(false)
	_brewed.append(true)
	_potency_bonus.append(p_potency_bonus)


func TryConsume(p_index: int, p_reagent_collection: ReagentCollection) -> bool:
	if(p_index < 0 or p_index >= _spent.size() or _spent[p_index]):
		return false
	_spent[p_index] = true
	if(not _brewed[p_index]):
		p_reagent_collection.Consume(_reagent_keys[p_index])
	return true
