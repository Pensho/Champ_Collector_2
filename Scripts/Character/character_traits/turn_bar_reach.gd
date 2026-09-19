class_name TurnBarReach extends RefCounted

## How a trait's positional reach is drawn on the turn bar by TraitReachOverlay.

const DEFAULT_OPACITY: float = 0.3

var _threshold: float
var _texture: Texture2D
var _opacity: float
var _both_directions: bool

## p_threshold is the reach as a fraction of the bar (0.0 - 1.0).
func _init(
		p_threshold: float,
		p_texture: Texture2D,
		p_opacity: float = DEFAULT_OPACITY,
		p_both_directions: bool = false) -> void:
	_threshold = p_threshold
	_texture = p_texture
	_opacity = p_opacity
	_both_directions = p_both_directions
