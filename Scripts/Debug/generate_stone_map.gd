extends SceneTree

## Bakes the stone map that adventure_ground_paved.gdshader reads to drop stones out whole.
## Segments a seamless stone tile on its dark grout, then writes per pixel:
## R,G = centre of the pixel's stone in tile UV (identical across the stone; wraps over the
## tile edge), B = distance to grout (1 in a stone's interior, 0 on grout).
## Grout pixels join their nearest stone.
##
## Run headless:
##   godot --headless -s res://Scripts/Debug/generate_stone_map.gd -- \
##     <source_image> <stone_map_out.png> [grout_threshold=0.17] [erode_passes=1] [debug_out.png]
## Raise grout_threshold or erode_passes when two stones merge; check with the debug image,
## which colours each detected stone and darkens its grout.

const MINIMUM_STONE_PIXELS: int = 30
const EDGE_FALLOFF_PIXELS: float = 3.0
const UNLABELED: int = -1
const DISCARDED: int = -2

var _width: int
var _height: int

func _init() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() < 2:
		push_error("Usage: -- <source_image> <stone_map_out.png> [grout_threshold] [erode_passes] [debug_out.png]")
		quit(1)
		return
	var source := Image.load_from_file(arguments[0])
	var grout_threshold: float = float(arguments[2]) if arguments.size() > 2 else 0.17
	var erode_passes: int = int(arguments[3]) if arguments.size() > 3 else 1
	_width = source.get_width()
	_height = source.get_height()

	var stone_mask: PackedByteArray = StoneMask(source, grout_threshold)
	for pass_index in erode_passes:
		stone_mask = Erode(stone_mask)
	var stone_labels: PackedInt32Array = LabelStones(stone_mask)
	var stone_count: int = 0
	for label in stone_labels:
		stone_count = maxi(stone_count, label + 1)
	var pixel_labels: PackedInt32Array = GrowLabels(stone_labels)
	var grout_distance: PackedFloat32Array = GroutDistance(stone_labels)
	var centres: Array[Vector2] = StoneCentres(pixel_labels, stone_count)

	var stone_map := Image.create(_width, _height, false, Image.FORMAT_RGB8)
	for index in pixel_labels.size():
		var centre: Vector2 = centres[pixel_labels[index]]
		var edge: float = clampf(grout_distance[index] / EDGE_FALLOFF_PIXELS, 0.0, 1.0)
		stone_map.set_pixel(index % _width, index / _width, Color(centre.x, centre.y, edge))
	stone_map.save_png(arguments[1])
	if arguments.size() > 4:
		SaveDebugImage(arguments[4], stone_labels, pixel_labels, stone_count)
	print("Stones found: %d" % stone_count)
	quit()

## 1 where the 3x3-blurred luminance is above the grout threshold.
func StoneMask(p_source: Image, p_grout_threshold: float) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(_width * _height)
	for y in _height:
		for x in _width:
			var total: float = 0.0
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					total += p_source.get_pixel(
						posmod(x + offset_x, _width), posmod(y + offset_y, _height)).get_luminance()
			mask[y * _width + x] = 1 if total / 9.0 > p_grout_threshold else 0
	return mask

func Erode(p_mask: PackedByteArray) -> PackedByteArray:
	var eroded := p_mask.duplicate()
	for index in p_mask.size():
		if p_mask[index] == 0:
			continue
		for neighbour in Neighbours(index):
			if p_mask[neighbour] == 0:
				eroded[index] = 0
				break
	return eroded

## Connected stone regions, wrapping over the tile edge; specks below MINIMUM_STONE_PIXELS
## are left UNLABELED so they count as grout.
func LabelStones(p_mask: PackedByteArray) -> PackedInt32Array:
	var labels := PackedInt32Array()
	labels.resize(_width * _height)
	labels.fill(UNLABELED)
	var next_label: int = 0
	for start in labels.size():
		if p_mask[start] == 0 or labels[start] != UNLABELED:
			continue
		var component: Array[int] = [start]
		labels[start] = next_label
		var cursor: int = 0
		while cursor < component.size():
			for neighbour in Neighbours(component[cursor]):
				if p_mask[neighbour] == 1 and labels[neighbour] == UNLABELED:
					labels[neighbour] = next_label
					component.append(neighbour)
			cursor += 1
		if component.size() < MINIMUM_STONE_PIXELS:
			for index in component:
				labels[index] = DISCARDED
		else:
			next_label += 1
	for index in labels.size():
		if labels[index] == DISCARDED:
			labels[index] = UNLABELED
	return labels

## Every unlabeled pixel takes the label of its nearest stone (breadth-first growth).
func GrowLabels(p_stone_labels: PackedInt32Array) -> PackedInt32Array:
	var labels := p_stone_labels.duplicate()
	var frontier: Array[int] = []
	for index in labels.size():
		if labels[index] != UNLABELED:
			frontier.append(index)
	while not frontier.is_empty():
		var next_frontier: Array[int] = []
		for index in frontier:
			for neighbour in Neighbours(index):
				if labels[neighbour] == UNLABELED:
					labels[neighbour] = labels[index]
					next_frontier.append(neighbour)
		frontier = next_frontier
	return labels

## Steps from each pixel to the nearest grout pixel; 0 on grout.
func GroutDistance(p_stone_labels: PackedInt32Array) -> PackedFloat32Array:
	var distance := PackedFloat32Array()
	distance.resize(_width * _height)
	distance.fill(-1.0)
	var frontier: Array[int] = []
	for index in p_stone_labels.size():
		if p_stone_labels[index] == UNLABELED:
			distance[index] = 0.0
			frontier.append(index)
	var step: float = 0.0
	while not frontier.is_empty():
		step += 1.0
		var next_frontier: Array[int] = []
		for index in frontier:
			for neighbour in Neighbours(index):
				if distance[neighbour] < 0.0:
					distance[neighbour] = step
					next_frontier.append(neighbour)
		frontier = next_frontier
	return distance

## Centre of each stone in tile UV. A circular mean per axis keeps a stone that wraps over
## the tile edge centred on itself instead of on the middle of the tile.
func StoneCentres(p_pixel_labels: PackedInt32Array, p_stone_count: int) -> Array[Vector2]:
	var sums: Array[Vector4] = []
	sums.resize(p_stone_count)
	sums.fill(Vector4.ZERO)
	for index in p_pixel_labels.size():
		var angle_x: float = TAU * (index % _width) / _width
		var angle_y: float = TAU * (index / _width) / _height
		sums[p_pixel_labels[index]] += Vector4(cos(angle_x), sin(angle_x), cos(angle_y), sin(angle_y))
	var centres: Array[Vector2] = []
	for sum in sums:
		centres.append(Vector2(
			fposmod(atan2(sum.y, sum.x), TAU) / TAU,
			fposmod(atan2(sum.w, sum.z), TAU) / TAU))
	return centres

func SaveDebugImage(
	p_path: String, p_stone_labels: PackedInt32Array,
	p_pixel_labels: PackedInt32Array, p_stone_count: int
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var colours: Array[Color] = []
	for stone in p_stone_count:
		colours.append(Color.from_hsv(rng.randf(), 0.6, 0.9))
	var debug_image := Image.create(_width, _height, false, Image.FORMAT_RGB8)
	for index in p_pixel_labels.size():
		var colour: Color = colours[p_pixel_labels[index]]
		if p_stone_labels[index] == UNLABELED:
			colour = colour.darkened(0.7)
		debug_image.set_pixel(index % _width, index / _width, colour)
	debug_image.save_png(p_path)

func Neighbours(p_index: int) -> Array[int]:
	var x: int = p_index % _width
	var y: int = p_index / _width
	return [
		y * _width + posmod(x + 1, _width), y * _width + posmod(x - 1, _width),
		posmod(y + 1, _height) * _width + x, posmod(y - 1, _height) * _width + x]
