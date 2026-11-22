extends SceneTree
## Golem carrying 2 crates in the alcove at col 25 walks left; only the
## crates (row 15) can hit the wall at (23,15). Should stop at x ~1100.

var t := 0.0
var g: Golem


func _initialize() -> void:
	change_scene_to_file("res://scenes/game.tscn")


func _process(delta: float) -> bool:
	t += delta
	var game := current_scene
	if game == null or not game.is_node_ready():
		return false
	if g == null and t > 0.5:
		g = preload("res://scenes/golem.tscn").instantiate()
		g.level = game.level
		g.monkey = game.monkey
		g.position = Level.feet_position(Vector2i(25, 18))
		game.add_child(g)
		g.state = Golem.State.ACTIVE
		g._set_carried(2)
		g.controlled = true
		game.monkey.controlled = false
		Input.action_press("move_left")
	if g and t > 3.0:
		print("[carry] golem x=%.1f (wall face at 1080, crate half-width 20.5 -> expect >= 1100)" % g.global_position.x)
		print("[carry] stack shape disabled=%s pos=%s size=%s" % [g.stack_shape.disabled, g.stack_shape.position, g.stack_shape.shape.size])
		quit()
		return true
	return false
