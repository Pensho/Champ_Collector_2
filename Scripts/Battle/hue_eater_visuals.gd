class_name HueEaterVisuals extends Node2D

## The Hue-Eater's battle props, mounted on her CharacterVisualEffects: Gathered Light's hexagon
## right of her and the prism left of her, both at half her height.

const SIDE_GAP: float = 22.0

## Gathered Light launches start here (SkillEffectScene.Anchor.Caster_Marker).
@export var _hexagon_marker: Marker2D
@export var _hexagon: GatheredLightHexagon
## Prism beams start here (SkillEffectScene.Anchor.Caster_Marker).
@export var _prism_marker: Marker2D
@export var _prism: HueEaterPrism

func Show(p_visual_effects: CharacterVisualEffects, p_slices: int, p_hexed: bool, p_alive: bool) -> void:
	_hexagon_marker.position = p_visual_effects.SpritePoint(Vector2(1.0, 0.5), Vector2(SIDE_GAP, 0.0))
	_hexagon.SetSlices(p_slices, true)
	_prism_marker.position = p_visual_effects.SpritePoint(Vector2(0.0, 0.5), Vector2(-SIDE_GAP, 0.0))
	_prism.visible = p_alive
	_prism.SetHexed(p_hexed)
