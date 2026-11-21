extends SceneTree
## Scripted smoke test. Drives the real game with simulated input and saves
## screenshots. Run (windowed, so screenshots work):
##   godot --path . -s tools/playtest.gd -- <screenshot_dir>

var out_dir := "user://playtest"
var game: Node
var step := 0
var t := 0.0
var shots := 0
var log_lines: PackedStringArray = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	change_scene_to_file("res://scenes/game.tscn")


func _process(delta: float) -> bool:
	t += delta
	game = current_scene
	if game == null or not game.is_node_ready():
		return false
	var m: Monkey = game.monkey
	var g: Golem = game.golem if is_instance_valid(game.golem) else null
	match step:
		0:
			if t > 0.8:
				shot("01_start")
				Input.action_press("move_right")
				next()
		1:
			if m.global_position.x >= 975.0:
				Input.action_release("move_right")
				if t > 0.3 and absf(m.velocity.x) < 1.0:
					tap("summon")
					next()
		2:
			if t > 0.5 and t < 0.55:
				shot("02_summoning")
			if g and g.state == Golem.State.ACTIVE and g.controlled:
				note("golem at %s, monkey at %s" % [g.global_position, m.global_position])
				shot("03_summoned")
				Input.action_press("move_right")
				next()
			elif t > 3.0:
				fail("golem never became active")
		3:
			if g.global_position.x >= 1192.5 - 54.0 or t > 4.0:
				Input.action_release("move_right")
				if absf(g.velocity.x) < 1.0:
					note("golem stopped at %s" % g.global_position)
					shot("04_next_to_box")
					tap("lift")
					next()
		4:
			if t > 0.45 and t < 0.5:
				shot("05_lifting")
			if g.carried > 0 and g.state == Golem.State.ACTIVE:
				note("carrying %d, golem at %s" % [g.carried, g.global_position])
				shot("06_carrying")
				Input.action_press("move_right")
				next()
			elif t > 3.0:
				fail("lift never finished")
		5:
			if g.global_position.x >= 1330.0 or t > 3.0:
				Input.action_release("move_right")
				if absf(g.velocity.x) < 1.0:
					tap("lift")
					next()
		6:
			if t > 1.0:
				note("after drop: carried=%d boxes=%s" % [g.carried, box_cells()])
				shot("07_dropped")
				tap("summon")  # swap back to monkey
				next()
		7:
			if t > 0.2:
				note("controlled monkey=%s golem=%s" % [m.controlled, g.controlled])
				tap("dismiss")
				next()
		8:
			if t > 0.4 and t < 0.45:
				shot("08_dismissing")
			if game.golem == null:
				note("golem dismissed, monkey controlled=%s" % m.controlled)
				# Jump test: hold jump briefly, record peak height.
				Input.action_press("jump")
				set_meta("y0", m.global_position.y)
				set_meta("peak", m.global_position.y)
				next()
			elif t > 3.0:
				fail("dismiss never finished")
		9:
			set_meta("peak", minf(get_meta("peak"), m.global_position.y))
			if t > 0.8:
				Input.action_release("jump")
				note("jump height: %.1f px (%.2f tiles)" % [get_meta("y0") - get_meta("peak"), (get_meta("y0") - get_meta("peak")) / 45.0])
				# Elevator test: stand on the box at (26,18), summon to the left.
				m.global_position = Level.feet_position(Vector2i(26, 17))
				m.facing = -1
				next()
		10:
			if t > 0.5 and m.is_on_floor():
				tap("summon")
				next()
		11:
			if g and g.state == Golem.State.ACTIVE and g.controlled:
				Input.action_press("move_right")  # turn to face the box
				next()
		12:
			if t > 0.1:
				Input.action_release("move_right")
				set_meta("rider_y", m.global_position.y)
				tap("lift")
				next()
		13:
			if t > 0.45 and t < 0.5:
				shot("10_elevator_lifting")
			if g.carried > 0 and g.state == Golem.State.ACTIVE and t > 0.2:
				note("elevator: monkey rose %.1f px (expect 90)" % (get_meta("rider_y") - m.global_position.y))
				shot("11_elevator_done")
				Input.action_press("move_left")
				next()
			elif t > 3.0:
				fail("elevator lift never finished")
		14:
			if t > 0.6:
				Input.action_release("move_left")
				note("riding: golem x %.1f, monkey x %.1f, monkey on golem=%s" % [g.global_position.x, m.global_position.x, g.is_carrying_monkey()])
				shot("12_riding")
				# Win test: drop the monkey onto the banana.
				m.global_position = Level.feet_position(Vector2i(9, 0))
				next()
		15:
			if game.finished:
				note("level complete!")
				if t > 0.6:
					shot("09_win")
					return finish()
			elif t > 2.0:
				fail("banana not collected")
	return false


func next() -> void:
	step += 1
	t = 0.0


func tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event.call_deferred(up)


func box_cells() -> Array:
	var out := []
	for b in game.level.get_boxes():
		out.append(Level.cell_of(b.position))
	return out


func shot(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))


func note(s: String) -> void:
	print("[playtest] ", s)


func fail(s: String) -> void:
	print("[playtest] FAIL at step %d: %s" % [step, s])
	shot("fail_step_%d" % step)
	quit(1)


func finish() -> bool:
	print("[playtest] PASS")
	quit(0)
	return true
