class_name Monkey
extends CharacterBody2D
## The wizard monkey. Runs, jumps (about one tile), and summons the golem.

signal summon_animation_done

const SPEED := 135.0
const GROUND_ACCEL := 1400.0
const AIR_ACCEL := 900.0
const GRAVITY := 1300.0
const MAX_FALL := 720.0
const JUMP_VELOCITY := -390.0
const JUMP_CUT := 0.45  ## Releasing jump early caps upward speed to this fraction.
const COYOTE_TIME := 0.08
const JUMP_BUFFER := 0.12
const HALF_WIDTH := 11.0
const HEIGHT := 34.0
## Where the feet/centre of the monkey are inside its 54x54 frames.
const ANCHOR := Vector2(27, 51)
## The staff's gem, relative to the feet, when facing right.
const STAFF_TIP := Vector2(19, -34)

var controlled := true
## True while playing the summon animation; input is ignored.
var busy := false
## Set by the golem while it lifts us on top of a stack; physics is paused.
var frozen := false
var facing := 1
## The body we're standing on (wall, box or golem), refreshed every frame.
var floor_body: Object = null

var _coyote := 0.0
var _was_on_floor := true
var _fall_speed := 0.0
var _jump_buffer := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var staff_light: PointLight2D = $StaffLight


func _ready() -> void:
	sprite.offset = -ANCHOR
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var active := controlled and not busy
	var input_x := Input.get_axis("move_left", "move_right") if active else 0.0
	if active and Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_coyote = COYOTE_TIME if is_on_floor() else maxf(_coyote - delta, 0.0)

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		SoundFx.play(&"jump")
		_jump_buffer = 0.0
		_coyote = 0.0
	if velocity.y < 0.0 and not (active and Input.is_action_pressed("jump")):
		velocity.y = maxf(velocity.y, JUMP_VELOCITY * JUMP_CUT)

	var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	velocity.x = move_toward(velocity.x, input_x * SPEED, accel * delta)
	if input_x != 0.0:
		facing = 1 if input_x > 0.0 else -1

	_fall_speed = velocity.y
	move_and_slide()
	_step_up(input_x)
	_sounds(delta)

	floor_body = null
	if is_on_floor():
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			if c.get_normal().y < -0.7:
				floor_body = c.get_collider()
				break
	_update_animation()


## Walk over tiny lips (a few px) instead of getting stuck on them, e.g. the
## seam between a carried stack and the ledge next to it.
func _step_up(input_x: float) -> void:
	const MAX_STEP := 4.0
	if input_x == 0.0 or not is_on_floor() or not is_on_wall():
		return
	var lifted := global_transform.translated(Vector2(0, -MAX_STEP))
	if test_move(global_transform, Vector2(0, -MAX_STEP)):
		return  # no headroom
	if not test_move(lifted, Vector2(signf(input_x) * 2.0, 0)):
		global_position.y -= MAX_STEP
		velocity.x = input_x * SPEED * 0.5


func _sounds(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _fall_speed > 180.0:
		SoundFx.play(&"land")
	_was_on_floor = on_floor
	SoundFx.set_loop(&"monkey_step", on_floor and absf(velocity.x) > 40.0 and not frozen)


func get_rect() -> Rect2:
	return Rect2(global_position.x - HALF_WIDTH, global_position.y - HEIGHT, HALF_WIDTH * 2, HEIGHT)


func play_summon() -> void:
	busy = true
	sprite.scale.x = facing
	staff_light.position.x = STAFF_TIP.x * facing
	sprite.play(&"summon")
	SoundFx.play(&"summon")
	# Staff flares while casting.
	var t := create_tween()
	t.tween_property(staff_light, "base_energy", 3.2, 0.35)
	t.tween_property(staff_light, "base_energy", 1.1, 0.6)


func _on_animation_finished() -> void:
	if sprite.animation == &"summon":
		busy = false
		summon_animation_done.emit()


func _update_animation() -> void:
	if busy:
		return
	sprite.scale.x = facing
	staff_light.position.x = STAFF_TIP.x * facing
	if not is_on_floor():
		if sprite.animation != &"jump":
			sprite.play(&"jump")
		sprite.pause()
		# Pick the jump pose from vertical speed: launch, rise, apex, fall.
		if velocity.y < -200.0:
			sprite.frame = 1
		elif velocity.y < -40.0:
			sprite.frame = 2
		elif velocity.y < 120.0:
			sprite.frame = 3
		else:
			sprite.frame = 4
	elif absf(velocity.x) > 10.0:
		sprite.play(&"walk")
	else:
		sprite.play(&"idle")
