class_name TextureCache extends RefCounted

static var _cache: Dictionary[String, Texture] = {}

static func Get(p_path: String) -> Texture:
	if(!_cache.has(p_path)):
		_cache[p_path] = load(p_path)
	return _cache[p_path]
