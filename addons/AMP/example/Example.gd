extends CanvasLayer

const TIMER_CUTOFF: int = 4

@export_category("AdaptiveMusicPlayer")
@export var amp: Node
@export var track_name: Label
@export_category("Inputs")
@export var clap_button: CheckButton
@export var kick_button: CheckButton
@export var snare_button: CheckButton
@export var text_input: LineEdit

@export_category("Info Panel")
@export var known_stems: TextEdit
@export var playing_stems: TextEdit

@export_category("Progress Bars")
@export_subgroup("Numerator")
@export var numerator_title: Label
@export var numerator_time: Label
@export var numerator_index: Label
@export_subgroup("Denominator")
@export var denominator_title: Label
@export var denominator_time: Label
@export var denominator_index: Label
@export_subgroup("Measure")
@export var measure_title: Label
@export var measure_time: Label
@export var measure_index: Label

func _ready() -> void:
	track_name.text = "%s - %sBPM" % [amp.track_name, amp.bpm]
	for identifier in amp.known_identifiers:
		var index: int = known_stems.get_line_count() - 1
		known_stems.insert_line_at(index, identifier)

func _process(_delta: float) -> void:
	numerator_time.text = str(amp.numerator.timer.time_left).left(TIMER_CUTOFF)
	denominator_time.text = str(amp.denominator.timer.time_left).left(TIMER_CUTOFF)
	measure_time.text = str(amp.measure.timer.time_left).left(TIMER_CUTOFF)

func _on_numerator_played(_numerator_data) -> void: 
	_blink_label(numerator_title)
	_blink_label(numerator_time)
	_blink_label(numerator_index)
	numerator_index.text = str(wrapi(int(numerator_index.text) + 1, 0, amp.time_signature.x))

func _on_denominator_played(_denominator_data) -> void:
	_blink_label(denominator_title)
	_blink_label(denominator_time)
	_blink_label(denominator_index)
	denominator_index.text = str(wrapi(int(denominator_index.text) + 1, 0, amp.time_signature.y))
	
func _on_measure_played(measure_data) -> void:
	_blink_label(measure_title)
	_blink_label(measure_time)
	_blink_label(measure_index)
	measure_index.text = str(measure_data.x)

func _blink_label(title: Label) -> void:
	var cached_self_modulate: Color = title.self_modulate
	var tween: Tween = create_tween()
	tween.tween_property(title, "self_modulate", Color.WHITE, 0.1)
	tween.tween_property(title, "self_modulate", cached_self_modulate, 0.1)

func _on_play_pressed() -> void: amp.play(amp.DAW_NAME)
func _on_pause_pressed() -> void: amp.pause()
func _on_stop_pressed() -> void: amp.stop()

func _on_clap_toggled(button_pressed: bool) -> void:
	if button_pressed: amp.add("Clap")
	else: amp.remove("Clap")

func _on_kick_toggled(button_pressed: bool) -> void:
	if button_pressed: amp.add("Kick")
	else: amp.remove("Kick")

func _on_snare_toggled(button_pressed: bool) -> void:
	if button_pressed: amp.add("Snare")
	else: amp.remove("Snare")

func _on_text_input_text_submitted(new_text: String) -> void:
	if new_text.is_empty(): new_text = text_input.placeholder_text
	amp.add(new_text)
	for stem in amp.get_handled_stems(new_text):
		match stem:
			"Clap":
				clap_button.set_pressed_no_signal(true)
			"Kick":
				kick_button.set_pressed_no_signal(true)
			"Snare":
				snare_button.set_pressed_no_signal(true)
	text_input.text = ""


func _on_stem_added(identifier) -> void:
	var index: int = playing_stems.get_line_count() - 1
	playing_stems.insert_line_at(index, identifier)


func _on_stem_removed(_identifier) -> void:
	#Bruh way to do it
	playing_stems.clear()
	for stem in amp._playing_stems:
		var index: int = playing_stems.get_line_count() - 1
		playing_stems.insert_line_at(index, stem)

