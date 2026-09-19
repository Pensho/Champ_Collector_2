shader_type canvas_item;

#include "res://Assets/Champ_Collector/Shaders/targeting_help_pulse.gdshaderinc"

void fragment() {
	COLOR.a *= targeting_help_pulse(TIME);
}
