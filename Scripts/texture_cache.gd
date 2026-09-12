class_name TextureCache extends RefCounted

static var _cache: Dictionary[String, Texture] = {}
static var _headshot_cache: Dictionary[String, Texture] = {}

static func Get(p_path: String) -> Texture:
	if(!_cache.has(p_path)):
		_cache[p_path] = load(p_path)
	return _cache[p_path]

## Converts a normalized (0-1) region into pixel coordinates, clamped to an image of
## p_size. Always returns a rectangle of at least one pixel inside those bounds.
static func NormalizedRegionToPixels(p_region: Rect2, p_size: Vector2i) -> Rect2i:
	var region: Rect2 = p_region.abs()
	var left: int = clampi(roundi(region.position.x * p_size.x), 0, p_size.x - 1)
	var top: int = clampi(roundi(region.position.y * p_size.y), 0, p_size.y - 1)
	var width: int = clampi(roundi(region.size.x * p_size.x), 1, p_size.x - left)
	var height: int = clampi(roundi(region.size.y * p_size.y), 1, p_size.y - top)
	return Rect2i(left, top, width, height)

## Returns the p_region sub-rectangle of the texture at p_path, baked into its own
## texture so it still spans the full 0-1 UV range of whatever draws it.
static func GetHeadshot(p_path: String, p_region: Rect2) -> Texture:
	var source: Texture2D = Get(p_path) as Texture2D
	if(source == null):
		return null

	var source_size: Vector2i = Vector2i(source.get_size())
	var pixel_region: Rect2i = NormalizedRegionToPixels(p_region, source_size)
	if(pixel_region == Rect2i(Vector2i.ZERO, source_size)):
		return source

	var key: String = "%s:%s" % [p_path, pixel_region]
	if(!_headshot_cache.has(key)):
		var image: Image = source.get_image()
		if(image == null):
			push_error("Cannot crop a headshot from '%s': the texture has no readable image." % p_path)
			return source
		_headshot_cache[key] = ImageTexture.create_from_image(image.get_region(pixel_region))
	return _headshot_cache[key]
