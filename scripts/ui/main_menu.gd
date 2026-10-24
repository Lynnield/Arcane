extends Control
## Main menu: Offline Adventure, Online Duel, Settings.


func _ready() -> void:
	var box := UiKit.screen(self)
	box.add_child(UiKit.label("ARCANE", 44, UiKit.GOLD))
	box.add_child(UiKit.spacer(12))
	box.add_child(UiKit.button("Play Offline", func() -> void: Game.goto(Game.OFFLINE_MENU)))
	box.add_child(UiKit.button("Play Online", func() -> void: Game.goto(Game.LOBBY)))
	box.add_child(UiKit.button("Settings", func() -> void: Game.goto(Game.SETTINGS)))
	box.add_child(UiKit.button("Credits", func() -> void: Game.goto(Game.CREDITS)))
	box.add_child(UiKit.button("Quit", func() -> void: get_tree().quit()))
