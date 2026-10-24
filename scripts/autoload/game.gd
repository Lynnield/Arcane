extends Node
## Scene flow, keyboard actions and the hand-off to the results screen.

const TITLE := "res://scenes/ui/title.tscn"
const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/ui/level_select.tscn"
const SETTINGS := "res://scenes/ui/settings.tscn"
const LOBBY := "res://scenes/ui/lobby.tscn"
const RESULTS := "res://scenes/ui/results.tscn"
const PVP_ARENA := "res://scenes/pvp_arena.tscn"

var current_level := 1
var last_result: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key_action("pause", [KEY_ESCAPE, KEY_P])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()


## Android back button: quit from the top menus, otherwise let the scene decide.
func _on_back() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene.scene_file_path == TITLE or scene.scene_file_path == MAIN_MENU:
		get_tree().quit()
	elif scene.has_method("on_back_requested"):
		scene.on_back_requested()
	else:
		goto(MAIN_MENU)


func goto(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)


func start_level(index: int) -> void:
	current_level = clampi(index, 1, LevelData.COUNT)
	goto("res://scenes/levels/level_%d.tscn" % current_level)


func finish_level(index: int, won: bool, time: float) -> void:
	var new_best := false
	var stars := LevelData.stars_for(index, time) if won else 0
	if won:
		new_best = Save.record_completion(index, time, stars)
	last_result = {
		"mode": "campaign", "level": index, "won": won, "time": time, "stars": stars,
		"best": Save.get_best_time(index), "new_best": new_best,
		"has_next": won and index < LevelData.COUNT,
	}
	goto(RESULTS)


func finish_match(won: bool, my_rounds: int, their_rounds: int) -> void:
	last_result = {"mode": "pvp", "won": won, "my_rounds": my_rounds, "their_rounds": their_rounds}
	Net.close()
	goto(RESULTS)


static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--.-"
	return "%02d:%04.1f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]
