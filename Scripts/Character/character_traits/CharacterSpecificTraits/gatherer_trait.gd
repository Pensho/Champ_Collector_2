class_name GathererTrait extends GatheredLightTrait

## A Gatherer's Gathered Light: the Hue-Eater's mechanic on a triangle above its head
## (Encounter_Design_Document.md 2.2, Chanter and Gatherers).

const VISUALS_SCENE: PackedScene = preload(
		"res://Scenes/Battle_Visual_Effects/Hue_Eater_Visual_Effects/gatherer_visuals.tscn")
const LAUNCH_SCENE: PackedScene = preload(
		"res://Scenes/Battle_Visual_Effects/Hue_Eater_Visual_Effects/gathered_light_triangle_launch.tscn")

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var visual_effects: CharacterVisualEffects = p_character_repr.GetVisualEffects()
	var visuals: GathererVisuals = visual_effects.TraitVisuals(VISUALS_SCENE)
	visuals.Show(visual_effects, _parts if _OwnerAlive() else 0)

func _LaunchScene() -> PackedScene:
	return LAUNCH_SCENE
