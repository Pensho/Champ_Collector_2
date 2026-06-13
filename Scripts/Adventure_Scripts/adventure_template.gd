class_name AdventureTemplate extends Resource

enum Mechanic_Frequency
{
	NONE,
	LOW,
	MEDIUM,
	HIGH,
}

@export var MIN_DEPTH: int = 18
@export var MAX_DEPTH: int = 36

@export var difficulty: int = 0
@export var branching_paths: Mechanic_Frequency
@export var rest_stops: Mechanic_Frequency
@export var hint_nodes: Mechanic_Frequency
@export var gamble_nodes: Mechanic_Frequency
@export var escalating_nodes: Mechanic_Frequency
