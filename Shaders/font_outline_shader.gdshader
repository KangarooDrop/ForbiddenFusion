shader_type canvas_item;

uniform float thresh : hint_range(0.0, 1.0, 0.01) = 0.00;

void fragment() {
	//COLOR = texture(TEXTURE, UV);
	//COLOR.a = ceil(COLOR.a);
	if(COLOR.a > thresh)
		COLOR.a = 1.0;
	else
		COLOR.a = 0.0;
}