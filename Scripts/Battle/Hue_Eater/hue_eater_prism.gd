class_name HueEaterPrism extends Node2D

## The Hue-Eater's prism: faces coloured for each beam outcome. While she holds Hexed, the swing
## face turns to her colour.

const PARTY_COLOR: Color = Color(1.0, 0.6, 0.3, 0.9)
const HUE_EATER_COLOR: Color = Color(0.6, 0.4, 1.0, 0.9)

@export var _swing_face: Polygon2D

func SetHexed(p_hexed: bool) -> void:
	_swing_face.color = HUE_EATER_COLOR if p_hexed else PARTY_COLOR
