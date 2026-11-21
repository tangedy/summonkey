extends Control
## Title screen. Space/Enter starts, Esc quits.

const GAME_SCENE := "res://scenes/game.tscn"

var _starting := false

@onready var prompt: Label = $Prompt
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	Music.play(&"menu")
	var blink := create_tween().set_loops()
	blink.tween_property(prompt, "modulate:a", 0.25, 0.6)
	blink.tween_property(prompt, "modulate:a", 1.0, 0.6)
	fade.show()
	create_tween().tween_property(fade, "modulate:a", 0.0, 0.8).from(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("lift") or event.is_action_pressed("jump"):
		_starting = true
		SoundFx.play(&"menu_select")
		var t := create_tween()
		t.tween_property(fade, "modulate:a", 1.0, 0.5)
		t.tween_callback(get_tree().change_scene_to_file.bind(GAME_SCENE))
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
