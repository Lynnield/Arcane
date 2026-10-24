class_name WizardVisual
extends Node2D
## Draws and animates a Player. Purely visual: it reads the player's state and
## never changes physics, so the hitbox and the orb spawn point stay the same.

var player: Player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var p := player
	var f := float(p.facing)
	var robe := Color.WHITE if p.hurt_flash > 0.0 else p.robe_color
	var dark := robe.darkened(0.35)
	var skin := Color("f1c7a0")
	var bob := 0.0
	if absf(p.velocity.x) > 10.0 and absf(p.velocity.y) < 1.0 and int(Time.get_ticks_msec() / 100) % 2 == 0:
		bob = -1.0

	# Robe and feet
	draw_rect(Rect2(-4, -1, 3, 1), Color("2a1f3d"))
	draw_rect(Rect2(1, -1, 3, 1), Color("2a1f3d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -1), Vector2(6, -1), Vector2(4, -12 + bob), Vector2(-4, -12 + bob)]), robe)
	draw_rect(Rect2(-6, -3, 12, 2), p.trim_color)
	draw_rect(Rect2(-4, -8 + bob, 8, 1), p.trim_color)
	# Head
	draw_rect(Rect2(-3, -18 + bob, 6, 6), skin)
	draw_rect(Rect2(1.0 if f > 0.0 else -2.0, -16 + bob, 1, 2), Color("1b1530"))
	draw_rect(Rect2(-3, -13 + bob, 6, 2), Color("e8e4f0"))
	# Hat
	draw_rect(Rect2(-6, -19 + bob, 12, 2), dark)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -19 + bob), Vector2(4, -19 + bob), Vector2(-3.0 * f, -29 + bob)]), robe)
	draw_rect(Rect2(-1.0 * f - 0.5, -24 + bob, 1, 1), p.trim_color)
	# Wand
	var dir := p.aim_velocity.normalized() if p.aiming and p.aim_velocity != Vector2.ZERO else Vector2(0.6 * f, -0.8).normalized()
	var hand := Vector2(Player.HAND.x * f, Player.HAND.y + bob)
	draw_line(hand, hand + dir * Player.WAND_LENGTH, Color("8a5a32"), 2.0)
	var glow := p.orb_color if p.aiming else p.orb_color.darkened(0.3)
	draw_circle(hand + dir * Player.WAND_LENGTH, 3.0 if p.aiming else 2.0, Color(glow, 0.5))
	draw_circle(hand + dir * Player.WAND_LENGTH, 1.2, Color.WHITE)
	if p.show_marker:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-3, -36), Vector2(3, -36), Vector2(0, -32)]), Color("f2c14e"))
