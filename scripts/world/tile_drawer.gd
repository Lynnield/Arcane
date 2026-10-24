class_name TileDrawer
extends Node2D
## Draws solid blocks as pixel-art tiles: grass/moss on exposed tops,
## dark edges and a few deterministic speckles per tile.

const TILE := LevelData.TILE

var palette: Dictionary = {}
var _rects: Array[Rect2i] = []
var _cells: Dictionary = {}


func add_rect(rect: Rect2i) -> void:
	_rects.append(rect)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_cells[Vector2i(x, y)] = true
	queue_redraw()


func _draw() -> void:
	var ground: Color = palette["ground"]
	var dark: Color = palette["ground_dark"]
	var top: Color = palette["top"]
	for rect in _rects:
		draw_rect(Rect2(rect.position.x * TILE, rect.position.y * TILE, rect.size.x * TILE, rect.size.y * TILE), ground)
	for key in _cells:
		var cell: Vector2i = key
		var p := Vector2(cell.x * TILE, cell.y * TILE)
		var h := absi(hash(cell))
		draw_rect(Rect2(p + Vector2(h % 12 + 1, (h >> 4) % 12 + 1), Vector2(2, 2)), dark)
		draw_rect(Rect2(p + Vector2((h >> 8) % 13, (h >> 12) % 13 + 1), Vector2(2, 1)), dark)
		if not _cells.has(cell + Vector2i.LEFT):
			draw_rect(Rect2(p, Vector2(1, TILE)), dark)
		if not _cells.has(cell + Vector2i.RIGHT):
			draw_rect(Rect2(p + Vector2(TILE - 1, 0), Vector2(1, TILE)), dark)
		if not _cells.has(cell + Vector2i.DOWN):
			draw_rect(Rect2(p + Vector2(0, TILE - 2), Vector2(TILE, 2)), dark)
		if not _cells.has(cell + Vector2i.UP):
			draw_rect(Rect2(p, Vector2(TILE, 4)), top)
			draw_rect(Rect2(p + Vector2(0, 4), Vector2(TILE, 1)), top.darkened(0.35))
			draw_rect(Rect2(p + Vector2(h % 14 + 1, -2), Vector2(1, 2)), top)
			draw_rect(Rect2(p + Vector2((h >> 5) % 14 + 1, -1), Vector2(1, 1)), top)
