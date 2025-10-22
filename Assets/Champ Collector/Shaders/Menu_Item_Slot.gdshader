shader_type canvas_item;

uniform sampler2D texture_albedo;

void fragment() {
    vec4 color = texture(texture_albedo, UV);

    if ((color.r < 0.001) && (color.g < 0.001) && (color.b < 0.001)) {
        // If the color is pure black, set the alpha channel to 0.0 (fully transparent).
        color.a = 0.0;
    }
	else {
		color.rgb = vec3(0.0, 0.0, 0.0);
		color.a = 0.8;
	}

    COLOR = color;
}
