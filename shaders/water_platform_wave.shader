shader_type canvas_item;

uniform float delta = 0.0;
uniform float radius = 120.0;


uniform float frequency=30;
uniform float depth = 0.005;

uniform float size_x=0.001;
uniform float size_y=0.001;
uniform float pixelized_step=0.0018;



/*
uniform sampler2D vignette;

void fragment() {
	vec3 vignette_color = texture(vignette,UV).rgb;
	//screen texture stores gaussian blurred copies on mipmaps
	COLOR.rgb = textureLod(SCREEN_TEXTURE,SCREEN_UV,(1.0-vignette_color.r)*4.0).rgb;
	COLOR.rgb*= texture(vignette,UV).rgb;
*/


void vertex() {
	UV = VERTEX / (radius * 2.0);
}


void fragment() {


	vec2 uv = SCREEN_UV;
	vec2 local_uv = UV;
	

	float the_pixelized_step = 0.0;
	// Waves
	uv.x = clamp(uv.x+sin(local_uv.y*frequency+delta)*depth,0,1);
	
	// Pixelated distortion
	//float pixelate_mod = abs(cos(local_uv.x*frequency+delta)*pixelized_step);
	float pixelate_mod = abs(cos(local_uv.x*frequency+delta)*the_pixelized_step);
	uv-=mod(uv,vec2(size_x+pixelate_mod,size_y+pixelate_mod));

	//vec3 c = textureLod(SCREEN_TEXTURE,uv,0.0).rgb;

	vec4 c = textureLod(SCREEN_TEXTURE,uv,0.0);

	
	COLOR=c;
	
}

