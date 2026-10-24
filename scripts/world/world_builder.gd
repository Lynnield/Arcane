class_name WorldBuilder
extends RefCounted
## Builds background, drawn tiles and collision from a list of solid rects.
## Shared by the campaign levels and the PvP arena.

const TILE := LevelData.TILE


static func build(root: Node2D, solids: Array, width: int, palette: Dictionary, add_bounds: bool) -> void:
	var height := LevelData.HEIGHT
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	var sky := SkyBackground.new()
	sky.palette = palette
	bg_layer.add_child(sky)
	root.add_child(bg_layer)

	var span := width * TILE + 800
	root.add_child(_hills_layer(0.2, palette["hills_far"], span, height * TILE, 150.0, 3))
	root.add_child(_hills_layer(0.5, palette["hills_near"], span, height * TILE, 95.0, 11))

	var tiles := TileDrawer.new()
	tiles.palette = palette
	var body := StaticBody2D.new()
	body.collision_layer = OrbPhysics.MASK_WORLD
	body.collision_mask = 0
	for s in solids:
		var x: int = s[0]
		var y: int = s[1]
		var w: int = s[2]
		var h: int = s[3]
		if h <= 0:
			h = height - y
		tiles.add_rect(Rect2i(x, y, w, h))
		_add_box(body, Rect2(x * TILE, y * TILE, w * TILE, h * TILE))
	if add_bounds:
		# Invisible side walls keep the wizard inside the level.
		_add_box(body, Rect2(-16, -400, 16, height * TILE + 400))
		_add_box(body, Rect2(width * TILE, -400, 16, height * TILE + 400))
	root.add_child(tiles)
	root.add_child(body)


static func _add_box(body: StaticBody2D, rect: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.get_center()
	body.add_child(cs)


static func _hills_layer(scale: float, color: Color, span: int, base_y: int, amplitude: float, seed_value: int) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(scale, 1.0)
	var hills := Hills.new()
	hills.color = color
	hills.span = span
	hills.base_y = base_y
	hills.amplitude = amplitude
	hills.seed_value = seed_value
	layer.add_child(hills)
	return layer
