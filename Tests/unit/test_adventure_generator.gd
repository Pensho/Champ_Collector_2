extends GutTest

var _layout: AdventureLayout
var _adventure: AdventureData

func before_each() -> void:
	_layout = AdventureLayout.new()
	_layout.MIN_DEPTH = 10
	_layout.MAX_DEPTH = 15
	_layout.branching_paths = AdventureLayout.Mechanic_Frequency.LOW
	_layout.rest_stops = AdventureLayout.Mechanic_Frequency.LOW
	_adventure = AdventureData.new()
	_adventure.layout = _layout

func test_generate_returns_nodes() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	assert_gt(nodes.size(), 0, "GenerateAdventure should return at least one node.")

func test_last_node_is_boss() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var has_boss: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			has_boss = true
			break
	assert_true(has_boss, "Generated adventure must contain a BOSS node.")

func test_spine_node_count_in_range() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var spine_nodes: int = 0
	for node in nodes:
		if node.node_type != NodeData.Node_Type.BOSS:
			var depth_matches_spine: bool = node.previous_node.size() <= 1 and node.next_node.size() <= 2
			if depth_matches_spine:
				spine_nodes += 1
	# At minimum the spine should be at least MIN_DEPTH long
	assert_gte(nodes.size(), _layout.MIN_DEPTH + 1, "Total nodes must be at least MIN_DEPTH + boss.")

func test_all_nodes_have_unique_indices() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var seen: Dictionary = {}
	for node in nodes:
		assert_false(seen.has(node.index), "Node index " + str(node.index) + " is duplicated.")
		seen[node.index] = true

func test_no_branching_when_none() -> void:
	_layout.branching_paths = AdventureLayout.Mechanic_Frequency.NONE
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			continue
		assert_lte(node.next_node.size(), 1, "NONE branching should produce no branch splits.")


func _MakeVariant(p_enemies: Array[CharacterPreset]) -> Context_Battle:
	var variant := Context_Battle.new()
	variant._enemies_wave_1 = p_enemies
	return variant


func _FightContexts(p_nodes: Array[NodeData]) -> Array[Context_Battle]:
	var contexts: Array[Context_Battle]
	for node in p_nodes:
		if node.node_type == NodeData.Node_Type.FIGHT:
			contexts.append(node.scene_context as Context_Battle)
	return contexts


func test_fight_nodes_have_battle_context() -> void:
	_adventure.battle_variants[_MakeVariant([CharacterPreset.new()])] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.FIGHT:
			assert_not_null(node.scene_context, "FIGHT node should have a scene_context.")
			assert_true(node.scene_context is Context_Battle, "FIGHT scene_context should be a Context_Battle.")


func test_fight_node_fields_exactly_one_variant_composition() -> void:
	var preset_a := CharacterPreset.new()
	var preset_b := CharacterPreset.new()
	var composition_a: Array[CharacterPreset] = [preset_a, preset_a, preset_a]
	var composition_b: Array[CharacterPreset] = [preset_b, preset_b]
	_adventure.battle_variants[_MakeVariant(composition_a)] = 1
	_adventure.battle_variants[_MakeVariant(composition_b)] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for context in _FightContexts(nodes):
		assert_true(context._enemies_wave_1 == composition_a or context._enemies_wave_1 == composition_b,
			"A FIGHT node's wave should be one variant's whole composition, never a per-slot mix.")


func test_fight_node_uses_adventure_loot_over_variant_loot() -> void:
	var variant := _MakeVariant([CharacterPreset.new()])
	variant._loot_table = LootTable.new()
	_adventure.battle_variants[variant] = 1
	var adventure_loot := LootTable.new()
	_adventure.combat_rewards = adventure_loot
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for context in _FightContexts(nodes):
		assert_eq(context._loot_table, adventure_loot, "The adventure's loot table should override the variant's.")


func test_mutating_node_context_leaves_variant_untouched() -> void:
	var variant_loot := LootTable.new()
	var variant := _MakeVariant([CharacterPreset.new()])
	variant._loot_table = variant_loot
	_adventure.battle_variants[variant] = 1
	_adventure.combat_rewards = LootTable.new()
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var context: Context_Battle = _FightContexts(nodes)[0]
	assert_ne(context, variant, "A FIGHT node should hold a copy of the variant, not the variant itself.")
	context._enemies_wave_1.append(CharacterPreset.new())
	assert_eq(variant._enemies_wave_1.size(), 1, "Changing a node's wave should not change the variant's wave.")
	assert_eq(variant._loot_table, variant_loot, "Overriding a node's loot table should not change the variant's.")


func test_regenerating_with_same_seed_rolls_same_variants() -> void:
	for i in 4:
		_adventure.battle_variants[_MakeVariant([CharacterPreset.new()])] = 1
	seed(1234)
	var first_waves: Array = _FightContexts(AdventureGenerator.GenerateAdventure(_adventure)).map(
		func(context: Context_Battle) -> CharacterPreset: return context._enemies_wave_1[0])
	seed(1234)
	var second_waves: Array = _FightContexts(AdventureGenerator.GenerateAdventure(_adventure)).map(
		func(context: Context_Battle) -> CharacterPreset: return context._enemies_wave_1[0])
	assert_eq(second_waves, first_waves, "A regenerated adventure should roll the same variant on every node.")


func test_boss_node_fields_boss_variant_composition() -> void:
	var boss_preset := CharacterPreset.new()
	_adventure.boss_battle_variants.append(_MakeVariant([boss_preset]))
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			assert_not_null(node.scene_context, "BOSS node should have a scene_context.")
			var ctx := node.scene_context as Context_Battle
			assert_eq(ctx._enemies_wave_1.size(), 1, "BOSS node should field the boss variant's composition.")
			assert_eq(ctx._enemies_wave_1[0], boss_preset, "BOSS enemy should come from boss_battle_variants.")


func test_rest_stop_nodes_have_rest_stop_context() -> void:
	_layout.rest_stops = AdventureLayout.Mechanic_Frequency.HIGH
	_adventure.battle_variants[_MakeVariant([CharacterPreset.new()])] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.REST_STOP:
			assert_true(node.scene_context is ContextRestStop, "REST_STOP node should have a ContextRestStop.")


func test_boss_node_uses_boss_rewards_when_set() -> void:
	_adventure.boss_battle_variants.append(_MakeVariant([CharacterPreset.new()]))
	var boss_loot := LootTable.new()
	_adventure.boss_rewards = boss_loot
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			var ctx := node.scene_context as Context_Battle
			assert_eq(ctx._loot_table, boss_loot, "BOSS node should use boss_rewards when set.")


func test_boss_node_falls_back_to_combat_rewards_when_boss_rewards_null() -> void:
	_adventure.boss_battle_variants.append(_MakeVariant([CharacterPreset.new()]))
	var fallback_loot := LootTable.new()
	_adventure.combat_rewards = fallback_loot
	_adventure.boss_rewards = null
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			var ctx := node.scene_context as Context_Battle
			assert_eq(ctx._loot_table, fallback_loot, "BOSS node should fall back to combat_rewards when boss_rewards is null.")


func test_no_crash_with_empty_adventure_pools() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	assert_gt(nodes.size(), 0, "Should still generate nodes with empty variant pools.")
	for node in nodes:
		if node.node_type == NodeData.Node_Type.FIGHT or node.node_type == NodeData.Node_Type.BOSS:
			assert_null(node.scene_context, "FIGHT/BOSS nodes should have null scene_context when variant pools are empty.")


# --- New interactive node types ---

func test_hint_nodes_are_generated_with_context() -> void:
	_layout.hint_nodes = AdventureLayout.Mechanic_Frequency.HIGH
	_adventure.hint_rewards = LootTable.new()
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var found: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.HINT:
			found = true
			var ctx := node.scene_context as ContextHint
			assert_true(ctx is ContextHint, "HINT node should have a ContextHint.")
			assert_not_null(ctx._loot_table, "HINT node should have a loot table when the adventure has hint_rewards configured.")
	assert_true(found, "HIGH hint_nodes frequency should generate at least one HINT node.")

func test_gamble_nodes_are_generated_with_context() -> void:
	_layout.gamble_nodes = AdventureLayout.Mechanic_Frequency.HIGH
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var found: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.GAMBLE:
			found = true
			var ctx := node.scene_context as ContextGamble
			assert_true(ctx is ContextGamble, "GAMBLE node should have a ContextGamble.")
			assert_ne(ctx.win_buff, Types.Buff_Type.Invalid, "Gamble win_buff should not be Invalid.")
			assert_ne(ctx.loss_debuff, Types.Debuff_Type.Invalid, "Gamble loss_debuff should not be Invalid.")
	assert_true(found, "HIGH gamble_nodes frequency should generate at least one GAMBLE node.")

func test_escalate_nodes_are_generated_with_context() -> void:
	_layout.escalate_nodes = AdventureLayout.Mechanic_Frequency.HIGH
	_adventure.escalate_rewards = LootTable.new()
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var found: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.ESCALATE:
			found = true
			var ctx := node.scene_context as ContextEscalate
			assert_true(ctx is ContextEscalate, "ESCALATE node should have a ContextEscalate.")
			assert_not_null(ctx._loot_table, "ESCALATE node should have a loot table when the adventure has escalate_rewards configured.")
	assert_true(found, "HIGH escalate_nodes frequency should generate at least one ESCALATE node.")

func test_rest_stop_nodes_have_granted_buff() -> void:
	_layout.rest_stops = AdventureLayout.Mechanic_Frequency.HIGH
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	var found: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.REST_STOP:
			found = true
			var ctx := node.scene_context as ContextRestStop
			assert_true(ctx is ContextRestStop, "REST_STOP node should have a ContextRestStop.")
			assert_ne(ctx.granted_buff, Types.Buff_Type.Invalid, "Rest Stop granted_buff should not be Invalid.")
	assert_true(found, "HIGH rest_stops frequency should generate at least one REST_STOP node.")

func test_fight_nodes_draw_stage_from_adventure_biome() -> void:
	var stage := PackedScene.new()
	_adventure.biome = BiomeData.new()
	_adventure.biome.stage_scenes.append(stage)
	_adventure.battle_variants[_MakeVariant([CharacterPreset.new()])] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for context in _FightContexts(nodes):
		assert_eq(context._stage_scene, stage, "FIGHT nodes should use a stage from the adventure's biome.")

func test_variant_stage_wins_over_biome_stage() -> void:
	var variant_stage := PackedScene.new()
	_adventure.biome = BiomeData.new()
	_adventure.biome.stage_scenes.append(PackedScene.new())
	var variant := _MakeVariant([CharacterPreset.new()])
	variant._stage_scene = variant_stage
	_adventure.battle_variants[variant] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for context in _FightContexts(nodes):
		assert_eq(context._stage_scene, variant_stage, "A variant's own stage should be kept over the biome's.")

func test_fight_nodes_have_no_stage_without_biome() -> void:
	_adventure.battle_variants[_MakeVariant([CharacterPreset.new()])] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_adventure)
	for context in _FightContexts(nodes):
		assert_null(context._stage_scene, "FIGHT nodes should fall back to no stage when the adventure has no biome.")

func _PoolBuffs(p_nodes: Array[NodeData], p_node_type: NodeData.Node_Type) -> Array[Types.Buff_Type]:
	var buffs: Array[Types.Buff_Type]
	for node in p_nodes:
		if node.node_type != p_node_type:
			continue
		if node.scene_context is ContextRestStop:
			buffs.append((node.scene_context as ContextRestStop).granted_buff)
		else:
			buffs.append((node.scene_context as ContextGamble).win_buff)
	return buffs

func _AssertBuffsDrawnFromPool(p_node_type: NodeData.Node_Type) -> void:
	var pool := AdventureBuffPool.new()
	pool.buffs = [Types.Buff_Type.Fortify, Types.Buff_Type.Haste]
	_adventure.buff_pool = pool
	for _run in 10:
		var buffs: Array[Types.Buff_Type] = _PoolBuffs(AdventureGenerator.GenerateAdventure(_adventure), p_node_type)
		assert_false(buffs.is_empty(), "HIGH frequency should generate at least one node of type %s." % p_node_type)
		for buff in buffs:
			assert_true(pool.buffs.has(buff), "Buff %s is outside the adventure's buff pool." % buff)

func test_rest_stop_buffs_drawn_from_adventure_pool() -> void:
	_layout.rest_stops = AdventureLayout.Mechanic_Frequency.HIGH
	_AssertBuffsDrawnFromPool(NodeData.Node_Type.REST_STOP)

func test_gamble_win_buffs_drawn_from_adventure_pool() -> void:
	_layout.rest_stops = AdventureLayout.Mechanic_Frequency.NONE
	_layout.gamble_nodes = AdventureLayout.Mechanic_Frequency.HIGH
	_AssertBuffsDrawnFromPool(NodeData.Node_Type.GAMBLE)

func test_empty_buff_pool_falls_back_to_any_buff() -> void:
	_layout.rest_stops = AdventureLayout.Mechanic_Frequency.HIGH
	_adventure.buff_pool = AdventureBuffPool.new()
	var buffs: Array[Types.Buff_Type] = _PoolBuffs(
			AdventureGenerator.GenerateAdventure(_adventure), NodeData.Node_Type.REST_STOP)
	assert_false(buffs.is_empty(), "HIGH rest_stops frequency should generate at least one REST_STOP node.")
	for buff in buffs:
		assert_ne(buff, Types.Buff_Type.Invalid, "Fallback buff should not be Invalid.")
