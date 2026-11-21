class_name Golem
extends CharacterBody2D
## The summoned big guy. Can't jump, but can lift a stack of up to three
## boxes onto its head, carry them (and a monkey riding on top), and put
## them down again. Lasts LIFETIME seconds before crumbling.

signal summon_finished
signal dismissed
signal message(text: String, at: Vector2)

enum State { SUMMONING, ACTIVE, LIFTING, DISMISSING }

const TILE := 45.0
const SPEED := 95.0
const ACCEL := 900.0
const GRAVITY := 1300.0
const MAX_FALL := 720.0
const LIFETIME := 30.0
const MAX_STACK := 3
const BODY_HALF_W := 19.0
const BODY_HEIGHT := 78.0
## The carried stack sits exactly two tiles above the golem's feet.
const CARRY_HEIGHT := 90.0
## In the lift animations the golem starts this far behind the box column.
const LIFT_STEP := 50.0
## Feet/centre position of the golem inside each animation's frames.
const ANCHORS := {
	&"idle": Vector2(31, 83),
	&"walk": Vector2(31, 83),
	&"summon": Vector2(48, 85),
	&"lift_1": Vector2(31, 143),
	&"lift_2": Vector2(31, 209),
	&"lift_3": Vector2(31, 239),
	&"carry_idle": Vector2(81, 143),
	&"carry_walk": Vector2(81, 143),
}
const BOX_TEXTURE := preload("res://assets/sprites/box.png")

var level: Level
var monkey: Monkey
var controlled := false
var facing := 1
var state := State.SUMMONING
var life := LIFETIME
var carried := 0
var _warned := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var particles: AnimatedSprite2D = $Particles
@onready var carried_body: AnimatableBody2D = $CarriedStack
@onready var stack_shape: CollisionShape2D = $CarriedStack/Shape
@onready var stack_visual: Node2D = $StackVisual
@onready var aura: PointLight2D = $Aura


func _ready() -> void:
	stack_shape.shape = stack_shape.shape.duplicate()
	# The carried crates are a separate solid body (boxes layer) so the monkey
	# can stand on them while walking straight through the golem itself.
	add_collision_exception_with(carried_body)
	particles.visible = false
	particles.animation_finished.connect(particles.hide)
	_set_carried(0)


func _physics_process(delta: float) -> void:
	queue_redraw()
	if state == State.ACTIVE:
		life -= delta
		if life <= 0.0:
			dismiss()
			return
		if life < 5.0 and not _warned:
			_warned = true
			SoundFx.play(&"golem_warning")
		# Pulse brighter and brighter as the summon runs out.
		if life < 6.0:
			var urgency := 1.0 - life / 6.0
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * lerpf(6.0, 18.0, urgency))
			var k := pulse * urgency * 0.8
			sprite.modulate = Color(1.0 + k, 1.0 + k * 1.4, 1.0 + k)
			aura.energy = 0.45 + k * 1.2
	if state != State.ACTIVE:
		return

	var input_x := Input.get_axis("move_left", "move_right") if controlled else 0.0
	velocity.x = move_toward(velocity.x, input_x * SPEED, ACCEL * delta)
	if input_x != 0.0:
		facing = 1 if input_x > 0.0 else -1
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	var before := global_position
	move_and_slide()
	var moved := global_position - before
	# Carry a monkey standing on our head / stack. (Runs before the monkey's
	# own physics step thanks to process_physics_priority = -1.)
	SoundFx.set_loop(&"golem_step", absf(moved.x) > 0.5 and is_on_floor())
	if moved.x != 0.0 and is_instance_valid(monkey) and is_carrying_monkey():
		monkey.move_and_collide(Vector2(moved.x, 0.0))
	_update_anim()


# --- summon / dismiss -------------------------------------------------------

func start_summon() -> void:
	state = State.SUMMONING
	_set_anim(&"summon")
	SoundFx.play(&"golem_appear")
	_play_particles(0.2)
	# Materialise in a burst of (HDR, so it blooms) green light.
	sprite.modulate = Color(2.4, 3.0, 2.4)
	aura.energy = 2.5
	var t := create_tween().set_parallel()
	t.tween_property(sprite, "modulate", Color.WHITE, 1.0)
	t.tween_property(aura, "energy", 0.45, 1.0)
	await sprite.animation_finished
	state = State.ACTIVE
	_update_anim()
	summon_finished.emit()


func dismiss() -> void:
	if state == State.DISMISSING:
		return
	state = State.DISMISSING
	controlled = false
	SoundFx.set_loop(&"golem_step", false)
	SoundFx.play(&"dismiss")
	_drop_in_place()
	sprite.offset = -ANCHORS[&"summon"]
	sprite.play_backwards(&"summon")
	_play_particles(0.0)
	var t := create_tween().set_parallel()
	t.tween_property(sprite, "modulate", Color(2.4, 3.0, 2.4, 0.0), 1.0)
	t.tween_property(aura, "energy", 0.0, 1.0)
	await sprite.animation_finished
	dismissed.emit()
	queue_free()


# --- lifting ----------------------------------------------------------------

## Space: lift the stack in front of us, or put down what we're carrying.
func toggle_carry() -> void:
	if state != State.ACTIVE or not is_on_floor():
		return
	if carried > 0:
		_try_drop()
	else:
		_try_lift()


func _try_lift() -> void:
	var feet := _feet_row()
	var target: Box = null
	var best := INF
	for b in level.get_boxes():
		if not b.resting or Level.cell_of(b.position).y != feet:
			continue
		var dx := (b.position.x - global_position.x) * facing
		if dx > 30.0 and dx < 68.0 and dx < best:
			best = dx
			target = b
	if target == null:
		_say("Nothing to lift")
		return

	var col := Level.cell_of(target.position).x
	var stack: Array[Box] = []
	var row := feet
	while true:
		var b := level.box_at(Vector2i(col, row))
		if b == null or not b.resting:
			break
		stack.append(b)
		row -= 1
	var n := stack.size()
	if n > MAX_STACK:
		_say("Too heavy!")
		return

	# We step into the box column and the stack rises two tiles, so every
	# cell from just above our feet to the new top of the stack must be clear.
	for r in range(feet - 1 - n, feet):
		var cell := Vector2i(col, r)
		var other := level.box_at(cell)
		if level.is_wall(cell) or (other != null and not stack.has(other)):
			_say("No room to lift")
			return

	var rider := is_instance_valid(monkey) and monkey.is_on_floor() and monkey.floor_body == stack[-1]
	if rider:
		if not level.is_free(Vector2i(col, feet - 2 - n)):
			_say("No headroom")
			return
	elif is_instance_valid(monkey):
		var region := Rect2(col * TILE, (feet - 1 - n) * TILE, TILE, (n + 1) * TILE).grow(-1.0)
		if monkey.get_rect().intersects(region):
			_say("Monkey's in the way")
			return

	state = State.LIFTING
	velocity = Vector2.ZERO
	SoundFx.set_loop(&"golem_step", false)
	SoundFx.play(&"lift")
	var col_x := (col + 0.5) * TILE
	for b in stack:
		b.hide()  # the animation draws the boxes; collision stays until it ends
	sprite.position.x = (col_x - LIFT_STEP * facing) - global_position.x
	_set_anim(StringName("lift_%d" % n))
	var rider_end_y := 0.0
	if rider:
		# Ride the box up in time with the animation instead of hovering.
		monkey.frozen = true
		monkey.velocity = Vector2.ZERO
		rider_end_y = monkey.global_position.y - CARRY_HEIGHT
		create_tween().tween_property(monkey, "global_position:y", rider_end_y, 0.6) \
				.set_delay(0.25).set_trans(Tween.TRANS_SINE)
	await sprite.animation_finished

	for b in stack:
		level.remove_box(b)
	global_position.x = col_x
	sprite.position.x = 0.0
	_set_carried(n)
	if rider and is_instance_valid(monkey):
		monkey.global_position.y = rider_end_y
		monkey.frozen = false
	state = State.ACTIVE
	_update_anim()


func _try_drop() -> void:
	var feet := _feet_row()
	var front_x := global_position.x + facing * (BODY_HALF_W + 1.0)
	var col := ceili(front_x / TILE) if facing > 0 else floori(front_x / TILE) - 1
	var cells: Array[Vector2i] = []
	for i in carried:
		cells.append(Vector2i(col, feet - 2 - i))
	for c in cells:
		var blocked := not level.is_free(c)
		if not blocked and is_instance_valid(monkey):
			blocked = monkey.get_rect().intersects(Level.cell_rect(c).grow(-1.0))
		if blocked:
			_say("No room to drop")
			return
	# Don't drop a stack onto the monkey's head: check the whole fall path.
	var land := cells[0].y
	while level.is_free(Vector2i(col, land + 1)):
		land += 1
	if is_instance_valid(monkey):
		var fall := Rect2(col * TILE, cells[0].y * TILE, TILE, (land - cells[0].y + 1) * TILE).grow(-1.0)
		if monkey.get_rect().intersects(fall):
			_say("Monkey's in the way")
			return
	_set_carried(0)
	SoundFx.play(&"drop")
	for c in cells:
		level.spawn_box(c)


## Used when the golem vanishes: the stack drops straight down where it is.
func _drop_in_place() -> void:
	if carried == 0:
		return
	var col := Level.cell_of(global_position).x
	var row := _feet_row() - 2
	var n := carried
	_set_carried(0)
	for i in n:
		while row > 0 and not level.is_free(Vector2i(col, row)):
			row -= 1
		level.spawn_box(Vector2i(col, row))
		row -= 1


# --- helpers ----------------------------------------------------------------

## True when the monkey is standing on the crates we're holding.
func is_carrying_monkey() -> bool:
	return is_instance_valid(monkey) and monkey.floor_body == carried_body


func _feet_row() -> int:
	return floori((global_position.y - 1.0) / TILE)


func _set_carried(n: int) -> void:
	carried = n
	stack_shape.disabled = n == 0
	# 2px slack on top so a stack fits through corridors exactly its height.
	var top := CARRY_HEIGHT + n * TILE - 2.0
	(stack_shape.shape as RectangleShape2D).size = Vector2(41, top - CARRY_HEIGHT)
	stack_shape.position = Vector2(0, -(top + CARRY_HEIGHT) / 2.0)
	for child in stack_visual.get_children():
		child.queue_free()
	for i in n:
		var s := Sprite2D.new()
		s.texture = BOX_TEXTURE
		s.region_enabled = true
		s.region_rect = Rect2(1, 4, 48, 45)
		s.position = Vector2(-1.5, -(CARRY_HEIGHT + TILE * i + TILE / 2.0))
		stack_visual.add_child(s)


func _update_anim() -> void:
	var moving := absf(velocity.x) > 5.0
	if carried > 0:
		_set_anim(&"carry_walk" if moving else &"carry_idle")
	else:
		_set_anim(&"walk" if moving else &"idle")


func _set_anim(anim: StringName) -> void:
	sprite.scale.x = facing
	sprite.offset = -ANCHORS[anim]
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _play_particles(delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_instance_valid(particles):
		return
	particles.scale.x = facing
	particles.show()
	particles.play(&"burst")


func _say(text: String) -> void:
	SoundFx.play(&"deny")
	message.emit(text, global_position + Vector2(0, -BODY_HEIGHT - 20))


func _draw() -> void:
	if state != State.ACTIVE:
		return
	var frac := clampf(life / LIFETIME, 0.0, 1.0)
	var top := -(CARRY_HEIGHT + carried * TILE if carried > 0 else BODY_HEIGHT) - 12.0
	var w := 32.0
	draw_rect(Rect2(-w / 2, top, w, 4), Color(0, 0, 0, 0.65))
	var col := Color(0.45, 1.0, 0.55) if frac > 0.25 else Color(1.0, 0.42, 0.3)
	if frac < 0.17 and (Time.get_ticks_msec() / 150) % 2 == 0:
		col = Color.WHITE
	draw_rect(Rect2(-w / 2 + 1, top + 1, (w - 2) * frac, 2), col)
