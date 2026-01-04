class_name ToolTip extends Control

const KeywordColors = preload("uid://bgywi0cu4mkig")

@export var title_text: String = "Item Title"
@export var description_text: String = "This is a detailed description that will wrap automatically."
const tooltip_scene = preload("uid://cne3qgmdo3t1u")

const PRESSED_TIME: float = 0.3

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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var is_over_me = get_global_rect().has_point(get_global_mouse_position())
		if event.pressed and is_over_me:
			timer.start()
		else:
			timer.stop()

func _show_tooltip() -> void:
	if not active_tooltip:
		active_tooltip = tooltip_scene.instantiate()
		add_child(active_tooltip)
	
	# 1. Update the text
	active_tooltip.get_node("MainVisuals/MarginContainer/VBoxContainer/Label_Title").text = title_text
	
	# 2. Process the Description for Keywords
	var processed_desc = _apply_keyword_colors(description_text)
	
	# 3. Apply to RichTextLabel (Note: use .text or .append_text with BBCode)
	active_tooltip.get_node("MainVisuals/MarginContainer/VBoxContainer/Label_Description").text = processed_desc
	
	# Calculate Position
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport_rect().size
	
	# Basic 'Smart' positioning: if too far right, flip to left of mouse
	var popup_width = 250 # Expected width
	if mouse_pos.x + popup_width > viewport_size.x:
		mouse_pos.x -= popup_width
	
	_animate_entrance()

func _apply_keyword_colors(original_text: String) -> String:
	var regex = RegEx.new()
	var processed_text = original_text
	
	for keyword in KeywordColors.keywords.keys():
		var color_code = KeywordColors.keywords[keyword].to_html()
		var pattern = "(?i)\\b(" + keyword + ")\\b"
		regex.compile(pattern)
		
		# $1 inserts the text found in the first set of parentheses
		var replacement = "[color=" + color_code + "]$1[/color]"
		
		processed_text = regex.sub(processed_text, replacement, true)
		
	return processed_text

func _animate_entrance() -> void:
	visuals = active_tooltip.get_node("MainVisuals")
	visuals.modulate.a = 0
	var mouse_pos = get_global_mouse_position()
	active_tooltip.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "modulate:a", 1.0, 0.3)
