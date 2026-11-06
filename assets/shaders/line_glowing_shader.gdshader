shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_power : hint_range(0.5, 5.0) = 2.0;

void fragment() {
	float dist = abs(UV.y - 0.5) * 2.0;
	float core = 1.0 - smoothstep(0.0, 0.3, dist);
	float glow = pow(1.0 - dist, glow_power);
	
	vec4 final_color = mix(glow_color * glow, core_color, core);
	final_color.a = glow;
	
	COLOR = final_color;
}
