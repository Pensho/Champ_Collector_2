class_name StructureLayoutOverlay extends Control

## Development overlay for the background preview: outlines a StructureLayout's lots
## (tinted by region) and plazas, following the map canvas as it scrolls.

const PLAZA_COLOR := Color(1.0, 1.0, 1.0, 0.8)
const LOT_FILL_ALPHA: float = 0.25
const OUTLINE_WIDTH: float = 2.0

var _layout: StructureLayout
var _canvas: Control


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if visible and _canvas != null:
		queue_redraw()


func Show(p_layout: StructureLayout, p_canvas: Control) -> void:
	_layout = p_layout
	_canvas = p_canvas
	queue_redraw()


func _draw() -> void:
	if _layout == null or _canvas == null:
		return
	draw_set_transform(_canvas.global_position - global_position)
	for lot in _layout.lots:
		var region_color: Color = _RegionColor(lot.region)
		draw_rect(lot.rect, Color(region_color, LOT_FILL_ALPHA))
		draw_rect(lot.rect, region_color, false, OUTLINE_WIDTH)
	for plaza in _layout.plazas:
		draw_rect(plaza, PLAZA_COLOR, false, OUTLINE_WIDTH)
	draw_set_transform(Vector2.ZERO)


## A stable colour per region resource, so the same region reads the same across seeds.
static func _RegionColor(p_region: BiomeRegionData) -> Color:
	if p_region == null:
		return Color.GRAY
	return Color.from_hsv(float(posmod(hash(p_region.resource_path), 360)) / 360.0, 0.8, 1.0)
