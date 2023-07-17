@tool
extends AnimationPlayer

signal numerator_played(index_and_timestamp: Vector2)
signal denominator_played(index_and_timestamp: Vector2)
signal measure_played(index_and_timestamp: Vector2)

signal music_started()
signal music_paused()
signal music_stopped()

signal stem_added(identifier: StringName)
signal stem_removed(identifier: StringName)

const LIB_NAME: StringName = "DAW"
const ANIM_NAME: StringName = "Stems"
const DAW_NAME: StringName = LIB_NAME + "/" + ANIM_NAME
const GROUP_PREFIX: StringName = "Group/"

@export_category("AdaptiveMusicPlayer")
@export var track_name: StringName = name:
	set(value): 
		if value.length() > 0: 
			track_name = value
		else: track_name = track_name.left(1); push_warning("Track Name can't be empty.")
@export_range(20, 300) var bpm: int = 100:
	set(value): bpm = value; _update_values()
@export var time_signature: Vector2i = Vector2i(4,4):
	set(value): time_signature = value; _update_values()
@export_range(1, 200) var measure_count: float = 100:
	set(value): measure_count = floor(value); _update_values()
@export var global_preset: StemPlaybackPreset
@export_subgroup("Debug")
@export var known_identifiers: PackedStringArray
@export var print_debug_log: bool = false

var _daw: Animation
var _playing: bool:
	set(value):
		_playing = value
		if _playing:
			if print_debug_log: print("Playing \"%s\"" % track_name)
			_update_values()
			_set_metric_positions()
			numerator.timer.name = "NumeratorTimer"
			denominator.timer.name = "DenominatorTimer"
			measure.timer.name = "MeasureTimer"
			add_child(numerator.timer)
			add_child(denominator.timer)
			add_child(measure.timer)
			numerator.timer.start(numerator_to_sec())
			denominator.timer.start(denominator_to_sec())
			measure.timer.start(measure_to_sec())
			super.play(DAW_NAME)
		else:
			numerator.timer.stop()
			denominator.timer.stop()
			measure.timer.stop()
			remove_child(numerator.timer)
			remove_child(denominator.timer)
			remove_child(measure.timer)
			super.pause()
var _playing_stems: PackedStringArray = []

var measure: _MetricPosition = _MetricPosition.new()
var numerator: _MetricPosition = _MetricPosition.new()
var denominator: _MetricPosition = _MetricPosition.new()

var numerator_count: int = 0
var denominator_count: int = 0


func _get_configuration_warnings() -> PackedStringArray:
	var warning: PackedStringArray
	var stream_players: Array = find_children("", "AudioStreamPlayer")
	if get_child_count() == 0 or not _has_stem():
		warning.append("No Stem found. Expected one AudioStemPlayer child.")
	return warning


func _init() -> void:
	if not root_node == NodePath("."): root_node = NodePath(".")

func _ready() -> void:
	_generate_audio_bus()
	if Engine.is_editor_hint(): return
	_connect_signals()
	if get_autoplay() == DAW_NAME: 
		_playing = true


func _enter_tree() -> void:
	if not Engine.is_editor_hint(): return
	set_meta("_is_amp", true)
	_connect_signals()
	if has_animation_library(LIB_NAME): 
		if not _daw: _daw = get_animation(DAW_NAME) 
		return
	add_animation_library(LIB_NAME, _create_anim_lib())
	_set_daw(known_identifiers)

func _on_child_entered_tree(child: Node) -> void:
	if child.has_meta("_has_amp") and not child.get_meta("_has_amp"):
		if child.get_meta("_has_amp"): return
		child.set_meta("_has_amp", true)
		child.bus = track_name
		_add_daw_track(child.identifier)

func _on_child_exited_tree(child: Node) -> void:
	if child.has_meta("_has_amp"):
		var index: int = known_identifiers.find(child.identifier)
		if index == -1: return
		known_identifiers.remove_at(index)

func set_autoplay(daw_name: String = "") -> void:
	if not Engine.is_editor_hint():
		_playing = true
	super.set_autoplay(daw_name)


func _connect_signals() -> void:
	if child_entered_tree.is_connected(_on_child_entered_tree): return
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exited_tree)
	animation_finished.connect(func (_daw: StringName): _internal_stop())
	numerator.signal_parsed.connect(_on_numerator_signal_parsed)
	denominator.signal_parsed.connect(_on_denominator_signal_parsed)
	measure.signal_parsed.connect(_on_measure_signal_parsed)

func _on_numerator_signal_parsed(index_and_timestamp: Vector2) -> void: numerator_played.emit(index_and_timestamp)
func _on_denominator_signal_parsed(index_and_timestamp: Vector2) -> void: denominator_played.emit(index_and_timestamp)
func _on_measure_signal_parsed(index_and_timestamp: Vector2) -> void: measure_played.emit(index_and_timestamp)

func _generate_audio_bus() -> void:
	await get_tree().process_frame
	if not AudioServer.get_bus_index(track_name) == -1: return
	if print_debug_log: print("Audio Bus \"%s\" not found. Creating new one." % track_name)
	AudioServer.add_bus()
	_set_audio_bus_name(AudioServer.bus_count - 1)
	
func _set_audio_bus_name(index: int) -> void:
	AudioServer.set_bus_name(index, track_name)
	for identifier in known_identifiers:
		stem_identifier_to_node(identifier).bus = track_name


func _set_metric_positions() -> void:
	measure.timestamps.clear()
	numerator.timestamps.clear()
	denominator.timestamps.clear()
	for index in range(measure_count): 
		measure.timestamps.append(float(measure_to_sec() * index))
	for index in range(numerator_count): 
		numerator.timestamps.append(float(numerator_to_sec() * index))
	for index in range(denominator_count): 
		denominator.timestamps.append(float(denominator_to_sec() * index))

func _has_stem() -> bool:
	for child in get_children():
		if child.has_meta("_has_amp"): return true
	return false


func _create_anim_lib() -> AnimationLibrary:
	var lib = AnimationLibrary.new()
	lib.add_animation(ANIM_NAME, Animation.new())
	_daw = lib.get_animation(ANIM_NAME)
	_daw.loop_mode = Animation.LOOP_LINEAR
	_update_values()
	return lib

func _set_daw(known_identifiers: Array) -> void:
	for identifier in known_identifiers:
		_add_daw_track(identifier)

func _add_daw_track(identifier: StringName) -> void:
	if not _daw: return
	var stem: AudioStreamPlayer = stem_identifier_to_node(identifier)
	var index = _daw.add_track(Animation.TYPE_AUDIO)
	_daw.track_set_path(index, NodePath(stem.name))
	known_identifiers.append(stem.identifier)
	if print_debug_log: print("\"%s\" stem added." % stem.identifier)


func _update_values() -> void:
	if not _daw: _daw = get_animation(DAW_NAME) 
	numerator_count = measure_count * time_signature.y
	denominator_count = measure_count * time_signature.y
	_daw.length = float(measure_to_sec() * measure_count)
	_daw.step = measure_to_sec()
	_set_metric_positions()


func stem_identifier_to_group(identifier: StringName):
	var grouped_stems: PackedStringArray = []
	if _is_identifier_group(identifier):
		var group_name: StringName = _get_identifier_group_name(identifier)
		grouped_stems = _get_stems_in_group(group_name)
	return grouped_stems

func _is_identifier_group(identifier: StringName) -> bool:
	return identifier.contains(GROUP_PREFIX)

func _get_identifier_group_name(identifier: StringName) -> StringName:
	return identifier.right(-6)

func _get_stems_in_group(group_name: StringName) -> PackedStringArray:
	var grouped_stems: PackedStringArray = []
	for identifier in known_identifiers:
		var stem: AudioStreamPlayer = stem_identifier_to_node(identifier)
		if stem.groups.has(group_name):
			grouped_stems.append(identifier)
	return grouped_stems


func get_child_stems() -> Array[AudioStreamPlayer]:
	var children_stems: Array[AudioStreamPlayer]
	for child in get_children():
		if child.has_meta("_has_amp"):
			children_stems.append(child)
	return children_stems

func stem_identifier_to_node(identifier: StringName) -> AudioStreamPlayer:
	var found_stem: AudioStreamPlayer
	for child in get_child_stems():
		if child.identifier == identifier:
			found_stem = child
			break
	if not found_stem: push_warning("%s not found." % identifier)
	return found_stem


func bpm_to_sec() -> float:
	return float(60.0 / bpm)
func measure_to_sec() -> float:
	return float(bpm_to_sec() * time_signature.y)
func numerator_to_sec() -> float:
	return float(measure_to_sec() / time_signature.x)
func denominator_to_sec() -> float:
	return float(measure_to_sec() / time_signature.y)


func get_handled_stems(identifier: StringName) -> PackedStringArray:
	var handled_stems: PackedStringArray = []
	if _is_identifier_group(identifier):
		var grouped_stems: PackedStringArray = stem_identifier_to_group(identifier)
		if grouped_stems.is_empty(): push_warning("No Stems found in \"%s\"." % _get_identifier_group_name(identifier)); return handled_stems 
		handled_stems.append_array(grouped_stems)
	else: 
		assert(known_identifiers.has(identifier), "\"%s\" is an unknown identifier." % identifier)
		handled_stems.append(identifier)
	return handled_stems


func add(identifier: StringName = "", data: StemPlaybackPreset = global_preset) -> void:
	if not global_preset: data = StemPlaybackPreset.new()
	if not _playing: _playing = true; music_started.emit()
	if identifier.is_empty(): identifier = data.default_identifier
	var added_stems: PackedStringArray = get_handled_stems(identifier)
	for stem_identifier in added_stems:
		if _playing_stems.has(stem_identifier): continue
		var stem: AudioStreamPlayer = stem_identifier_to_node(stem_identifier)
		var abs_data: StemPlaybackPreset = data
		if stem.preset: abs_data = stem.preset
		var index: int = known_identifiers.find(stem_identifier)
		var stream: AudioStream = stem.audio
		match abs_data.start_effect:
			ASP.MODE_SFX_NONE:
				stem.volume_db = abs_data.default_volume
			ASP.MODE_SFX_FADE:
				stem.fade_volume(true, abs_data)
				if print_debug_log: print("\"%s\" is fading in." % stem_identifier)
			_:
				return push_warning("Start Effect {%s} is invalid." % abs_data.start_effect)
		match abs_data.playback_mode:
			ASP.MODE_PLAYBACK_DO_LOOP:
				var timestamps: PackedFloat32Array
				match abs_data.insert_position:
					ASP.MODE_INSERT_POS_AT_NUMERATOR:
						timestamps = numerator.timestamps
					ASP.MODE_INSERT_POS_AT_DENOMINATOR:
						timestamps = denominator.timestamps
					ASP.MODE_INSERT_POS_AT_MEASURE:
						timestamps = measure.timestamps
					_:
						return push_warning("Insert Mode {%s} is invalid." % abs_data.insert_position)
				for timestamp in timestamps:
					_daw.audio_track_insert_key(index, timestamp, stream)
				if print_debug_log: print("\"%s\" will be played in loop." % stem_identifier)
				_playing_stems.append(stem_identifier)
				stem_added.emit(stem_identifier)
			ASP.MODE_PLAYBACK_NO_LOOP:
				var timestamp: float
				match abs_data.insert_position:
					ASP.MODE_INSERT_POS_AT_NUMERATOR:
						timestamp = numerator.next().y
					ASP.MODE_INSERT_POS_AT_DENOMINATOR:
						timestamp = denominator.next().y
					ASP.MODE_INSERT_POS_AT_MEASURE:
						timestamp = measure.next().y
					_:
						return push_warning("Insert Mode {%s} is invalid." % abs_data.insert_position)
				_daw.audio_track_insert_key(index, timestamp, stream)
				if print_debug_log: print("\"%s\" will be played at {%s}." % [stem_identifier, timestamp])
				_playing_stems.append(stem_identifier)
				stem_added.emit(stem_identifier)
				if not abs_data.repeat_on_restart:
					var thread: Thread = Thread.new()
					await get_tree().process_frame
					var time_left: float = measure.timer.time_left + stream.get_length()
					thread.start(_threaded_oneshot_removal.bind(thread, stem_identifier, time_left, index, timestamp))

func remove(identifier: StringName = "", data: StemPlaybackPreset = global_preset) -> void: 
	if not global_preset: global_preset = StemPlaybackPreset.new()
	if identifier.is_empty(): identifier = data.default_identifier
	var removed_stems: PackedStringArray = get_handled_stems(identifier)
	for stem_identifier in removed_stems:
		if not _playing_stems.has(stem_identifier): continue
		var stem: AudioStreamPlayer = stem_identifier_to_node(stem_identifier)
		var abs_data: StemPlaybackPreset = data
		if stem.preset: abs_data = stem.preset
		var index = known_identifiers.find(stem_identifier)
		var key_count: int = _daw.track_get_key_count(index)
		match abs_data.end_effect:
			ASP.MODE_SFX_NONE:
				for i in range(key_count):
					_daw.track_remove_key(index, 0)
				_playing_stems.remove_at(_playing_stems.find(stem_identifier))
				if print_debug_log: print("\"%s\" was removed." % stem_identifier)
				stem_removed.emit(identifier)
			ASP.MODE_SFX_FADE:
				stem.fade_volume(false, abs_data)
				if print_debug_log: print("\"%s\" is fading out." % stem_identifier)
				var thread: Thread = Thread.new()
				await get_tree().process_frame
				thread.start(_threaded_removal.bind(thread, stem_identifier, abs_data.fade_out_time, key_count, index))
			_:
				return push_warning("End Mode {%s} is invalid. Could not remove Stem." % abs_data.start_effect)

func _threaded_oneshot_removal(thread: Thread, identifier: StringName, time_left: float, index: int, timestamp: float):
	await get_tree().create_timer(time_left).timeout
	_daw.track_remove_key_at_time(index, timestamp)
	if _playing_stems.has(identifier):
		_playing_stems.remove_at(_playing_stems.find(identifier))
		if print_debug_log: print("\"%s\" was removed. (Oneshot)" % identifier)
	stem_removed.emit(identifier)
	thread.wait_to_finish()

func _threaded_removal(thread: Thread, identifier: StringName, time_left: float, key_count: int, index: int):
	await get_tree().create_timer(time_left).timeout
	for i in range(key_count):
		_daw.track_remove_key(index, 0)
	_playing_stems.remove_at(_playing_stems.find(identifier))
	if print_debug_log: print("\"%s\" was removed." % identifier)
	stem_removed.emit(identifier)
	thread.wait_to_finish()


func play(daw: StringName = DAW_NAME, custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false) -> void:
	if _playing: push_warning("\"%s\" is already playing." % track_name); return
	music_started.emit()
	_playing = true

func pause() -> void:
	if not is_playing(): return 
	await denominator_played
	if print_debug_log: print("Paused \"%s\"" % track_name)
	_playing = false
	music_paused.emit()

func stop(keep_state: bool = false) -> void:
	if not is_playing(): return
	if print_debug_log: print("\"%s\" stopped." % track_name)
	_internal_stop()
	super.stop()

func _internal_stop():
	_playing = false
	measure._reset()
	numerator._reset()
	denominator._reset()
	music_stopped.emit()


class _MetricPosition:
	signal signal_parsed(index_and_timestamp: Vector2)
	var timer: Timer
	var timestamps: PackedFloat32Array = []
	var index: int = 0
	func _init() -> void:
		timer = Timer.new()
		timer.timeout.connect(_on_timer_timout)
	func _reset() -> void:
		index = 0
		timestamps.clear()
	func _on_timer_timout():
		index = wrapi(index + 1, 0, timestamps.size())
		signal_parsed.emit(current())
	func first() -> Vector2:
		return Vector2(0, timestamps[0])
	func prev(seek_index: int = 1) -> Vector2:
		return Vector2(index - seek_index, timestamps[wrapi(index - seek_index, 0, timestamps.size())])
	func current() -> Vector2:
		return Vector2(index, timestamps[index])
	func next(seek_index: int = 1) -> Vector2:
		return Vector2(index + seek_index, timestamps[wrapi(index + seek_index, 0, timestamps.size())])
	func last() -> Vector2:
		return Vector2(timestamps.size() - 1, timestamps[timestamps.size() - 1])
	func sec2prev() -> float:
		return float(current().y - prev().y)
	func sec2next() -> float:
		return float(next().y - current().y)

