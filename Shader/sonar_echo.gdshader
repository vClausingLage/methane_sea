shader_type canvas_item;

render_mode blend_add, unshaded;

uniform float intensity = 1.6;
uniform float alpha_boost = 1.0;

void fragment() {
    vec4 base = texture(TEXTURE, UV) * COLOR;
    base.rgb *= intensity;
    base.a = clamp(base.a * alpha_boost, 0.0, 1.0);
    COLOR = base;
}