extends Control
## In-game credits. Keep in sync with docs/CREDITS.md.

const LINES := [
	["Team", "Lynnield - developer"],
	["Engine", "Godot Engine 4.7 - MIT License\nJuan Linietsky, Ariel Manzur and contributors"],
	["Font", "Open Sans by Steve Matteson - SIL Open Font License 1.1"],
	["Art", "Original - drawn in code"],
	["Sound and music", "Original - synthesized in code"],
]


func _ready() -> void:
	var box := UiKit.screen(self)
	box.add_child(UiKit.label("Credits", 28, UiKit.GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for entry in LINES:
		var heading := UiKit.label(entry[0], 13, UiKit.MUTED)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(heading)
		var value := UiKit.label(entry[1], 13)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(value)
	box.add_child(UiKit.spacer(6))
	box.add_child(UiKit.button("Back", func() -> void: Game.goto(Game.MAIN_MENU), 160.0))
