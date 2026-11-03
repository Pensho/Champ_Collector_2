extends GutTest

# CharacterVisualEffects.ScaledSpritePoint places trait props on the sprite box, scaled around the
# sprite's pivot by the art scale alone.

const PIVOT: Vector2 = Vector2(125.0, 250.0)
const SIZE: Vector2 = Vector2(250.0, 250.0)

func test_at_unit_scale_the_point_is_the_fraction_plus_the_offset() -> void:
	var point: Vector2 = CharacterVisualEffects.ScaledSpritePoint(
			PIVOT, SIZE, Vector2.ONE, Vector2(1.0, 0.5), Vector2(30.0, 0.0))
	assert_eq(point, Vector2(280.0, 125.0))

func test_the_art_scale_grows_the_point_away_from_the_pivot() -> void:
	var point: Vector2 = CharacterVisualEffects.ScaledSpritePoint(
			PIVOT, SIZE, Vector2(2.0, 2.0), Vector2(0.0, 0.5), Vector2(-30.0, 0.0))
	assert_eq(point, Vector2(-185.0, 0.0))

func test_the_pivot_itself_never_moves() -> void:
	var point: Vector2 = CharacterVisualEffects.ScaledSpritePoint(
			PIVOT, SIZE, Vector2(1.4, 1.4), Vector2(0.5, 1.0), Vector2.ZERO)
	assert_eq(point, PIVOT)
