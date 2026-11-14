extends GutTest

const ACTS: Array[ActData] = [preload("res://Data/Adventure_Data/Acts/act_reclaimed_city.tres")]
const SLOTS: Array[Types.Slot] = [Types.Slot.Weapon, Types.Slot.OffHand, Types.Slot.Boots]

func _AssertCoversSlots(p_pool: Array[EquipmentPreset], p_owner: String) -> void:
	for slot in SLOTS:
		assert_true(p_pool.any(func(preset: EquipmentPreset) -> bool: return slot == preset._slot),
			"%s's gear pool should cover %s" % [p_owner, Types.Slot.keys()[slot]])

func test_every_act_pool_covers_all_three_slots() -> void:
	for act in ACTS:
		_AssertCoversSlots(act.gear_pool, act.display_name)

func test_every_adventure_pool_covers_all_three_slots_and_sits_in_its_act_pool() -> void:
	for act in ACTS:
		for adventure in act.adventures:
			_AssertCoversSlots(adventure.gear_pool, adventure.display_name)
			for preset in adventure.gear_pool:
				assert_true(act.gear_pool.has(preset),
					"%s's %s should be in %s's pool" % [adventure.display_name, preset._name, act.display_name])

func test_every_pool_entry_is_registered() -> void:
	for act in ACTS:
		var pools: Array = [act.gear_pool]
		for adventure in act.adventures:
			pools.append(adventure.gear_pool)
		for pool in pools:
			for preset: EquipmentPreset in pool:
				assert_false(EquipmentPresetRegistry.KeyFor(preset).is_empty(),
					"%s should be registered in PRESETS" % preset._name)
