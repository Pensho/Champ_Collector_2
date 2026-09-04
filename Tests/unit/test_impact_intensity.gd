extends GutTest

# Coverage for ImpactIntensity: the damage-to-magnitude curve behind Art_Style_Guide.md 6.3's
# impact feedback layer (squash, flash, screen shake). Pure static functions, no battle state
# involved.

func test_normalize_clamps_to_zero_and_one() -> void:
	assert_eq(ImpactIntensity.Normalize(0, 100), 0.0)
	assert_eq(ImpactIntensity.Normalize(50, 100), 0.5)
	assert_eq(ImpactIntensity.Normalize(100, 100), 1.0)
	assert_eq(ImpactIntensity.Normalize(500, 100), 1.0, "Overkill damage should clamp at 1.0.")

func test_normalize_is_zero_when_max_health_is_not_positive() -> void:
	assert_eq(ImpactIntensity.Normalize(10, 0), 0.0)
	assert_eq(ImpactIntensity.Normalize(10, -5), 0.0)

func test_squash_increases_monotonically_with_intensity() -> void:
	assert_eq(ImpactIntensity.SquashForIntensity(0.0), ImpactIntensity.MINIMUM_SQUASH)
	assert_eq(ImpactIntensity.SquashForIntensity(1.0), ImpactIntensity.MAXIMUM_SQUASH)
	assert_true(ImpactIntensity.SquashForIntensity(0.5) > ImpactIntensity.SquashForIntensity(0.1),
			"Squash should grow with intensity.")

func test_flash_always_plays_even_at_zero_intensity() -> void:
	# Chip damage still flashes; only shake has a floor.
	assert_true(ImpactIntensity.FlashSecondsForIntensity(0.0) > 0.0)
	assert_true(ImpactIntensity.FlashSecondsForIntensity(1.0) >= ImpactIntensity.FlashSecondsForIntensity(0.0))

func test_shake_is_zero_below_the_minimum_intensity() -> void:
	var below_floor: float = ImpactIntensity.MINIMUM_SHAKE_INTENSITY * 0.5
	assert_eq(ImpactIntensity.ShakeAmplitudeForIntensity(below_floor), 0.0)
	assert_eq(ImpactIntensity.ShakeSecondsForIntensity(below_floor), 0.0)

func test_shake_is_nonzero_and_bounded_at_and_above_the_minimum_intensity() -> void:
	for intensity in [ImpactIntensity.MINIMUM_SHAKE_INTENSITY, 0.5, 1.0]:
		var amplitude: float = ImpactIntensity.ShakeAmplitudeForIntensity(intensity)
		assert_true(amplitude >= ImpactIntensity.MINIMUM_SHAKE_AMPLITUDE and
				amplitude <= ImpactIntensity.MAXIMUM_SHAKE_AMPLITUDE,
				"Shake amplitude at intensity %f (%f) is out of bounds." % [intensity, amplitude])
		var shake_seconds: float = ImpactIntensity.ShakeSecondsForIntensity(intensity)
		assert_true(shake_seconds >= ImpactIntensity.MINIMUM_SHAKE_SECONDS and
				shake_seconds <= ImpactIntensity.MAXIMUM_SHAKE_SECONDS + 0.0001,
				"Shake duration at intensity %f (%f) is out of bounds." % [intensity, shake_seconds])
