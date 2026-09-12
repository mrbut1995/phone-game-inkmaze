shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float border_thickness : hint_range(0.001, 0.2) = 0.03;
uniform float glow_spread : hint_range(0.001, 0.15) = 0.03;
uniform float border_margin : hint_range(0.001, 0.15) = 0.05;

void fragment() {
	vec2 dist_to_edge_2d = min(UV, 1.0 - UV);
	float d = min(dist_to_edge_2d.x, dist_to_edge_2d.y);

	float stroke_center = border_margin + border_thickness * 0.5;
	float half_thickness = border_thickness * 0.5;

	float dist_to_stroke = max(0.0, abs(d - stroke_center) - half_thickness);
	float dist_to_center = abs(d - stroke_center);
	float core = 1.0 - smoothstep(0.0, border_thickness * 0.35, dist_to_center);
	float glow = exp(-dist_to_stroke / max(glow_spread, 0.0001));

	float outer_fade = smoothstep(0.0, border_margin, d);
	if (d < stroke_center) {
		glow *= outer_fade;
	}

	vec4 final_color = mix(glow_color, core_color, core);
	final_color.a = glow;

	COLOR = final_color;
}
