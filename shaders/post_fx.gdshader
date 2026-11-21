shader_type canvas_item;
// Final screen pass: gentle colour grade, vignette and a touch of film grain.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float vignette_strength = 0.28;
uniform float vignette_softness = 0.55;
uniform float saturation = 1.08;
uniform float contrast = 1.03;
uniform vec3 shadow_tint = vec3(0.97, 0.99, 1.05);
uniform vec3 highlight_tint = vec3(1.04, 1.01, 0.97);
uniform float grain = 0.018;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= mix(shadow_tint, highlight_tint, smoothstep(0.15, 0.75, lum));
	vec2 d = SCREEN_UV - 0.5;
	d.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float v = smoothstep(0.85, 0.85 - vignette_softness, length(d) * 1.35);
	c *= mix(1.0 - vignette_strength, 1.0, v);
	c += (hash(SCREEN_UV * 640.0 + fract(TIME * 7.0)) - 0.5) * grain;
	COLOR = vec4(c, 1.0);
}
