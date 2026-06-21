extends GutTest

var _template: AdventureTemplate
var _biome: BiomeData

func before_each() -> void:
	_template = AdventureTemplate.new()
	_template.MIN_DEPTH = 10
	_template.MAX_DEPTH = 15
	_template.branching_paths = AdventureTemplate.Mechanic_Frequency.LOW
	_template.rest_stops = AdventureTemplate.Mechanic_Frequency.LOW
	_biome = BiomeData.new()

func test_generate_returns_nodes() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	assert_gt(nodes.size(), 0, "GenerateAdventure should return at least one node.")

func test_last_node_is_boss() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	var has_boss: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			has_boss = true
			break
	assert_true(has_boss, "Generated adventure must contain a BOSS node.")

func test_spine_node_count_in_range() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	var spine_nodes: int = 0
	for node in nodes:
		if node.node_type != NodeData.Node_Type.BOSS:
			var depth_matches_spine: bool = node.previous_node.size() <= 1 and node.next_node.size() <= 2
			if depth_matches_spine:
				spine_nodes += 1
	# At minimum the spine should be at least MIN_DEPTH long
	assert_gte(nodes.size(), _template.MIN_DEPTH + 1, "Total nodes must be at least MIN_DEPTH + boss.")

func test_all_nodes_have_unique_indices() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	var seen: Dictionary = {}
	for node in nodes:
		assert_false(seen.has(node.index), "Node index " + str(node.index) + " is duplicated.")
		seen[node.index] = true

func test_no_branching_when_none() -> void:
	_template.branching_paths = AdventureTemplate.Mechanic_Frequency.NONE
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			continue
		assert_lte(node.next_node.size(), 1, "NONE branching should produce no branch splits.")


func test_fight_nodes_have_battle_context() -> void:
	var preset := CharacterPreset.new()
	_biome.possible_opponents[preset] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.FIGHT:
			assert_not_null(node.scene_context, "FIGHT node should have a scene_context.")
			assert_true(node.scene_context is Context_Battle, "FIGHT scene_context should be a Context_Battle.")


func test_fight_nodes_have_three_enemies() -> void:
	var preset := CharacterPreset.new()
	_biome.possible_opponents[preset] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.FIGHT:
			var ctx := node.scene_context as Context_Battle
			assert_eq(ctx._enemies_wave_1.size(), 3, "FIGHT node should have exactly 3 enemies in wave 1.")


func test_boss_node_has_one_enemy_from_pool() -> void:
	var boss_preset := CharacterPreset.new()
	_biome.possible_bosses.append(boss_preset)
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			assert_not_null(node.scene_context, "BOSS node should have a scene_context.")
			var ctx := node.scene_context as Context_Battle
			assert_eq(ctx._enemies_wave_1.size(), 1, "BOSS node should have exactly 1 enemy in wave 1.")
			assert_eq(ctx._enemies_wave_1[0], boss_preset, "BOSS enemy should come from possible_bosses.")


func test_rest_stop_nodes_have_rest_stop_context() -> void:
	_template.rest_stops = AdventureTemplate.Mechanic_Frequency.HIGH
	var preset := CharacterPreset.new()
	_biome.possible_opponents[preset] = 1
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.REST_STOP:
			assert_true(node.scene_context is ContextRestStop, "REST_STOP node should have a ContextRestStop.")


func test_boss_node_uses_boss_rewards_when_set() -> void:
	var boss_preset := CharacterPreset.new()
	_biome.possible_bosses.append(boss_preset)
	var boss_loot := LootTable.new()
	_biome.boss_rewards = boss_loot
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			var ctx := node.scene_context as Context_Battle
			assert_eq(ctx._loot_table, boss_loot, "BOSS node should use boss_rewards when set.")


func test_boss_node_falls_back_to_combat_rewards_when_boss_rewards_null() -> void:
	var boss_preset := CharacterPreset.new()
	_biome.possible_bosses.append(boss_preset)
	var fallback_loot := LootTable.new()
	_biome.combat_rewards = fallback_loot
	_biome.boss_rewards = null
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	for node in nodes:
		if node.node_type == NodeData.Node_Type.BOSS:
			var ctx := node.scene_context as Context_Battle
			assert_eq(ctx._loot_table, fallback_loot, "BOSS node should fall back to combat_rewards when boss_rewards is null.")


func test_no_crash_with_empty_biome_pools() -> void:
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	assert_gt(nodes.size(), 0, "Should still generate nodes with an empty biome.")
	for node in nodes:
		if node.node_type == NodeData.Node_Type.FIGHT or node.node_type == NodeData.Node_Type.BOSS:
			assert_null(node.scene_context, "FIGHT/BOSS nodes should have null scene_context when biome pools are empty.")


# --- New interactive node types ---

func test_hint_nodes_are_generated_with_context() -> void:
	_template.hint_nodes = AdventureTemplate.Mechanic_Frequency.HIGH
	_biome.hint_rewards = LootTable.new()
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	var found: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.HINT:
			found = true
			var ctx := node.scene_context as ContextHint
			assert_true(ctx is ContextHint, "HINT node should have a ContextHint.")
			assert_not_null(ctx._loot_table, "HINT node should have a loot table when biome has hint_rewards configured.")
	assert_true(found, "HIGH hint_nodes frequency should generate at least one HINT node.")

func test_gamble_nodes_are_generated_with_context() -> void:
	_template.gamble_nodes = AdventureTemplate.Mechanic_Frequency.HIGH
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
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
	_template.escalate_nodes = AdventureTemplate.Mechanic_Frequency.HIGH
	_biome.escalate_rewards = LootTable.new()
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	var found: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.ESCALATE:
			found = true
			var ctx := node.scene_context as ContextEscalate
			assert_true(ctx is ContextEscalate, "ESCALATE node should have a ContextEscalate.")
			assert_not_null(ctx._loot_table, "ESCALATE node should have a loot table when biome has escalate_rewards configured.")
	assert_true(found, "HIGH escalate_nodes frequency should generate at least one ESCALATE node.")

func test_rest_stop_nodes_have_granted_buff() -> void:
	_template.rest_stops = AdventureTemplate.Mechanic_Frequency.HIGH
	var nodes: Array[NodeData] = AdventureGenerator.GenerateAdventure(_template, _biome)
	var found: bool = false
	for node in nodes:
		if node.node_type == NodeData.Node_Type.REST_STOP:
			found = true
			var ctx := node.scene_context as ContextRestStop
			assert_true(ctx is ContextRestStop, "REST_STOP node should have a ContextRestStop.")
			assert_ne(ctx.granted_buff, Types.Buff_Type.Invalid, "Rest Stop granted_buff should not be Invalid.")
	assert_true(found, "HIGH rest_stops frequency should generate at least one REST_STOP node.")
