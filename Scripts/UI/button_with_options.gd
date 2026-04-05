class_name ButtonWithOptions extends Control

const KEYWORD_COLORS = preload("uid://bgywi0cu4mkig")

@onready var base_rect: ColorRect = $ColorRect

@onready var button_left: Button = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer_Buttons/Button_Left
@onready var button_middle: Button = $ColorRect/MarginContainer/VBoxContainer/HBoxContainer_Buttons/Button_Middle

@onready var label_title: Label = $ColorRect/MarginContainer/VBoxContainer/Label_Title
@onready var rich_text_label_info: RichTextLabel = $ColorRect/MarginContainer/VBoxContainer/RichTextLabel_Info

func SetText(p_title: String, p_body: String) -> void:
	label_title.text = p_title
	rich_text_label_info.text = _apply_keyword_colors(p_body)

func SetLeftButton(p_name: String, p_func_ptr: Callable) -> void:
	button_left.text = p_name
	button_left.connect("button_up", p_func_ptr)
	button_left.show()

func SetMiddleButton(p_name: String, p_func_ptr: Callable) -> void:
	button_middle.text = p_name
	button_middle.connect("button_up", p_func_ptr)
	button_middle.show()

func _on_cancel_button_up() -> void:
	self.hide()

func GetSize() -> Vector2:
	return Vector2(base_rect.get_rect().size.x, base_rect.get_rect().size.y)

func SetSize(p_width: int, p_height: int) -> void:
	base_rect.size.x = p_width
	base_rect.size.y = p_height

func _apply_keyword_colors(original_text: String) -> String:
	var regex = RegEx.new()
	var processed_text = original_text
	
	for keyword in KEYWORD_COLORS.KEYWORDS.keys():
		var color_code = KEYWORD_COLORS.KEYWORDS[keyword].to_html()
		var pattern = "(?i)\\b(" + keyword + ")\\b"
		regex.compile(pattern)
		
		# $1 inserts the text found in the first set of parentheses
		var replacement = "[color=" + color_code + "]$1[/color]"
		
		processed_text = regex.sub(processed_text, replacement, true)
		
	return processed_text
