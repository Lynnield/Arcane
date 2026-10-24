extends Control
## Sound volume, larger interface text and progress reset.

var _volume_label: Label
var _confirm_reset := false
var _reset_button: Button


func _ready() -> void:
	var box := UiKit.screen(self)
	box.add_child(UiKit.label("Settings", 28, UiKit.GOLD))

	_volume_label = UiKit.label("", 0)
	box.add_child(_volume_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Save.master_volume
	slider.custom_minimum_size = Vector2(240, 28)
	slider.value_changed.connect(_on_volume_changed)
	box.add_child(slider)
	_update_volume_label()

	var big := CheckButton.new()
	big.text = "Large text"
	big.button_pressed = Save.large_text
	big.focus_mode = Control.FOCUS_NONE
	big.toggled.connect(_on_large_text)
	box.add_child(big)

	_reset_button = UiKit.button("Reset Progress", _on_reset)
	box.add_child(_reset_button)
	box.add_child(UiKit.button("Back", func() -> void: Game.goto(Game.MAIN_MENU)))


func _on_volume_changed(value: float) -> void:
	Save.master_volume = value
	Save.apply_volume()
	Save.save_data()
	_update_volume_label()
	Sfx.play("click")


func _update_volume_label() -> void:
	_volume_label.text = "Volume  %d%%" % roundi(Save.master_volume * 100.0)


func _on_large_text(on: bool) -> void:
	Save.large_text = on
	Save.save_data()
	Game.goto(Game.SETTINGS)


func _on_reset() -> void:
	if not _confirm_reset:
		_confirm_reset = true
		_reset_button.text = "Tap again to confirm"
		return
	Save.reset_progress()
	_confirm_reset = false
	_reset_button.text = "Progress reset"
