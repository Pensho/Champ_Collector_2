extends GutTest

# Direct coverage for the two ordered turn-bar queries (TurnBar.GetCharactersBehindOrdered,
# TurnBar.GetCharactersByProximityOrdered), built for Caravan Cadence / Contagion Bond.
# Bypasses Init() (which needs a populated character dictionary and a themed scene); markers
# are hand-placed TextureRects, matching how the unordered siblings are exercised only
# indirectly today but giving the new sort logic direct regression coverage.

var _bar: TurnBar = null

func before_each() -> void:
	_bar = TurnBar.new()
	_bar.size = Vector2(1000.0, 100.0)
	var markers: Array[TextureRect] = []
	for i in 4:
		var marker: TextureRect = TextureRect.new()
		markers.append(marker)
	_bar._character_turn_markers = markers

func _place(p_ID: int, p_x: float) -> void:
	_bar._character_turn_markers[p_ID].position.x = p_x

func test_behind_ordered_returns_furthest_behind_first() -> void:
	_place(0, 800.0)
	_place(1, 200.0)
	_place(2, 500.0)
	_place(3, 0.0)

	assert_eq(_bar.GetCharactersBehindOrdered(0), [3, 1, 2],
			"Characters behind the owner should be ordered furthest-behind first")

func test_behind_ordered_excludes_owner_and_anyone_ahead() -> void:
	_place(0, 500.0)
	_place(1, 500.0)
	_place(2, 900.0)
	_place(3, 100.0)

	assert_eq(_bar.GetCharactersBehindOrdered(0), [3],
			"A tied marker and one ahead of the owner should both be excluded")

func test_proximity_ordered_returns_nearest_first_both_directions() -> void:
	_place(0, 500.0)
	_place(1, 700.0)
	_place(2, 550.0)
	_place(3, 100.0)

	assert_eq(_bar.GetCharactersByProximityOrdered(0, 0.30), [2, 1],
			"Only characters within the window should return, nearest first regardless of direction")

func test_proximity_ordered_respects_the_window_bound() -> void:
	_place(0, 500.0)
	_place(1, 900.0)

	assert_eq(_bar.GetCharactersByProximityOrdered(0, 0.10), [],
			"A character outside the window should not be returned")

func test_proximity_ordered_rejects_out_of_range_percent() -> void:
	_place(0, 500.0)
	_place(1, 550.0)

	assert_eq(_bar.GetCharactersByProximityOrdered(0, 1.5), [],
			"An out-of-range percent should return an empty array, matching the sibling queries")
