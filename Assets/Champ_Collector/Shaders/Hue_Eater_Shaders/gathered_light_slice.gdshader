shader_type canvas_item;
// One Gathered Light slice, a wedge from the origin to the 12 and 2 o'clock hexagon corners:
// greys what lies behind it, inside a bright outline. Both edges are antialiased.
render_mode blend_premul_alpha;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float radius = 80.0;
uniform float gap = 12.0;
uniform vec4 outline_color : source_color = vec4(0.92, 0.92, 0.92, 1.0);
uniform float outline_width = 1.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

// Signed distance to a triangle: negative inside.
float TriangleDistance(vec2 p, vec2 a, vec2 b, vec2 c) {
	vec2 e0 = b - a;
	vec2 e1 = c - b;
	vec2 e2 = a - c;
	vec2 v0 = p - a;
	vec2 v1 = p - b;
	vec2 v2 = p - c;
	vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
	vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
	vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
	float s = sign(e0.x * e2.y - e0.y * e2.x);
	vec2 d = min(min(vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
			vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
			vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
	return -sqrt(d.x) * sign(d.y);
}

void fragment() {
	vec2 top = vec2(0.0, -radius);
	vec2 right = vec2(radius * 0.866025, -radius * 0.5);
	// Shrinking a triangle's distance field keeps its corners sharp, so gaps stay even.
	float distance_to_edge = TriangleDistance(local_position, vec2(0.0), top, right) + gap * 0.5;
	float pixel = max(fwidth(distance_to_edge), 0.0001);
	float coverage = clamp(0.5 - distance_to_edge / pixel, 0.0, 1.0);
	float outline = clamp(0.5 + (distance_to_edge + outline_width) / pixel, 0.0, 1.0);
	vec3 behind = texture(screen_texture, SCREEN_UV).rgb;
	vec3 grey = vec3(dot(behind, vec3(0.299, 0.587, 0.114)));
	float alpha = coverage * COLOR.a;
	COLOR = vec4(mix(grey, outline_color.rgb, outline * outline_color.a) * alpha, alpha);
}
