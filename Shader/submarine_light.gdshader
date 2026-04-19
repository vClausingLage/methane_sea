shader_type canvas_item;

uniform float length = 600.0;
uniform float width = 0.5;
uniform float softness = 0.6;
uniform float intensity = 1.4;
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 0.9, 1.0);

void fragment() {
    
    vec2 uv = UV;
    
    float x = uv.x;
    float y = uv.y - 0.5;

    float cone = abs(y) / width;

    float beam = smoothstep(1.0, softness, cone);

    float fade = smoothstep(1.0, 0.0, x);

    float strength = beam * fade * intensity;

    COLOR = vec4(light_color.rgb * strength, strength);
	
	uv.y += sin(TIME * 2.0 + uv.x * 10.0) * 0.01;

}