extends GutTest

# Every Gathered Light trait's shape scenes, the one beside its owner and the one it launches,
# must have exactly as many slices as the trait's parts to complete.

const HUE_EATER_TRAIT: HueEaterTrait = preload("res://Data/Character_Traits/Enemy_Traits/Hue_Eater_Trait.tres")
const GATHERER_TRAIT: GathererTrait = preload("res://Data/Character_Traits/Enemy_Traits/Gatherer_Trait.tres")

func _shapes_in(p_scene: PackedScene) -> Array[GatheredLightShape]:
	var shapes: Array[GatheredLightShape] = []
	var pending: Array[Node] = [autofree(p_scene.instantiate())]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is GatheredLightShape:
			shapes.append(node)
		pending.append_array(node.get_children())
	return shapes

func _assert_shapes_match(p_trait: GatheredLightTrait, p_scenes: Array[PackedScene]) -> void:
	for scene in p_scenes:
		var shapes: Array[GatheredLightShape] = _shapes_in(scene)
		assert_eq(shapes.size(), 1, "%s holds one Gathered Light shape" % scene.resource_path)
		for shape in shapes:
			assert_eq(shape.PartCount(), p_trait._parts_to_complete,
					"%s has a slice per part of %s" % [scene.resource_path, p_trait.resource_path])

func test_the_hue_eater_shapes_have_a_slice_per_part() -> void:
	_assert_shapes_match(HUE_EATER_TRAIT, [HueEaterTrait.VISUALS_SCENE, HueEaterTrait.LAUNCH_SCENE])

func test_the_gatherer_shapes_have_a_slice_per_part() -> void:
	_assert_shapes_match(GATHERER_TRAIT, [GathererTrait.VISUALS_SCENE, GathererTrait.LAUNCH_SCENE])
