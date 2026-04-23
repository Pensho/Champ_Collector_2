class_name AdventureTemplate extends Resource

enum Mechanic_Frequency
{
	NONE,
	LOW,
	MEDIUM,
	HIGH,
}

@export var MAX_NODES: int = 50
@export var MIN_NODES: int = 40

@export var difficulty: int = 0
@export var branching_paths: Mechanic_Frequency
@export var rest_stops: Mechanic_Frequency
