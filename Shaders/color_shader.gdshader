shader_type canvas_item;

uniform bool showError = false;
uniform vec4 cWhite : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 cGray : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 cBlack : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV);
	if(c.r == 1.0 && c.g == 1.0 && c.b == 1.0)
		c = cWhite;
	else if(c.r == 0.0 && c.g == 0.0 && c.b == 0.0)
		c = cBlack;
	else if(c.r == 0.8 && c.g == 0.8 && c.b == 0.8)
		c = cGray;
	else if(showError)
		c = vec4(1.0, 0.0, 0.0, 1.0);
	COLOR = c;
}
