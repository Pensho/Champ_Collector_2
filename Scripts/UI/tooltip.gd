class_name ToolTip extends Control

const KEYWORD_COLORS = preload("uid://bgywi0cu4mkig")
const TOOLTIP_SCENE = preload("uid://cne3qgmdo3t1u")
const PRESSED_TIME: float = 0.3

## Shared by every tooltip: whether the press in progress opened one, so the control
## underneath can ignore the release that ends the hold.
static var _press_consumed: bool = false
static var _consumed_on_frame: int = -1

@export var title_text: String = "Item Title"
@export var description_text: String = "This is a detailed description that will wrap automatically."
## When true a press inside this control opens the tooltip immediately instead of
## requiring a PRESSED_TIME hold.
@export var show_on_press: bool = false

var visuals: PanelContainer
var timer: Timer
var active_tooltip: PopupPanel
var _tap_gesture: TapGesture = TapGesture.new()

static func ConsumedPress() -> bool:
	return _press_consumed

static func MarkPressConsumed() -> void:
	_press_consumed = true
	_consumed_on_frame = Engine.get_process_frames()

static func RegisterPress() -> void:
	# Every visible tooltip registers the same press; skip the reset if a show_on_press
	# tooltip already consumed it this frame.
	if _consumed_on_frame != Engine.get_process_frames():
		_press_consumed = false

func _ready() -> void:
	# Connect the timer to a function that spawns the tooltip
	timer = Timer.new()
	timer.wait_time = PRESSED_TIME
	timer.one_shot = true
	timer.timeout.connect(_show_tooltip)
	add_child(timer)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	_tap_gesture.HandleEvent(event)
	if event is InputEventMouseMotion:
		# A hold that becomes a scroll swipe should not open the tooltip mid-scroll.
		if not _tap_gesture.IsTap():
			timer.stop()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			RegisterPress()
		var is_over_me = get_global_rect().has_point(get_global_mouse_position())
		if event.pressed and is_over_me:
			if show_on_press:
				# Deferred so the press reaches the control underneath before it is released.
				_show_tooltip.call_deferred()
			else:
				timer.start()
		else:
			timer.stop()

func _show_tooltip() -> void:
	MarkPressConsumed()
	_ReleaseHeldControl()
	if not active_tooltip:
		active_tooltip = TOOLTIP_SCENE.instantiate()
		add_child(active_tooltip)
	
	# 1. Update the text
	active_tooltip.get_node("MainVisuals/MarginContainer/VBoxContainer/Label_Title").text = title_text
	
	# 2. Process the Description for Keywords
	var processed_desc = KEYWORD_COLORS.ApplyKeywordColors(description_text)
	
	# 3. Apply to RichTextLabel (Note: use .text or .append_text with BBCode)
	active_tooltip.get_node("MainVisuals/MarginContainer/VBoxContainer/Label_Description").text = processed_desc
	
	# Calculate Position
	var mouse_position = get_global_mouse_position()
	var viewport_size = get_viewport_rect().size
	
	# Basic 'Smart' positioning: if too far right, flip to left of mouse
	var popup_width = 250 # Expected width
	if mouse_position.x + popup_width > viewport_size.x:
		mouse_position.x -= popup_width
	
	_animate_entrance()

## The popup swallows the hold's real release, which would leave the pressed button stuck
## until some later click fires its button_up. Release it now, while the press is consumed.
func _ReleaseHeldControl() -> void:
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = get_viewport().get_mouse_position()
	release.global_position = release.position
	get_viewport().push_input(release, true)

func _animate_entrance() -> void:
	visuals = active_tooltip.get_node("MainVisuals")
	visuals.modulate.a = 0
	var mouse_position = get_global_mouse_position()
	active_tooltip.popup(Rect2i(mouse_position.x, mouse_position.y, 0, 0))
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "modulate:a", 1.0, 0.3)
