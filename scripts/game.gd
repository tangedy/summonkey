extends Node2D
## Runs a level: routes input between the monkey and the golem, handles
## summoning/dismissing, the camera, messages, music and the win screen.

const GolemScene := preload("res://scenes/golem.tscn")
const TITLE_SCENE := "res://scenes/title.tscn"
const GHOST_TEXTURE := preload("res://assets/sprites/golem_idle/golem_idle_01.png")
const CAMERA_LIFT := Vector2(0, -30)

var golem: Golem = null
var finished := false
var elapsed := 0.0
var summons := 0

var _shake := 0.0
var _ghost: Sprite2D

@onready var level: Level = $Level
@onready var monkey: Monkey = $Monkey
@onready var camera: Camera2D = $Camera
@onready var status_label: Label = $HUD/Status
@onready var win_panel: Control = $HUD/WinPanel
@onready var win_stats: Label = $HUD/WinPanel/Stats
@onready var fade: ColorRect = $HUD/Fade


func _ready() -> void:
	add_to_group(&"shakers")
	Music.play(&"menu", -3.0)
	SoundFx.set_loop(&"monkey_step", false)
	SoundFx.set_loop(&"golem_step", false)
	level.build()
	level.goal_reached.connect(_on_goal_reached)
	monkey.global_position = level.monkey_start
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(level.pixel_size.x)
	camera.limit_bottom = int(level.pixel_size.y)
	camera.global_position = monkey.global_position + CAMERA_LIFT
	camera.reset_smoothing.call_deferred()
	_make_ghost()
	win_panel.hide()
	fade.show()
	create_tween().tween_property(fade, "modulate:a", 0.0, 0.6).from(1.0)
	_update_status()


func _process(delta: float) -> void:
	if not finished:
		elapsed += delta
	var focus := _controlled_body()
	var lift := CAMERA_LIFT
	if focus == golem and golem.carried > 0:
		lift.y -= 25.0 + golem.carried * 30.0  # keep the stack (and any rider) in view
	camera.global_position = focus.global_position + lift
	_shake = move_toward(_shake, 0.0, 14.0 * delta)
	camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)).round()
	_update_ghost()
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(TITLE_SCENE)
		return
	if finished:
		return
	if event.is_action_pressed("summon"):
		_on_summon_pressed()
	elif event.is_action_pressed("lift"):
		if _golem_ready() and golem.controlled:
			golem.toggle_carry()
	elif event.is_action_pressed("dismiss"):
		_dismiss_golem()


## Called through the "shakers" group (e.g. by boxes landing).
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _controlled_body() -> Node2D:
	if is_instance_valid(golem) and golem.controlled:
		return golem
	return monkey


func _golem_ready() -> bool:
	return is_instance_valid(golem) and golem.state == Golem.State.ACTIVE


# --- summoning --------------------------------------------------------------

func _on_summon_pressed() -> void:
	if monkey.busy:
		return
	if golem == null:
		if monkey.controlled and monkey.is_on_floor():
			_summon()
	elif _golem_ready():
		SoundFx.play(&"swap")
		_set_golem_control(not golem.controlled)


func _summon() -> void:
	var spot := _find_summon_spot()
	monkey.play_summon()
	if spot.x >= 0:
		summons += 1
		golem = GolemScene.instantiate()
		golem.level = level
		golem.monkey = monkey
		golem.facing = monkey.facing
		golem.position = Level.feet_position(spot)
		golem.message.connect(show_message)
		golem.dismissed.connect(_on_golem_dismissed)
		add_child(golem)
		move_child(golem, monkey.get_index())  # draw behind the monkey
		golem.start_summon()
	await monkey.summon_animation_done
	if not is_instance_valid(golem):
		SoundFx.play(&"summon_fail")
		show_message("No room to summon", monkey.global_position + Vector2(0, -50))
		return
	if golem.state == Golem.State.SUMMONING:
		await golem.summon_finished
	if _golem_ready() and not finished:
		_set_golem_control(true)


## Like the jam version: the golem appears in the column in front of the
## monkey, standing on a ledge at the same height, one step up, or one down.
func _find_summon_spot() -> Vector2i:
	var feet := Level.cell_of(monkey.global_position + Vector2(0, -1))
	var front_x := monkey.global_position.x + monkey.facing * (Monkey.HALF_WIDTH + 1.0)
	var col := ceili(front_x / Level.TILE) if monkey.facing > 0 else floori(front_x / Level.TILE) - 1
	for ground_row in [feet.y + 1, feet.y, feet.y + 2]:
		var ground := Vector2i(col, ground_row)
		if level.is_solid(ground) and level.is_free(ground + Vector2i.UP) \
				and level.is_free(ground + Vector2i.UP * 2):
			return ground + Vector2i.UP
	return Vector2i(-1, -1)


func _dismiss_golem() -> void:
	if not _golem_ready():
		return
	if not monkey.busy and monkey.is_on_floor():
		monkey.play_summon()
	golem.dismiss()


func _on_golem_dismissed() -> void:
	golem = null
	monkey.controlled = not finished


func _set_golem_control(on: bool) -> void:
	golem.controlled = on
	monkey.controlled = not on


# --- summon preview ---------------------------------------------------------

## A faint golem silhouette showing where K would summon, so players can
## line up summons without trial and error.
func _make_ghost() -> void:
	_ghost = Sprite2D.new()
	_ghost.texture = GHOST_TEXTURE
	_ghost.centered = false
	_ghost.offset = Vector2(-31, -83)
	_ghost.modulate = Color(0.6, 1.0, 0.75, 0.22)
	_ghost.z_index = -1
	_ghost.hide()
	add_child(_ghost)


func _update_ghost() -> void:
	var show_it := not finished and golem == null and monkey.controlled \
			and not monkey.busy and monkey.is_on_floor()
	if show_it:
		var spot := _find_summon_spot()
		show_it = spot.x >= 0
		if show_it:
			_ghost.position = Level.feet_position(spot)
			_ghost.scale.x = monkey.facing
	_ghost.visible = show_it


# --- feedback ---------------------------------------------------------------

func show_message(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, 16)
	label.position = at - Vector2(80, 8)
	label.z_index = 50
	add_child(label)
	var t := create_tween()
	t.tween_property(label, "position:y", label.position.y - 18, 0.9)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	t.tween_callback(label.queue_free)


func _update_status() -> void:
	var who := "Golem" if _controlled_body() != monkey else "Monkey"
	var text := "Controlling: %s" % who
	if is_instance_valid(golem) and golem.state != Golem.State.SUMMONING:
		text += "    Golem: %ds" % ceili(maxf(golem.life, 0.0))
	status_label.text = text


func _on_goal_reached() -> void:
	finished = true
	monkey.controlled = false
	if is_instance_valid(golem):
		golem.controlled = false
	Music.play(&"win", 0.0, 0.6)
	SoundFx.play(&"banana")
	var plural := "" if summons == 1 else "s"
	win_stats.text = "Time  %d:%04.1f\n%d golem%s summoned" % [int(elapsed) / 60, fmod(elapsed, 60.0), summons, plural]
	win_panel.modulate.a = 0.0
	win_panel.show()
	create_tween().tween_property(win_panel, "modulate:a", 1.0, 0.5)
