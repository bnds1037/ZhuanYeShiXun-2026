extends OverlayUI_Tab

## A tab that allows changing useful settings.

const SETTINGS_PATH: String = "user://settings.cfg"

## The default music volume (linear, not db)
@export var default_music_volume := 0.8
## The default sound effects volume (linear, not db)
@export var default_sound_effects_volume := 0.8
## The default ui sounds volume (linear, not db)
@export var default_ui_sounds_volume := 0.5

var _config: ConfigFile = ConfigFile.new()


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear_value))


func _ready() -> void:
	_config.load(SETTINGS_PATH)

	_on_setting_display_item_selected(_config.get_value("settings", "display_mode", 0))

	_set_bus_volume("UI_SFX", _config.get_value("settings", "ui_sounds_volume", default_ui_sounds_volume))
	_set_bus_volume("Music", _config.get_value("settings", "music_volume", default_music_volume))
	_set_bus_volume("SFX", _config.get_value("settings", "sound_effects_volume", default_sound_effects_volume))

	super()


func _open() -> void:
	%Setting_Display.select(0)
	if get_viewport().get_window().mode == Window.MODE_FULLSCREEN:
		%Setting_Display.select(1)

	%Setting_TextSpeed.value = _config.get_value("settings", "text_speed", 1.0)
	%Setting_AutoSpeed.value = _config.get_value("settings", "auto_advance_modifier", 1.0)
	%Setting_SkipUnseen.button_pressed = _config.get_value("settings", "skip_unseen_text", false)
	%Setting_SkipSeen.button_pressed = _config.get_value("settings", "skip_auto_seen_text", false)
	%Setting_MusicVolume.value = _config.get_value("settings", "music_volume", default_music_volume)
	%Setting_SoundsVolume.value = _config.get_value("settings", "sound_effects_volume", default_sound_effects_volume)
	%Setting_UIVolume.value = _config.get_value("settings", "ui_sounds_volume", default_ui_sounds_volume)


#region SETTINGS CHANGED SIGNALS
################################################################################

func _save_settings() -> void:
	_config.save(SETTINGS_PATH)


## Display Setting
func _on_setting_display_item_selected(index: int) -> void:
	match index:
		0:
			get_viewport().get_window().mode = Window.MODE_WINDOWED
		1:
			get_viewport().get_window().mode = Window.MODE_FULLSCREEN
	_config.set_value("settings", "display_mode", index)
	_save_settings()


## Text Speed Setting
func _on_setting_text_speed_value_changed(value: float) -> void:
	_config.set_value("settings", "text_speed", value)
	_save_settings()


## Auto Advance Speed Setting
func _on_setting_auto_speed_value_changed(value: float) -> void:
	_config.set_value("settings", "auto_advance_modifier", value)
	_save_settings()


## Input Settings
func _on_setting_skip_unseen_toggled(toggled_on: bool) -> void:
	_config.set_value("settings", "skip_unseen_text", toggled_on)
	_save_settings()


func _on_setting_skip_seen_toggled(toggled_on: bool) -> void:
	_config.set_value("settings", "skip_auto_seen_text", toggled_on)
	_save_settings()


## Audio Volumes
func _on_setting_music_volume_value_changed(value: float) -> void:
	_config.set_value("settings", "music_volume", value)
	_save_settings()
	_set_bus_volume("Music", value)


func _on_setting_sounds_volume_value_changed(value: float) -> void:
	_config.set_value("settings", "sound_effects_volume", value)
	_save_settings()
	_set_bus_volume("SFX", value)


func _on_setting_ui_volume_value_changed(value: float) -> void:
	_config.set_value("settings", "ui_sounds_volume", value)
	_save_settings()
	_set_bus_volume("UI_SFX", value)

#endregion
