extends GutTest

# Coverage for CharacterSpriteAnimator: the idle bob, hit reaction, lunge and death
# transform layer behind Art_Style_Guide.md 6.3. Built directly (not via the packed scene)
# with its own pivot/sprite nodes, following the add_child_autofree + wait_seconds pattern
# used for DamageTrailBar.

var _animator: CharacterSpriteAnimator
var _pivot: Node2D
var _sprite: TextureRect
var _silhouette_outline: TextureRect

func before_each() -> void:
	_pivot = Node2D.new()
	_sprite = TextureRect.new()
	_pivot.add_child(_sprite)
	_silhouette_outline = TextureRect.new()
	_sprite.add_child(_silhouette_outline)
	_animator = CharacterSpriteAnimator.new()
	_animator._pivot = _pivot
	_animator._sprite = _sprite
	_animator._silhouette_outline = _silhouette_outline
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

func test_base_scale_persists_across_frames() -> void:
	_animator.SetIdleEnabled(false)
	_animator.SetBaseScale(Vector2(1.5, 1.5))
	await wait_frames(2)
	assert_eq(_sprite.scale, Vector2(1.5, 1.5))

func test_impact_returns_to_the_base_scale_once_it_settles() -> void:
	_animator.SetIdleEnabled(false)
	_animator.SetBaseScale(Vector2(2.0, 2.0))
	_animator.PlayImpact(1.0, 1.0)
	await wait_frames(2)
	assert_true(_sprite.scale.y > 2.0, "The stretch should apply on top of the base scale.")
	await wait_seconds(0.3)
	assert_almost_eq(_sprite.scale.x, 2.0, 0.001)
	assert_almost_eq(_sprite.scale.y, 2.0, 0.001)

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

func test_silhouette_outline_follows_the_sprite_texture_and_flip() -> void:
	_sprite.size = Vector2(100, 100)
	_sprite.texture = _MakeTexture(400)
	_sprite.flip_h = true
	_animator.SyncSilhouetteOutline()
	assert_eq(_silhouette_outline.texture, _sprite.texture)
	assert_true(_silhouette_outline.flip_h)
	var expected_texels: float = _animator._silhouette_outline_width_pixels * 4.0
	assert_almost_eq(_silhouette_outline.material.get_shader_parameter("outline_width_texels"),
			expected_texels, 0.001)

func test_silhouette_outline_hides_while_the_target_outline_shows() -> void:
	_sprite.size = Vector2(100, 100)
	_sprite.texture = _MakeTexture(100)
	_animator.SetTargetOutline(true)
	assert_false(_silhouette_outline.visible)
	_animator.SetTargetOutline(false)
	assert_true(_silhouette_outline.visible)

func test_silhouette_outline_fades_on_death_and_returns_on_revive() -> void:
	_animator.PlayDeath()
	await wait_seconds(CharacterSpriteAnimator.DEATH_SECONDS + 0.05)
	assert_almost_eq(_silhouette_outline.modulate.a, 0.0, 0.001)
	_animator.Revive()
	assert_eq(_silhouette_outline.modulate.a, 1.0)

func _MakeTexture(p_width: int) -> ImageTexture:
	return ImageTexture.create_from_image(Image.create(p_width, p_width, false, Image.FORMAT_RGBA8))

func IDLE_PERIOD() -> float:
	return CharacterSpriteAnimator.IDLE_PERIOD_SECONDS
