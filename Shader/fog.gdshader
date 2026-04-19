shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.02,0.05,0.08,1.0);
uniform float density = 1.2;

void fragment() {

    vec2 center = vec2(0.5,0.5);
    float dist = distance(UV, center);

    float fog = smoothstep(0.2, density, dist);

    COLOR = vec4(fog_color.rgb, fog);
}