class_name BiomeVisualData extends Resource

## The full background look of one biome: palette, region zones, and node-type props.
## Noise seed and placement jitter are driven at render time from
## AdventureState._generation_seed, so the same adventure always renders the same scenery.
##
## Two-tier generation: a low-frequency region_noise picks a coarse-cell BiomeRegionData
## zone (contiguous patches), then each zone's decor entries scatter elements within it
## using the high-frequency detail_noise. See AdventureBackgroundGenerator.

# Base background
@export var background_top_color: Color
@export var background_bottom_color: Color   # vertical gradient; equal = flat

@export var detail_noise: FastNoiseLite      # high-frequency, per-element placement
@export var region_noise: FastNoiseLite      # low-frequency, picks the zone per coarse cell

@export var regions: Array[BiomeRegionData]
@export var coarse_cell_size: float = 256.0
@export var fine_cell_size: float = 44.0

# Node-type prop clusters. Texture drawn near each node of that type.
@export var node_props: Dictionary[NodeData.Node_Type, Texture2D]
