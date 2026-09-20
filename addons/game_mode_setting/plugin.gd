@tool
extends EditorPlugin

## Keeps the build mode project setting present and typed. Godot drops a setting whose value
## is empty when it writes project.godot, which would take the row out of Project Settings
## and leave no way to pick a mode from the editor. Registering it on every editor start
## restores the row, and the enum hint offers exactly the modes GameModeRegistry ships, so
## the field cannot be cleared into an unusable state or filled with an unknown name.

func _enter_tree() -> void:
	_RegisterBuildModeSetting()

func _RegisterBuildModeSetting() -> void:
	var setting_name: String = GameModeRegistry.BUILD_MODE_SETTING
	var default_mode_name: String = GameModeRegistry.DefaultPool().mode_name
	# An empty value counts as missing: the field having been cleared should heal to the
	# default mode rather than sit blank.
	var needs_value: bool = not ProjectSettings.has_setting(setting_name) \
			or str(ProjectSettings.get_setting(setting_name, "")).is_empty()
	if(needs_value):
		ProjectSettings.set_setting(setting_name, default_mode_name)
	# The initial value is empty, not the default mode: Godot leaves a setting out of
	# project.godot when it matches its initial value, which would drop the chosen mode
	# from an exported build and from version control.
	ProjectSettings.set_initial_value(setting_name, "")
	ProjectSettings.set_as_basic(setting_name, true)
	var mode_names: Array[String] = []
	for pool: ContentPool in GameModeRegistry.POOLS:
		mode_names.append(pool.mode_name)
	ProjectSettings.add_property_info({
		"name": setting_name,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(mode_names),
	})
	if(needs_value):
		ProjectSettings.save()
