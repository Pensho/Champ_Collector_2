class_name SkillButton extends Button

@onready var _cooldown_overlay: TextureRect = $TextureRect
@onready var _cooldown: Label = $TextureRect/Label

func SetCooldown(p_cooldown: int) -> void:
	_cooldown_overlay.show()
	_cooldown.text = str(p_cooldown)
	_cooldown.show()
	self.disabled = true

func ClearCooldown() -> void:
	_cooldown_overlay.hide()
	_cooldown.hide()
	self.disabled = false
