shader_type canvas_item;

uniform sampler2D scroll_texture : repeat_enable, filter_nearest;

uniform mat3 rotation_basis;
uniform float alpha :  hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);

    vec2 p = UV * 2.0 - 1.0;

    float r2 = dot(p, p);

    if (r2 > 1.0) {
        discard;
    }

    // Sphere surface point
    float z = sqrt(1.0 - r2);

    vec3 sphere_pos = vec3(p.x, p.y, z);

    // Rotate sphere
    vec3 rotated = rotation_basis * sphere_pos;

    // Convert rotated sphere position to spherical UV
    float u = atan(rotated.x, rotated.z) / (1.0 * PI) + 0.5;
    float v = acos(clamp(-rotated.y, -1.0, 1.0)) / PI;

    vec2 sphere_uv = vec2(u, v);

    vec4 detail = texture(scroll_texture, sphere_uv);

    COLOR = vec4(base_color.rgb * detail.rgb, base_color.a * alpha);
}