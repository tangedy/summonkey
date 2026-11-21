extends Node
## Autoload "Sfx": fire-and-forget sound effects by name.
##
## Drop a file named after a slot into res://assets/sfx/ (.wav, .ogg or .mp3),
## e.g. assets/sfx/jump.wav, and it plays automatically. Missing files are
## silently skipped, so every hook in the game is safe to call today.

const DIR := "res://assets/sfx/"
const EXTENSIONS := ["wav", "ogg", "mp3"]

## slot name -> [volume_db, random pitch spread]
const SLOTS := {
	# monkey
	&"jump": [-4.0, 0.06],
	&"land": [-8.0, 0.08],
	&"monkey_step": [-14.0, 0.12],
	&"summon": [-2.0, 0.0],
	&"summon_fail": [-4.0, 0.0],
	&"swap": [-6.0, 0.05],
	# golem
	&"golem_appear": [-3.0, 0.0],
	&"golem_step": [-10.0, 0.1],
	&"lift": [-4.0, 0.04],
	&"drop": [-4.0, 0.04],
	&"golem_warning": [-6.0, 0.0],
	&"dismiss": [-3.0, 0.0],
	&"deny": [-6.0, 0.05],
	# world
	&"box_land": [-6.0, 0.1],
	&"banana": [0.0, 0.0],
	# menus
	&"menu_select": [-4.0, 0.0],
}
const VOICES := 10

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _loops := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: StringName in SLOTS:
		for ext: String in EXTENSIONS:
			var path := "%s%s.%s" % [DIR, slot, ext]
			if ResourceLoader.exists(path):
				_streams[slot] = load(path)
				break
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


## Play `slot` if a file exists for it. Unknown slot names are a bug, so they warn.
func play(slot: StringName, volume_offset_db := 0.0) -> void:
	if not SLOTS.has(slot):
		push_warning("Sfx: unknown slot '%s'" % slot)
		return
	if not _streams.has(slot):
		return
	var cfg: Array = SLOTS[slot]
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[slot]
	p.volume_db = cfg[0] + volume_offset_db
	p.pitch_scale = 1.0 + randf_range(-cfg[1], cfg[1])
	p.play()


## Start/stop a looping sound (footsteps). Safe to call every frame.
func set_loop(slot: StringName, on: bool) -> void:
	if not _streams.has(slot):
		return
	var p: AudioStreamPlayer = _loops.get(slot)
	if on:
		if p == null:
			p = AudioStreamPlayer.new()
			var stream: AudioStream = _streams[slot].duplicate()
			if "loop" in stream:
				stream.loop = true
			p.stream = stream
			p.volume_db = SLOTS[slot][0]
			add_child(p)
			_loops[slot] = p
		if not p.playing:
			p.play()
	elif p and p.playing:
		p.stop()


## Which slots currently have a sound file (handy for checking your drops).
func loaded_slots() -> Array:
	return _streams.keys()
