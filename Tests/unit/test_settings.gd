extends GutTest

var _settings: Settings

func before_each() -> void:
	_settings = Settings.new()

func after_each() -> void:
	_settings.free()
	if FileAccess.file_exists(Settings.CONFIG_PATH):
		DirAccess.remove_absolute(Settings.CONFIG_PATH)

func test_defaults_match_documented_values() -> void:
	assert_eq(_settings.master_volume, Settings.DEFAULT_MASTER_VOLUME)
	assert_eq(_settings.music_volume, Settings.DEFAULT_MUSIC_VOLUME)
	assert_eq(_settings.sound_effects_volume, Settings.DEFAULT_SOUND_EFFECTS_VOLUME)
	assert_eq(_settings.screen_shake_enabled, Settings.DEFAULT_SCREEN_SHAKE_ENABLED)
	assert_eq(_settings.fullscreen, Settings.DEFAULT_FULLSCREEN)
	assert_eq(_settings.locale, Settings.DEFAULT_LOCALE)

func test_reset_to_defaults_restores_defaults_after_mutation() -> void:
	_settings.master_volume = 0.2
	_settings.music_volume = 0.3
	_settings.sound_effects_volume = 0.4
	_settings.screen_shake_enabled = false
	_settings.fullscreen = true
	_settings.locale = "en"

	_settings.ResetToDefaults()

	assert_eq(_settings.master_volume, Settings.DEFAULT_MASTER_VOLUME)
	assert_eq(_settings.music_volume, Settings.DEFAULT_MUSIC_VOLUME)
	assert_eq(_settings.sound_effects_volume, Settings.DEFAULT_SOUND_EFFECTS_VOLUME)
	assert_eq(_settings.screen_shake_enabled, Settings.DEFAULT_SCREEN_SHAKE_ENABLED)
	assert_eq(_settings.fullscreen, Settings.DEFAULT_FULLSCREEN)

func test_save_then_load_round_trips_values() -> void:
	_settings.master_volume = 0.6
	_settings.music_volume = 0.25
	_settings.sound_effects_volume = 0.75
	_settings.screen_shake_enabled = false
	_settings.fullscreen = true

	_settings.Save()

	var loaded: Settings = Settings.new()
	loaded.Load()

	assert_almost_eq(loaded.master_volume, 0.6, 0.0001)
	assert_almost_eq(loaded.music_volume, 0.25, 0.0001)
	assert_almost_eq(loaded.sound_effects_volume, 0.75, 0.0001)
	assert_eq(loaded.screen_shake_enabled, false)
	assert_eq(loaded.fullscreen, true)
	loaded.free()

func test_zero_volume_mutes_the_bus() -> void:
	_settings.SetMusicVolume(0.0)

	var bus_index: int = AudioServer.get_bus_index("Music")
	assert_true(AudioServer.is_bus_mute(bus_index))

func test_positive_volume_unmutes_the_bus_and_sets_zero_db_at_full_value() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)

	_settings.SetMusicVolume(1.0)

	var bus_index: int = AudioServer.get_bus_index("Music")
	assert_false(AudioServer.is_bus_mute(bus_index))
	assert_almost_eq(AudioServer.get_bus_volume_db(bus_index), 0.0, 0.001)

func test_set_locale_updates_the_translation_server() -> void:
	_settings.SetLocale("en")

	assert_eq(TranslationServer.get_locale(), "en")
