extends GutTest

# Coverage for CharacterSpriteAnimator: the idle bob, hit reaction, lunge and death
# transform layer behind Art_Style_Guide.md 6.3. Built directly (not via the packed scene)
# with its own pivot/sprite nodes, following the add_child_autofree + wait_seconds pattern
# used for DamageTrailBar.

var _animator: CharacterSpriteAnimator
var _pivot: Node2D
var _sprite: TextureRect

func before_each() -> void:
	_pivot = Node2D.new()
	_sprite = TextureRect.new()
	_pivot.add_child(_sprite)
	_animator = CharacterSpriteAnimator.new()
	_animator._pivot = _pivot
	_animator._sprite = _sprite
	_animator.add_child(_pivot)
	add_child_autofree(_animator)

func test_idle_bob_stretches_only_vertically_from_the_foot_pivot() -> void:
	await wait_seconds(IDLE_PERIOD() * 1.1)
	# The pivot itself never moves for idle: only the sprite's own vertical scale bobs, anchored
	# at its pivot_offset (the feet), so the feet never lift off the ground line.
	assert_eq(_pivot.position, Vector2.ZERO)
	assert_almost_eq(_sprite.scale.x, 1.0, 0.001)
	assert_true(_sprite.scale.y >= 1.0 and
			_sprite.scale.y <= 1.0 + CharacterSpriteAnimator.IDLE_SCALE_AMOUNT + 0.001)

func test_disabling_idle_settles_the_pivot_at_the_origin() -> void:
	_animator.SetIdleEnabled(false)
	await wait_frames(2)
	assert_eq(_pivot.position, Vector2.ZERO)
	assert_eq(_sprite.scale, Vector2.ONE)

func test_impact_grows_taller_and_knocks_back_then_returns_to_base() -> void:
	_animator.SetIdleEnabled(false)
	_animator.PlayImpact(1.0, 1.0)
	await wait_frames(2)
	assert_true(_sprite.scale.y > 1.0, "The stretch should grow the sprite taller mid-reaction.")
	assert_true(_pivot.position.x > 0.0, "A positive-direction impact should knock back toward +x.")
	await wait_seconds(0.3)
	assert_eq(_pivot.position, Vector2.ZERO)
	assert_almost_eq(_sprite.scale.x, 1.0, 0.001)
	assert_almost_eq(_sprite.scale.y, 1.0, 0.001)

func test_lunge_returns_to_the_base_position_once_it_settles() -> void:
	_animator.SetIdleEnabled(false)
	_animator.PlayLunge(1.0)
	await wait_frames(2)
	assert_true(_pivot.position.x > 0.0, "A positive-direction lunge should move right mid-reaction.")
	await wait_seconds(0.4)
	assert_eq(_pivot.position, Vector2.ZERO)

func test_overlapping_reactions_leave_no_residual_offset() -> void:
	_animator.SetIdleEnabled(false)
	_animator.PlayImpact(1.0, 1.0)
	await wait_seconds(0.02)
	_animator.PlayLunge(-1.0)
	await wait_seconds(0.4)
	assert_eq(_pivot.position, Vector2.ZERO)
	assert_almost_eq(_sprite.scale.x, 1.0, 0.001)
	assert_almost_eq(_sprite.scale.y, 1.0, 0.001)

func test_death_stops_idle_bob() -> void:
	_animator.PlayDeath()
	await wait_seconds(CharacterSpriteAnimator.DEATH_SECONDS + 0.05)
	var scale_after_death_settles: Vector2 = _sprite.scale
	await wait_seconds(IDLE_PERIOD())
	# Idle contributes nothing once dead: scale should not have moved again after death settled.
	assert_eq(_sprite.scale, scale_after_death_settles)

func test_revive_after_death_re_enables_idle_bob() -> void:
	_animator.PlayDeath()
	await wait_seconds(CharacterSpriteAnimator.DEATH_SECONDS + 0.05)
	_animator.Revive()
	await wait_seconds(IDLE_PERIOD() * 1.1)
	assert_eq(_pivot.position, Vector2.ZERO)
	assert_true(_sprite.scale.y >= 1.0 and
			_sprite.scale.y <= 1.0 + CharacterSpriteAnimator.IDLE_SCALE_AMOUNT + 0.001)

func IDLE_PERIOD() -> float:
	return CharacterSpriteAnimator.IDLE_PERIOD_SECONDS
