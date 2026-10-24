extends Node2D
## Online Wizard Duel. Best of three rounds, 100 HP each, fixed camera.
## Each phone moves its own wizard and streams its state. Shots go through the
## host, which spawns every orb, decides hits, sets health and ends rounds.
## Simultaneous defeat (both wizards reach 0 HP in the same frame) is a draw:
## nobody scores and the round is replayed.

const TILE := LevelData.TILE
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ORB_SCENE := preload("res://scenes/magic_orb.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const HOST_COLOR := Color("6b4fd8")
const CLIENT_COLOR := Color("2fae9b")
const ORB_MASK := OrbPhysics.MASK_WORLD | OrbPhysics.MASK_PLAYER

var players: Dictionary = {}
var orbs: Dictionary = {}
var local_id := 1
var client_id := 0
var hud: Hud
var controls: TouchControls
var round_active := false
var host_score := 0
var client_score := 0

var _spawns: Array = []
var _began := false
var _round_number := 0
var _round_check_pending := false
var _match_over := false
var _next_orb_id := 1
var _send_timer := 0.0
var _last_fire_ms: Dictionary = {}


func _ready() -> void:
	var data := LevelData.arena()
	WorldBuilder.build(self, data["solids"], data["width"], data["palette"], false)
	_spawns = data["spawns"]

	var camera := Camera2D.new()
	camera.position = Vector2(data["width"] * TILE / 2.0, LevelData.HEIGHT * TILE / 2.0)
	add_child(camera)

	hud = HUD_SCENE.instantiate() as Hud
	hud.mode = "pvp"
	add_child(hud)
	hud.menu_requested.connect(_leave)

	if not Net.is_online():
		hud.show_menu("Not connected", [["Main Menu", _leave]], "The duel needs a host and a guest on the same Wi-Fi.")
		return

	Net.arena = self
	local_id = multiplayer.get_unique_id()
	client_id = Net.opponent_id if multiplayer.is_server() else local_id
	controls = TouchControls.new()
	add_child(controls)
	_make_player(1, _spawns[0], HOST_COLOR)
	_make_player(client_id, _spawns[1], CLIENT_COLOR)
	_refresh_hud()
	hud.set_objective("Waiting for opponent...")

	if multiplayer.is_server():
		try_begin()
	else:
		Net.client_ready.rpc_id(1)


func _exit_tree() -> void:
	if Net.arena == self:
		Net.arena = null


func _make_player(id: int, tile: Vector2i, color: Color) -> void:
	var p := PLAYER_SCENE.instantiate() as Player
	p.name = "Wizard%d" % id
	p.peer_id = id
	p.robe_color = color
	p.is_local = id == local_id
	p.show_marker = p.is_local
	p.max_health = Tuning.PVP_MAX_HEALTH
	p.health = Tuning.PVP_MAX_HEALTH
	p.spawn_orbs_locally = false
	p.orb_mask = ORB_MASK
	p.orb_color = Color("b48cff") if id == 1 else Color("7cf0d0")
	p.can_act = false
	p.position = LevelData.foot(tile)
	if p.is_local:
		p.controls = controls
		p.fired.connect(_on_local_fired)
	add_child(p)
	players[id] = p


func _local() -> Player:
	return players.get(local_id)


func _rival() -> Player:
	return players.get(client_id if local_id == 1 else 1)


func _physics_process(delta: float) -> void:
	if _match_over or not Net.is_online() or players.is_empty():
		return
	_send_timer -= delta
	if _send_timer <= 0.0:
		_send_timer = 1.0 / Tuning.NET_SEND_RATE
		var me := _local()
		Net.player_state.rpc(me.global_position, me.velocity, me.facing, me.aiming, me.aim_velocity)


# --- Rounds (host drives, both phones apply) --------------------------------

func try_begin() -> void:
	if _began or not multiplayer.is_server() or not Net.client_is_ready:
		return
	_began = true
	_start_round()


func _start_round() -> void:
	_round_number += 1
	Net.begin_round.rpc(_round_number, host_score, client_score)


func on_round_begin(round_number: int, new_host_score: int, new_client_score: int) -> void:
	host_score = new_host_score
	client_score = new_client_score
	for orb in orbs.values():
		if is_instance_valid(orb):
			orb.queue_free()
	orbs.clear()
	players[1].teleport(LevelData.foot(_spawns[0]))
	players[client_id].teleport(LevelData.foot(_spawns[1]))
	for p in players.values():
		p.reset_health()
		p.can_act = false
	_refresh_hud()
	hud.set_objective("First to %d rounds" % Tuning.PVP_ROUNDS_TO_WIN)
	hud.show_message("Round %d" % round_number, 0.8)
	for count in ["3", "2", "1"]:
		await get_tree().create_timer(0.7).timeout
		if _match_over or not is_inside_tree():
			return
		hud.show_message(count, 0.4)
	await get_tree().create_timer(0.7).timeout
	if _match_over or not is_inside_tree():
		return
	hud.show_message("Fight!", 0.6)
	_local().can_act = true
	round_active = true


func on_round_end(winner_id: int, new_host_score: int, new_client_score: int, match_over: bool) -> void:
	round_active = false
	host_score = new_host_score
	client_score = new_client_score
	_local().can_act = false
	_refresh_hud()
	if winner_id == 0:
		hud.show_message("Draw! Round replayed", 2.0)
	elif winner_id == local_id:
		hud.show_message("Round won!", 2.0)
	else:
		hud.show_message("Round lost", 2.0)
	if not match_over:
		return
	_match_over = true
	var mine := host_score if local_id == 1 else client_score
	var theirs := client_score if local_id == 1 else host_score
	await get_tree().create_timer(2.2).timeout
	Game.finish_match(mine > theirs, mine, theirs)


func _queue_round_check() -> void:
	if not _round_check_pending:
		_round_check_pending = true
		_check_round.call_deferred()


func _check_round() -> void:
	_round_check_pending = false
	if not round_active:
		return
	var host_down: bool = players[1].health <= 0
	var client_down: bool = players[client_id].health <= 0
	if not host_down and not client_down:
		return
	round_active = false
	var winner := 0
	if host_down and not client_down:
		winner = client_id
		client_score += 1
	elif client_down and not host_down:
		winner = 1
		host_score += 1
	var over := host_score >= Tuning.PVP_ROUNDS_TO_WIN or client_score >= Tuning.PVP_ROUNDS_TO_WIN
	Net.end_round.rpc(winner, host_score, client_score, over)
	if not over:
		await get_tree().create_timer(2.5).timeout
		if is_inside_tree() and Net.is_online():
			_start_round()


# --- Shots -------------------------------------------------------------------

func _on_local_fired(origin: Vector2, vel: Vector2) -> void:
	if multiplayer.is_server():
		host_fire(1, origin, vel)
	else:
		Net.request_fire.rpc_id(1, origin, vel)


## Host only: validate a shot request, then spawn the orb on both phones.
func host_fire(shooter_id: int, origin: Vector2, vel: Vector2) -> void:
	if not round_active or not players.has(shooter_id):
		return
	var shooter: Player = players[shooter_id]
	if shooter.health <= 0 or vel.length() > Tuning.ORB_MAX_SPEED * 1.01:
		return
	if origin.distance_to(shooter.global_position + Vector2(0, -11)) > 40.0:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_fire_ms.get(shooter_id, -100000)) < int(Tuning.FIRE_COOLDOWN * 800.0):
		return
	var active := 0
	for orb in orbs.values():
		if is_instance_valid(orb) and orb.owner_peer == shooter_id:
			active += 1
	if active >= Tuning.PVP_MAX_ACTIVE_ORBS:
		return
	_last_fire_ms[shooter_id] = now
	Net.spawn_orb.rpc(shooter_id, _next_orb_id, origin, vel)
	_next_orb_id += 1


func spawn_orb(owner_id: int, orb_id: int, origin: Vector2, vel: Vector2) -> void:
	var shooter: Player = players.get(owner_id)
	if shooter == null:
		return
	var exclude: Array[RID] = [shooter.get_rid()]
	var orb := ORB_SCENE.instantiate() as MagicOrb
	orb.setup(origin, vel, ORB_MASK, exclude, Tuning.PVP_DAMAGE, shooter, shooter.orb_color)
	orb.apply_damage = false
	orb.orb_id = orb_id
	orb.owner_peer = owner_id
	orb.impacted.connect(_on_orb_impacted)
	orb.tree_exited.connect(func() -> void: orbs.erase(orb_id))
	orbs[orb_id] = orb
	add_child(orb)
	if owner_id != local_id:
		Sfx.play("enemy_shoot")


func remove_orb(orb_id: int) -> void:
	var orb = orbs.get(orb_id)
	if is_instance_valid(orb):
		orb.vanish()


## Orbs fly on both phones, but only the host's copy can deal damage.
func _on_orb_impacted(orb: MagicOrb, collider: Object, _at: Vector2) -> void:
	if not multiplayer.is_server() or not Net.is_online():
		return
	Net.remove_orb.rpc(orb.orb_id)
	if round_active and collider is Player and collider.peer_id != orb.owner_peer:
		var target := collider as Player
		Net.set_health.rpc(target.peer_id, maxi(target.health - Tuning.PVP_DAMAGE, 0))
		_queue_round_check()


func apply_health(peer_id: int, hp: int) -> void:
	if players.has(peer_id):
		players[peer_id].set_health(hp)
		_refresh_hud()


func on_remote_state(sender: int, pos: Vector2, vel: Vector2, facing: int, aiming: bool, aim_vel: Vector2) -> void:
	if sender != local_id and players.has(sender):
		players[sender].set_remote_state(pos, vel, facing, aiming, aim_vel)


# --- HUD / leaving ------------------------------------------------------------

func _refresh_hud() -> void:
	var me := _local()
	var rival := _rival()
	if me:
		hud.set_health(me.health, me.max_health)
	if rival:
		hud.set_rival_health(rival.health, rival.max_health)
	var mine := host_score if local_id == 1 else client_score
	var theirs := client_score if local_id == 1 else host_score
	hud.set_info("Rounds  %d - %d" % [mine, theirs])


func on_connection_lost(message: String) -> void:
	if _match_over:
		return
	_match_over = true
	round_active = false
	if _local():
		_local().can_act = false
	hud.show_menu("Connection lost", [["Main Menu", _leave]], message)


func _leave() -> void:
	_match_over = true
	Net.close()
	Game.goto(Game.MAIN_MENU)


## Android back button.
func on_back_requested() -> void:
	hud.toggle_pause()
