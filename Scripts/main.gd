extends Node

const DEBUG_OVERLAY_SCENE = preload("res://Scenes/debug/debug_overlay.tscn")

var _instance: Main_Instance = null

func _ready() -> void:
	_instance = Main_Instance.new()
	_instance.Init()
	self.add_child(_instance)
	if(OS.has_feature("editor")):
		add_child(DEBUG_OVERLAY_SCENE.instantiate())

func GetInstance() -> Main_Instance:
	if(null == _instance):
		_instance = Main_Instance.new()
		_instance.Init()
		self.add_child(_instance)
	return _instance
