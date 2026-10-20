extends GutTest

var _cue: SoundCue

func before_each() -> void:
	_cue = SoundCue.new()

func test_unlimited_cue_plays_regardless_of_active_count() -> void:
	assert_true(SoundPlaybackRules.ShouldPlay(_cue, 50, INF), "A maximum of 0 should never limit the cue.")

func test_cue_below_its_limit_plays() -> void:
	_cue.maximum_simultaneous = 2
	assert_true(SoundPlaybackRules.ShouldPlay(_cue, 1, INF), "One active instance is below a limit of 2.")

func test_cue_at_its_limit_is_dropped() -> void:
	_cue.maximum_simultaneous = 2
	assert_false(SoundPlaybackRules.ShouldPlay(_cue, 2, INF), "A request beyond the limit should be dropped.")

func test_cue_inside_its_interval_is_dropped() -> void:
	_cue.minimum_interval = 0.1
	assert_false(SoundPlaybackRules.ShouldPlay(_cue, 0, 0.05),
		"A request sooner than the interval should be dropped.")

func test_cue_after_its_interval_plays() -> void:
	_cue.minimum_interval = 0.1
	assert_true(SoundPlaybackRules.ShouldPlay(_cue, 0, 0.1), "A request at the interval should play.")

func test_choose_player_prefers_first_idle() -> void:
	var busy: Array[bool] = [true, false, false]
	var looping: Array[bool] = [false, false, false]
	var start_times: Array[float] = [0.0, 0.0, 0.0]
	assert_eq(SoundPlaybackRules.ChoosePlayer(busy, looping, start_times), 1,
		"The first idle player should be chosen.")

func test_choose_player_steals_oldest_when_none_idle() -> void:
	var busy: Array[bool] = [true, true, true]
	var looping: Array[bool] = [false, false, false]
	var start_times: Array[float] = [3.0, 1.0, 2.0]
	assert_eq(SoundPlaybackRules.ChoosePlayer(busy, looping, start_times), 1,
		"With none idle, the oldest player should be stolen.")

func test_choose_player_never_steals_a_loop() -> void:
	var busy: Array[bool] = [true, true, true]
	var looping: Array[bool] = [true, false, false]
	var start_times: Array[float] = [0.0, 2.0, 1.0]
	assert_eq(SoundPlaybackRules.ChoosePlayer(busy, looping, start_times), 2,
		"The oldest looping player should be skipped.")

func test_choose_player_refuses_when_every_player_loops() -> void:
	var busy: Array[bool] = [true, true]
	var looping: Array[bool] = [true, true]
	var start_times: Array[float] = [0.0, 1.0]
	assert_eq(SoundPlaybackRules.ChoosePlayer(busy, looping, start_times), -1,
		"With every player looping, nothing should be chosen.")
