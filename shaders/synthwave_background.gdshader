shader_type canvas_item;

uniform float stage : hint_range(0.0, 4.0) = 0.0;
uniform float grade : hint_range(1.0, 13.0) = 1.0;
uniform float grid_speed : hint_range(0.0, 0.4) = 0.10;
uniform float shooting_star_intensity : hint_range(0.0, 1.0) = 0.0;
uniform bool grid_color_override_enabled = false;
uniform vec4 grid_color_override : source_color = vec4(1.0);

float hash21(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453123);
}

float line_segment(vec2 point, vec2 start, vec2 end, float width) {
	vec2 delta = end - start;
	float projection = clamp(dot(point - start, delta) / dot(delta, delta), 0.0, 1.0);
	return smoothstep(width, 0.0, length(point - (start + delta * projection)));
}

float grade_thirteen_math_mark(vec2 point, float kind) {
	if (kind < 1.0) {
		// Summation
		return max(line_segment(point, vec2(0.16, -0.16), vec2(-0.14, -0.16), 0.018), max(line_segment(point, vec2(-0.14, -0.16), vec2(0.10, 0.0), 0.018), max(line_segment(point, vec2(0.10, 0.0), vec2(-0.14, 0.16), 0.018), line_segment(point, vec2(-0.14, 0.16), vec2(0.16, 0.16), 0.018))));
	}
	if (kind < 2.0) {
		// f(x)
		float f_mark = max(line_segment(point, vec2(-0.17, 0.14), vec2(-0.17, -0.10), 0.016), max(line_segment(point, vec2(-0.17, -0.10), vec2(-0.10, -0.16), 0.016), line_segment(point, vec2(-0.21, -0.02), vec2(-0.11, -0.02), 0.016)));
		float left_parenthesis = max(line_segment(point, vec2(-0.06, -0.13), vec2(-0.09, 0.0), 0.014), line_segment(point, vec2(-0.09, 0.0), vec2(-0.06, 0.13), 0.014));
		float x_mark = max(line_segment(point, vec2(-0.01, -0.06), vec2(0.08, 0.07), 0.014), line_segment(point, vec2(0.08, -0.06), vec2(-0.01, 0.07), 0.014));
		float right_parenthesis = max(line_segment(point, vec2(0.13, -0.13), vec2(0.16, 0.0), 0.014), line_segment(point, vec2(0.16, 0.0), vec2(0.13, 0.13), 0.014));
		return max(f_mark, max(left_parenthesis, max(x_mark, right_parenthesis)));
	}
	if (kind < 3.0) {
		// Infinity
		float left_loop = smoothstep(0.035, 0.0, abs(length(point - vec2(-0.08, 0.0)) - 0.09));
		float right_loop = smoothstep(0.035, 0.0, abs(length(point - vec2(0.08, 0.0)) - 0.09));
		return max(left_loop, right_loop) * step(abs(point.y), 0.10);
	}
	if (kind < 4.0) {
		// Partial derivative
		float loop = smoothstep(0.028, 0.0, abs(length(point - vec2(0.03, 0.04)) - 0.11));
		float stem = line_segment(point, vec2(-0.07, 0.06), vec2(-0.03, -0.14), 0.016);
		float hook = line_segment(point, vec2(-0.03, -0.14), vec2(0.08, -0.17), 0.016);
		return max(loop, max(stem, hook));
	}
	if (kind < 5.0) {
		// y'
		float y_mark = max(line_segment(point, vec2(-0.12, -0.11), vec2(0.0, 0.04), 0.016), max(line_segment(point, vec2(0.12, -0.11), vec2(0.0, 0.04), 0.016), line_segment(point, vec2(0.0, 0.04), vec2(-0.05, 0.17), 0.016)));
		float prime_mark = line_segment(point, vec2(0.13, -0.17), vec2(0.17, -0.10), 0.014);
		return max(y_mark, prime_mark);
	}
	if (kind < 6.0) {
		// Double integral
		float left_integral = smoothstep(0.018, 0.0, abs(point.x + 0.07 - sin(point.y * 12.0) * 0.035)) * step(abs(point.y), 0.16);
		float right_integral = smoothstep(0.018, 0.0, abs(point.x - 0.07 - sin(point.y * 12.0) * 0.035)) * step(abs(point.y), 0.16);
		return max(left_integral, right_integral);
	}
	if (kind < 7.0) {
		// Product
		float top = line_segment(point, vec2(-0.13, -0.15), vec2(0.13, -0.15), 0.018);
		float left = line_segment(point, vec2(-0.12, -0.15), vec2(-0.12, 0.15), 0.018);
		float right = line_segment(point, vec2(0.12, -0.15), vec2(0.12, 0.15), 0.018);
		return max(top, max(left, right));
	}
	if (kind < 8.0) {
		// Delta
		float left = line_segment(point, vec2(0.0, -0.16), vec2(-0.15, 0.15), 0.018);
		float right = line_segment(point, vec2(0.0, -0.16), vec2(0.15, 0.15), 0.018);
		float base = line_segment(point, vec2(-0.15, 0.15), vec2(0.15, 0.15), 0.018);
		return max(left, max(right, base));
	}
	if (kind < 9.0) {
		// Not equal
		float upper_line = line_segment(point, vec2(-0.15, -0.06), vec2(0.15, -0.06), 0.016);
		float lower_line = line_segment(point, vec2(-0.15, 0.06), vec2(0.15, 0.06), 0.016);
		float slash = line_segment(point, vec2(-0.10, 0.15), vec2(0.10, -0.15), 0.018);
		return max(upper_line, max(lower_line, slash));
	}
	// Approximately equal
	float upper_wave = abs(point.y + 0.055 - sin(point.x * 18.0) * 0.025);
	float lower_wave = abs(point.y - 0.055 - sin(point.x * 18.0) * 0.025);
	return max(smoothstep(0.018, 0.0, upper_wave), smoothstep(0.018, 0.0, lower_wave)) * step(abs(point.x), 0.16);
}

vec3 shooting_stars(vec2 uv, float horizon, float intensity) {
	vec2 pixel_uv = floor(uv * vec2(320.0, 180.0)) / vec2(320.0, 180.0);
	vec3 streak_color = vec3(0.0);
	for (int lane = 0; lane < 6; lane++) {
		float lane_seed = hash21(vec2(float(lane), 37.0));
		float duration = mix(2.8, 5.4, lane_seed);
		float cycle = floor(TIME / duration + lane_seed * 11.0);
		float spawn_seed = hash21(vec2(float(lane) * 5.7, cycle + 71.0));
		float is_active = step(1.0 - intensity * 0.32, spawn_seed);
		float progress = fract(TIME / duration + lane_seed * 11.0);
		vec2 direction = normalize(vec2(1.0, mix(0.34, 0.52, lane_seed)));
		vec2 start = vec2(mix(-0.20, 0.56, hash21(vec2(cycle, lane_seed))), mix(0.08, 0.27, hash21(vec2(lane_seed, cycle + 9.0))));
		vec2 head = start + direction * progress * 1.15;
		float trail_length = mix(0.035, 0.085, hash21(vec2(cycle + 3.0, lane_seed)));
		float core = line_segment(pixel_uv, head - direction * trail_length, head, 0.00175);
		float glow = line_segment(pixel_uv, head - direction * trail_length, head, 0.005) * 0.16;
		float sky_mask = step(pixel_uv.y, horizon - 0.035);
		vec3 color = mix(vec3(1.0), vec3(0.42, 0.86, 1.0), lane_seed) * (core * 0.68 + glow);
		streak_color += color * is_active * sky_mask;
	}
	return streak_color;
}

void fragment() {
	vec2 uv = UV;
	float horizon = 0.43;
	float ground = max((uv.y - horizon) / (1.0 - horizon), 0.0);
	float kitten_blend = clamp(stage, 0.0, 1.0);
	float big_cat_blend = clamp(stage - 1.0, 0.0, 1.0);
	float tiger_blend = clamp(stage - 2.0, 0.0, 1.0);
	float nerd_cat_blend = clamp(stage - 3.0, 0.0, 1.0);
	float grade_eleven_blend = smoothstep(10.0, 11.0, grade) * (1.0 - smoothstep(11.0, 12.0, grade));
	float light_blue_palette_blend = smoothstep(11.0, 12.0, grade);

	vec3 black = vec3(0.0);
	vec3 purple = vec3(0.055, 0.014, 0.105);
	vec3 magenta = vec3(0.34, 0.05, 0.36);
	vec3 sky = mix(black, purple, kitten_blend * smoothstep(0.0, horizon, uv.y));
	sky = mix(sky, mix(vec3(0.08, 0.03, 0.23), magenta, uv.y / horizon), big_cat_blend * step(uv.y, horizon));
	sky = mix(sky, mix(vec3(0.16, 0.04, 0.33), vec3(0.94, 0.22, 0.47), uv.y / horizon), tiger_blend * step(uv.y, horizon));
	sky = mix(sky, mix(black, vec3(0.015, 0.10, 0.055), smoothstep(0.0, horizon, uv.y)), grade_eleven_blend);
	sky = mix(sky, mix(black, vec3(0.06, 0.22, 0.42), smoothstep(0.0, horizon, uv.y)), light_blue_palette_blend);

	float star_field = 0.0;
	if (kitten_blend > 0.0 && uv.y < horizon) {
		vec2 star_cell = floor(uv * vec2(42.0, 20.0));
		float star_seed = hash21(star_cell);
		vec2 star_center = fract(uv * vec2(42.0, 20.0)) - 0.5;
		float twinkle = 0.55 + 0.45 * sin(TIME * (1.2 + star_seed * 1.8) + star_seed * 18.0);
		float star_threshold = mix(0.975, 0.94, big_cat_blend);
		star_field = smoothstep(0.075, 0.0, length(star_center)) * step(star_threshold, star_seed) * twinkle * kitten_blend;
	}

	float safe_ground = max(ground, 0.025);
	float vertical_phase = abs(fract((uv.x - 0.5) / safe_ground * 11.0) - 0.5);
	float vertical_lines = smoothstep(0.055, 0.0, vertical_phase);
	float horizontal_phase = abs(fract(1.5 / safe_ground + TIME * grid_speed * 1.5) - 0.5);
	float horizontal_lines = smoothstep(0.058, 0.0, horizontal_phase);
	float grid = (vertical_lines + horizontal_lines) * step(horizon, uv.y);

	vec3 grid_color = vec3(0.62, 0.38, 1.0);
	grid_color = mix(grid_color, vec3(0.62, 0.38, 1.0), kitten_blend);
	grid_color = mix(grid_color, vec3(1.0, 0.62, 0.20), big_cat_blend);
	grid_color = mix(grid_color, vec3(1.0, 0.86, 0.18), tiger_blend);
	grid_color = mix(grid_color, vec3(1.0), nerd_cat_blend);
	grid_color = mix(grid_color, vec3(0.35, 1.0, 0.55), grade_eleven_blend);
	grid_color = mix(grid_color, vec3(0.48, 0.80, 1.0), light_blue_palette_blend);
	if (grid_color_override_enabled) {
		grid_color = grid_color_override.rgb;
	}
	float grid_fade = smoothstep(0.02, 0.52, ground);
	float horizon_glow = exp(-abs(uv.y - horizon) * 22.0) * (kitten_blend * 0.06 + big_cat_blend * 0.06 + tiger_blend * 0.20);

	float symbols = 0.0;
	if (nerd_cat_blend > 0.0 && uv.y < horizon) {
		vec2 symbol_cell = floor(uv * vec2(7.0, 4.0));
		float seed = hash21(symbol_cell + 19.0);
		float symbol_kind = floor(hash21(symbol_cell + 41.0) * 2.0);
		float infinity_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(1.0, 0.0)));
		float approximately_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(5.0, 1.0)));
		float partial_derivative_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(6.0, 0.0)));
		float y_prime_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(0.0, 0.0)));
		float double_integral_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(3.0, 0.0)));
		float product_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(6.0, 1.0)));
		float delta_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(5.0, 0.0)));
		float not_equal_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(1.0, 1.0)));
		float f_x_cell = 1.0 - step(0.1, distance(symbol_cell, vec2(0.0, 1.0)));
		symbol_kind = mix(symbol_kind, 2.0, infinity_cell);
		symbol_kind = mix(symbol_kind, 3.0, approximately_cell);
		symbol_kind = mix(symbol_kind, 4.0, partial_derivative_cell);
		symbol_kind = mix(symbol_kind, 5.0, y_prime_cell);
		symbol_kind = mix(symbol_kind, 6.0, double_integral_cell);
		symbol_kind = mix(symbol_kind, 7.0, product_cell);
		symbol_kind = mix(symbol_kind, 8.0, delta_cell);
		symbol_kind = mix(symbol_kind, 9.0, not_equal_cell);
		symbol_kind = mix(symbol_kind, 1.0, f_x_cell);
		vec2 local = fract(uv * vec2(7.0, 4.0)) - 0.5;
		local.y += sin(TIME * 0.28 + seed * 12.0) * 0.10;
		float symbol_visible = max(step(0.72, seed), max(infinity_cell, max(approximately_cell, max(partial_derivative_cell, max(y_prime_cell, max(double_integral_cell, max(product_cell, max(delta_cell, max(not_equal_cell, f_x_cell)))))))));
		float center_f_x = step(0.5, symbol_cell.x) * step(symbol_cell.x, 5.5) * step(0.5, symbol_kind) * (1.0 - step(1.5, symbol_kind));
		symbol_visible *= (1.0 - center_f_x) + f_x_cell;
		symbols = grade_thirteen_math_mark(local, symbol_kind) * symbol_visible * 0.22;
	}

	vec3 color = sky;
	color += grid * grid_fade * grid_color * (0.55 + ground * 0.45);
	vec3 horizon_color = mix(vec3(0.48, 0.20, 0.92), vec3(1.0, 0.25, 0.42), big_cat_blend);
	horizon_color = mix(horizon_color, vec3(1.0, 0.53, 0.16), tiger_blend);
	horizon_color = mix(horizon_color, vec3(0.34, 0.72, 1.0), light_blue_palette_blend);
	color += horizon_glow * horizon_color;
	color += star_field * mix(vec3(0.28, 0.56, 1.0), vec3(1.0, 0.58, 0.82), tiger_blend);
	color += shooting_stars(uv, horizon, shooting_star_intensity);
	color += symbols * vec3(0.40, 0.82, 1.0);
	COLOR = vec4(color, 1.0);
}