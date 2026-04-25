shader_type canvas_item;

uniform vec4 deep_color : source_color = vec4(0.035, 0.055, 0.08, 1.0);
uniform vec4 mid_color : source_color = vec4(0.08, 0.12, 0.16, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.14, 0.19, 0.23, 1.0);
uniform float wave_scale = 3.2;
uniform float wave_speed = 0.34;
uniform float contrast = 0.34;
uniform float ripple_strength = 0.2;

void fragment() {
	vec2 uv = UV * wave_scale;
	float t = TIME * wave_speed;

	float drift = sin(uv.x * 0.75 + t * 0.7) * 0.22;
	uv.y += drift;

	float swell_a = sin(uv.x * 1.1 + t + sin(uv.y * 1.2 - t * 0.8));
	float swell_b = sin(uv.y * 2.3 - t * 1.9 + cos(uv.x * 1.6 + t * 1.2));
	float swell_c = sin((uv.x + uv.y * 0.7) * 2.0 - t * 1.35);
	float ripples = sin((uv.x - uv.y * 1.4) * 4.8 + t * 3.2) * ripple_strength;
	float waves = swell_a * 0.45 + swell_b * 0.3 + swell_c * 0.25 + ripples;

	float depth_mask = clamp(0.5 + waves * contrast, 0.0, 1.0);
	float highlight_band = smoothstep(0.5, 0.92, 0.5 + waves * 0.5);
	float shadow_band = smoothstep(0.18, 0.8, 1.0 - (0.5 + waves * 0.5));

	vec3 color = mix(deep_color.rgb, mid_color.rgb, depth_mask);
	color = mix(color, highlight_color.rgb, highlight_band * 0.45);
	color *= 1.0 - shadow_band * 0.18;

	float vignette = smoothstep(0.18, 0.92, length(UV - vec2(0.5)) * 1.15);
	color *= 1.0 - vignette * 0.14;

	COLOR = vec4(color, 1.0);
}
