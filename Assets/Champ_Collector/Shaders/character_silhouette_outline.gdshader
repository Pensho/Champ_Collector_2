shader_type canvas_item;
render_mode unshaded;

// Draws the sprite's silhouette dilated by outline_width_texels in one flat color. The node
// sits behind the sprite, so only the ring outside the art stays visible.
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width_texels = 1.0;
// The same thickness in the rect's local pixels: the quad grows by this on every side
// so the outline has room where the art touches the texture's edge.
uniform float outline_margin = 0.0;
uniform vec2 rect_size = vec2(1.0);

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
	// Grows away from the rect's center rather than along UV, so a flip_h sprite expands outward too.
	VERTEX += sign(VERTEX - rect_size * 0.5) * outline_margin;
}

void fragment() {
	vec2 margin_fraction = vec2(outline_margin) / rect_size;
	vec2 uv = (UV * (1.0 + 2.0 * margin_fraction)) - margin_fraction;
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
	COLOR = near_opaque ? outline_color * vertex_color : vec4(0.0);
}
