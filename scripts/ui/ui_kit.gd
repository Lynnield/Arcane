class_name UiKit
extends RefCounted
## Shared theme and widget helpers so every screen looks the same.

const TEXT := Color("f4efff")
const MUTED := Color("b9b0d8")
const GOLD := Color("f2c14e")
const ACCENT := Color("7b5cff")

static var _theme: Theme
static var _theme_large := false


static func theme() -> Theme:
	if _theme and _theme_large == Save.large_text:
		return _theme
	_theme_large = Save.large_text
	var t := Theme.new()
	t.default_font_size = 19 if _theme_large else 15
	t.set_stylebox("normal", "Button", _box(Color("2b2350"), ACCENT))
	t.set_stylebox("hover", "Button", _box(Color("3a2f6e"), Color("a48bff")))
	t.set_stylebox("pressed", "Button", _box(Color("1d1738"), GOLD))
	t.set_stylebox("disabled", "Button", _box(Color("1f1c2b"), Color("4a4560")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("6d6688"))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color("120c22"))
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.08, 0.06, 0.16, 0.92), ACCENT, 16))
	t.set_stylebox("normal", "LineEdit", _box(Color("1d1738"), ACCENT))
	t.set_stylebox("focus", "LineEdit", _box(Color("1d1738"), GOLD))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color("6d6688"))
	_theme = t
	return t


static func _box(bg: Color, border: Color, margin: float = 10.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = margin + 4.0
	box.content_margin_right = margin + 4.0
	box.content_margin_top = margin * 0.5
	box.content_margin_bottom = margin * 0.5
	return box


## Sets up a full-screen menu with sky background; returns the centered column.
static func screen(root: Control) -> VBoxContainer:
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = theme()
	root.add_child(SkyBackground.new())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)
	return box


static func button(text: String, action: Callable, min_width: float = 220.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(min_width, 44 if Save.large_text else 36)
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		action.call())
	return b


## wrap_width > 0 wraps the text at that width (labels in containers need one).
static func label(text: String, font_size: int = 0, color: Color = TEXT, wrap_width: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap_width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap_width
	if font_size > 0:
		l.add_theme_font_size_override("font_size", font_size + (4 if Save.large_text else 0))
	l.add_theme_color_override("font_color", color)
	return l


static func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
