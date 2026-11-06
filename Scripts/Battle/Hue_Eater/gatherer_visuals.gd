class_name GathererVisuals extends Node2D

## A Gatherer's battle prop, mounted on its CharacterVisualEffects: the Gathered Light triangle
## above its head.

const TOP_GAP: float = 47.0

## Gathered Light launches start here (SkillEffectScene.Anchor.Caster_Marker).
@export var _triangle_marker: Marker2D
@export var _triangle: GatheredLightShape

func Show(p_visual_effects: CharacterVisualEffects, p_parts: int) -> void:
	_triangle_marker.position = p_visual_effects.SpritePoint(Vector2(0.5, 0.0), Vector2(0.0, -TOP_GAP))
	_triangle.SetSlices(p_parts, true)
