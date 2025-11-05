shader_type canvas_item;

uniform vec2 rect_size = vec2(40.0, 40.0);
uniform vec2 margin = vec2(10.0, 10.0);

const int bayer4[] = 
	{
		0, 8, 2, 10,
		12, 4, 14, 6,
		3, 11, 1, 9,
		15, 7, 13, 9
	};

float stepifyFloat(float val, float stepper)
{
	return float(int(val / stepper)) * stepper;
}

void fragment() {
	vec2 ipos = UV * rect_size;
	ipos.x = floor(ipos.x);
	ipos.y = floor(ipos.y);
	int bayerOffset = bayer4[int(ipos.x) % 4 + 4 * (int(ipos.y) % 4)];
	
	float vComp = 1.0;
	bool BL = false;
	bool BR = false;
	if(stepifyFloat(UV.x, 1.0/rect_size.x) < stepifyFloat(UV.y, 1.0/rect_size.y))
	{
		BL = true;
	}
	if(stepifyFloat(1.0-UV.x, 1.0/rect_size.x) < stepifyFloat(UV.y, 1.0/rect_size.y))
	{
		BR = true;
	}
	if(BL)
		if(BR)
			vComp = (rect_size.y-ipos.y)/margin.y;
		else
			vComp = (ipos.x)/margin.x;
	else
		if(BR)
			vComp = (rect_size.x-ipos.x)/margin.x;
		else
			vComp = (ipos.y)/margin.y;
	
	
	if (float(bayerOffset)/16.0 >= vComp)
		COLOR.a = 0.0;
}
