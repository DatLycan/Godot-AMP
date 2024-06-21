@tool
@icon("res://addons/AMP/icons/ASP_D_icon.png")
extends Resource
class_name StemPlaybackPreset

## The identifier that is used when no identifier is specified in the AdaptiveMusicPlayer's add() function.
var default_identifier: StringName = "Group/ALL"
var _hide_default_identifier: bool = false
## The default volume of sound in dB that the stem sets itself when adding.
var default_volume: float = 0:
	set(value):
		default_volume = value
## How the stem is played when added.
var playback_mode: int = ASP.MODE_PLAYBACK_DO_LOOP:
	set(value):
		playback_mode = value
		notify_property_list_changed()
## If true the stem will not be removed when the track restarts.
var repeat_on_restart: bool = false
@export_subgroup("Add")
## The metric position at which the stem is added.
@export_enum("Measure:22", "Numerator:20", "Denominator:21") var insert_position: int = ASP.MODE_INSERT_POS_AT_MEASURE
## The stems played effect when adding.
@export_enum("None:10", "Fade:11") var start_effect: int = ASP.MODE_SFX_NONE:
	set(value):
		start_effect = value
		if Engine.is_editor_hint():
			fade_in_time = 4
			notify_property_list_changed()
var fade_in_time: float = 4
@export_subgroup("Remove")
## The stems played effect when removing. 
@export_enum("None:10", "Fade:11") var end_effect: int = ASP.MODE_SFX_NONE:
	set(value):
		end_effect = value
		if Engine.is_editor_hint():
			fade_out_time = 4
			notify_property_list_changed()
var fade_out_time: float = 4
@export_subgroup("")


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	
	var default_identifier_usage = PROPERTY_USAGE_DEFAULT
	if _hide_default_identifier:
		default_identifier_usage = PROPERTY_USAGE_NO_EDITOR
	properties.append({
		"name": "default_identifier",
		"type": TYPE_STRING_NAME,
		"usage": default_identifier_usage
	})
	
	properties.append({
		"name": "playback_mode",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Looped:0, Oneshot:1"
	})

	properties.append({
		"name": "default_volume",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "-80, 24"
	})
	
	var repeat_on_restart_usage = PROPERTY_USAGE_NO_EDITOR
	if playback_mode == ASP.MODE_PLAYBACK_NO_LOOP:
		repeat_on_restart_usage = PROPERTY_USAGE_DEFAULT
	else: repeat_on_restart = false
	properties.append({
		"name": "repeat_on_restart",
		"type": TYPE_BOOL,
		"usage": repeat_on_restart_usage
	})
	
	var fade_in_usage = PROPERTY_USAGE_NO_EDITOR
	if start_effect == ASP.MODE_SFX_FADE:
		fade_in_usage = PROPERTY_USAGE_DEFAULT
	properties.append({
		"name": "Add/fade_in_time",
		"type": TYPE_FLOAT,
		"usage": fade_in_usage,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.5, 30"
	})

	var fade_out_usage = PROPERTY_USAGE_NO_EDITOR
	if end_effect == ASP.MODE_SFX_FADE:
		fade_out_usage = PROPERTY_USAGE_DEFAULT
	properties.append({
		"name": "Remove/fade_out_time",
		"type": TYPE_FLOAT,
		"usage": fade_out_usage,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.1, 10"
	})
	return properties


func _set(property: StringName, value) -> bool:
	match property:
		"Add/fade_in_time":
			fade_in_time = value
		"Remove/fade_out_time":
			fade_out_time = value
	return true

func _get(property: StringName):
	match property:
		"Add/fade_in_time":
			return fade_in_time
		"Remove/fade_out_time":
			return fade_out_time


func _init(_default_identifier: StringName = "Group/ALL", _playback_mode: int = ASP.MODE_PLAYBACK_NO_LOOP, _default_volume: float = default_volume, _position: int = ASP.MODE_INSERT_POS_AT_MEASURE, _effect: int = ASP.MODE_SFX_NONE) -> void:
	default_identifier = _default_identifier
	playback_mode = _playback_mode
	default_volume = _default_volume
	insert_position = _position
	start_effect = _effect
	end_effect = _effect


static func new(default_identifier: StringName = "Group/ALL", playback_mode: int = ASP.MODE_PLAYBACK_NO_LOOP, position: int = ASP.MODE_INSERT_POS_AT_MEASURE, default_volume: float = 0, effect: int = ASP.MODE_SFX_NONE):
	super.new()
