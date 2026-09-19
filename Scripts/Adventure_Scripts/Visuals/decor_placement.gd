@tool
class_name DecorPlacement extends RefCounted

## Pure result of one scenery element placement, produced by AdventureBackgroundGenerator
## and by StageClutterGenerator. Holds no node/scene references so the generators stay
## unit-testable.

var texture: Texture2D
var position: Vector2
var scale: float = 1.0
var rotation_degrees: float = 0.0
var flip_h: bool = false
var tint: Color = Color.WHITE
var z_index: int = 0
var shadow_rect: Rect2 = Rect2()
var shadow_color: Color = Color.TRANSPARENT
