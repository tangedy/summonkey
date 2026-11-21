extends PointLight2D
## Gentle candle-style flicker around `base_energy` (taken from `energy` on
## ready). Tween `base_energy` to flare the light without fighting the flicker.

@export var amount := 0.18
@export var speed := 5.0

var base_energy := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0


func _ready() -> void:
	base_energy = energy
	_noise.seed = randi()
	_noise.frequency = 0.6


func _process(delta: float) -> void:
	_t += delta * speed
	energy = base_energy * (1.0 + amount * _noise.get_noise_1d(_t))
