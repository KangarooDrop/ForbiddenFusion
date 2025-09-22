shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float brightness : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float dimMax : hint_range(0.0, 1.0, 0.01) = 0.5;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	float dimMul = mix(dimMax, 1.0, brightness);
	//color.r *= (1.0 - (1.0 - dimMul) / 2.0);
	color.r *= (1.0 - (1.0 - dimMul) * 0.9);
	color.g *= dimMul;
	color.b *= dimMul;
	COLOR = color;
}
