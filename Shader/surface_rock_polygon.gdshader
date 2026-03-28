shader_type canvas_item;

uniform sampler2D rock_texture;
uniform float fade_start = 40.0;
uniform float fade_end = 120.0;

void fragment() {

    vec2 uv = UV;

    vec4 rock = texture(rock_texture, uv * vec2(6.0,2.0));

    float fade = smoothstep(fade_start, fade_end, UV.y * 200.0);

    vec3 final_color = mix(rock.rgb, vec3(0.0), fade);

    COLOR = vec4(final_color, 1.0);
}