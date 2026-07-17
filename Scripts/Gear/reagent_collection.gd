class_name ReagentCollection extends Node

## Persistent player-owned reagent inventory, keyed by the ReagentRegistry identifier
## string. Mirrors Scripts/Gear/item_collection.gd structurally.

var _reagent_counts: Dictionary[String, int] = {}

func _ready() -> void:
	self.name = self.get_script().get_global_name()
	add_to_group(SaveManager.GROUP_SAVEABLE)

func Add(p_reagent_key: String, p_amount: int = 1) -> void:
	_reagent_counts[p_reagent_key] = _reagent_counts.get(p_reagent_key, 0) + p_amount

func Consume(p_reagent_key: String) -> bool:
	if(not _reagent_counts.has(p_reagent_key)):
		return false
	_reagent_counts[p_reagent_key] -= 1
	if(_reagent_counts[p_reagent_key] <= 0):
		_reagent_counts.erase(p_reagent_key)
	return true

func GetCount(p_reagent_key: String) -> int:
	return _reagent_counts.get(p_reagent_key, 0)

func GetAllOwned() -> Dictionary[String, int]:
	return _reagent_counts

func Serialize() -> Dictionary:
	return {"counts": _reagent_counts.duplicate()}

func Deserialize(p_data: Dictionary) -> void:
	if(not p_data.has("counts")):
		print("No reagent counts found in save slot.")
		return

	_reagent_counts.clear()
	for reagent_key in p_data["counts"].keys():
		if(not ReagentRegistry.REAGENTS.has(reagent_key)):
			print("Skipping unknown reagent key from save: ", reagent_key)
			continue
		_reagent_counts[reagent_key] = int(p_data["counts"][reagent_key])
