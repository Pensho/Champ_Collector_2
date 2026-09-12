extends GutTest

const KNIGHT_TEXTURE_PATH: String = "res://Assets/Champ_Collector/Creatures/Knight/Knight_0004.png"
const FULL_REGION: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)

func test_full_region_covers_the_whole_image() -> void:
	assert_eq(TextureCache.NormalizedRegionToPixels(FULL_REGION, Vector2i(200, 200)),
		Rect2i(0, 0, 200, 200), "A 0-1 region should map to the entire image.")
	assert_eq(TextureCache.NormalizedRegionToPixels(FULL_REGION, Vector2i(128, 128)),
		Rect2i(0, 0, 128, 128), "The whole image regardless of source resolution.")

func test_same_region_scales_with_the_source_resolution() -> void:
	var region: Rect2 = Rect2(0.25, 0.1, 0.5, 0.5)
	assert_eq(TextureCache.NormalizedRegionToPixels(region, Vector2i(200, 200)),
		Rect2i(50, 20, 100, 100), "Normalized coordinates should scale to a 200px source.")
	assert_eq(TextureCache.NormalizedRegionToPixels(region, Vector2i(1024, 1024)),
		Rect2i(256, 102, 512, 512), "The same region should hold on a 1024px source.")

func test_non_square_source_scales_each_axis_separately() -> void:
	assert_eq(TextureCache.NormalizedRegionToPixels(Rect2(0.5, 0.0, 0.5, 0.25), Vector2i(120, 80)),
		Rect2i(60, 0, 60, 20), "Each axis should scale by its own dimension.")

func test_oversized_region_is_clamped_inside_the_image() -> void:
	assert_eq(TextureCache.NormalizedRegionToPixels(Rect2(0.5, 0.5, 2.0, 2.0), Vector2i(200, 200)),
		Rect2i(100, 100, 100, 100), "A region running past the edge should stop at it.")
	assert_eq(TextureCache.NormalizedRegionToPixels(Rect2(-1.0, -1.0, 1.0, 1.0), Vector2i(200, 200)),
		Rect2i(0, 0, 200, 200), "A region starting before the origin should start at it.")

func test_degenerate_region_still_yields_at_least_one_pixel() -> void:
	assert_eq(TextureCache.NormalizedRegionToPixels(Rect2(0.0, 0.0, 0.0, 0.0), Vector2i(200, 200)),
		Rect2i(0, 0, 1, 1), "A zero-size region should not produce an empty rectangle.")
	assert_eq(TextureCache.NormalizedRegionToPixels(Rect2(1.0, 1.0, 0.5, 0.5), Vector2i(200, 200)),
		Rect2i(199, 199, 1, 1), "A region beyond the far edge should collapse onto the last pixel.")

func test_inverted_region_is_normalized_before_conversion() -> void:
	assert_eq(TextureCache.NormalizedRegionToPixels(Rect2(0.75, 0.75, -0.5, -0.5), Vector2i(200, 200)),
		Rect2i(50, 50, 100, 100), "A negative size should describe the same rectangle.")

func test_full_region_reuses_the_uncropped_texture() -> void:
	assert_same(TextureCache.GetHeadshot(KNIGHT_TEXTURE_PATH, FULL_REGION),
		TextureCache.Get(KNIGHT_TEXTURE_PATH), "An uncropped headshot should not copy the image.")

func test_cropped_headshot_is_cached_and_sized_to_the_region() -> void:
	var region: Rect2 = Rect2(0.25, 0.1, 0.5, 0.5)
	var headshot: Texture2D = TextureCache.GetHeadshot(KNIGHT_TEXTURE_PATH, region) as Texture2D
	var source: Texture2D = TextureCache.Get(KNIGHT_TEXTURE_PATH) as Texture2D
	var expected: Rect2i = TextureCache.NormalizedRegionToPixels(region, Vector2i(source.get_size()))

	assert_eq(Vector2i(headshot.get_size()), expected.size,
		"The cropped texture should be exactly the region's pixel size.")
	assert_same(TextureCache.GetHeadshot(KNIGHT_TEXTURE_PATH, region), headshot,
		"Repeating the same path and region should hit the cache.")

func test_collection_serves_the_headshot_region_of_the_collected_preset() -> void:
	var preset: CharacterPreset = load("res://Data/Character_Player_Variants/Knight.tres").duplicate(true)
	preset._headshot_region = Rect2(0.25, 0.05, 0.5, 0.5)
	var collection: CharacterCollection = autofree(CharacterCollection.new())
	collection.Add(preset)

	var full: Texture2D = collection.GetCharacterTexture(preset._name) as Texture2D
	var headshot: Texture2D = collection.GetCharacterHeadshotTexture(preset._name) as Texture2D
	var expected: Rect2i = TextureCache.NormalizedRegionToPixels(
			preset._headshot_region, Vector2i(full.get_size()))

	assert_eq(Vector2i(headshot.get_size()), expected.size,
		"The collection should crop to the preset's region, not serve the full figure.")
	assert_same(TextureCache.GetHeadshot(preset._texture, preset._headshot_region), headshot,
		"A preset-driven caller should get the same cached crop as the collection.")
