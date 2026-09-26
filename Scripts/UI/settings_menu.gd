class_name SettingsMenu extends Control

const LOCALE_BY_LANGUAGE_ID: Dictionary[int, String] = {
	0: "en",
}

@export var _background: ColorRect
@export var _master_volume_slider: HSlider
@export var _music_volume_slider: HSlider
@export var _sound_effects_volume_slider: HSlider
@export var _screen_shake_check_box: CheckBox
@export var _targeting_help_check_box: CheckBox
@export var _fullscreen_check_box: CheckBox
@export var _frames_per_second_overlay_check_box: CheckBox
@export var _vertical_sync_check_box: CheckBox
@export var _maximum_frame_rate_option_button: OptionButton
@export var _language_option_button: OptionButton

var _populating: bool = false

func GetSize() -> Vector2:
	return _background.get_rect().size

func Init() -> void:
	_populating = true

	var settings: Settings = _get_settings()
	_master_volume_slider.value = settings.master_volume
	_music_volume_slider.value = settings.music_volume
	_sound_effects_volume_slider.value = settings.sound_effects_volume
	_screen_shake_check_box.button_pressed = settings.screen_shake_enabled
	_targeting_help_check_box.button_pressed = settings.targeting_help_enabled
	_fullscreen_check_box.button_pressed = settings.fullscreen
	_fullscreen_check_box.visible = not OS.has_feature("mobile")
	_frames_per_second_overlay_check_box.button_pressed = settings.frames_per_second_overlay_enabled
	_vertical_sync_check_box.button_pressed = settings.vertical_sync_enabled
	_maximum_frame_rate_option_button.select(_maximum_frame_rate_option_button.get_item_index(settings.maximum_frame_rate))

	for language_id in LOCALE_BY_LANGUAGE_ID:
		if LOCALE_BY_LANGUAGE_ID[language_id] == settings.locale:
			_language_option_button.select(_language_option_button.get_item_index(language_id))
			break

	_populating = false

func _get_settings() -> Settings:
	return get_node("/root/Game_Settings")

func _on_master_volume_changed(p_value: float) -> void:
	if _populating:
		return
	_get_settings().SetMasterVolume(p_value)

func _on_music_volume_changed(p_value: float) -> void:
	if _populating:
		return
	_get_settings().SetMusicVolume(p_value)

func _on_sound_effects_volume_changed(p_value: float) -> void:
	if _populating:
		return
	_get_settings().SetSoundEffectsVolume(p_value)

func _on_screen_shake_toggled(p_pressed: bool) -> void:
	if _populating:
		return
	_get_settings().SetScreenShakeEnabled(p_pressed)

func _on_targeting_help_toggled(p_pressed: bool) -> void:
	if _populating:
		return
	_get_settings().SetTargetingHelpEnabled(p_pressed)

func _on_fullscreen_toggled(p_pressed: bool) -> void:
	if _populating:
		return
	_get_settings().SetFullscreen(p_pressed)

func _on_frames_per_second_overlay_toggled(p_pressed: bool) -> void:
	if _populating:
		return
	_get_settings().SetFramesPerSecondOverlayEnabled(p_pressed)

func _on_vertical_sync_toggled(p_pressed: bool) -> void:
	if _populating:
		return
	_get_settings().SetVerticalSyncEnabled(p_pressed)

func _on_maximum_frame_rate_selected(p_index: int) -> void:
	if _populating:
		return
	_get_settings().SetMaximumFrameRate(_maximum_frame_rate_option_button.get_item_id(p_index))

func _on_language_selected(p_index: int) -> void:
	if _populating:
		return
	var language_id: int = _language_option_button.get_item_id(p_index)
	_get_settings().SetLocale(LOCALE_BY_LANGUAGE_ID.get(language_id, Settings.DEFAULT_LOCALE))

func _on_reset_pressed() -> void:
	_get_settings().ResetToDefaults()
	Init()

func _on_back_pressed() -> void:
	self.hide()
