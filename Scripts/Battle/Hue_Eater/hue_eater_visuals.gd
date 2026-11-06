class_name HueEaterVisuals extends Node2D

## The Hue-Eater's battle props, mounted on her CharacterVisualEffects: Gathered Light's hexagon
## right of her and the crystal die left of her, both at half her height.

const SIDE_GAP: float = 22.0

## Gathered Light launches start here (SkillEffectScene.Anchor.Caster_Marker).
@export var _hexagon_marker: Marker2D
@export var _hexagon: GatheredLightShape
## Prismatic Rain beams start here (SkillEffectScene.Anchor.Caster_Marker).
@export var _die_marker: Marker2D
@export var _die: HueEaterCrystalDie

func Show(p_visual_effects: CharacterVisualEffects, p_slices: int, p_hexed: bool, p_alive: bool) -> void:
	_hexagon_marker.position = p_visual_effects.SpritePoint(Vector2(1.0, 0.5), Vector2(SIDE_GAP, 0.0))
	_hexagon.SetSlices(p_slices, true)
	_die_marker.position = p_visual_effects.SpritePoint(Vector2(0.0, 0.5), Vector2(-SIDE_GAP, 0.0))
	_die.visible = p_alive
	_die.SetHexed(p_hexed)
