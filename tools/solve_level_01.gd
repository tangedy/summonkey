extends SceneTree
## Plays level 1 start-to-banana using only inputs (no teleporting), proving
## it's beatable. Saves a screenshot per stage. Run windowed:
##   godot --path . -s tools/solve_level_01.gd -- <screenshot_dir>

const T := 45.0

var out_dir := "user://solve"
var game: Node
var steps: Array = []
var idx := 0
var t := 0.0
var total := 0.0
var _flag := false


static func cx(col: int) -> float:
	return (col + 0.5) * T


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	change_scene_to_file("res://scenes/game.tscn")
	_build_route()


func _build_route() -> void:
	steps = [
		wait(0.8),
		# Stage 1: clear the box blocking the tunnel.
		walk(&"m", cx(18)), face(&"m", 1), tap_wait("summon", 0.0), until_golem_active(),
		walk(&"g", cx(26) - 46.0), tap_wait("lift", 0.0), until_carrying(1), shot("s1_lifted"),
		walk(&"g", cx(22)), tap_wait("lift", 0.3), until_carrying(0), shot("s1_dropped"),
		tap_wait("dismiss", 0.0), until_no_golem(),
		# Stage 2: hop the dropped box, crawl the tunnel, ride the pit box up.
		walk(&"m", cx(20)), jump_to(&"m", cx(22)), walk(&"m", cx(32)), jump_to(&"m", cx(33)), face(&"m", -1), wait(0.2),
		tap_wait("summon", 0.0), until_golem_active(),
		face(&"g", 1), tap_wait("lift", 0.0), until_carrying(1), shot("s2_elevator"),
		tap_wait("summon", 0.2), jump_to(&"m", cx(31)), wait(0.2), shot("s2_ledge"),
		tap_wait("dismiss", 0.0), until_no_golem(),
		# Stage 3: elevator up the one-wide shaft.
		walk(&"m", cx(29)), jump_to(&"m", cx(28)), face(&"m", 1), wait(0.2),
		tap_wait("summon", 0.0), until_golem_active(),
		face(&"g", -1), tap_wait("lift", 0.0), until_carrying(1), shot("s3_shaft"),
		tap_wait("summon", 0.2),
		jump_to(&"m", cx(29)), jump_to(&"m", cx(30)), jump_to(&"m", cx(31)), shot("s3_top"),
		tap_wait("dismiss", 0.0), until_no_golem(),
		# Stage 4: two elevators up to the banana platform.
		jump_to(&"m", cx(32)), face(&"m", -1), wait(0.2),
		tap_wait("summon", 0.0), until_golem_active(),
		face(&"g", 1), tap_wait("lift", 0.0), until_carrying(1), shot("s4_elevator1"),
		tap_wait("summon", 0.2), walk(&"m", cx(33)),
		tap_wait("summon", 0.2), face(&"g", -1), tap_wait("lift", 0.3), until_carrying(0),
		walk(&"g", cx(34) - 44.0),
		tap_wait("summon", 0.2), walk(&"m", cx(34)), wait(0.3),
		tap_wait("summon", 0.2), face(&"g", 1), tap_wait("lift", 0.0), until_carrying(3), shot("s4_elevator2"),
		tap_wait("summon", 0.2), jump_to(&"m", cx(33)),
		tap_wait("dismiss", 0.0), until_no_golem(),
		# Stage 5: golem lifts the 3-box stack; monkey walks through him and
		# hops under the crates to the shaft into the middle room.
		walk(&"m", cx(29)), face(&"m", -1), wait(0.2),
		tap_wait("summon", 0.0), until_golem_active(),
		walk(&"g", cx(27)), tap_wait("lift", 0.0), until_carrying(3), shot("s5_stack_lifted"),
		tap_wait("summon", 0.2), walk(&"m", cx(26)), jump_to(&"m", cx(25)),
		walk(&"m", cx(24)), shot("s5_middle_room"),
		tap_wait("dismiss", 0.0), until_no_golem(),
		# Stage 6: middle room. Crate elevator, over the top, staircase, exit left.
		walk(&"m", cx(22)), jump_to(&"m", cx(21)), face(&"m", -1), wait(0.2),
		tap_wait("summon", 0.0), until_golem_active(),
		walk(&"g", cx(19)), face(&"g", 1),
		tap_wait("summon", 0.2), jump_to(&"m", cx(20)),
		tap_wait("summon", 0.2), tap_wait("lift", 0.0), until_carrying(2), shot("s6_elevator"),
		tap_wait("summon", 0.2), jump_to(&"m", cx(21)), walk(&"m", 937.0), jump_to(&"m", cx(19)),
		tap_wait("summon", 0.2), walk(&"g", cx(18)),
		tap_wait("summon", 0.2), walk(&"m", cx(18)),
		tap_wait("summon", 0.2), walk(&"g", cx(17)),
		tap_wait("summon", 0.2), jump_to(&"m", cx(16)), shot("s6_staircase"),
		tap_wait("summon", 0.2), walk(&"g", cx(14)), tap_wait("lift", 0.3), until_carrying(0),
		tap_wait("dismiss", 0.0), until_no_golem(),
		jump_to(&"m", cx(15)), jump_to(&"m", cx(14)), walk(&"m", cx(13)),
		drop_then(&"m", 1, cx(13)), walk(&"m", cx(12)), shot("s6_exit"),
		walk(&"m", cx(11)), shot("s7_left_room"),
		# Stage 7: left room. Lift the 2-crate stack, walk through the golem,
		# put the stack back, ride it up, get carried across, crate elevator
		# up the shaft to the banana.
		walk(&"m", cx(8)), face(&"m", -1), wait(0.2),
		tap_wait("summon", 0.0), until_golem_active(),
		tap_wait("lift", 0.0), until_carrying(2),
		tap_wait("summon", 0.2), walk(&"m", cx(5)), jump_to(&"m", cx(4)),
		tap_wait("summon", 0.2), walk(&"g", cx(7) + 8.0), face(&"g", -1), tap_wait("lift", 0.3), until_carrying(0),
		tap_wait("summon", 0.2), walk(&"m", 233.0), jump_to(&"m", cx(6)), shot("s7_on_stack"),
		tap_wait("summon", 0.2), tap_wait("lift", 0.0), until_carrying(2),
		walk(&"g", cx(8)), shot("s7_carried"),
		tap_wait("summon", 0.2), jump_to(&"m", cx(9)), jump_to(&"m", cx(10)),
		tap_wait("dismiss", 0.0), until_no_golem(),
		face(&"m", -1), wait(0.2), tap_wait("summon", 0.0), until_golem_active(),
		face(&"g", 1), tap_wait("lift", 0.0), until_carrying(1), shot("s7_shaft"),
		tap_wait("summon", 0.2), jump_to(&"m", cx(9)),
		until_won(), wait(1.0), shot("s8_win"),
	]


func _process(delta: float) -> bool:
	game = current_scene
	if game == null or not game.is_node_ready():
		return false
	t += delta
	total += delta
	if total > 240.0:
		return fail("timed out")
	if idx >= steps.size():
		print("[solve] PASS in %.1fs game time, %d summons" % [game.elapsed, game.summons])
		quit(0)
		return true
	var done: bool = steps[idx].call(delta)
	if done:
		idx += 1
		t = 0.0
		_flag = false
	return false


# --- step builders ------------------------------------------------------------

func body(who: StringName) -> CharacterBody2D:
	return game.monkey if who == &"m" else game.golem


func wait(seconds: float) -> Callable:
	return func(_d: float) -> bool: return t >= seconds


func walk(who: StringName, x: float) -> Callable:
	return func(_d: float) -> bool:
		var b := body(who)
		if game.finished:
			_release_moves()
			return true
		if b == null:
			return fail("no %s to walk" % who)
		var dx := x - b.global_position.x
		_release_moves()
		if absf(dx) > 6.0 and t < 8.0:
			Input.action_press("move_right" if dx > 0 else "move_left")
			return false
		if absf(b.velocity.x) < 2.0 and b.is_on_floor():
			if absf(dx) > 14.0:
				return fail("%s stuck at x=%.1f (wanted %.1f)" % [who, b.global_position.x, x])
			return true
		return false


func jump_to(who: StringName, x: float) -> Callable:
	return func(_d: float) -> bool:
		var b := body(who)
		if game.finished:
			_release_moves()
			return true
		var dx := x - b.global_position.x
		if OS.has_environment("SOLVE_TRACE") and t < 0.6:
			print("[trace] t=%.3f pos=%s vel=%s floor=%s ceil=%s wall=%s jump=%s" % [t, b.global_position, b.velocity, b.is_on_floor(), b.is_on_ceiling(), b.is_on_wall(), Input.is_action_pressed("jump")])
		_release_moves()
		if absf(dx) > 5.0:
			Input.action_press("move_right" if dx > 0 else "move_left")
		if not _flag and t < 0.02:
			_send("jump", true)
			return false
		if not b.is_on_floor():
			_flag = true  # left the ground
		if t > 0.35 and Input.is_action_pressed("jump"):
			_send("jump", false)
		if _flag and b.is_on_floor() and absf(dx) <= 8.0 and absf(b.velocity.x) < 2.0:
			_release_moves()
			if Input.is_action_pressed("jump"):
				_send("jump", false)
			return true
		if t > 3.0:
			return fail("%s jump to %.1f failed, at %s" % [who, x, b.global_position])
		return false


## Walk `first_dir` until airborne, then steer toward x and land there.
func drop_then(who: StringName, first_dir: int, x: float) -> Callable:
	return func(_d: float) -> bool:
		var b := body(who)
		_release_moves()
		if not _flag:
			if b.is_on_floor():
				Input.action_press("move_right" if first_dir > 0 else "move_left")
				return t > 3.0 and fail("%s never left the floor" % who)
			_flag = true
		var dx := x - b.global_position.x
		if absf(dx) > 4.0:
			Input.action_press("move_right" if dx > 0 else "move_left")
		if b.is_on_floor() and t > 0.1:
			_release_moves()
			if absf(dx) > 34.0:
				return fail("%s landed at %s, wanted x=%.1f" % [who, b.global_position, x])
			return true
		return t > 4.0 and fail("drop_then timed out")


func face(who: StringName, dir: int) -> Callable:
	return func(_d: float) -> bool:
		var b := body(who)
		if b.facing == dir:
			_release_moves()
			return t > 0.1
		Input.action_press("move_right" if dir > 0 else "move_left")
		return false


func tap_wait(action: String, after: float) -> Callable:
	return func(_d: float) -> bool:
		if not _flag:
			_flag = true
			var ev := InputEventAction.new()
			ev.action = action
			ev.pressed = true
			Input.parse_input_event(ev)
			var up := InputEventAction.new()
			up.action = action
			Input.parse_input_event.call_deferred(up)
		return t >= after + 0.05


func until_golem_active() -> Callable:
	return func(_d: float) -> bool:
		var g: Golem = game.golem
		if g and g.state == Golem.State.ACTIVE and g.controlled:
			return true
		if t > 3.0:
			return fail("golem never became active (monkey at %s facing %d)" % [game.monkey.global_position, game.monkey.facing])
		return false


func until_carrying(n: int) -> Callable:
	return func(_d: float) -> bool:
		var g: Golem = game.golem
		if g and g.carried == n and g.state == Golem.State.ACTIVE:
			return t > 0.15
		if t > 3.0:
			return fail("expected golem carrying %d (golem %s)" % [n, "missing" if g == null else "at %s carrying %d" % [g.global_position, g.carried]])
		return false


func until_no_golem() -> Callable:
	return func(_d: float) -> bool:
		if game.golem == null and game.monkey.controlled and not game.monkey.busy:
			return true
		if t > 3.0:
			return fail("golem never went away")
		return false


func until_won() -> Callable:
	return func(_d: float) -> bool:
		if game.finished:
			_release_moves()
			return true
		if t > 3.0:
			return fail("didn't reach the banana, monkey at %s" % game.monkey.global_position)
		return false


func shot(name: String) -> Callable:
	return func(_d: float) -> bool:
		root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
		var m: Monkey = game.monkey
		print("[solve] %s  monkey %s cell %s" % [name, m.global_position, Level.cell_of(m.global_position + Vector2(0, -1))])
		return true


func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _release_moves() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")


func fail(msg: String) -> bool:
	print("[solve] FAIL at step %d: %s" % [idx, msg])
	var m: Monkey = game.monkey
	print("[solve]   monkey ctrl=%s busy=%s frozen=%s floor=%s vel=%s axis=%.1f floor_body=%s" % [m.controlled, m.busy, m.frozen, m.is_on_floor(), m.velocity, Input.get_axis("move_left", "move_right"), m.floor_body])
	for b in game.level.get_boxes():
		if b.global_position.distance_to(m.global_position) < 120:
			print("[solve]   box near at %s resting=%s" % [b.global_position, b.resting])
	root.get_texture().get_image().save_png(out_dir.path_join("fail_step_%d.png" % idx))
	quit(1)
	return true
