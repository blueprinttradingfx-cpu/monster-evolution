shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Apply base color to non-transparent areas
	vec3 final_rgb = tex_color.rgb * base_color.rgb;

	// Add procedural glow based on alpha edges
	float glow = glow_intensity * (1.0 - tex_color.a);

	COLOR = vec4(final_rgb, tex_color.a);
	COLOR.rgb += glow_color.rgb * glow_intensity * tex_color.a;
}
