extends Control
## Offline mode select: the five-level adventure or a duel against the computer.


func _ready() -> void:
	var box := UiKit.screen(self)
	box.add_child(UiKit.label("Play Offline", 28, UiKit.GOLD))
	box.add_child(UiKit.label("No internet needed", 13, UiKit.MUTED))
	box.add_child(UiKit.spacer(4))
	box.add_child(UiKit.button("Adventure (5 levels)", func() -> void: Game.goto(Game.LEVEL_SELECT), 300.0))
	box.add_child(UiKit.spacer(6))
	box.add_child(UiKit.label("Duel vs Computer", 16))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for level in [1, 2, 3]:
		var difficulty: int = level
		row.add_child(UiKit.button(CpuBrain.level_name(level), func() -> void: Game.start_cpu_duel(difficulty), 94.0))
	box.add_child(row)
	box.add_child(UiKit.spacer(6))
	box.add_child(UiKit.button("Back", func() -> void: Game.goto(Game.MAIN_MENU), 160.0))
