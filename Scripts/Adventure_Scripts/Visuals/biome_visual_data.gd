class_name BiomeVisualData extends Resource

## The full background look of one biome: palette, scatter layers, and node-type props.
## Noise seed and placement jitter are driven at render time from
## AdventureState._generation_seed, so the same adventure always renders the same scenery.

# Base background
@export var background_top_color: Color
@export var background_bottom_color: Color   # vertical gradient; equal = flat

@export var noise: FastNoiseLite

# Scatter layers, drawn back-to-front in array order.
@export var decor_layers: Array[DecorLayerData]

# Node-type prop clusters. Texture drawn near each node of that type.
@export var node_props: Dictionary[NodeData.Node_Type, Texture2D]
