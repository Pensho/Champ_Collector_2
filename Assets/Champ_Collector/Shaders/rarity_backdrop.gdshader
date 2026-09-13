shader_type canvas_item;

uniform vec4 rarity_color : source_color = vec4(0.0);
uniform float edge_darkening : hint_range(0.0, 1.0) = 0.6;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float distance_from_center = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	vec3 edge_color = rarity_color.rgb * (1.0 - edge_darkening);
	COLOR = vec4(mix(rarity_color.rgb, edge_color, distance_from_center), rarity_color.a * alpha);
}
