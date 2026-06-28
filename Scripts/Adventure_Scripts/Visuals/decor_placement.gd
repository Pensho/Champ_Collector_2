class_name DecorPlacement extends RefCounted

## Pure result of one scenery element placement, produced by AdventureBackgroundGenerator.
## Holds no node/scene references so the generator stays unit-testable.

var texture: Texture2D
var position: Vector2
var scale: float = 1.0
var rotation_degrees: float = 0.0
var flip_h: bool = false
var tint: Color = Color.WHITE
var z_index: int = 0
