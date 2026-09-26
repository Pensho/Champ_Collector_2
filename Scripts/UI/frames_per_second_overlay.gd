class_name FramesPerSecondOverlay extends CanvasLayer

@export var _label: Label

var _shown_frames_per_second: int = -1

func _ready() -> void:
	var settings: Settings = get_node("/root/Game_Settings")
	settings.frames_per_second_overlay_changed.connect(SetOverlayEnabled)
	SetOverlayEnabled(settings.frames_per_second_overlay_enabled)

func _process(_delta: float) -> void:
	var frames_per_second: int = roundi(Engine.get_frames_per_second())
	if frames_per_second == _shown_frames_per_second:
		return
	_shown_frames_per_second = frames_per_second
	_label.text = "FPS: %d" % frames_per_second

func SetOverlayEnabled(p_enabled: bool) -> void:
	visible = p_enabled
	set_process(p_enabled)
