shader_type canvas_item;

uniform float radius = 120.0;


void vertex() {
	UV = VERTEX / (radius * 2.0);
}


void fragment() {


	vec2 uv = SCREEN_UV;
	vec2 local_uv = UV;
	// Waves

	vec4 c = textureLod(SCREEN_TEXTURE,uv,0.0);
	float vect_len = length(local_uv);
	float dist = vect_len / radius * 3.75;

	if (dist < 0.011) {
		c.r += dist * 10.0;
		c.g += dist * 10.0;
		c.b += dist * 15.0;
		c.a = 0.6;
	}
	else {
		c.r += dist * 10.0;
		c.g += dist * 10.0;
		c.b += dist * 15.0;
		c.a = 0.9;
	}

	COLOR=c;
	
}
