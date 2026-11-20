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

## Item tooltips add a type line under the title and an implicit between two dividers, all centered.
var subtitle_text: String = ""
var implicit_text: String = ""
var center_text: bool = false

var visuals: PanelContainer
var timer: Timer
var active_tooltip: PopupPanel
var _tap_gesture: TapGesture = TapGesture.new()

func SetItemText(p_title: String, p_item_text: ItemText) -> void:
	title_text = p_title
	subtitle_text = p_item_text.subtitle
	implicit_text = p_item_text.implicit
	description_text = p_item_text.body
	center_text = true

func ClearItemText() -> void:
	subtitle_text = ""
	implicit_text = ""
	center_text = false

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
	
	var box: String = "MainVisuals/MarginContainer/VBoxContainer/"
	var label_title: Label = active_tooltip.get_node(box + "Label_Title")
	label_title.text = title_text
	label_title.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER if center_text else HORIZONTAL_ALIGNMENT_LEFT)
	var label_subtitle: Label = active_tooltip.get_node(box + "Label_Subtitle")
	label_subtitle.text = subtitle_text
	label_subtitle.visible = not subtitle_text.is_empty()
	var label_implicit: RichTextLabel = active_tooltip.get_node(box + "RichTextLabel_Implicit")
	label_implicit.text = _Centered(KEYWORD_COLORS.ApplyKeywordColors(implicit_text))
	label_implicit.visible = not implicit_text.is_empty()
	active_tooltip.get_node(box + "ColorRect_Implicit_Divider").visible = label_implicit.visible
	active_tooltip.get_node(box + "Label_Description").text = _Centered(
			KEYWORD_COLORS.ApplyKeywordColors(description_text))
	
	# Calculate Position
	var mouse_position = get_global_mouse_position()
	var viewport_size = get_viewport_rect().size
	
	# Basic 'Smart' positioning: if too far right, flip to left of mouse
	var popup_width = 250 # Expected width
	if mouse_position.x + popup_width > viewport_size.x:
		mouse_position.x -= popup_width
	
	_animate_entrance()

func _Centered(p_text: String) -> String:
	return "[center]" + p_text + "[/center]" if center_text else p_text

## The popup swallows the hold's real release, which would leave the pressed button stuck
## until some later click releases it. Release it now, while the press is consumed.
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
