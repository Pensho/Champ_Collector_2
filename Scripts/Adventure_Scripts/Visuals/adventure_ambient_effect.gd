class_name AdventureAmbientEffect extends GPUParticles2D

## A particle effect on the Adventure screen, listed in BiomeVisualData.ambient_effects.
## A map effect scrolls with the map and is refitted to each generated map's size; a screen
## effect stays fixed over the visible area and keeps the layout authored in its scene.

@export var follows_map: bool = false
## Particles per pixel of map height; 0 keeps the amount authored in the scene.
@export var amount_per_height: float = 0.0
@export var min_amount: int = 1
## 0 leaves the amount uncapped.
@export var max_amount: int = 0
## Widens the emission box past the map's left edge so particles drift in from off-screen.
@export var left_spawn_margin: float = 0.0


static func AmountForHeight(p_height: float, p_per_height: float, p_min: int, p_max: int) -> int:
	var result: int = maxi(p_min, int(p_height * p_per_height))
	if p_max > 0:
		result = mini(result, p_max)
	return result


static func EmissionSize(p_map_size: Vector2, p_left_margin: float) -> Vector2:
	return Vector2(p_map_size.x + p_left_margin, p_map_size.y)


static func EmissionCenter(p_map_size: Vector2, p_left_margin: float) -> Vector2:
	return Vector2((p_map_size.x - p_left_margin) * 0.5, p_map_size.y * 0.5)


static func VisibilityRect(p_emission_size: Vector2, p_particle_margin: float) -> Rect2:
	var half_size: Vector2 = p_emission_size * 0.5 + Vector2.ONE * p_particle_margin
	return Rect2(-half_size, half_size * 2.0)


func FitToMap(p_map_size: Vector2) -> void:
	if amount_per_height > 0.0:
		amount = AmountForHeight(p_map_size.y, amount_per_height, min_amount, max_amount)
	position = EmissionCenter(p_map_size, left_spawn_margin)
	var emission_size: Vector2 = EmissionSize(p_map_size, left_spawn_margin)

	var scene_process := process_material as ParticleProcessMaterial
	if scene_process == null:
		push_warning("AdventureAmbientEffect %s needs a ParticleProcessMaterial to fit the map." % name)
		return
	# A copy, so refitting never edits the material every instance of the scene shares.
	var fitted_process := scene_process.duplicate() as ParticleProcessMaterial
	fitted_process.emission_shape_scale = Vector3(emission_size.x, emission_size.y, 1.0) * 0.5
	process_material = fitted_process
	visibility_rect = VisibilityRect(emission_size, _ParticleMargin(fitted_process.scale_max))


## How far a scaled particle sprite reaches past its own center.
func _ParticleMargin(p_scale_max: float) -> float:
	if texture == null:
		return 0.0
	var frames := Vector2.ONE
	var canvas_material := material as CanvasItemMaterial
	if canvas_material != null and canvas_material.particles_animation:
		frames = Vector2(maxf(1.0, canvas_material.particles_anim_h_frames),
				maxf(1.0, canvas_material.particles_anim_v_frames))
	return (texture.get_size() / frames).length() * 0.5 * p_scale_max
