shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 grayscale = vec3(0.299 * COLOR.r + 0.587 * COLOR.g + 0.114 * COLOR.b);
	COLOR.rgb = mix(COLOR.rgb, grayscale, grayscale_amount);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash_amount);
}
