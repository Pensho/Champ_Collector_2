shader_type canvas_item;
// Unshaded because the scene's DirectionalLight2D blends subtractively, which
// flattens an un-normal-mapped surface to black.
render_mode unshaded;

// Ground-plane projection for the battle floor band. The rect this runs on must
// span the full viewport width and exactly the screen band from far_y to near_y;
// the uniforms below are screen-space pixels and are kept in sync with the rect
// by hand.

uniform vec4 base_color : source_color = vec4(0.750, 0.675, 0.522, 1.0);
uniform vec4 mottle_color : source_color = vec4(0.660, 0.586, 0.440, 1.0);

uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.6;
// 0 leaves the noise smooth; 2-4 posterizes it into flat patches.
uniform int noise_steps : hint_range(0, 6) = 3;

// Blotch size, independent of the cell grid. Lowering these enlarges the
// patches and repeats the texture fewer times across the floor at once.
uniform vec2 noise_scale = vec2(22.5, 20.9);
uniform vec2 noise_offset = vec2(0.0, 0.0);
// A second sample at a non-integer multiple of the first. The two repeat
// periods never coincide, so the combination hides the texture's own tiling.
uniform float noise_detail_scale : hint_range(0.1, 8.0) = 2.7;
uniform float noise_detail_weight : hint_range(0.0, 1.0) = 0.35;

uniform float far_y = 430.0;
uniform float near_y = 600.0;
// Raising horizon_y toward far_y strengthens the perspective; lowering it flattens.
uniform float horizon_y = 324.0;

uniform float cells_across : hint_range(1.0, 32.0) = 8.0;
uniform float depth_density : hint_range(0.1, 16.0) = 2.65;
uniform vec2 scroll = vec2(0.0, 0.0);

uniform float grid_line_width : hint_range(0.0, 4.0) = 0.0;
uniform vec4 grid_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform vec4 haze_color : source_color = vec4(0.055, 0.086, 0.078, 1.0);
uniform float haze_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	float band = near_y - far_y;
	float a = (far_y - horizon_y) + UV.y * band;
	if (a <= 0.001) {
		discard;
	}

	// 1.0 at the near edge, growing toward the horizon. Sharing this factor
	// between both axes is what makes the ground converge instead of shear.
	float k = (near_y - horizon_y) / a;

	vec2 ground = vec2((UV.x - 0.5) * k, k);
	vec2 cell_uv = ground * vec2(cells_across, depth_density) + scroll;
	vec2 noise_uv = ground * noise_scale + noise_offset;

	float n = mix(
		texture(noise_texture, noise_uv).r,
		texture(noise_texture, noise_uv * noise_detail_scale + vec2(0.37, 0.71)).r,
		noise_detail_weight
	);
	if (noise_steps > 0) {
		float steps = float(noise_steps);
		n = floor(n * steps) / max(steps - 1.0, 1.0);
	}
	vec4 col = mix(base_color, mottle_color, clamp(n, 0.0, 1.0) * noise_strength);

	if (grid_line_width > 0.0) {
		vec2 cell = fract(cell_uv);
		vec2 edge = min(cell, 1.0 - cell);
		vec2 texel = max(fwidth(cell_uv), vec2(1e-6));
		float distance_in_pixels = min(edge.x / texel.x, edge.y / texel.y);
		float line = 1.0 - smoothstep(0.0, grid_line_width, distance_in_pixels);
		col.rgb = mix(col.rgb, grid_color.rgb, line * grid_color.a);
	}

	float k_far = (near_y - horizon_y) / max(far_y - horizon_y, 0.001);
	float depth_ratio = clamp((k - 1.0) / max(k_far - 1.0, 0.001), 0.0, 1.0);
	col.rgb = mix(col.rgb, haze_color.rgb, depth_ratio * haze_strength);

	COLOR = col;
}
