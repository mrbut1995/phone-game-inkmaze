shader_type canvas_item;
// ============================================================================
// PALETTE REMAP — đổi BẢNG MÀU chính xác cho art phẳng (SVG fill), tối đa 4 cặp.
//
// Khác `color_remap.gdshader` (nội suy "trắng + k*màu" cho mảng NHẠT):
// shader này so khớp TRỰC TIẾP màu fill: lấy 2 màu nguồn GẦN NHẤT trong danh
// sách (f1..f4) rồi trộn 2 màu đích tương ứng (t1..t4) theo trọng số khoảng cách:
//   · pixel đúng 1 màu nguồn  -> đúng 100% màu đích (vùng phẳng)
//   · pixel viền AA (trộn 2 màu nguồn) -> trộn 2 màu đích, giữ viền mượt
//   · alpha của màu đích cũng được trộn (đặt alpha 0 -> xoá hẳn mảng đó)
//
// LƯU Ý: material CHỈ áp cho chính node gắn nó — node con phải tự gắn material
// riêng (hoặc bật `use_parent_material`).
// count = 0 -> giữ nguyên ảnh gốc (identity).
// ============================================================================

uniform int count = 0;
uniform vec4 f1 : source_color = vec4(1.0);
uniform vec4 t1 : source_color = vec4(1.0);
uniform vec4 f2 : source_color = vec4(1.0);
uniform vec4 t2 : source_color = vec4(1.0);
uniform vec4 f3 : source_color = vec4(1.0);
uniform vec4 t3 : source_color = vec4(1.0);
uniform vec4 f4 : source_color = vec4(1.0);
uniform vec4 t4 : source_color = vec4(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (count <= 0) {
		COLOR = c * COLOR;
	} else {
		vec4 froms[4] = {f1, f2, f3, f4};
		vec4 tos[4] = {t1, t2, t3, t4};
		float d1 = 1e9;
		float d2 = 1e9;
		vec4 r1 = vec4(0.0);
		vec4 r2 = vec4(0.0);
		for (int i = 0; i < 4; i++) {
			if (i >= count) {
				break;
			}
			float dd = distance(c.rgb, froms[i].rgb);
			if (dd < d1) {
				d2 = d1;
				r2 = r1;
				d1 = dd;
				r1 = tos[i];
			} else if (dd < d2) {
				d2 = dd;
				r2 = tos[i];
			}
		}
		float w = (d1 + d2 > 0.000001) ? d2 / (d1 + d2) : 1.0;
		vec4 remap = mix(r2, r1, w);
		COLOR = vec4(remap.rgb, remap.a * c.a) * COLOR;
	}
}
