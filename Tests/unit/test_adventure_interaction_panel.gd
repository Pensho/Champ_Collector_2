extends GutTest

func test_escalate_accepted_grants_reagents_from_loot_table() -> void:
	var panel := AdventureInteractionPanel.new()
	panel._state = AdventureState.new()

	var context := ContextEscalate.new()
	context._loot_table = LootTable.new()
	context._loot_table._drop_result._silver = 5
	context._loot_table._drop_result._supplies = 2
	context._loot_table._drop_result._reagents = ["Sigil_Speed_Uncommon"]

	var reagent_collection: ReagentCollection = main.GetInstance()._reagent_collection
	var count_before: int = reagent_collection.GetCount("Sigil_Speed_Uncommon")

	panel._on_escalate_accepted(context)

	assert_eq(
			reagent_collection.GetCount("Sigil_Speed_Uncommon"),
			count_before + 1,
			"Accepting an Escalate node should grant its guaranteed reagent to the player's collection")
	panel.free()

func test_escalate_accepted_grants_multiple_reagents() -> void:
	var panel := AdventureInteractionPanel.new()
	panel._state = AdventureState.new()

	var context := ContextEscalate.new()
	context._loot_table = LootTable.new()
	context._loot_table._drop_result._reagents = ["Sigil_Speed_Uncommon", "Sigil_Speed_Rare"]

	var reagent_collection: ReagentCollection = main.GetInstance()._reagent_collection
	var uncommon_before: int = reagent_collection.GetCount("Sigil_Speed_Uncommon")
	var rare_before: int = reagent_collection.GetCount("Sigil_Speed_Rare")

	panel._on_escalate_accepted(context)

	assert_eq(reagent_collection.GetCount("Sigil_Speed_Uncommon"), uncommon_before + 1)
	assert_eq(reagent_collection.GetCount("Sigil_Speed_Rare"), rare_before + 1)
	panel.free()
