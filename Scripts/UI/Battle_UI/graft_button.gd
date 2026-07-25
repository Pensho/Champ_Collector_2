class_name GraftButton extends Button

@onready var _tooltip: ToolTip = $Control

func SetToolTip(p_title: String, p_description: String) -> void:
	_tooltip.title_text = p_title
	_tooltip.description_text = p_description
