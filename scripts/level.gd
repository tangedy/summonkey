class_name Level
extends Node2D
## Builds a level from an ASCII map and answers grid questions about it.
##
## Map legend:  # wall   . air   M monkey start   B box   N banana (goal)
## Walls are invisible collision; the look comes from the painted background.

signal goal_reached

const TILE := 45
const BoxScene := preload("res://scenes/box.tscn")
const BananaScene := preload("res://scenes/banana.tscn")

@export_file("*.txt") var map_file := "res://levels/level_01.txt"

var width := 0
var height := 0
var monkey_start := Vector2.ZERO
var pixel_size: Vector2:
	get:
		return Vector2(width, height) * TILE

var _walls := {}

@onready var _walls_body: StaticBody2D = $Walls
@onready var _boxes: Node2D = $Boxes
@onready var _goals: Node2D = $Goals


func build() -> void:
	var text := FileAccess.get_file_as_string(map_file)
	assert(text != "", "Could not read level map " + map_file)
	var rows := PackedStringArray()
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		if line != "":
			rows.append(line)
	height = rows.size()
	for y in height:
		var row := rows[y]
		width = maxi(width, row.length())
		for x in row.length():
			var cell := Vector2i(x, y)
			match row[x]:
				"#":
					_walls[cell] = true
				"B":
					spawn_box(cell)
				"M":
					monkey_start = feet_position(cell)
				"N":
					_spawn_banana(cell)
	_build_wall_collision()


# --- grid helpers -----------------------------------------------------------

static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


static func cell_center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * TILE


## Position of a character standing in cell `c` (origin at the feet).
static func feet_position(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * TILE, (c.y + 1) * TILE)


static func cell_rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * TILE, Vector2(TILE, TILE))


func is_wall(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= width or c.y >= height:
		return true
	return _walls.has(c)


func box_at(c: Vector2i) -> Box:
	for b in get_boxes():
		if cell_of(b.position) == c:
			return b
	return null


func is_solid(c: Vector2i) -> bool:
	return is_wall(c) or box_at(c) != null


func is_free(c: Vector2i) -> bool:
	return not is_solid(c)


func get_boxes() -> Array[Box]:
	var out: Array[Box] = []
	for child in _boxes.get_children():
		if child is Box and not child.is_queued_for_deletion():
			out.append(child)
	return out


func spawn_box(c: Vector2i) -> Box:
	var b: Box = BoxScene.instantiate()
	b.position = cell_center(c)
	_boxes.add_child(b)
	return b


func remove_box(b: Box) -> void:
	_boxes.remove_child(b)
	b.queue_free()


# --- building ---------------------------------------------------------------

func _spawn_banana(c: Vector2i) -> void:
	var banana: Area2D = BananaScene.instantiate()
	banana.position = cell_center(c)
	banana.collected.connect(goal_reached.emit)
	_goals.add_child(banana)


## Merges wall cells into as few rectangles as possible (greedy), so
## characters don't snag on seams between hundreds of tiny tiles.
func _build_wall_collision() -> void:
	var used := {}
	for y in height:
		for x in width:
			var start := Vector2i(x, y)
			if not _walls.has(start) or used.has(start):
				continue
			var w := 1
			while _walls.has(Vector2i(x + w, y)) and not used.has(Vector2i(x + w, y)):
				w += 1
			var h := 1
			while _row_is_free_wall(x, y + h, w, used):
				h += 1
			for yy in h:
				for xx in w:
					used[Vector2i(x + xx, y + yy)] = true
			_add_rect(Rect2(x * TILE, y * TILE, w * TILE, h * TILE))
	# Invisible borders so nothing leaves through the open top or sides.
	var s := pixel_size
	_add_rect(Rect2(-TILE * 2, -TILE * 4, TILE * 2, s.y + TILE * 8))
	_add_rect(Rect2(s.x, -TILE * 4, TILE * 2, s.y + TILE * 8))
	_add_rect(Rect2(-TILE * 2, -TILE * 4, s.x + TILE * 4, TILE * 4))


func _row_is_free_wall(x: int, y: int, w: int, used: Dictionary) -> bool:
	for i in w:
		var c := Vector2i(x + i, y)
		if not _walls.has(c) or used.has(c):
			return false
	return true


func _add_rect(r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = r.get_center()
	_walls_body.add_child(cs)
