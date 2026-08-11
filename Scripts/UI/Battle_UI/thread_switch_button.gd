class_name ThreadSwitchButton extends Button

const STANCE_COLOR: Dictionary[WeftAndWarpTrait.Thread_Type, Color] = {
	WeftAndWarpTrait.Thread_Type.Silver: Color(0.75, 0.78, 0.82, 1.0),
	WeftAndWarpTrait.Thread_Type.Golden: Color(1.0, 0.843, 0.0, 1.0),
	WeftAndWarpTrait.Thread_Type.Black: Color(0.30, 0.28, 0.35, 1.0),
}

@onready var _stance_label: Label = $Stance_Label
@onready var _tooltip: ToolTip = $Control

func RefreshVisual(p_thread: WeftAndWarpTrait.Thread_Type) -> void:
	self_modulate = STANCE_COLOR.get(p_thread, Color.WHITE)
	_stance_label.text = WeftAndWarpTrait.Thread_Type.keys()[p_thread]

func SetToolTip(p_title: String, p_description: String) -> void:
	_tooltip.title_text = p_title
	_tooltip.description_text = p_description
