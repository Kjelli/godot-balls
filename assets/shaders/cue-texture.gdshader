shader_type canvas_item;

uniform sampler2D scroll_texture : repeat_enable, filter_nearest;

uniform mat3 rotation_basis;
uniform float alpha :  hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);

    // Map Y to a -1.0 to 1.0 range for the cylinder's thickness.
    // X stays as a standard 0.0 to 1.0 range along the length of the cue.
    float y_ndc = UV.y * 2.0 - 1.0;

    // Cylinder clipping: if the texture has transparent padding, 
    // we only discard if it exceeds the cylinder's physical edge.
    if (abs(y_ndc) > 1.0) {
        discard;
    }
	
    // Cylinder surface point (X is flat/linear, Y and Z form the circular cross-section)
    float z = sqrt(1.0 - y_ndc * y_ndc);
    vec3 cylinder_pos = vec3(UV.x, y_ndc, z);

    // Rotate the cylinder surface using your existing basis
    vec3 rotated = rotation_basis * cylinder_pos;

    // Convert the rotated position back to cylindrical UVs
    // u maps linearly along the length (using the rotated X)
    float u = rotated.x; 
    // v wraps around the circumference of the stick (using rotated Y and Z)
    float v = atan(rotated.y, rotated.z) / (2.0 * PI) + 0.5;

    vec2 cylinder_uv = vec2(u, v);

    vec4 detail = texture(scroll_texture, cylinder_uv);

    COLOR = vec4(base_color.rgb * detail.rgb, base_color.a * alpha);
}