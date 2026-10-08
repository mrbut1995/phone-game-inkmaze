shader_type canvas_item;
// ============================================================================
// COLOR REMAP — thay tối đa 8 cặp màu "from -> to" trên texture/nút (mọi pixel con).
//
// Cách hiểu: file SVG gốc được vẽ theo công thức "nền trắng trộn màu nguồn" (tỉ lệ k).
// Shader ước lượng k cho từng pixel (chiếu lên đường white->from), rồi xuất
// "nền trắng trộn màu đích" cùng tỉ lệ ⇒ đổi tông màu MƯỢT, giữ nguyên viền
// khử răng cưa & các mảng nền nhạt (fill tint). Pixel không khớp cặp nào giữ nguyên.
//
// Dùng: gắn ShaderMaterial lên node cha (VD nút Dungeon) — material áp cho cả node
// con (CircleIcon/TopBadge/BottomLabel...). Chỉ cần set các cặp có dùng;
// cặp bỏ trống giữ mặc định trắng→trắng (vô hại).
// ============================================================================

const int PAIRS = 8;

uniform vec4 f1 : source_color = vec4(1.0);
uniform vec4 t1 : source_color = vec4(1.0);
uniform vec4 f2 : source_color = vec4(1.0);
uniform vec4 t2 : source_color = vec4(1.0);
uniform vec4 f3 : source_color = vec4(1.0);
uniform vec4 t3 : source_color = vec4(1.0);
uniform vec4 f4 : source_color = vec4(1.0);
uniform vec4 t4 : source_color = vec4(1.0);
uniform vec4 f5 : source_color = vec4(1.0);
uniform vec4 t5 : source_color = vec4(1.0);
uniform vec4 f6 : source_color = vec4(1.0);
uniform vec4 t6 : source_color = vec4(1.0);
uniform vec4 f7 : source_color = vec4(1.0);
uniform vec4 t7 : source_color = vec4(1.0);
uniform vec4 f8 : source_color = vec4(1.0);
uniform vec4 t8 : source_color = vec4(1.0);

// Sai số tối đa (0..1) để coi pixel "thuộc" một cặp màu
uniform float tolerance : hint_range(0.0, 0.5) = 0.06;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec4 froms[PAIRS] = {f1, f2, f3, f4, f5, f6, f7, f8};
	vec4 tos[PAIRS] = {t1, t2, t3, t4, t5, t6, t7, t8};

	float best_err = tolerance;
	vec3 result = c.rgb;
	bool matched = false;
	for (int i = 0; i < PAIRS; i++) {
		vec3 df = froms[i].rgb - vec3(1.0);
		float denom = dot(df, df);
		if (denom < 0.001) {
			continue; // cặp trắng/chưa dùng
		}
		float k = clamp(dot(c.rgb - vec3(1.0), df) / denom, 0.0, 1.0);
		vec3 pred = vec3(1.0) + df * k;
		float err = distance(c.rgb, pred);
		if (err < best_err) {
			best_err = err;
			result = vec3(1.0) + (tos[i].rgb - vec3(1.0)) * k;
			matched = true;
		}
	}
	if (matched) {
		COLOR = vec4(result, c.a);
	} else {
		COLOR = c;
	}
}
