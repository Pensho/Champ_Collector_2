extends Node

const RED_BOOTS = preload("uid://c3g7cshxhg0rw")

var _instance: Main_Instance = null

var _keys_pressed: Dictionary[Key, bool] = { KEY_0 : false, KEY_8 : false }

func _ready() -> void:
	_instance = Main_Instance.new()
	_instance.Init()
	self.add_child(_instance)

func GetInstance() -> Main_Instance:
	if(null == _instance):
		_instance = Main_Instance.new()
		_instance.Init()
		self.add_child(_instance)
	return _instance

func _process(_delta: float) -> void:
	if(OS.has_feature("editor")):
		if(Input.is_key_pressed(KEY_0) and !_keys_pressed[KEY_0]):
			_keys_pressed[KEY_0] = true
			print(get_tree_string_pretty())
		if(!Input.is_key_pressed(KEY_0) and _keys_pressed[KEY_0]):
			_keys_pressed[KEY_0] = false
		
		if(Input.is_key_pressed(KEY_8) and !_keys_pressed[KEY_8]):
			var preset = RED_BOOTS.duplicate(true)
			preset._rarity = Types.Rarity.Legendary
			preset.Setup()
			_instance._item_collection.AddPreset(preset)
			_keys_pressed[KEY_8] = true
		if(!Input.is_key_pressed(KEY_8) and _keys_pressed[KEY_8]):
			_keys_pressed[KEY_8] = false
