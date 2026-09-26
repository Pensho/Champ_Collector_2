class_name Settings extends Node

signal frames_per_second_overlay_changed(p_enabled: bool)

const CONFIG_PATH: String = "user://settings.cfg"
const CONFIG_SECTION: String = "settings"

const DEFAULT_MASTER_VOLUME: float = 1.0
const DEFAULT_MUSIC_VOLUME: float = 1.0
const DEFAULT_SOUND_EFFECTS_VOLUME: float = 1.0
const DEFAULT_SCREEN_SHAKE_ENABLED: bool = true
const DEFAULT_TARGETING_HELP_ENABLED: bool = true
const DEFAULT_FULLSCREEN: bool = false
const DEFAULT_FRAMES_PER_SECOND_OVERLAY_ENABLED: bool = false
const DEFAULT_VERTICAL_SYNC_ENABLED: bool = true
const DEFAULT_MAXIMUM_FRAME_RATE: int = 60
const DEFAULT_LOCALE: String = "en"

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sound_effects_volume: float = DEFAULT_SOUND_EFFECTS_VOLUME
var screen_shake_enabled: bool = DEFAULT_SCREEN_SHAKE_ENABLED
var targeting_help_enabled: bool = DEFAULT_TARGETING_HELP_ENABLED
var fullscreen: bool = DEFAULT_FULLSCREEN
var frames_per_second_overlay_enabled: bool = DEFAULT_FRAMES_PER_SECOND_OVERLAY_ENABLED
var vertical_sync_enabled: bool = DEFAULT_VERTICAL_SYNC_ENABLED
var maximum_frame_rate: int = DEFAULT_MAXIMUM_FRAME_RATE
var locale: String = DEFAULT_LOCALE

func _ready() -> void:
	Load()
	ApplyAll()

func Load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	master_volume = config.get_value(CONFIG_SECTION, "master_volume", DEFAULT_MASTER_VOLUME)
	music_volume = config.get_value(CONFIG_SECTION, "music_volume", DEFAULT_MUSIC_VOLUME)
	sound_effects_volume = config.get_value(
			CONFIG_SECTION, "sound_effects_volume", DEFAULT_SOUND_EFFECTS_VOLUME)
	screen_shake_enabled = config.get_value(
			CONFIG_SECTION, "screen_shake_enabled", DEFAULT_SCREEN_SHAKE_ENABLED)
	targeting_help_enabled = config.get_value(
			CONFIG_SECTION, "targeting_help_enabled", DEFAULT_TARGETING_HELP_ENABLED)
	fullscreen = config.get_value(CONFIG_SECTION, "fullscreen", DEFAULT_FULLSCREEN)
	frames_per_second_overlay_enabled = config.get_value(
			CONFIG_SECTION, "frames_per_second_overlay_enabled", DEFAULT_FRAMES_PER_SECOND_OVERLAY_ENABLED)
	vertical_sync_enabled = config.get_value(
			CONFIG_SECTION, "vertical_sync_enabled", DEFAULT_VERTICAL_SYNC_ENABLED)
	maximum_frame_rate = config.get_value(CONFIG_SECTION, "maximum_frame_rate", DEFAULT_MAXIMUM_FRAME_RATE)
	locale = config.get_value(CONFIG_SECTION, "locale", DEFAULT_LOCALE)

func Save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(CONFIG_SECTION, "master_volume", master_volume)
	config.set_value(CONFIG_SECTION, "music_volume", music_volume)
	config.set_value(CONFIG_SECTION, "sound_effects_volume", sound_effects_volume)
	config.set_value(CONFIG_SECTION, "screen_shake_enabled", screen_shake_enabled)
	config.set_value(CONFIG_SECTION, "targeting_help_enabled", targeting_help_enabled)
	config.set_value(CONFIG_SECTION, "fullscreen", fullscreen)
	config.set_value(CONFIG_SECTION, "frames_per_second_overlay_enabled", frames_per_second_overlay_enabled)
	config.set_value(CONFIG_SECTION, "vertical_sync_enabled", vertical_sync_enabled)
	config.set_value(CONFIG_SECTION, "maximum_frame_rate", maximum_frame_rate)
	config.set_value(CONFIG_SECTION, "locale", locale)
	config.save(CONFIG_PATH)

func ApplyAll() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("Sound Effects", sound_effects_volume)
	_apply_fullscreen()
	_apply_vertical_sync()
	_apply_maximum_frame_rate()
	_apply_locale()
	frames_per_second_overlay_changed.emit(frames_per_second_overlay_enabled)

func SetMasterVolume(p_value: float) -> void:
	master_volume = p_value
	_apply_bus_volume("Master", master_volume)
	Save()

func SetMusicVolume(p_value: float) -> void:
	music_volume = p_value
	_apply_bus_volume("Music", music_volume)
	Save()

func SetSoundEffectsVolume(p_value: float) -> void:
	sound_effects_volume = p_value
	_apply_bus_volume("Sound Effects", sound_effects_volume)
	Save()

func SetScreenShakeEnabled(p_enabled: bool) -> void:
	screen_shake_enabled = p_enabled
	Save()

func SetTargetingHelpEnabled(p_enabled: bool) -> void:
	targeting_help_enabled = p_enabled
	Save()

func SetFullscreen(p_enabled: bool) -> void:
	fullscreen = p_enabled
	_apply_fullscreen()
	Save()

func SetFramesPerSecondOverlayEnabled(p_enabled: bool) -> void:
	frames_per_second_overlay_enabled = p_enabled
	frames_per_second_overlay_changed.emit(frames_per_second_overlay_enabled)
	Save()

func SetVerticalSyncEnabled(p_enabled: bool) -> void:
	vertical_sync_enabled = p_enabled
	_apply_vertical_sync()
	Save()

func SetMaximumFrameRate(p_frame_rate: int) -> void:
	maximum_frame_rate = p_frame_rate
	_apply_maximum_frame_rate()
	Save()

func SetLocale(p_locale: String) -> void:
	locale = p_locale
	_apply_locale()
	Save()

func ResetToDefaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sound_effects_volume = DEFAULT_SOUND_EFFECTS_VOLUME
	screen_shake_enabled = DEFAULT_SCREEN_SHAKE_ENABLED
	targeting_help_enabled = DEFAULT_TARGETING_HELP_ENABLED
	fullscreen = DEFAULT_FULLSCREEN
	frames_per_second_overlay_enabled = DEFAULT_FRAMES_PER_SECOND_OVERLAY_ENABLED
	vertical_sync_enabled = DEFAULT_VERTICAL_SYNC_ENABLED
	maximum_frame_rate = DEFAULT_MAXIMUM_FRAME_RATE
	locale = DEFAULT_LOCALE
	ApplyAll()
	Save()

func _apply_bus_volume(p_bus_name: String, p_linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(p_bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, p_linear_volume <= 0.0)
	if p_linear_volume > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(p_linear_volume))

func _apply_fullscreen() -> void:
	# Handheld window mode toggles system bars / immersive mode; the fullscreen
	# setting only applies to desktop windowing.
	if _is_handheld():
		return
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _apply_vertical_sync() -> void:
	var mode: int = DisplayServer.VSYNC_ENABLED if vertical_sync_enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)

func _apply_maximum_frame_rate() -> void:
	Engine.max_fps = maximum_frame_rate

func _apply_locale() -> void:
	TranslationServer.set_locale(locale)

func _is_handheld() -> bool:
	return OS.has_feature("mobile")
