shader_type canvas_item;
// Unshaded because the scene's DirectionalLight2D blends subtractively, which
// flattens an un-normal-mapped surface to black.
render_mode unshaded;

// Mottled ground partly covered by a tiling stone floor. Coverage noise is sampled at each
// stone's centre (from the baked stone map), so stones are kept, faded or dropped whole.

#include "res://Assets/Champ_Collector/Shaders/Adventure_Shaders/adventure_ground_mottle.gdshaderinc"

uniform sampler2D stone_texture : source_color, repeat_enable, filter_linear_mipmap;
// Baked by Scripts/Debug/generate_stone_map.gd: R,G = the pixel's stone centre in tile UV,
// B = distance to grout.
uniform sampler2D stone_map : repeat_enable, filter_nearest;
// Pixels covered by one repeat of the stone texture.
uniform vec2 stone_tile_size = vec2(256.0, 256.0);

// Pixels covered by one repeat of noise_texture when it is read as stone coverage.
uniform vec2 coverage_tile_size = vec2(2048.0, 2048.0);
// Higher leaves fewer stones.
uniform float coverage_threshold : hint_range(0.0, 1.0) = 0.5;
// Stones up to this far below the threshold fade into the ground instead of dropping out;
// 0 drops them outright.
uniform float fade_band : hint_range(0.0, 1.0) = 0.0;
// Opacity of a fully kept stone; what lies beneath the ground shows through the rest.
uniform float stone_opacity : hint_range(0.0, 1.0) = 0.5;
// Random per-stone shift of the threshold; roughens the paving's outline.
uniform float stone_randomness : hint_range(0.0, 1.0) = 0.25;
// Stones within this band above the threshold are worn: wear_tint creeps in from their grout.
uniform float wear_band : hint_range(0.0, 0.5) = 0.12;
uniform vec4 wear_tint : source_color = vec4(0.3, 0.38, 0.22, 1.0);
uniform float brightness_variation : hint_range(0.0, 1.0) = 0.25;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

float hash_2d(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 ground = mottled_ground(texture(TEXTURE, UV), local_position);

	vec2 stone_uv = local_position / stone_tile_size;
	vec3 stone_data = texture(stone_map, stone_uv).rgb;
	// The stone's centre may lie in the neighbouring tile repeat; shift it to the one nearest
	// this pixel. Built from integers plus the stored centre, so it is exact across the stone.
	vec2 tile_index = floor(stone_uv) - round(stone_data.rg - fract(stone_uv));
	vec2 stone_centre = tile_index + stone_data.rg;

	float stone_random = hash_2d(stone_centre);
	float coverage = texture(noise_texture, stone_centre * stone_tile_size / coverage_tile_size
		+ noise_offset + vec2(0.5, 0.25)).r;
	coverage += (stone_random - 0.5) * stone_randomness;
	float presence = fade_band > 0.0
		? smoothstep(coverage_threshold - fade_band, coverage_threshold, coverage)
		: step(coverage_threshold, coverage);
	if (presence <= 0.0) {
		COLOR = ground;
	} else {
		vec4 stone = texture(stone_texture, stone_uv);
		stone.rgb *= 1.0 + (hash_2d(stone_centre + 17.0) - 0.5) * brightness_variation;
		float wear = 1.0 - smoothstep(coverage_threshold, coverage_threshold + wear_band, coverage);
		float creep = 1.0 - smoothstep(wear - 0.15, wear + 0.15, stone_data.b);
		stone.rgb = mix(stone.rgb, stone.rgb * wear_tint.rgb, creep * wear);
		COLOR = mix(ground, vec4(stone.rgb, ground.a * stone_opacity), presence);
	}
}
