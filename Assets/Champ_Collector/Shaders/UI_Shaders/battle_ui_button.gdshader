shader_type canvas_item;

uniform float radius = 0.5; // Radius of the circle 
uniform float feather = 0.03; // Feathering of the circle's edge 
uniform vec2 center = vec2(0.5, 0.5); // Center of the circle 

void fragment() { 
    float dist = length(UV - center); // Distance from current pixel to the center 
    float alpha = smoothstep(radius, radius - feather, dist); // Smooth transition 
    COLOR.a *= alpha; // Apply mask for transparency 
}


