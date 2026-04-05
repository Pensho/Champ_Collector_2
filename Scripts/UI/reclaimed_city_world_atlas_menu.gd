extends Control

@export var _silver_UI: ResourceUISlot
@export var _supplies_UI: ResourceUISlot
@export var _fortunes_favor_UI: ResourceUISlot

@warning_ignore("unused_parameter") # Main menu requires nothing from the ContextContainer.
func Init(p_context_container: ContextContainer) -> void:
	_silver_UI.SetText(str(main.GetInstance()._resources._silver))
	_silver_UI.SetTexture(main.GetInstance()._resources.SILVER_COIN_TEXTURE)
	_supplies_UI.SetText(str(main.GetInstance()._resources._supplies) + "/" + str(GameBalance.MAX_SUPPLIES))
	_supplies_UI.SetTexture(main.GetInstance()._resources.SUPPLIES_TEXTURE)
	_fortunes_favor_UI.SetText(str(main.GetInstance()._resources._fortunes_favor))
	_fortunes_favor_UI.SetTexture(main.GetInstance()._resources.FORTUNES_FAVOR_BONE_1)

func _on_town_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://cfdrcdtsx2jh7"
	main.GetInstance().change_scene(context_container)

func _on_statues_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://d3kgucyfmcvip"
	main.GetInstance().change_scene(context_container)

func _on_experience_quests_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._static_context = load("uid://dstgijwmiqvo1") # Battle Variant, Battle_Context
	context_container._previous_scene = "uid://df6f1b4xoipjq"
	context_container._scene = "uid://d3hg8jxy8xj8n"
	main.GetInstance().change_scene(context_container)
