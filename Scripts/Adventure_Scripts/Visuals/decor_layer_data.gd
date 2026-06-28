class_name DecorLayerData extends Resource

## One noise-driven scatter rule for a single element kind (e.g. "grass tuft").

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
