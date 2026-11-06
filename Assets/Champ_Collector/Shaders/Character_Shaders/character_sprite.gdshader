shader_type canvas_item;

#include "res://Assets/Champ_Collector/Shaders/Character_Shaders/targeting_help_pulse.gdshaderinc"

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;

uniform bool outline_enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0);
// Outline thickness in texture texels, sampled around each pixel the art does not fully cover.
uniform float outline_width_texels = 1.0;
// The same thickness in the rect's local pixels: the quad grows by this on every side
// so the outline has room where the art touches the texture's edge.
uniform float outline_margin = 0.0;
uniform vec2 rect_size = vec2(1.0);

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
	if (outline_enabled) {
		// Grows away from the rect's center rather than along UV, so a flip_h sprite
		// (UV.x running 1 to 0) expands outward too.
		VERTEX += sign(VERTEX - rect_size * 0.5) * outline_margin;
	}
}

void fragment() {
	vec2 uv = UV;
	if (outline_enabled) {
		vec2 margin_fraction = vec2(outline_margin) / rect_size;
		uv = (UV * (1.0 + 2.0 * margin_fraction)) - margin_fraction;
		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR = vec4(0.0);
		} else {
			COLOR = texture(TEXTURE, uv) * vertex_color;
			NORMAL_MAP = texture(NORMAL_TEXTURE, uv).rgb;
		}
	}

	vec3 grayscale = vec3(0.299 * COLOR.r + 0.587 * COLOR.g + 0.114 * COLOR.b);
	COLOR.rgb = mix(COLOR.rgb, grayscale, grayscale_amount);
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);

	// The texture's own alpha, not COLOR's: a translucent sprite must not count as outline space.
	float art_alpha = uv == clamp(uv, vec2(0.0), vec2(1.0)) ? texture(TEXTURE, uv).a : 0.0;
	if (outline_enabled && art_alpha < 1.0) {
		// The highest filtered alpha nearby, so the outline's edge fades instead of stepping.
		float outline_coverage = 0.0;
		for (float i = -ceil(outline_width_texels); i <= ceil(outline_width_texels); i++) {
			float x = clamp(i, -outline_width_texels, outline_width_texels);
			float offset = floor(sqrt(pow(outline_width_texels + 0.5, 2.0) - x * x));
			for (float j = -ceil(offset); j <= ceil(offset); j++) {
				vec2 xy = uv + TEXTURE_PIXEL_SIZE * vec2(x, clamp(j, -offset, offset));
				if (xy == clamp(xy, vec2(0.0), vec2(1.0))) {
					outline_coverage = max(outline_coverage, texture(TEXTURE, xy).a);
				}
			}
		}
		// The art lies over its outline, so partly transparent edge texels blend into it.
		float outline = outline_color.a * targeting_help_pulse(TIME) * outline_coverage * (1.0 - art_alpha);
		float alpha = COLOR.a + outline * (1.0 - COLOR.a);
		COLOR.rgb = (COLOR.rgb * COLOR.a + outline_color.rgb * outline * (1.0 - COLOR.a)) / max(alpha, 0.0001);
		COLOR.a = alpha;
	}
}
