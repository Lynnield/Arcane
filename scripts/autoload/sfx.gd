extends Node
## Tiny synthesized sound effects and a looping background tune, so the
## project needs no audio files. Respects Save.sound_on / Save.music_on.

const RATE := 22050
const MUSIC_VOLUME_DB := -10.0

var _sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_sounds["jump"] = _tone(300.0, 600.0, 0.12, "square", 0.18)
	_sounds["double_jump"] = _tone(600.0, 1300.0, 0.16, "sine", 0.3)
	_sounds["shoot"] = _tone(900.0, 300.0, 0.18, "square", 0.16)
	_sounds["enemy_shoot"] = _tone(500.0, 200.0, 0.18, "sine", 0.3)
	_sounds["hit"] = _tone(400.0, 80.0, 0.14, "noise", 0.3)
	_sounds["hurt"] = _tone(220.0, 90.0, 0.25, "square", 0.22)
	_sounds["defeat"] = _tone(600.0, 60.0, 0.4, "noise", 0.3)
	_sounds["click"] = _tone(700.0, 700.0, 0.05, "square", 0.12)
	_sounds["checkpoint"] = _tone(500.0, 1000.0, 0.25, "sine", 0.3)
	_sounds["unlock"] = _tone(400.0, 1200.0, 0.45, "sine", 0.3)
	_sounds["win"] = _tone(500.0, 1500.0, 0.6, "square", 0.15)
	_sounds["lose"] = _tone(400.0, 100.0, 0.7, "square", 0.15)

	_music = AudioStreamPlayer.new()
	_music.stream = _make_music()
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	update_music()


func play(sound: String) -> void:
	if not Save.sound_on or not _sounds.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[sound]
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()


## Starts or stops the background tune to match Save.music_on.
func update_music() -> void:
	if Save.music_on and not _music.playing:
		_music.play()
	elif not Save.music_on and _music.playing:
		_music.stop()


func _tone(freq_start: float, freq_end: float, duration: float, wave: String, volume: float) -> AudioStreamWAV:
	var count := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += lerpf(freq_start, freq_end, t) / RATE
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"noise":
				s = randf_range(-1.0, 1.0)
			_:
				s = sin(phase * TAU)
		data.encode_s16(i * 2, int(s * volume * (1.0 - t) * 32767.0))
	return _wav(data, false)


## Calm minor-key arpeggio loop: Am - F - C - G, 2 s per chord.
func _make_music() -> AudioStreamWAV:
	var chords := [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
	var chord_len := 2.0
	var note_len := 0.25
	var total := int(chords.size() * chord_len * RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var lead_phase := 0.0
	var bass_phase := 0.0
	for i in total:
		var t := float(i) / RATE
		var chord: Array = chords[int(t / chord_len) % chords.size()]
		var step := int(t / note_len)
		var pattern := [0, 1, 2, 1]
		var note: int = chord[pattern[step % 4]] + 12
		var note_t := fmod(t, note_len) / note_len
		lead_phase += _midi_freq(note) / RATE
		bass_phase += _midi_freq(chord[0] - 12) / RATE
		var lead := (1.0 if fmod(lead_phase, 1.0) < 0.25 else -1.0) * 0.10 * (1.0 - note_t * 0.8)
		var tri := 4.0 * absf(fmod(bass_phase, 1.0) - 0.5) - 1.0
		var bass := tri * 0.22
		data.encode_s16(i * 2, int(clampf(lead + bass, -1.0, 1.0) * 32767.0))
	var wav := _wav(data, true)
	wav.loop_end = total
	return wav


static func _midi_freq(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


func _wav(data: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
	return wav
