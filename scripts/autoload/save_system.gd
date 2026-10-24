extends Node
## Local campaign progress and settings, stored in user://save.cfg.
## Works offline. Unreadable or invalid data is set aside and replaced with defaults.

const PATH := "user://save.cfg"
const CORRUPT_PATH := "user://save.corrupt.cfg"

var unlocked := 1
var best_times: Dictionary = {}
var best_stars: Dictionary = {}
var master_volume := 0.8
var large_text := false
var last_ip := ""


func _ready() -> void:
	load_data()
	apply_volume()


func load_data() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(PATH)
	if err == ERR_FILE_NOT_FOUND:
		return
	if err != OK:
		push_warning("Save data unreadable (%s); starting fresh." % error_string(err))
		_set_aside_corrupt()
		return
	unlocked = clampi(int(_number(cfg.get_value("progress", "unlocked", 1), 1.0)), 1, LevelData.COUNT)
	best_times.clear()
	best_stars.clear()
	for i in range(1, LevelData.COUNT + 1):
		var t := _number(cfg.get_value("best_times", "level_%d" % i, -1.0), -1.0)
		if t > 0.0 and is_finite(t):
			best_times[i] = t
		var s := int(_number(cfg.get_value("best_stars", "level_%d" % i, 0), 0.0))
		if s > 0:
			best_stars[i] = clampi(s, 1, 3)
	master_volume = clampf(_number(cfg.get_value("settings", "master_volume", 0.8), 0.8), 0.0, 1.0)
	var big = cfg.get_value("settings", "large_text", false)
	large_text = big is bool and big
	var ip = cfg.get_value("settings", "last_ip", "")
	last_ip = ip if ip is String else ""


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	for i in best_times:
		cfg.set_value("best_times", "level_%d" % i, best_times[i])
	for i in best_stars:
		cfg.set_value("best_stars", "level_%d" % i, best_stars[i])
	cfg.set_value("settings", "master_volume", master_volume)
	cfg.set_value("settings", "large_text", large_text)
	cfg.set_value("settings", "last_ip", last_ip)
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("Could not save progress (%s)." % error_string(err))


func is_unlocked(level: int) -> bool:
	return level <= unlocked


func get_best_time(level: int) -> float:
	return best_times.get(level, -1.0)


func get_best_stars(level: int) -> int:
	return best_stars.get(level, 0)


## Unlocks the next level, keeps the most stars earned and stores the time
## if it beats the record. Returns true when this run is a new best time.
func record_completion(level: int, time: float, stars: int) -> bool:
	unlocked = maxi(unlocked, mini(level + 1, LevelData.COUNT))
	best_stars[level] = maxi(stars, get_best_stars(level))
	var new_best := not best_times.has(level) or time < float(best_times[level])
	if new_best:
		best_times[level] = time
	save_data()
	return new_best


func reset_progress() -> void:
	unlocked = 1
	best_times.clear()
	best_stars.clear()
	save_data()


func apply_volume() -> void:
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))


static func _number(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		return float(value)
	return fallback


func _set_aside_corrupt() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists(CORRUPT_PATH.get_file()):
		dir.remove(CORRUPT_PATH.get_file())
	dir.rename(PATH.get_file(), CORRUPT_PATH.get_file())
