shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 currentColor = texture(SCREEN_TEXTURE, SCREEN_UV);
	currentColor.a = 1.0;

	float edgeVal = 0.0;
	vec2 directions[] =
	{
		vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0),
		vec2(1.0, 1.0), vec2(-1.0, 1.0), vec2(-1.0, -1.0), vec2(1.0, -1.0)
	};

	for(int i = 0; i < directions.length(); i++)
	{
		vec2 otherUV = SCREEN_UV + SCREEN_PIXEL_SIZE * directions[i];
		vec4 otherColor = texture(SCREEN_TEXTURE, otherUV);
		otherColor.a = 1.0;
		edgeVal += distance(currentColor, otherColor) / float(directions.length());
	}

	float g = min(1.0, edgeVal * 3.0);
	COLOR = vec4(0.0, g, 0.0, 1.0);
}
