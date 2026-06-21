shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);
uniform float base_alpha = 0.3;
uniform float fade_uv = 0.04;
uniform vec2 region_uv_range = vec2(0.0, 1.0); // AtlasTexture region's UV bounds; UV is not 0..1 over the drawn quad.

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float local_uv = (UV.x - region_uv_range.x) / (region_uv_range.y - region_uv_range.x);
	float edge = smoothstep(0.0, fade_uv, local_uv) * smoothstep(0.0, fade_uv, 1.0 - local_uv);
	COLOR = vec4(tex.rgb * tint.rgb, tint.a * base_alpha * edge);
}
