extends GutTest

var _bar: DamageTrailBar

func before_each() -> void:
	_bar = DamageTrailBar.new()
	_bar.max_value = 100
	_bar.value = 100
	add_child_autofree(_bar)

func test_follow_holds_value_during_hold_window() -> void:
	_bar.Follow(60)
	await wait_seconds(0.2)
	assert_eq(_bar.value, 100.0)

func test_follow_drains_to_target_after_hold_and_drain() -> void:
	_bar.Follow(60)
	await wait_seconds(1.2)
	assert_eq(_bar.value, 60.0)

func test_cascade_of_hits_merges_into_one_drain() -> void:
	_bar.Follow(80)
	await wait_seconds(0.3)
	_bar.Follow(50)
	await wait_seconds(0.3)
	# Original hold would have expired by now had it not been restarted by the second hit.
	assert_eq(_bar.value, 100.0)
	await wait_seconds(1.2)
	assert_eq(_bar.value, 50.0)

func test_follow_with_higher_health_snaps_immediately() -> void:
	_bar.value = 40
	_bar.Follow(70)
	assert_eq(_bar.value, 70.0)

func test_snap_to_sets_value_with_no_pending_tween() -> void:
	_bar.Follow(60)
	_bar.SnapTo(90)
	assert_eq(_bar.value, 90.0)
	await wait_seconds(0.9)
	assert_eq(_bar.value, 90.0)
