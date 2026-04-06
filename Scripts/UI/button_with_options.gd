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

func SetLeftButton(p_name: String, p_func_ptr: Callable, p_color: Color = Color.WHITE) -> void:
	button_left.text = p_name
	if(!p_func_ptr.is_null()):
		button_left.connect("button_up", p_func_ptr)
	button_left.add_theme_color_override("font_color", p_color)
	button_left.show()

func SetMiddleButton(p_name: String, p_func_ptr: Callable, p_color: Color = Color.WHITE) -> void:
	button_middle.text = p_name
	if(!p_func_ptr.is_null()):
		button_middle.connect("button_up", p_func_ptr)
	button_middle.add_theme_color_override("font_color", p_color)
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
	
	regex.compile("\\+(\\d+\\.?\\d*)")
	processed_text = regex.sub(processed_text, "+[color=#44FF44]$1[/color]", true)

	regex.compile("-(\\d+\\.?\\d*)")
	processed_text = regex.sub(processed_text, "[color=#FF4444]$1[/color]", true)

	# Negative lookbehind (?<!\]) skips numbers already inside a color tag
	regex.compile("(?<!\\])\\b(\\d+\\.?\\d*)\\b")
	processed_text = regex.sub(processed_text, "[color=#FFD700]$1[/color]", true)

	return processed_text
