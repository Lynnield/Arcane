class_name LevelData
extends RefCounted
## Campaign layouts. Units are 16 px tiles.
## solids: [x, y, w, h]; h == 0 extends the block to the bottom of the level.
## Entity positions are the tile the entity stands in (its feet touch the tile below).
## Enemy kinds: D = target dummy, S = stationary, R = patrol, B = boss.

const TILE := 16
const COUNT := 5
const HEIGHT := 23
const NAMES := ["The First Spell", "The Broken Path", "The Moving Threat", "The Ruined Tower", "The Final Trial"]
const GOALS := [
	"Hit the target dummy, then enter the portal",
	"Cross the broken path and defeat both sentries",
	"Defeat all 6 foes - the goblins keep moving",
	"Climb the ruined tower and defeat all 6 foes",
	"Defeat the Guardian, then enter the portal",
]
## Clear time (seconds) for 3 stars; up to 1.5x par earns 2 stars.
const PAR_TIMES := [30.0, 50.0, 85.0, 100.0, 70.0]


static func level_name(index: int) -> String:
	return str(NAMES[clampi(index, 1, COUNT) - 1])


static func goal(index: int) -> String:
	return str(GOALS[clampi(index, 1, COUNT) - 1])


static func par_time(index: int) -> float:
	return float(PAR_TIMES[clampi(index, 1, COUNT) - 1])


static func stars_for(index: int, time: float) -> int:
	var par := par_time(index)
	if time <= par:
		return 3
	if time <= par * 1.5:
		return 2
	return 1


## World position of the feet of something standing in `tile`.
static func foot(tile: Vector2i) -> Vector2:
	return Vector2((tile.x + 0.5) * TILE, (tile.y + 1) * TILE)


static func get_level(index: int) -> Dictionary:
	match index:
		1:
			return {
				"width": 72, "palette": palette("meadow"),
				"solids": [[0, 19, 72, 0], [20, 17, 6, 2], [34, 17, 3, 2]],
				"player": Vector2i(2, 18),
				"enemies": [["D", Vector2i(48, 18)]],
				"checkpoints": [],
				"exit": Vector2i(68, 18),
				"signs": [
					[Vector2i(4, 13), "Move with the left stick (or A / D)"],
					[Vector2i(16, 11), "Tap JUMP (or Space) to hop up - tap again in the air to double jump"],
					[Vector2i(30, 11), "Touch the right side, pull BACK and release to cast"],
					[Vector2i(44, 13), "Hit the target dummy"],
					[Vector2i(61, 13), "Defeat every foe to open the portal"],
				],
			}
		2:
			return {
				"width": 96, "palette": palette("dusk"),
				"solids": [[0, 19, 12, 0], [15, 17, 4, 0], [23, 16, 5, 1], [32, 18, 10, 0],
					[46, 16, 3, 1], [52, 14, 4, 1], [60, 17, 16, 0], [80, 19, 16, 0]],
				"player": Vector2i(2, 18),
				"enemies": [["S", Vector2i(38, 17)], ["S", Vector2i(70, 16)]],
				"checkpoints": [],
				"exit": Vector2i(92, 18),
				"signs": [[Vector2i(6, 14), "Falling sends you back, but costs time"]],
			}
		3:
			return {
				"width": 112, "palette": palette("cave"),
				"solids": [[0, 19, 20, 0], [24, 17, 12, 0], [40, 15, 10, 1], [40, 19, 30, 0],
					[54, 16, 4, 1], [74, 18, 8, 0], [86, 17, 26, 0], [98, 14, 4, 1]],
				"player": Vector2i(2, 18),
				"enemies": [["R", Vector2i(14, 18)], ["S", Vector2i(33, 16)], ["R", Vector2i(45, 14)],
					["S", Vector2i(56, 15)], ["R", Vector2i(92, 16)], ["S", Vector2i(100, 13)]],
				"checkpoints": [],
				"exit": Vector2i(108, 16),
				"signs": [[Vector2i(5, 13), "Patrollers move - lead your shots"]],
			}
		4:
			return {
				"width": 120, "palette": palette("ruins"),
				"solids": [[0, 19, 14, 0], [14, 17, 3, 0], [17, 15, 3, 0], [20, 13, 10, 1],
					[20, 19, 40, 0], [33, 16, 5, 1], [40, 14, 4, 1], [46, 12, 6, 1],
					[64, 17, 4, 0], [68, 15, 4, 0], [72, 13, 4, 0], [76, 11, 4, 0],
					[80, 11, 16, 1], [94, 19, 26, 0]],
				"player": Vector2i(2, 18),
				"enemies": [["S", Vector2i(27, 12)], ["R", Vector2i(35, 18)], ["S", Vector2i(50, 11)],
					["S", Vector2i(86, 10)], ["R", Vector2i(90, 10)], ["S", Vector2i(108, 18)]],
				"checkpoints": [Vector2i(56, 18)],
				"exit": Vector2i(116, 18),
				"signs": [],
			}
		_:
			return {
				"width": 64, "palette": palette("golden"),
				"solids": [[0, 19, 64, 0], [12, 15, 6, 1], [28, 13, 8, 1], [46, 15, 6, 1]],
				"player": Vector2i(3, 18),
				"enemies": [["B", Vector2i(50, 18)]],
				"checkpoints": [],
				"exit": Vector2i(60, 18),
				"signs": [[Vector2i(4, 13), "The Guardian awaits"]],
			}


static func arena() -> Dictionary:
	return {
		"width": 40, "palette": palette("arena"),
		"solids": [[-8, 19, 56, 0], [-8, -6, 8, 0], [40, -6, 8, 0],
			[6, 15, 6, 1], [28, 15, 6, 1], [14, 12, 12, 1]],
		"spawns": [Vector2i(4, 18), Vector2i(35, 18)],
	}


static func palette(theme: String) -> Dictionary:
	match theme:
		"meadow":
			return _p("5fb4e8", "cdeef5", "a3d9b5", "6fbf8a", "7a5232", "5a3a22", "5cc23a", false)
		"dusk":
			return _p("6b3f8f", "f29b8a", "b0608f", "7d3f73", "6e6a80", "4c4860", "9a7fd0", false)
		"cave":
			return _p("1a1428", "2c2340", "2f2747", "3b3158", "5e4a6e", "3d2f4a", "6fc6d6", true)
		"ruins":
			return _p("13243b", "2f5a6b", "1f3d4a", "2b5560", "4b4f6b", "33364d", "e0a84a", true)
		"golden":
			return _p("6ec3e8", "f5e7b8", "c8b178", "9bb56a", "8a6040", "603f28", "7cc246", false)
		_:
			return _p("241a3d", "5b3a7a", "3a2b5c", "4a3570", "51486b", "362f4b", "b48cff", true)


static func _p(sky_top: String, sky_bottom: String, hills_far: String, hills_near: String,
		ground: String, ground_dark: String, top: String, stars: bool) -> Dictionary:
	return {
		"sky_top": Color(sky_top), "sky_bottom": Color(sky_bottom),
		"hills_far": Color(hills_far), "hills_near": Color(hills_near),
		"ground": Color(ground), "ground_dark": Color(ground_dark),
		"top": Color(top), "stars": stars,
	}
