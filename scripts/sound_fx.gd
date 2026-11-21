class_name SoundFx
## Static entry point for sound effects: SoundFx.play(&"jump").
## Looks up the "Sfx" autoload at runtime so scripts that compile before
## autoloads exist (tools, tests) still work.


static func play(slot: StringName, volume_offset_db := 0.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var sfx := tree.root.get_node_or_null(^"Sfx")
	if sfx:
		sfx.play(slot, volume_offset_db)


static func set_loop(slot: StringName, on: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var sfx := tree.root.get_node_or_null(^"Sfx")
	if sfx:
		sfx.set_loop(slot, on)
