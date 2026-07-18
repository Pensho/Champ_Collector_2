class_name ReagentButton extends Button

const SPENT_MODULATE: Color = Color(0.35, 0.35, 0.35, 1.0)

@onready var _tooltip: ToolTip = $Control

func SetToolTip(p_title: String, p_description: String) -> void:
	_tooltip.title_text = p_title
	_tooltip.description_text = p_description

func MarkSpent() -> void:
	self.modulate = SPENT_MODULATE
	self.disabled = true
