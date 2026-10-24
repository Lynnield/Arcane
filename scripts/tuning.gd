class_name Tuning
extends RefCounted
## Gameplay values the concept paper (section 18) leaves open until playtesting.
## Change them here; every system reads from this file.

# Player movement
const PLAYER_SPEED := 120.0
const PLAYER_ACCEL := 900.0
## Used when reversing direction, so turning around feels snappy.
const PLAYER_TURN_ACCEL := 1800.0
## Used on the ground with no input, so the wizard stops cleanly.
const PLAYER_FRICTION := 1400.0
const PLAYER_GRAVITY := 900.0
const MAX_FALL_SPEED := 500.0
const JUMP_VELOCITY := -330.0
## Near the top of a held jump gravity is reduced for a brief, floaty hang.
const APEX_HANG_SPEED := 40.0
const APEX_GRAVITY_SCALE := 0.6
## Extra jumps allowed in the air (pressing jump again while airborne).
const AIR_JUMPS := 1
const DOUBLE_JUMP_VELOCITY := -290.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const PLAYER_MAX_HEALTH := 100

# Pull-back aiming (viewport pixels)
const MIN_PULL := 12.0
const MAX_PULL := 90.0

# Magic orb
const ORB_MIN_SPEED := 150.0
const ORB_MAX_SPEED := 420.0
const ORB_GRAVITY := 500.0
const ORB_MAX_LIFETIME := 3.0
const ORB_DAMAGE := 25
const FIRE_COOLDOWN := 0.35
const PREVIEW_TIME := 1.1

# Enemies
const ENEMY_ORB_SPEED := 320.0
const ENEMY_ORB_DAMAGE := 20
const ENEMY_SIGHT := 240.0
const STATIONARY_HEALTH := 50
const STATIONARY_COOLDOWN := 2.4
const PATROL_HEALTH := 50
const PATROL_SPEED := 40.0
const PATROL_COOLDOWN := 3.0
const BOSS_HEALTH := 300
const BOSS_SPEED := 55.0
const BOSS_COOLDOWN := 1.3
const BOSS_SIGHT := 360.0
const BOSS_ORB_SPEED := 380.0

# Checkpoints
const FALL_TIME_PENALTY := 5.0
const RESPAWN_PROTECTION := 1.5

# PvP
const PVP_MAX_HEALTH := 100
const PVP_DAMAGE := 20
const PVP_MAX_ACTIVE_ORBS := 3
const PVP_ROUNDS_TO_WIN := 2
const NET_PORT := 7777
const NET_SEND_RATE := 30.0
