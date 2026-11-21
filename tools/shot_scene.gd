extends SceneTree
## Opens a scene, waits, saves a screenshot.
##   godot --path . -s tools/shot_scene.gd -- res://scenes/title.tscn out.png [seconds]

var _t := 0.0
var _wait := 2.0
var _out := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[1]
	if a.size() > 2:
		_wait = float(a[2])
	change_scene_to_file(a[0])


func _process(delta: float) -> bool:
	_t += delta
	var a := OS.get_cmdline_user_args()
	if a.size() > 3 and current_scene and current_scene.get("monkey"):
		var xy := a[3].split(",")
		var m: Node2D = current_scene.monkey
		if _t < 0.3:
			m.global_position = Vector2(float(xy[0]), float(xy[1]))
	if a.size() > 4 and current_scene and current_scene.has_node("PostFX"):
		var flags := a[4].split("+")
		if "nofx" in flags:
			current_scene.get_node("PostFX").visible = false
		if "noambient" in flags:
			current_scene.get_node("Level/Lighting/Ambient").visible = false
		if "nolight" in flags:
			var l := current_scene.get_node_or_null("Level/Lighting")
			if l:
				l.queue_free()
		if "noenv" in flags:
			current_scene.get_node("WorldEnvironment").environment = null
	if _t >= _wait:
		root.get_texture().get_image().save_png(_out)
		quit(0)
		return true
	return false
