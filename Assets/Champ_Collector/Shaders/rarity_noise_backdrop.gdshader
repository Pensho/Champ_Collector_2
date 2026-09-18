shader_type canvas_item;

uniform vec4 rarity_color : source_color = vec4(0.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

group_uniforms noise;
uniform sampler2D noise_texture : filter_linear, repeat_enable;
uniform vec2 noise_scale = vec2(1.0);
uniform vec2 noise_offset = vec2(0.0);
uniform float noise_contrast : hint_range(0.0, 4.0) = 1.0;
// Remaps the raw noise value (x) to the mix weight between dark and rarity color (y).
uniform sampler2D noise_curve : hint_default_white, filter_linear, repeat_disable;
uniform bool use_noise_curve = true;
uniform float noise_darkening : hint_range(0.0, 1.0) = 0.6;

group_uniforms vertical_shade;
// Brightness multiplier from top (x = 0) to bottom (x = 1).
uniform sampler2D shade_curve : hint_default_white, filter_linear, repeat_disable;
uniform float shade_strength : hint_range(0.0, 1.0) = 1.0;
group_uniforms;

void fragment() {
	float noise_value = texture(noise_texture, UV * noise_scale + noise_offset).r;
	noise_value = clamp((noise_value - 0.5) * noise_contrast + 0.5, 0.0, 1.0);
	if (use_noise_curve) {
		noise_value = texture(noise_curve, vec2(noise_value, 0.0)).r;
	}
	vec3 dark_color = rarity_color.rgb * (1.0 - noise_darkening);
	vec3 noise_color = mix(dark_color, rarity_color.rgb, noise_value);

	float vertical_shade = texture(shade_curve, vec2(UV.y, 0.0)).r;
	vertical_shade = mix(1.0, vertical_shade, shade_strength);

	COLOR = vec4(noise_color * vertical_shade, rarity_color.a * alpha);
}
