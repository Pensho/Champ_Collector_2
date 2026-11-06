class_name HueEaterCrystalDie extends Node2D

## The Hue-Eater's crystal die, which her beams strike: colourless, tinted red while she holds
## Hexed. The art stays greyscale so the tint is owned here.

const HEXED_TINT: Color = Color(1.0, 0.35, 0.35)

func SetHexed(p_hexed: bool) -> void:
	modulate = HEXED_TINT if p_hexed else Color.WHITE
