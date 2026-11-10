class_name StructureLayout extends RefCounted

## The map's built geometry for one adventure, computed once by StructureLayoutGenerator
## so every map layer draws from the same roads and lots.

## One rectangular plot of built ground and the region that decorates it.
class Lot:
	var rect: Rect2
	var region: BiomeRegionData

	func _init(p_rect: Rect2, p_region: BiomeRegionData) -> void:
		rect = p_rect
		region = p_region


## Road polyline per edge, keyed by Vector2i(from node index, to node index).
var roads: Dictionary[Vector2i, PackedVector2Array] = {}
var lots: Array[Lot] = []
## Clear ground around each node, left free of lots.
var plazas: Array[Rect2] = []
## Landmark props, placed before lots and kept clear of them.
var landmarks: Array[DecorPlacement] = []
