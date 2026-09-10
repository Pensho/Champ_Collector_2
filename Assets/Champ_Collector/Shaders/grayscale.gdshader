shader_type canvas_item;

uniform bool weighted = true;
uniform float grayscale_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec3 grayscale = mix(vec3((COLOR.r + COLOR.g + COLOR.b) / 3.0), vec3(0.299 * COLOR.r + 0.587 * COLOR.g + 0.114 * COLOR.b), float(weighted));
	COLOR.rgb = mix(COLOR.rgb, grayscale, grayscale_amount);
}
