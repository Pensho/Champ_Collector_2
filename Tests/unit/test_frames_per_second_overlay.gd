extends GutTest

const OVERLAY_SCENE: PackedScene = preload("res://Scenes/ui/General_UI/Frames_Per_Second_Overlay.tscn")

var _overlay: FramesPerSecondOverlay

func before_each() -> void:
	_overlay = OVERLAY_SCENE.instantiate()
	add_child_autofree(_overlay)

func test_enabling_shows_the_overlay_and_starts_processing() -> void:
	_overlay.SetOverlayEnabled(true)

	assert_true(_overlay.visible)
	assert_true(_overlay.is_processing())

func test_disabling_hides_the_overlay_and_stops_processing() -> void:
	_overlay.SetOverlayEnabled(true)
	_overlay.SetOverlayEnabled(false)

	assert_false(_overlay.visible)
	assert_false(_overlay.is_processing())
