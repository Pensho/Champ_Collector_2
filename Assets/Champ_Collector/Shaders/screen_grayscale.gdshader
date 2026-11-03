shader_type canvas_item;

// Draws what lies behind the node in greyscale, keeping the node's own alpha for fades.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec3 behind = texture(screen_texture, SCREEN_UV).rgb;
	COLOR = vec4(vec3(dot(behind, vec3(0.299, 0.587, 0.114))), COLOR.a);
}
