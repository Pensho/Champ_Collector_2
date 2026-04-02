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

func _on_war_room_button_pressed() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://df6f1b4xoipjq"
	main.GetInstance().change_scene(context_container)

func _on_button_view_collection_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "res://Scenes/ui/Inspect_Collection_Menu.tscn"
	main.GetInstance().change_scene(context_container)

func _on_button_quit_button_up() -> void:
	var context_container: ContextContainer = ContextContainer.new()
	context_container._scene = "uid://c6c1o3oabj0pf"
	main.GetInstance().change_scene(context_container)
