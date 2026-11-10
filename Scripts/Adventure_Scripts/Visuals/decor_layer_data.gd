class_name DecorLayerData extends Resource

## One noise-driven scatter rule for a single element kind (e.g. "grass tuft").

## How elements are positioned. The lot modes only apply in biomes with a StructureLayoutData.
enum Placement_Mode {
	SCATTER,     # random points across the region (inside its lot when lots exist)
	LOT_EDGE,    # pieces stepped along the lot's sides
	LOT_CORNER,  # one element on each lot corner
	LOT_FILL,    # at most one element per lot, sized to fit it
}

## Which lot sides a LOT_EDGE layer uses.
enum Edge_Orientation {
	ANY,
	HORIZONTAL,  # top and bottom sides
	VERTICAL,    # left and right sides
	TOP,         # top side only; its pieces show the face turned into the lot
	BOTTOM,      # bottom side only
}

@export var textures: Array[Texture2D]        # variants, one picked per placement
@export var density: float = 0.5              # 0..1, fraction of candidate cells used
@export var noise_threshold_min: float = 0.0  # place only where noise sample is in range
@export var noise_threshold_max: float = 1.0
@export var scale_min: float = 1.0
@export var scale_max: float = 1.0
@export var rotation_jitter_degrees: float = 0.0
@export var allow_horizontal_flip: bool = true
@export var tint: Color = Color.WHITE
@export var z_index: int = 0                  # ground decal (<0) vs prop (>0)
@export var node_avoidance_radius: float = 60.0        # keep clear of node/edge positions
@export var clears_other_decor: bool = false           # removes non-clearing decor overlapping it

@export_group("Lot placement")
@export var placement_mode: Placement_Mode = Placement_Mode.SCATTER
@export var edge_orientation: Edge_Orientation = Edge_Orientation.ANY
## Distance between LOT_EDGE pieces; set it to the rendered piece length so pieces abut.
@export var edge_spacing: float = 0.0
## How far LOT_EDGE and LOT_CORNER elements sit inside the lot's outline.
@export var edge_inset: float = 0.0
