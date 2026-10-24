extends Control
## Results for a campaign level or a PvP match, with the next actions.


func _ready() -> void:
	var r := Game.last_result
	var box := UiKit.screen(self)
	if r.is_empty():
		Game.goto(Game.MAIN_MENU)
		return
	var won: bool = r["won"]
	if r["mode"] == "campaign":
		var level: int = r["level"]
		box.add_child(UiKit.label("Level Complete!" if won else "Defeated", 34, UiKit.GOLD if won else Color("ff7a7a")))
		box.add_child(UiKit.label("%d. %s" % [level, LevelData.level_name(level)], 16, UiKit.MUTED))
		box.add_child(StarRow.new(r.get("stars", 0), 14.0))
		box.add_child(UiKit.label("Time  " + Game.format_time(r["time"]), 18))
		if won:
			box.add_child(UiKit.label("Best  %s   (3 stars: under %s)" % [Game.format_time(r["best"]), Game.format_time(LevelData.par_time(level))], 15, UiKit.MUTED))
			if r["new_best"]:
				box.add_child(UiKit.label("New best time!", 16, UiKit.GOLD))
		else:
			box.add_child(UiKit.label("Your wizard ran out of health. Try again!", 15, UiKit.MUTED))
		box.add_child(UiKit.spacer(8))
		if r["has_next"]:
			box.add_child(UiKit.button("Next Level", func() -> void: Game.start_level(level + 1)))
		box.add_child(UiKit.button("Retry", func() -> void: Game.start_level(level)))
		box.add_child(UiKit.button("Menu", func() -> void: Game.goto(Game.LEVEL_SELECT)))
	else:
		box.add_child(UiKit.label("Victory!" if won else "Defeat", 34, UiKit.GOLD if won else Color("ff7a7a")))
		box.add_child(UiKit.label("Rounds  %d - %d" % [r["my_rounds"], r["their_rounds"]], 18))
		box.add_child(UiKit.spacer(8))
		box.add_child(UiKit.button("Duel Again", func() -> void: Game.goto(Game.LOBBY)))
		box.add_child(UiKit.button("Menu", func() -> void: Game.goto(Game.MAIN_MENU)))
