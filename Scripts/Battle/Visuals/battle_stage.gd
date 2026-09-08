class_name BattleStage extends Node2D

## Root of one battle stage: the bands of Art_Style_Guide.md 10.3 — background, floor,
## midband, foreground — laid out by hand in the scene file. Every element is an authored
## node, so a stage is previewed and edited in the editor rather than assembled at runtime.
## The only runtime work is scattering floor clutter, which needs the character positions
## the stage cannot know on its own.

@export var _floor_clutter: StageClutterView

## Scatters this stage's floor clutter clear of where the characters stand. Positions are
## global; the clutter view scatters in its own local space.
func GenerateClutter(p_character_positions: Array[Vector2], p_generation_seed: int) -> void:
	if _floor_clutter == null:
		return
	var to_clutter_space: Transform2D = _floor_clutter.get_global_transform().affine_inverse()
	var local_positions: Array[Vector2] = []
	for character_position: Vector2 in p_character_positions:
		local_positions.append(to_clutter_space * character_position)
	_floor_clutter.Generate(local_positions, p_generation_seed)
