extends Node2D
## Offline campaign level. Builds itself from LevelData and runs the rules:
## defeat every enemy to open the portal, reach it to win. Falling respawns the
## wizard at the last checkpoint (or the start) with a time penalty.

const TILE := LevelData.TILE
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const STATIONARY_SCENE := preload("res://scenes/enemies/stationary_enemy.tscn")
const PATROL_SCENE := preload("res://scenes/enemies/patrol_enemy.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")

@export var level_index := 1

var player: Player
var hud: Hud
var controls: TouchControls
var exit_portal: ExitPortal
var camera: Camera2D
var elapsed := 0.0
var finished := false
var enemies_total := 0
var enemies_left := 0

var _respawn_point := Vector2.ZERO
var _kill_y := 0.0


func _ready() -> void:
	var data := LevelData.get_level(level_index)
	var width: int = data["width"]
	WorldBuilder.build(self, data["solids"], width, data["palette"], true)
	_kill_y = LevelData.HEIGHT * TILE + 48

	for sign_data in data["signs"]:
		_add_sign(sign_data[0], sign_data[1])
	for tile in data["checkpoints"]:
		var cp := Checkpoint.new()
		cp.position = LevelData.foot(tile)
		cp.activated.connect(_on_checkpoint)
		add_child(cp)

	exit_portal = ExitPortal.new()
	exit_portal.position = LevelData.foot(data["exit"])
	exit_portal.reached.connect(_on_exit_reached)
	exit_portal.touched_while_locked.connect(func() -> void: hud.show_message("Defeat every foe first", 1.2))
	add_child(exit_portal)

	controls = TouchControls.new()
	add_child(controls)
	player = PLAYER_SCENE.instantiate() as Player
	player.controls = controls
	player.position = LevelData.foot(data["player"])
	_respawn_point = player.position
	add_child(player)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_right = width * TILE
	camera.limit_top = 0
	camera.limit_bottom = LevelData.HEIGHT * TILE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.offset = Vector2(0, -24)
	player.add_child(camera)

	for entry in data["enemies"]:
		_spawn_enemy(entry[0], entry[1])

	hud = HUD_SCENE.instantiate() as Hud
	add_child(hud)
	hud.restart_requested.connect(func() -> void: Game.start_level(level_index))
	hud.menu_requested.connect(func() -> void: Game.goto(Game.MAIN_MENU))
	player.health_changed.connect(hud.set_health)
	player.died.connect(_on_player_died)
	hud.set_health(player.health, player.max_health)
	hud.set_time(0.0)
	_update_objective()
	hud.show_message("%d. %s" % [level_index, LevelData.level_name(level_index)], 1.8)
	if enemies_total == 0:
		exit_portal.unlock()


func _spawn_enemy(kind: String, tile: Vector2i) -> void:
	var enemy: Enemy
	match kind:
		"D":
			enemy = STATIONARY_SCENE.instantiate()
			enemy.style = "dummy"
			enemy.can_shoot = false
			enemy.body_size = Vector2(14, 28)
		"S":
			enemy = STATIONARY_SCENE.instantiate()
		"R":
			enemy = PATROL_SCENE.instantiate()
			enemy.style = "goblin"
			enemy.max_health = Tuning.PATROL_HEALTH
			enemy.fire_cooldown = Tuning.PATROL_COOLDOWN
			enemy.body_size = Vector2(12, 18)
			enemy.body_color = Color("5fa84a")
		"B":
			var boss := PATROL_SCENE.instantiate() as PatrolEnemy
			boss.style = "golem"
			boss.max_health = Tuning.BOSS_HEALTH
			boss.fire_cooldown = Tuning.BOSS_COOLDOWN
			boss.sight = Tuning.BOSS_SIGHT
			boss.orb_speed = Tuning.BOSS_ORB_SPEED
			boss.speed = Tuning.BOSS_SPEED
			boss.hops = true
			boss.body_size = Vector2(26, 30)
			boss.body_color = Color("8a7560")
			enemy = boss
		_:
			push_warning("Unknown enemy kind '%s'" % kind)
			return
	enemy.position = LevelData.foot(tile)
	enemy.target = player
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	enemies_total += 1
	enemies_left += 1


func _add_sign(tile: Vector2i, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(150, 40)
	label.position = Vector2(tile.x * TILE + TILE / 2.0 - 75.0, tile.y * TILE)
	var settings := LabelSettings.new()
	settings.font_size = 11
	settings.font_color = Color("fffbe8")
	settings.outline_size = 4
	settings.outline_color = Color("1b1530")
	label.label_settings = settings
	add_child(label)


func _physics_process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	hud.set_time(elapsed)
	if player.global_position.y > _kill_y:
		_respawn()


func _respawn() -> void:
	elapsed += Tuning.FALL_TIME_PENALTY
	player.respawn(_respawn_point)
	camera.reset_smoothing()
	Sfx.play("hurt")
	hud.show_message("+%d s" % int(Tuning.FALL_TIME_PENALTY), 1.0)


func _update_objective() -> void:
	if enemies_left > 0:
		hud.set_objective("Defeat enemies: %d / %d" % [enemies_total - enemies_left, enemies_total])
	else:
		hud.set_objective("Reach the portal!")


func _on_enemy_defeated(_enemy: Enemy) -> void:
	enemies_left -= 1
	_update_objective()
	if enemies_left == 0:
		exit_portal.unlock()
		hud.show_message("The portal is open!")


func _on_checkpoint(cp: Checkpoint) -> void:
	_respawn_point = cp.global_position
	hud.show_message("Checkpoint!", 1.0)


func _on_exit_reached() -> void:
	_finish(true)


func _on_player_died() -> void:
	_finish(false)


func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	hud.allow_pause = false
	player.can_act = false
	Sfx.play("win" if won else "lose")
	hud.show_message("Level Complete!" if won else "Defeated...", 2.0)
	await get_tree().create_timer(1.4).timeout
	Game.finish_level(level_index, won, elapsed)


## Android back button.
func on_back_requested() -> void:
	hud.toggle_pause()
