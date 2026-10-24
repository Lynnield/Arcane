extends Control
## Main menu: Offline Adventure, Online Duel, Settings.


func _ready() -> void:
	var box := UiKit.screen(self)
	box.add_child(UiKit.label("ARCANE", 44, UiKit.GOLD))
	box.add_child(UiKit.spacer(12))
	box.add_child(UiKit.button("Offline Adventure", func() -> void: Game.goto(Game.LEVEL_SELECT)))
	box.add_child(UiKit.button("Online Duel", func() -> void: Game.goto(Game.LOBBY)))
	box.add_child(UiKit.button("Settings", func() -> void: Game.goto(Game.SETTINGS)))
	box.add_child(UiKit.button("Quit", func() -> void: get_tree().quit()))
