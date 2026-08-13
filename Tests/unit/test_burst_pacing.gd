extends GutTest

# Coverage for BurstPacing: the escalation curve behind Concept_Document.md 1.1.5's cascade
# presentation (Technical_Design_Document.md 7.9). Pure static functions, no battle state
# involved.

const MAX_STEP: int = CascadeResolver.MAX_CASCADE_INSTANCES_PER_ACTION

func test_step_zero_is_the_unescalated_base_case() -> void:
	assert_almost_eq(BurstPacing.DelayForStep(0), BurstPacing.BASE_DELAY, 0.0001)
	assert_almost_eq(BurstPacing.ScaleForStep(0), BurstPacing.BASE_SCALE, 0.0001)
	assert_almost_eq(BurstPacing.OvershootForStep(0), BurstPacing.BASE_OVERSHOOT, 0.0001)
	var base_color: Color = Color(0.298, 0.565, 0.871, 1.0)
	assert_eq(BurstPacing.ColorForStep(base_color, 0), base_color)

func test_delay_decreases_strictly_until_it_holds_at_the_floor() -> void:
	var previous_delay: float = BurstPacing.DelayForStep(1)
	var reached_floor: bool = is_equal_approx(previous_delay, BurstPacing.MINIMUM_DELAY)
	for step in range(2, MAX_STEP + 1):
		var delay: float = BurstPacing.DelayForStep(step)
		if(reached_floor):
			assert_almost_eq(delay, BurstPacing.MINIMUM_DELAY, 0.0001,
					"Step %d should hold at the floor once reached." % step)
		else:
			assert_true(delay < previous_delay,
					"Step %d (%f) should be strictly less than step %d (%f) before the floor." %
							[step, delay, step - 1, previous_delay])
			reached_floor = is_equal_approx(delay, BurstPacing.MINIMUM_DELAY)
		previous_delay = delay
	assert_true(reached_floor, "The floor should be reached within MAX_STEP steps.")

func test_scale_increases_strictly_until_it_holds_at_the_maximum() -> void:
	var previous_scale: float = BurstPacing.ScaleForStep(1)
	var reached_maximum: bool = is_equal_approx(previous_scale, BurstPacing.MAXIMUM_SCALE)
	for step in range(2, MAX_STEP + 1):
		var scale: float = BurstPacing.ScaleForStep(step)
		if(reached_maximum):
			assert_almost_eq(scale, BurstPacing.MAXIMUM_SCALE, 0.0001,
					"Step %d should hold at the maximum once reached." % step)
		else:
			assert_true(scale > previous_scale,
					"Step %d (%f) should be strictly greater than step %d (%f) before the maximum." %
							[step, scale, step - 1, previous_scale])
			reached_maximum = is_equal_approx(scale, BurstPacing.MAXIMUM_SCALE)
		previous_scale = scale
	assert_true(reached_maximum, "The maximum should be reached within MAX_STEP steps.")

func test_overshoot_increases_strictly_or_holds_at_the_maximum() -> void:
	var previous_overshoot: float = BurstPacing.OvershootForStep(1)
	for step in range(2, MAX_STEP + 1):
		var overshoot: float = BurstPacing.OvershootForStep(step)
		var at_maximum: bool = is_equal_approx(previous_overshoot, BurstPacing.MAXIMUM_OVERSHOOT)
		if(at_maximum):
			assert_almost_eq(overshoot, BurstPacing.MAXIMUM_OVERSHOOT, 0.0001,
					"Step %d should hold at the maximum once reached." % step)
		else:
			assert_true(overshoot > previous_overshoot,
					"Step %d (%f) should be strictly greater than step %d (%f) before the maximum." %
							[step, overshoot, step - 1, previous_overshoot])
		previous_overshoot = overshoot

func test_color_is_exactly_red_at_and_beyond_the_full_red_step() -> void:
	var base_colors: Array[Color] = [Color.WHITE, Color(1.0, 0.45, 0.1, 1.0), Color(0.6, 0.6, 0.6, 1.0)]
	for base_color in base_colors:
		for step in range(BurstPacing.FULL_RED_STEP, MAX_STEP + 1):
			assert_eq(BurstPacing.ColorForStep(base_color, step), Color.RED,
					"Step %d should be exactly red regardless of the base color." % step)

func test_no_function_returns_an_out_of_bounds_value_across_the_full_step_range() -> void:
	for step in range(0, MAX_STEP + 1):
		var delay: float = BurstPacing.DelayForStep(step)
		assert_true(delay >= BurstPacing.MINIMUM_DELAY and delay <= BurstPacing.BASE_DELAY,
				"Delay at step %d (%f) is out of bounds." % [step, delay])
		var scale: float = BurstPacing.ScaleForStep(step)
		assert_true(scale >= BurstPacing.BASE_SCALE and scale <= BurstPacing.MAXIMUM_SCALE,
				"Scale at step %d (%f) is out of bounds." % [step, scale])
		var overshoot: float = BurstPacing.OvershootForStep(step)
		assert_true(overshoot > BurstPacing.BASE_SCALE and overshoot <= BurstPacing.MAXIMUM_OVERSHOOT,
				"Overshoot at step %d (%f) is out of bounds." % [step, overshoot])
		var color: Color = BurstPacing.ColorForStep(Color.WHITE, step)
		assert_true(color.r <= 1.0 and color.g >= 0.0 and color.g <= 1.0 and color.b >= 0.0 and color.b <= 1.0,
				"Color at step %d (%s) is out of bounds." % [step, color])

func test_summed_delay_across_a_full_fan_out_cascade_stays_under_the_presentation_cap() -> void:
	var total_delay: float = 0.0
	for step in range(1, MAX_STEP + 1):
		total_delay += BurstPacing.DelayForStep(step)
	assert_true(total_delay < 2.0,
			"Summed delay across a full cascade (%f) should stay under the two-second cap, " %
					total_delay + "so the cap remains a safety valve rather than the normal exit path.")
