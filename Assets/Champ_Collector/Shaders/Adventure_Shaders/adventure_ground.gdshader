shader_type canvas_item;
// Unshaded because the scene's DirectionalLight2D blends subtractively, which
// flattens an un-normal-mapped surface to black.
render_mode unshaded;

// Top-down mottle over the adventure map's gradient fill (TEXTURE). Noise is
// sampled in local pixels, so blotch size holds however tall the map grows.

// Multiplied onto the gradient where the noise is high.
uniform vec4 mottle_tint : source_color = vec4(0.6, 0.6, 0.6, 1.0);

uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.6;
// 0 leaves the noise smooth; 2-4 posterizes it into flat patches.
uniform int noise_steps : hint_range(0, 6) = 3;
// Width of the ramp between neighbouring steps: 0 is a hard edge, 1 leaves no flat
// band at all.
uniform float step_blend : hint_range(0.0, 1.0) = 0.5;

// Pixels covered by one repeat of the noise texture.
uniform vec2 noise_tile_size = vec2(1024.0, 1024.0);
// Set per adventure from its generation seed.
uniform vec2 noise_offset = vec2(0.0, 0.0);
// A second sample at a non-integer multiple of the first. The two repeat
// periods never coincide, so the combination hides the texture's own tiling.
uniform float noise_detail_scale : hint_range(0.1, 8.0) = 2.7;
uniform float noise_detail_weight : hint_range(0.0, 1.0) = 0.35;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 noise_uv = local_position / noise_tile_size + noise_offset;

	float n = mix(
		texture(noise_texture, noise_uv).r,
		texture(noise_texture, noise_uv * noise_detail_scale + vec2(0.37, 0.71)).r,
		noise_detail_weight
	);
	if (noise_steps > 0) {
		float steps = float(noise_steps);
		// Shifted by half a step so each boundary sits mid-cell, where the
		// smoothstep ramps from the band below into the band above.
		float shifted = n * steps + 0.5;
		float half_width = max(step_blend, 0.001) * 0.5;
		float ramp = smoothstep(0.5 - half_width, 0.5 + half_width, fract(shifted));
		n = (floor(shifted) - 1.0 + ramp) / max(steps - 1.0, 1.0);
	}

	vec4 base = texture(TEXTURE, UV);
	vec4 mottled = vec4(base.rgb * mottle_tint.rgb, base.a);
	COLOR = mix(base, mottled, clamp(n, 0.0, 1.0) * noise_strength);
}
