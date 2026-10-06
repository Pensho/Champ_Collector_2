class_name PreparationCard extends Button

const UNAFFORDABLE_ALPHA: float = 0.4

@export var _label_title: Label
@export var _label_effect: Label
@export var _label_cost: Label

func Setup(p_title: String, p_effect: String, p_cost: int, p_affordable: bool) -> void:
	_label_title.text = p_title
	_label_effect.text = p_effect
	_label_cost.text = "%d Supplies" % p_cost
	disabled = not p_affordable
	modulate.a = 1.0 if p_affordable else UNAFFORDABLE_ALPHA

func SetChosen(p_chosen: bool) -> void:
	set_pressed_no_signal(p_chosen)
