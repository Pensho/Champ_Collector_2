class_name ToolTip extends Control

const KEYWORD_COLORS = preload("uid://bgywi0cu4mkig")
const TOOLTIP_SCENE = preload("uid://cne3qgmdo3t1u")
const PRESSED_TIME: float = 0.3

@export var title_text: String = "Item Title"
@export var description_text: String = "This is a detailed description that will wrap automatically."
## When true a press inside this control opens the tooltip immediately instead of
## requiring a PRESSED_TIME hold.
@export var show_on_press: bool = false

var visuals: PanelContainer
var timer: Timer
var active_tooltip: PopupPanel

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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var is_over_me = get_global_rect().has_point(get_global_mouse_position())
		if event.pressed and is_over_me:
			if show_on_press:
				_show_tooltip()
			else:
				timer.start()
		else:
			timer.stop()

func _show_tooltip() -> void:
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

func _animate_entrance() -> void:
	visuals = active_tooltip.get_node("MainVisuals")
	visuals.modulate.a = 0
	var mouse_position = get_global_mouse_position()
	active_tooltip.popup(Rect2i(mouse_position.x, mouse_position.y, 0, 0))
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "modulate:a", 1.0, 0.3)
