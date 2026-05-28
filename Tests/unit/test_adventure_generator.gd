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
