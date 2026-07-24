class_name Settings extends Node

const CONFIG_PATH: String = "user://settings.cfg"
const CONFIG_SECTION: String = "settings"

const DEFAULT_MASTER_VOLUME: float = 1.0
const DEFAULT_MUSIC_VOLUME: float = 1.0
const DEFAULT_SOUND_EFFECTS_VOLUME: float = 1.0
const DEFAULT_SCREEN_SHAKE_ENABLED: bool = true
const DEFAULT_FULLSCREEN: bool = false
const DEFAULT_LOCALE: String = "en"

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sound_effects_volume: float = DEFAULT_SOUND_EFFECTS_VOLUME
# Read by future screen-shake effect code to decide whether to apply camera shake.
var screen_shake_enabled: bool = DEFAULT_SCREEN_SHAKE_ENABLED
var fullscreen: bool = DEFAULT_FULLSCREEN
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
	fullscreen = config.get_value(CONFIG_SECTION, "fullscreen", DEFAULT_FULLSCREEN)
	locale = config.get_value(CONFIG_SECTION, "locale", DEFAULT_LOCALE)

func Save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(CONFIG_SECTION, "master_volume", master_volume)
	config.set_value(CONFIG_SECTION, "music_volume", music_volume)
	config.set_value(CONFIG_SECTION, "sound_effects_volume", sound_effects_volume)
	config.set_value(CONFIG_SECTION, "screen_shake_enabled", screen_shake_enabled)
	config.set_value(CONFIG_SECTION, "fullscreen", fullscreen)
	config.set_value(CONFIG_SECTION, "locale", locale)
	config.save(CONFIG_PATH)

func ApplyAll() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("Sound Effects", sound_effects_volume)
	_apply_fullscreen()
	_apply_locale()

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

func SetFullscreen(p_enabled: bool) -> void:
	fullscreen = p_enabled
	_apply_fullscreen()
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
	fullscreen = DEFAULT_FULLSCREEN
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
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _apply_locale() -> void:
	TranslationServer.set_locale(locale)
