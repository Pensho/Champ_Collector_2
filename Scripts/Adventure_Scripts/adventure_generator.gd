class_name AdventureGenerator extends Node


static func GenerateAdventure(p_template: AdventureTemplate, p_biome: BiomeData) -> Array[NodeData]:
	var nodes: Array[NodeData]
	
	var num_nodes: int = randi_range(p_template.MIN_NODES, p_template.MAX_NODES)
	var start_node: NodeData = NodeData.new()
	start_node.depth = 0
	start_node.node_type = NodeData.Node_Type.FIGHT
	start_node.depth = 0
	nodes.append(start_node)
	var end_node: NodeData = NodeData.new()
	end_node.node_type = NodeData.Node_Type.BOSS
	nodes.append(end_node)

	var rest_stops: int = SetRestNumber(p_template.rest_stops)
	var branches: int = SetNumberOfBranchingPaths(p_template.branching_paths)
	var branch_length: int = SetBranchLength(p_template.branching_paths)
	if(1 <= branches):
		branch_length = num_nodes

	while (nodes.size() < num_nodes):
		nodes.append(CreateBranch(start_node, branch_length, rest_stops, branches))

	for i in nodes.size():
		nodes[i].index = i
		if(nodes[i].depth > end_node.depth):
			end_node.depth = nodes[i].depth + 1

	return nodes

static func CreateBranch(
			p_start_node: NodeData,
			p_length: int,
			p_rest_stops: int,
			p_branches: int
			) -> Array[NodeData]:
	var branch_nodes: Array[NodeData]
	for i in p_length:
		var node: NodeData = NodeData.new()
		node.depth = p_start_node.depth + 1 + i
		branch_nodes.append(node)
	for i in branch_nodes.size():
		if (i == 0):
			p_start_node.next_node.append(branch_nodes[i])
			branch_nodes[i].previous_node.append(p_start_node)
		else:
			branch_nodes[i - 1].next_node.append(branch_nodes[i])
			branch_nodes[i].previous_node.append(branch_nodes[i - 1])
	return branch_nodes

static func SetRestNumber(p_frequency: AdventureTemplate.Mechanic_Frequency) -> int:
	match p_frequency:
		AdventureTemplate.Mechanic_Frequency.LOW:
			return randi_range(0, 1)
		AdventureTemplate.Mechanic_Frequency.MEDIUM:
			return randi_range(2, 3)
		AdventureTemplate.Mechanic_Frequency.HIGH:
			return randi_range(3, 5)
		AdventureTemplate.Mechanic_Frequency.NONE, _:
			return 0

static func SetNumberOfBranchingPaths(p_frequency: AdventureTemplate.Mechanic_Frequency) -> int:
	match p_frequency:
		AdventureTemplate.Mechanic_Frequency.LOW:
			return randi_range(1, 2)
		AdventureTemplate.Mechanic_Frequency.MEDIUM:
			return randi_range(2, 3)
		AdventureTemplate.Mechanic_Frequency.HIGH:
			return randi_range(3, 5)
		AdventureTemplate.Mechanic_Frequency.NONE, _:
			return 0

static func SetBranchLength(p_frequency: AdventureTemplate.Mechanic_Frequency) -> int:
	match p_frequency:
		AdventureTemplate.Mechanic_Frequency.LOW:
			return randi_range(3, 5)
		AdventureTemplate.Mechanic_Frequency.MEDIUM:
			return randi_range(2, 4)
		AdventureTemplate.Mechanic_Frequency.HIGH:
			return randi_range(2, 3)
		AdventureTemplate.Mechanic_Frequency.NONE, _:
			return 0

# static func SetBranchingPaths(nodes: Array[NodeData], number_of_branching_paths: int, branch_length: int) -> void:
# 	var possible_branch_points: Array[NodeData] = nodes.slice(0, nodes.size() - 1)
# 	for i in number_of_branching_paths:
# 		if (possible_branch_points.size() == 0):
# 			break
# 		var branch_point_index: int = randi_range(0, possible_branch_points.size() - 1)
# 		var branch_point: NodeData = possible_branch_points[branch_point_index]
# 		var branch_nodes: Array[NodeData] = CreateBranch(branch_point, branch_length)
# 		branch_point.next_node.append(branch_nodes[0])
# 		for j in branch_nodes.size():
# 			if (j < branch_nodes.size() - 1):
# 				branch_nodes[j].next_node.append(branch_nodes[j + 1])
