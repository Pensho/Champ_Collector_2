shader_type canvas_item;

// Opaque from the left edge up to `reveal`, fading out over `edge_softness` past it.
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	float edge = reveal * (1.0 + edge_softness);
	float mask = 1.0 - smoothstep(edge - edge_softness, edge, UV.x);
	COLOR = texture(TEXTURE, UV) * vec4(1.0, 1.0, 1.0, mask);
}
