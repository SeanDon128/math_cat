shader_type canvas_item;

uniform vec4 fur_color : source_color = vec4(0.913725, 0.470588, 0.141176, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.678431, 0.258824, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.427451, 0.207843, 0.121569, 1.0);

varying vec4 sprite_color;

void vertex() {
	sprite_color = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Swap only the three fur shades; keep eyes, cream markings, and accessories.
	if (distance(pixel.rgb, vec3(233.0, 120.0, 36.0) / 255.0) < 0.01) {
		pixel.rgb = fur_color.rgb;
	} else if (distance(pixel.rgb, vec3(255.0, 173.0, 66.0) / 255.0) < 0.01) {
		pixel.rgb = highlight_color.rgb;
	} else if (distance(pixel.rgb, vec3(109.0, 53.0, 31.0) / 255.0) < 0.01) {
		pixel.rgb = shadow_color.rgb;
	}
	COLOR = pixel * sprite_color;
}
