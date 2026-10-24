extends Control
## Online lobby. One phone hosts, the other joins by IP on the same Wi-Fi.

var _status: Label
var _ip_edit: LineEdit
var _host_button: Button
var _join_button: Button
var _retry_button: Button
var _cancel_button: Button
var _last_action := ""


func _ready() -> void:
	Net.close()
	var box := UiKit.screen(self)
	box.add_child(UiKit.label("Online Duel", 28, UiKit.GOLD))
	box.add_child(UiKit.label("Both phones must be on the same Wi-Fi network.", 13, UiKit.MUTED))
	_host_button = UiKit.button("Host Match", _host)
	box.add_child(_host_button)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_ip_edit = LineEdit.new()
	_ip_edit.placeholder_text = "Host IP, e.g. 192.168.1.5"
	_ip_edit.text = Save.last_ip
	_ip_edit.custom_minimum_size = Vector2(210, 36)
	_ip_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	_ip_edit.text_submitted.connect(func(_t: String) -> void: _join())
	row.add_child(_ip_edit)
	_join_button = UiKit.button("Join", _join, 90.0)
	row.add_child(_join_button)
	box.add_child(row)

	_status = UiKit.label("", 14, UiKit.TEXT, 420.0)
	box.add_child(_status)
	_retry_button = UiKit.button("Retry", _retry, 160.0)
	_retry_button.visible = false
	box.add_child(_retry_button)
	_cancel_button = UiKit.button("Back", _back, 160.0)
	box.add_child(_cancel_button)

	Net.opponent_joined.connect(_on_opponent_joined)
	Net.joined_host.connect(_on_joined_host)
	Net.failed.connect(_fail)
	Net.opponent_left.connect(_fail)


func _host() -> void:
	_last_action = "host"
	var err := Net.host()
	if err != OK:
		_fail("Could not host on port %d (%s)." % [Tuning.NET_PORT, error_string(err)])
		return
	var ips := Net.local_addresses()
	var where := ", ".join(ips) if not ips.is_empty() else "(no Wi-Fi address found - is Wi-Fi on?)"
	_set_busy(true, "Hosting. Your opponent joins with:\n%s\nWaiting for opponent..." % where)


func _join() -> void:
	_last_action = "join"
	var ip := _ip_edit.text.strip_edges()
	if not ip.is_valid_ip_address():
		_fail("Enter the IP address shown on the host's screen.")
		return
	Save.last_ip = ip
	Save.save_data()
	var err := Net.join(ip)
	if err != OK:
		_fail("Could not start connection (%s)." % error_string(err))
		return
	_set_busy(true, "Connecting to %s..." % ip)


func _on_opponent_joined(_id: int) -> void:
	_status.text = "Opponent joined! Starting..."
	await get_tree().create_timer(1.0).timeout
	if Net.is_host():
		Net.client_is_ready = false
		Net.start_match.rpc()


func _on_joined_host() -> void:
	_status.text = "Connected! Waiting for the host to start..."


func _fail(message: String) -> void:
	Net.close()
	_set_busy(false, message)
	_retry_button.visible = _last_action != ""


func _retry() -> void:
	if _last_action == "host":
		_host()
	else:
		_join()


func _set_busy(busy: bool, message: String) -> void:
	_status.text = message
	_host_button.disabled = busy
	_join_button.disabled = busy
	_ip_edit.editable = not busy
	_retry_button.visible = false
	_cancel_button.text = "Cancel" if busy else "Back"


func _back() -> void:
	if _host_button.disabled:
		Net.close()
		_set_busy(false, "Cancelled.")
		return
	Net.close()
	Game.goto(Game.MAIN_MENU)


## Android back button.
func on_back_requested() -> void:
	_back()
