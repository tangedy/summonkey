extends Area2D
## The level goal. Touch it with the monkey to finish the level.

signal collected

var _taken := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var bob := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	bob.tween_property(_sprite, "position:y", -4.0, 0.7)
	bob.tween_property(_sprite, "position:y", 0.0, 0.7)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Monkey:
		return
	_taken = true
	collected.emit()
	var t := create_tween().set_parallel()
	t.tween_property(_sprite, "scale", Vector2(1.8, 1.8), 0.35)
	t.tween_property(_sprite, "modulate:a", 0.0, 0.35)
