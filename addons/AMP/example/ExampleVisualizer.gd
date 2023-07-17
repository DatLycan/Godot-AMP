extends ProgressBar

const SMOOTH_STEP: float = 100

@onready var amp: AnimationPlayer = $"../../../../../../../ExampleBeat"
@export_enum("Numerator: 0", "Denominator: 1", "Measure: 2") var type: int

func _ready() -> void:
	match type:
		0:
			max_value = amp.numerator_to_sec() * SMOOTH_STEP
		1:
			max_value = amp.denominator_to_sec() * SMOOTH_STEP
		2:
			max_value = amp.measure_to_sec() * SMOOTH_STEP

func _process(_delta: float) -> void:
	if not amp: return
	match type:
		0:
			value = amp.numerator.timer.time_left * SMOOTH_STEP
		1:
			value = amp.denominator.timer.time_left * SMOOTH_STEP
		2:
			value = amp.measure.timer.time_left * SMOOTH_STEP
	
