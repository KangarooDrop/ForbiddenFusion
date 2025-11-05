shader_type canvas_item;

//uniform vec4 cf0 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
//uniform vec4 cf1 : source_color = vec4(0.625, 0.625, 0.625, 1.0);
//uniform vec4 cf2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);

//uniform vec4 ct0 : source_color = vec4(1.0, 0.0, 1.0, 1.0);
//uniform vec4 ct1 : source_color = vec4(0.75, 0.75, 0.75, 1.0);
//uniform vec4 ct2 : source_color = vec4(0.5, 0.0, 0.5, 1.0);

uniform vec4 cWhite : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 cBlack : source_color = vec4(0.0, 1.0, 0.0, 1.0);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV);
	if (c.r == c.g && c.g == c.b)
	{
		float cVal = (c.r + c.g + c.b) / 3.0;
		c = mix(cBlack, cWhite, cVal);
	}
	
	/*
	if(c == cf0)
		c = ct0;
	else if(c == cf1)
		c = ct1;
	else if(c == cf2)
		c = ct2;
	*/
	
	COLOR = c;
}
