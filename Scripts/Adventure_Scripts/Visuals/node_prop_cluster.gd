class_name NodePropCluster extends Resource

## A set of decor layers scattered in a ring around each node of one Node_Type, replacing
## the old single-texture node prop. Reuses DecorLayerData/ZoneDecorEntry so the same
## density, scale, rotation, flip, tint and texture-variant mechanics apply.

@export var decor: Array[ZoneDecorEntry]
@export var inner_radius: float = 48.0
@export var outer_radius: float = 96.0
@export var sample_count: int = 12
