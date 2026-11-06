shader_type canvas_item;

uniform sampler2D texture_albedo;
uniform vec4 silhouette_color : source_color = vec4(0.5, 0.5, 0.5, 0.6);

void fragment() {
    vec4 color = texture(texture_albedo, UV);

    if ((color.r < 0.1) && (color.g < 0.1) && (color.b < 0.1)) {
        // If the color is pure black, set the alpha channel to 0.0 (fully transparent).
        color.a = 0.0;
    }
	else {
		color = silhouette_color;
	}

    COLOR = color;
}
