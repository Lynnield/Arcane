extends Control
## Title screen. Any tap, click or key continues to the main menu.

var _leaving := false


func _ready() -> void:
	var box := UiKit.screen(self)
	var title := UiKit.label("ARCANE", 72, UiKit.GOLD)
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)
	box.add_child(UiKit.label("A wizard platformer", 16, UiKit.MUTED))
	box.add_child(UiKit.spacer(40))
	var prompt := UiKit.label("Tap to begin", 16)
	box.add_child(prompt)
	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.25, 0.8)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.8)


func _input(event: InputEvent) -> void:
	if _leaving:
		return
	var is_tap := event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey
	if is_tap and event.is_pressed() and not event.is_echo():
		_leaving = true
		Sfx.play("click")
		Game.goto(Game.MAIN_MENU)
