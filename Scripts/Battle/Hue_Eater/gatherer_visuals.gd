class_name GathererVisuals extends Node2D

## A Gatherer's battle prop, mounted on its CharacterVisualEffects: its Gathered Light shape
## above its head.

const TOP_GAP: float = 10.0

## Gathered Light launches start here (SkillEffectScene.Anchor.Caster_Marker).
@export var _shape_marker: Marker2D
@export var _shape: GatheredLightShape

func Show(p_visual_effects: CharacterVisualEffects, p_parts: int) -> void:
	_shape_marker.position = p_visual_effects.SpritePoint(Vector2(0.5, 0.0), Vector2(0.0, TOP_GAP))
	_shape.SetSlices(p_parts, true)
