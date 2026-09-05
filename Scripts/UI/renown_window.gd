class_name RenownWindow extends Control

signal attribute_selected(attribute: Types.Attribute)
signal cancelled

@export var _attribute_buttons: Dictionary[Types.Attribute, Button] = {}

func _ready() -> void:
	for attribute: Types.Attribute in _attribute_buttons.keys():
		_attribute_buttons[attribute].connect("button_up", _on_attribute_button_up.bind(attribute))

func Refresh(p_character: Character) -> void:
	for attribute: Types.Attribute in Game_Balance.RENOWN_ATTRIBUTES:
		var button: Button = _attribute_buttons[attribute]
		var current_rank: int = p_character.GetRenownRankFor(attribute)
		var current_percent: int = p_character.GetRenownPercentBonus(attribute)
		var next_percent: int = current_percent + p_character.GetRenownPercentPerRank(attribute)
		button.text = "%s (Rank %d)   +%d%% -> +%d%%" % [
				Types.Attribute.keys()[attribute], current_rank, current_percent, next_percent]

func _on_attribute_button_up(p_attribute: Types.Attribute) -> void:
	attribute_selected.emit(p_attribute)

func _on_button_cancel_button_up() -> void:
	cancelled.emit()
