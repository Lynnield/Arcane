extends Node
## LAN multiplayer over ENet. The host phone is peer 1 and is authoritative
## for hits, health and round results. Gameplay RPCs live on this autoload
## (its node path is the same on both phones) and are forwarded to the
## running PvP arena.

signal opponent_joined(id: int)
signal joined_host
signal failed(message: String)
signal opponent_left(message: String)

const JOIN_TIMEOUT_MS := 8000

## Set by the arena while a match scene is running.
var arena: Node = null
var opponent_id := 0
var client_is_ready := false

var _joining := false
var _join_deadline := 0
var _closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(_delta: float) -> void:
	if _joining and Time.get_ticks_msec() > _join_deadline:
		close()
		failed.emit("No answer from the host. Check the IP address and that both phones are on the same Wi-Fi.")


func is_online() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and not (peer is OfflineMultiplayerPeer) \
		and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_host() -> bool:
	return is_online() and multiplayer.is_server()


func host() -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(Tuning.NET_PORT, 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func join(address: String) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, Tuning.NET_PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_joining = true
	_join_deadline = Time.get_ticks_msec() + JOIN_TIMEOUT_MS
	return OK


func close() -> void:
	_joining = false
	opponent_id = 0
	client_is_ready = false
	var peer := multiplayer.multiplayer_peer
	if peer != null and not (peer is OfflineMultiplayerPeer):
		_closing = true
		peer.close()
		multiplayer.multiplayer_peer = null
		_closing = false


static func local_addresses() -> PackedStringArray:
	var out := PackedStringArray()
	for address in IP.get_local_addresses():
		var parts := address.split(".")
		if parts.size() != 4:
			continue
		var second := parts[1].to_int()
		if address.begins_with("192.168.") or address.begins_with("10.") \
				or (parts[0] == "172" and second >= 16 and second <= 31):
			out.append(address)
	return out


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		opponent_id = id
		opponent_joined.emit(id)


func _on_peer_disconnected(id: int) -> void:
	if not _closing and id == opponent_id:
		_lost.call_deferred("Your opponent disconnected.")


func _on_connected_to_server() -> void:
	_joining = false
	opponent_id = 1
	joined_host.emit()


func _on_connection_failed() -> void:
	_joining = false
	_fail_join.call_deferred()


# Peer teardown must not happen inside the multiplayer poll that emitted the
# signal (it crashes), so the handlers above defer to these.
func _fail_join() -> void:
	close()
	failed.emit("Could not connect. Check the IP address and that both phones are on the same Wi-Fi.")


func _on_server_disconnected() -> void:
	if not _closing:
		_lost.call_deferred("Lost connection to the host.")


func _lost(message: String) -> void:
	if not is_online() and opponent_id == 0:
		return
	if arena:
		arena.on_connection_lost(message)
	opponent_left.emit(message)
	close()


# --- Match RPCs -------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func start_match() -> void:
	Game.goto(Game.PVP_ARENA)


@rpc("any_peer", "call_remote", "reliable")
func client_ready() -> void:
	if multiplayer.is_server():
		client_is_ready = true
		if arena:
			arena.try_begin()


@rpc("any_peer", "call_remote", "unreliable_ordered")
func player_state(pos: Vector2, vel: Vector2, facing: int, aiming: bool, aim_vel: Vector2) -> void:
	if arena:
		arena.on_remote_state(multiplayer.get_remote_sender_id(), pos, vel, facing, aiming, aim_vel)


@rpc("any_peer", "call_remote", "reliable")
func request_fire(origin: Vector2, vel: Vector2) -> void:
	if multiplayer.is_server() and arena:
		arena.host_fire(multiplayer.get_remote_sender_id(), origin, vel)


@rpc("authority", "call_local", "reliable")
func spawn_orb(owner_id: int, orb_id: int, origin: Vector2, vel: Vector2) -> void:
	if arena:
		arena.spawn_orb(owner_id, orb_id, origin, vel)


@rpc("authority", "call_remote", "reliable")
func remove_orb(orb_id: int) -> void:
	if arena:
		arena.remove_orb(orb_id)


@rpc("authority", "call_local", "reliable")
func set_health(peer_id: int, hp: int) -> void:
	if arena:
		arena.apply_health(peer_id, hp)


@rpc("authority", "call_local", "reliable")
func begin_round(round_number: int, host_score: int, client_score: int) -> void:
	if arena:
		arena.on_round_begin(round_number, host_score, client_score)


@rpc("authority", "call_local", "reliable")
func end_round(winner_id: int, host_score: int, client_score: int, match_over: bool) -> void:
	if arena:
		arena.on_round_end(winner_id, host_score, client_score, match_over)
