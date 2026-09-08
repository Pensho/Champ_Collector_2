class_name Context_Battle extends Static_Context

@warning_ignore_start("unused_private_class_variable")

@export var _enemies_wave_1: Array[CharacterPreset]
@export var _enemies_wave_2: Array[CharacterPreset]
@export var _enemies_wave_3: Array[CharacterPreset]
@export var _stage_scene: PackedScene
@export var _environment_effects: Array[PackedScene]
@export var _global_scene_light: Color = Color(1.0, 1.0, 1.0)
@export var _global_scene_darkness: Color = Color(0.0, 0.0, 0.0)
## Fraction of the frame the darkness gradient covers, 0.0 to 1.0.
@export var _scene_darkness_height: float = 0.3

@export var _loot_table: LootTable

@warning_ignore_restore("unused_private_class_variable")
