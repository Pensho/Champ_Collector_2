shader_type canvas_item;
// Unshaded because the scene's DirectionalLight2D blends subtractively, which
// flattens an un-normal-mapped surface to black.
render_mode unshaded;

#include "res://Assets/Champ_Collector/Shaders/Adventure_Shaders/adventure_ground_mottle.gdshaderinc"

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	COLOR = mottled_ground(texture(TEXTURE, UV), local_position);
}
