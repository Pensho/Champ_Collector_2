shader_type canvas_item;

#include "res://Assets/Champ_Collector/Shaders/targeting_help_pulse.gdshaderinc"

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;

uniform bool outline_enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0);
// Outline thickness in texture texels, sampled around each transparent pixel.
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
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash_amount);

	if (outline_enabled && COLOR.a <= 0.0) {
		// Samples a circle of outline_width_texels around this transparent pixel; any
		// opaque texel inside it puts this pixel on the outline.
		float width = outline_width_texels;
		bool near_opaque = false;
		for (float i = -ceil(width); i <= ceil(width) && !near_opaque; i++) {
			float x = clamp(i, -width, width);
			float offset = floor(sqrt(pow(width + 0.5, 2.0) - x * x));
			for (float j = -ceil(offset); j <= ceil(offset); j++) {
				vec2 xy = uv + TEXTURE_PIXEL_SIZE * vec2(x, clamp(j, -offset, offset));
				if (xy == clamp(xy, vec2(0.0), vec2(1.0)) && texture(TEXTURE, xy).a > 0.0) {
					near_opaque = true;
					break;
				}
			}
		}
		if (near_opaque) {
			COLOR = vec4(outline_color.rgb, outline_color.a * targeting_help_pulse(TIME));
		}
	}
}
