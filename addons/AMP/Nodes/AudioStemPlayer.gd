@tool
extends AudioStreamPlayer

@export_category("AudioStemPlayer")
## The identifier this stem listens to on add().
@export var identifier: StringName = name:
	set(value): 
		if value.length() > 0: identifier = value
		else: identifier = identifier.left(1); push_warning("Identifier can't be empty.")
		_set_preset()
## The group identifiers this stem listens to when the prefix "Group/" is added on add().
@export var groups: PackedStringArray
## A preset that overrides the global preset of the AdaptiveMusicPlayer.
@export var preset: StemPlaybackPreset:
	set(value):
		preset = value
		_set_preset()
## The AudioStream object to be played on add().
@export var audio: AudioStream


func _get_configuration_warnings() -> PackedStringArray:
	var warning: PackedStringArray
	if not get_meta("_has_amp"):
		warning.append("No MusicPlayer found. Expected an AudioMusicPlayer parent.")
	if not audio:
		warning.append("No AudioStream found. Expected attached AudioStream.")
	return warning


func _init() -> void:
	set_meta("_has_amp", false)
	groups.append(StringName("ALL"))

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if not get_parent().has_meta("_is_amp"):
		set_meta("_has_amp", false)


func _set_preset():
	if preset:
		preset.default_identifier = identifier
		preset._hide_default_identifier = true
		preset.notify_property_list_changed()


func fade_volume(fade_in: bool, data: StemPlaybackPreset = preset):
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	if fade_in:
		volume_db = -80
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "volume_db", data.default_volume, data.fade_in_time)
	else:
		volume_db = data.default_volume
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(self, "volume_db", -80, data.fade_out_time)
