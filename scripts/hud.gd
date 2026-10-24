class_name Hud
extends CanvasLayer
## In-game HUD: health, timer, objective, centre messages and the pause menu.
## mode "campaign" pauses the tree; mode "pvp" shows a menu without pausing.

signal restart_requested
signal menu_requested

var mode := "campaign"
var allow_pause := true

var _root: Control
var _health: Bar
var _rival_health: Bar
var _time_label: Label
var _objective: Label
var _message: Label
var _sub_message: Label
var _message_tween: Tween
var _overlay: ColorRect
var _overlay_box: VBoxContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiKit.theme()
	add_child(_root)

	_health = Bar.new()
	_health.caption = "YOU" if mode == "pvp" else "HP"
	_health.fill = Color("5fe08a")
	_health.position = Vector2(10, 10)
	_root.add_child(_health)

	_time_label = UiKit.label("", 13)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_time_label.position = Vector2(10, 24)
	_root.add_child(_time_label)

	_objective = UiKit.label("", 14)
	_objective.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_objective.offset_top = 6
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_objective)

	if mode == "pvp":
		_rival_health = Bar.new()
		_rival_health.caption = "RIVAL"
		_rival_health.fill = Color("ff6b6b")
		_rival_health.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_rival_health.offset_left = -Bar.WIDTH - 100
		_rival_health.offset_right = -52
		_rival_health.offset_top = 14
		_root.add_child(_rival_health)

	var pause := Button.new()
	pause.text = "II"
	pause.focus_mode = Control.FOCUS_NONE
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -46
	pause.offset_right = -8
	pause.offset_top = 6
	pause.offset_bottom = 40
	pause.pressed.connect(toggle_pause)
	_root.add_child(pause)

	_message = UiKit.label("", 28, UiKit.GOLD)
	_message.set_anchors_preset(Control.PRESET_FULL_RECT)
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.offset_bottom = -60
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_message)

	_sub_message = UiKit.label("", 16, UiKit.TEXT)
	_sub_message.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sub_message.offset_top = 10
	_sub_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_sub_message)

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_root.add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	_overlay_box = VBoxContainer.new()
	_overlay_box.add_theme_constant_override("separation", 8)
	panel.add_child(_overlay_box)


func set_health(current: int, maximum: int) -> void:
	_health.set_value(current, maximum)


func set_rival_health(current: int, maximum: int) -> void:
	if _rival_health:
		_rival_health.set_value(current, maximum)


func set_time(seconds: float) -> void:
	_time_label.text = Game.format_time(seconds)


func set_info(text: String) -> void:
	_time_label.text = text


func set_objective(text: String) -> void:
	_objective.text = text


## `sub` is an optional smaller line under the message (e.g. the level goal).
func show_message(text: String, duration: float = 1.6, sub: String = "") -> void:
	_message.text = text
	_sub_message.text = sub
	_message.modulate.a = 1.0
	_sub_message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.4)
	_message_tween.parallel().tween_property(_sub_message, "modulate:a", 0.0, 0.4)


func is_menu_open() -> bool:
	return _overlay.visible


func toggle_pause() -> void:
	if _overlay.visible:
		resume()
		return
	if not allow_pause:
		return
	if mode == "campaign":
		get_tree().paused = true
	_show_pause_menu()


func _show_pause_menu() -> void:
	var items := [["Resume", resume]]
	if mode == "pvp":
		items.append(["Leave Match", func() -> void: menu_requested.emit()])
	else:
		items.append(["Restart", func() -> void: restart_requested.emit()])
	items.append(["Sound: " + ("On" if Save.sound_on else "Off"), func() -> void:
		Save.sound_on = not Save.sound_on
		Save.save_data()
		_show_pause_menu()])
	items.append(["Music: " + ("On" if Save.music_on else "Off"), func() -> void:
		Save.music_on = not Save.music_on
		Save.save_data()
		Sfx.update_music()
		_show_pause_menu()])
	if mode != "pvp":
		items.append(["Quit to Menu", func() -> void: menu_requested.emit()])
	show_menu("Paused" if mode != "pvp" else "Duel", items)


func resume() -> void:
	_overlay.visible = false
	if mode == "campaign":
		get_tree().paused = false


## items: [[button text, Callable], ...]
func show_menu(title: String, items: Array, body: String = "") -> void:
	for child in _overlay_box.get_children():
		child.queue_free()
	_overlay_box.add_child(UiKit.label(title, 24, UiKit.GOLD))
	if body != "":
		_overlay_box.add_child(UiKit.label(body, 0, UiKit.TEXT, 260.0))
	for item in items:
		_overlay_box.add_child(UiKit.button(item[0], item[1]))
	_overlay.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if mode == "campaign" and allow_pause and not _overlay.visible:
			toggle_pause()


class Bar extends Control:
	const WIDTH := 110.0
	var caption := ""
	var fill := Color.GREEN
	var _value := 1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(WIDTH + 40, 12)
		size = custom_minimum_size

	func set_value(current: int, maximum: int) -> void:
		_value = clampf(float(current) / maxf(maximum, 1), 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(0, 10), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color("120c22"))
		draw_string(font, Vector2(0, 10), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiKit.TEXT)
		var bar := Rect2(38, 1, WIDTH, 10)
		draw_rect(bar.grow(1), Color("120c22"))
		draw_rect(bar, Color("3a2f50"))
		draw_rect(Rect2(bar.position, Vector2(WIDTH * _value, bar.size.y)), fill)
		draw_rect(Rect2(bar.position, Vector2(WIDTH * _value, 2)), fill.lightened(0.35))
