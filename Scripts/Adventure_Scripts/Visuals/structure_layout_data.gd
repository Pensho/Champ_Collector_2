class_name StructureLayoutData extends Resource

## Tuning for a constructed biome's background: how its map is laid out as streets, lots
## and walls instead of organic scatter. Assigned on BiomeVisualData; null keeps the
## organic pipeline.

## Vertical node jitter, replacing AdventureNodePlacement.DEFAULT_VERTICAL_JITTER so rows
## stay level enough for street lanes between them.
@export var node_vertical_jitter: float = 0.0

@export_group("Streets")
## Length cut off each street corner by its 45° chamfer.
@export var chamfer_size: float = 0.0
## Preferred distance between the horizontal runs of two streets sharing a row gap.
@export var lane_spacing: float = 0.0
## Below this spacing a row gap's streets cross it as single diagonals instead.
@export var minimum_lane_spacing: float = 0.0
## Space kept between node rects and the band the horizontal runs use.
@export var street_clearance: float = 0.0

@export_group("Lots")
## Lots are split until both sides are at most lot_size_max; pieces under lot_size_min
## on either side are dropped. A lot_size_max of 0 makes no lots.
@export var lot_size_min: float = 0.0
@export var lot_size_max: float = 0.0
## Gap left between the two halves of every split.
@export var street_width: float = 0.0
## Each lot side moves inward by a random amount up to this.
@export var lot_jitter: float = 0.0
## Lots shrink to sides on multiples of this; match it to edge_spacing so walls fit
## each side exactly. 0 leaves lots unsnapped.
@export var lot_grid_size: float = 0.0
## Clear space kept around every node rect.
@export var plaza_margin: float = 0.0
## Clear space kept on each side of a road, beyond its half width.
@export var road_clearance: float = 0.0

@export_group("Landmarks")
## Massive props placed a set number of times per map before lots are laid out.
@export var landmarks: Array[LandmarkData]

@export_group("Open ground")
## Decorates open ground outside lots, plazas and road corridors. Null leaves it bare.
@export var street_region: BiomeRegionData
