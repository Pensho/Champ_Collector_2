class_name AudioHandler extends Node

const POOL_SIZE: int = 16
const SILENT_VOLUME_DB: float = -80.0
const MUSIC_BUS: StringName = &"Music"

var _players: Array[AudioStreamPlayer] = []
var _player_cues: Array[SoundCue] = []
var _player_looping: Array[bool] = []
var _player_start_times: Array[float] = []
var _player_handles: Array[int] = []
var _player_tweens: Array[Tween] = []
var _last_start_by_cue: Dictionary[SoundCue, float] = {}
var _next_handle: int = 0

var _music_players: Array[AudioStreamPlayer] = []
var _music_tweens: Array[Tween] = [null, null]
var _active_music_index: int = 0
var _music_track: AudioStream = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index: int in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.finished.connect(_on_player_finished.bind(index))
		add_child(player)
		_players.append(player)
		_player_cues.append(null)
		_player_looping.append(false)
		_player_start_times.append(0.0)
		_player_handles.append(-1)
		_player_tweens.append(null)
	for index: int in 2:
		var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
		music_player.bus = MUSIC_BUS
		add_child(music_player)
		_music_players.append(music_player)

func Play(p_cue: SoundCue, p_pitch_scale: float = 1.0) -> void:
	_Start(p_cue, p_pitch_scale, false)

func PlayLoop(p_cue: SoundCue) -> int:
	var index: int = _Start(p_cue, 1.0, true)
	if index < 0:
		return -1
	_player_handles[index] = _next_handle
	_next_handle += 1
	return _player_handles[index]

func StopLoop(p_handle: int, p_fade_seconds: float = 0.0) -> void:
	if p_handle < 0:
		return
	var index: int = _player_handles.find(p_handle)
	if index < 0:
		return
	_player_handles[index] = -1
	_player_looping[index] = false
	_FadeOutAndStop(_players[index], _player_tweens, index, p_fade_seconds)

func PlayMusic(p_track: AudioStream, p_fade_seconds: float) -> void:
	if p_track == _music_track:
		return
	_music_track = p_track
	_FadeOutAndStop(_music_players[_active_music_index], _music_tweens, _active_music_index, p_fade_seconds)
	if p_track == null:
		return
	_active_music_index = 1 - _active_music_index
	var incoming: AudioStreamPlayer = _music_players[_active_music_index]
	_KillTween(_music_tweens, _active_music_index)
	incoming.stream = p_track
	incoming.volume_db = SILENT_VOLUME_DB if p_fade_seconds > 0.0 else 0.0
	incoming.play()
	if p_fade_seconds > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(incoming, "volume_db", 0.0, p_fade_seconds)
		_music_tweens[_active_music_index] = tween

func _Start(p_cue: SoundCue, p_pitch_scale: float, p_looping: bool) -> int:
	if p_cue == null or p_cue.stream == null:
		return -1
	var now: float = _Now()
	var seconds_since_last_start: float = now - _last_start_by_cue.get(p_cue, -INF)
	if not SoundPlaybackRules.ShouldPlay(p_cue, _ActiveCount(p_cue), seconds_since_last_start):
		return -1
	var busy: Array[bool] = []
	for player: AudioStreamPlayer in _players:
		busy.append(player.playing)
	var index: int = SoundPlaybackRules.ChoosePlayer(busy, _player_looping, _player_start_times)
	if index < 0:
		return -1
	var player: AudioStreamPlayer = _players[index]
	_KillTween(_player_tweens, index)
	player.stop()
	player.stream = p_cue.stream
	player.bus = p_cue.bus
	player.volume_db = p_cue.volume_db
	player.pitch_scale = p_pitch_scale
	player.play()
	_player_cues[index] = p_cue
	_player_looping[index] = p_looping
	_player_start_times[index] = now
	_player_handles[index] = -1
	_last_start_by_cue[p_cue] = now
	return index

func _ActiveCount(p_cue: SoundCue) -> int:
	var count: int = 0
	for index: int in _players.size():
		if _players[index].playing and _player_cues[index] == p_cue:
			count += 1
	return count

func _FadeOutAndStop(p_player: AudioStreamPlayer, p_tweens: Array[Tween], p_index: int, p_fade_seconds: float) -> void:
	_KillTween(p_tweens, p_index)
	if not p_player.playing or p_fade_seconds <= 0.0:
		p_player.stop()
		return
	var tween: Tween = create_tween()
	tween.tween_property(p_player, "volume_db", SILENT_VOLUME_DB, p_fade_seconds)
	tween.tween_callback(p_player.stop)
	p_tweens[p_index] = tween

func _KillTween(p_tweens: Array[Tween], p_index: int) -> void:
	if p_tweens[p_index] != null:
		p_tweens[p_index].kill()
		p_tweens[p_index] = null

func _Now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _on_player_finished(p_index: int) -> void:
	# A loop survives a stream that was not imported as looping.
	if _player_looping[p_index]:
		_players[p_index].play()
