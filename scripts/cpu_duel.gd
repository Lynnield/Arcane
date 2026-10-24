extends Node2D
## Offline Wizard Duel against the computer. Same arena and rules as the
## online duel: best of three rounds, 100 HP each. Works with no network.
## Both wizards falling in the same frame is a draw and the round is replayed.

const TILE := LevelData.TILE
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const ORB_MASK := OrbPhysics.MASK_WORLD | OrbPhysics.MASK_PLAYER

var player: Player
var cpu: Player
var brain: CpuBrain
var hud: Hud
var controls: TouchControls
var camera: Camera2D
var my_rounds := 0
var cpu_rounds := 0
var round_active := false

var _spawns: Array = []
var _round_number := 0
var _check_pending := false
var _over := false


func _ready() -> void:
	var data := LevelData.arena()
	WorldBuilder.build(self, data["solids"], data["width"], data["palette"], false)
	_spawns = data["spawns"]
	camera = Camera2D.new()
	camera.position = Vector2(data["width"] * TILE / 2.0, LevelData.HEIGHT * TILE / 2.0)
	add_child(camera)

	controls = TouchControls.new()
	add_child(controls)
	player = _make_wizard(Color("6b4fd8"), Color("8fe3ff"))
	player.controls = controls
	player.show_marker = true
	add_child(player)

	var boss := Game.cpu_difficulty == CpuBrain.BOSS
	brain = ArcaneBrain.new() if boss else CpuBrain.new()
	brain.difficulty = Game.cpu_difficulty
	add_child(brain)
	cpu = _make_wizard(Color("f4f1ff") if boss else Color("c2414f"), Color("ff3b8d") if boss else Color("ffa36b"))
	if boss:
		cpu.visual_style = "arcane"
		cpu.max_health = Tuning.ARCANE_HEALTH
		cpu.health = Tuning.ARCANE_HEALTH
		cpu.orb_damage = Tuning.ARCANE_ORB_DAMAGE
	cpu.controls = brain
	cpu.reads_keyboard = false
	add_child(cpu)
	brain.me = cpu
	brain.foe = player
	player.hurt.connect(func() -> void: ScreenShake.shake(camera))

	for w in [player, cpu]:
		w.health_changed.connect(func(_c: int, _m: int) -> void: _refresh_hud())
		w.died.connect(_queue_round_check)

	hud = HUD_SCENE.instantiate() as Hud
	hud.mode = "cpu"
	add_child(hud)
	hud.restart_requested.connect(func() -> void: Game.start_cpu_duel(Game.cpu_difficulty))
	hud.menu_requested.connect(func() -> void: Game.goto(Game.OFFLINE_MENU))
	if boss:
		hud.set_rival_mystery("ARCANE")
		hud.set_objective("Bonus duel: The Arcane - first to %d rounds" % Tuning.PVP_ROUNDS_TO_WIN)
	else:
		hud.set_objective("Duel vs Computer (%s) - first to %d rounds" % [CpuBrain.level_name(Game.cpu_difficulty), Tuning.PVP_ROUNDS_TO_WIN])
	_start_round()


func _make_wizard(robe: Color, orb: Color) -> Player:
	var w := PLAYER_SCENE.instantiate() as Player
	w.robe_color = robe
	w.orb_color = orb
	w.max_health = Tuning.PVP_MAX_HEALTH
	w.health = Tuning.PVP_MAX_HEALTH
	w.orb_mask = ORB_MASK
	w.orb_damage = Tuning.PVP_DAMAGE
	w.can_act = false
	return w


func _start_round() -> void:
	_round_number += 1
	for node in get_children():
		if node is MagicOrb:
			node.queue_free()
	player.teleport(LevelData.foot(_spawns[0]))
	cpu.teleport(LevelData.foot(_spawns[1]))
	for w in [player, cpu]:
		w.reset_health()
		w.can_act = false
	_refresh_hud()
	hud.show_message("Round %d" % _round_number, 0.8)
	if cpu.visual_style == "arcane":
		cpu.visual.show_title("Da Goat", 3.0)
	for count in ["3", "2", "1"]:
		await get_tree().create_timer(0.7, false).timeout
		hud.show_message(count, 0.4)
	await get_tree().create_timer(0.7, false).timeout
	if _over:
		return
	hud.show_message("Fight!", 0.6)
	player.can_act = true
	cpu.can_act = true
	round_active = true


func _queue_round_check() -> void:
	if not _check_pending:
		_check_pending = true
		_check_round.call_deferred()


func _check_round() -> void:
	_check_pending = false
	if not round_active:
		return
	var player_down := player.health <= 0
	var cpu_down := cpu.health <= 0
	if not player_down and not cpu_down:
		return
	round_active = false
	player.can_act = false
	cpu.can_act = false
	if player_down and cpu_down:
		hud.show_message("Draw! Round replayed", 2.0)
	elif cpu_down:
		my_rounds += 1
		hud.show_message("Round won!", 2.0)
	else:
		cpu_rounds += 1
		hud.show_message("Round lost", 2.0)
	_refresh_hud()
	await get_tree().create_timer(2.2, false).timeout
	if my_rounds >= Tuning.PVP_ROUNDS_TO_WIN or cpu_rounds >= Tuning.PVP_ROUNDS_TO_WIN:
		_over = true
		Sfx.play("win" if my_rounds > cpu_rounds else "lose")
		Game.finish_cpu_duel(my_rounds > cpu_rounds, my_rounds, cpu_rounds)
	else:
		_start_round()


func _refresh_hud() -> void:
	hud.set_health(player.health, player.max_health)
	hud.set_rival_health(cpu.health, cpu.max_health)
	hud.set_info("Rounds  %d - %d" % [my_rounds, cpu_rounds])


## Android back button.
func on_back_requested() -> void:
	hud.toggle_pause()
