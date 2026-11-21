extends Node
## Autoload "Music": plays one looping track at a time and crossfades
## between them. Survives scene changes and restarts.

const TRACKS := {
	&"menu": preload("res://assets/audio/menu_theme.mp3"),
	&"win": preload("res://assets/audio/end_screen.mp3"),
}
const SILENT_DB := -40.0

var current: StringName = &""
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for stream: AudioStreamMP3 in TRACKS.values():
		stream.loop = true
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = SILENT_DB
		add_child(p)
		_players.append(p)


## Crossfade to `track`. `volume_db` lets gameplay sit a bit under the menu.
func play(track: StringName, volume_db := 0.0, fade := 1.0) -> void:
	if track == current:
		create_tween().tween_property(_players[0], "volume_db", volume_db, fade)
		return
	current = track
	var incoming := _players[1]
	var outgoing := _players[0]
	_players.reverse()
	incoming.stream = TRACKS[track]
	incoming.volume_db = SILENT_DB
	incoming.play()
	var t := create_tween().set_parallel()
	t.tween_property(incoming, "volume_db", volume_db, fade)
	t.tween_property(outgoing, "volume_db", SILENT_DB, fade)
	t.chain().tween_callback(outgoing.stop)
