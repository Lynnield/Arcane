extends Control
## Campaign level list. Only unlocked levels can be played; all of them stay replayable.


func _ready() -> void:
	var box := UiKit.screen(self)
	box.add_child(UiKit.label("Offline Adventure", 26, UiKit.GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for i in range(1, LevelData.COUNT + 1):
		var text := "%d. %s" % [i, LevelData.level_name(i)]
		if Save.is_unlocked(i):
			var best := Save.get_best_time(i)
			text += "\nBest " + (Game.format_time(best) if best > 0.0 else "--")
		else:
			text += "\nLocked"
		var level := i
		var b := UiKit.button(text, func() -> void: Game.start_level(level), 270.0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 52 if Save.large_text else 44
		b.disabled = not Save.is_unlocked(i)
		if b.disabled:
			b.icon = UiKit.lock_icon()
			b.add_theme_color_override("icon_disabled_color", Color.WHITE)
		if Save.is_unlocked(i):
			var stars := StarRow.new(Save.get_best_stars(i), 6.0)
			stars.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			stars.offset_left = -50
			stars.offset_right = -6
			stars.offset_top = -7
			stars.offset_bottom = 7
			b.add_child(stars)
		grid.add_child(b)
	box.add_child(UiKit.spacer(4))
	box.add_child(UiKit.button("Back", func() -> void: Game.goto(Game.MAIN_MENU), 160.0))
