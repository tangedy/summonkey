class_name Box
extends AnimatableBody2D
## A crate the golem can lift. Boxes only ever move vertically: they fall
## until they land on a wall, another box, or the golem. They never rest on
## the monkey (he'd be pinned); if one lands on him he gets nudged aside.

const TILE := 45.0
const GRAVITY := 1500.0
const MAX_FALL := 650.0

## True once the box is sitting on something (safe to lift / stand on).
var resting := true

var _fall_speed := 0.0


func _physics_process(delta: float) -> void:
	_fall_speed = minf(_fall_speed + GRAVITY * delta, MAX_FALL)
	var hit := move_and_collide(Vector2(0, _fall_speed * delta))
	if hit:
		if not resting and not (hit.get_collider() is CharacterBody2D):
			# Landed on the grid: snap so stacks line up perfectly.
			position.y = roundf((position.y - TILE / 2) / TILE) * TILE + TILE / 2
		if not resting and _fall_speed > 250.0:
			get_tree().call_group(&"shakers", &"shake", clampf(_fall_speed / 220.0, 1.0, 3.0))
			SoundFx.play(&"box_land")
		resting = true
		_fall_speed = 0.0
	else:
		resting = false
