@tool
class_name StageClutterEntry extends Resource

## One scatter rule for floor clutter, mirroring DecorLayerData but placed against the
## battle floor strip and kept clear of the character line.

@export var textures: Array[Texture2D]
@export var density: float = 0.5
@export var scale_min: float = 1.0
@export var scale_max: float = 1.0
@export var rotation_jitter_degrees: float = 0.0
@export var allow_horizontal_flip: bool = true
@export var tint: Color = Color.WHITE
@export var character_avoidance_radius: float = 20.0

@export_group("Ground Shadow")
@export var shadow_width_ratio: float = 0.0
@export var shadow_height: float = 16.0
@export var shadow_color: Color = Color("07060aff")
@export var shadow_vertical_offset: float = 5.0
