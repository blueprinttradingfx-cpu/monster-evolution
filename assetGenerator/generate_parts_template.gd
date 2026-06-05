@tool
extends EditorScript

const CANVAS_SIZE := Vector2i(128, 96)
const SAVE_DIR := "res://assets/sprites/face/"

func _run() -> void:
	# Ensure the filesystem directory exists
	var global_dir = ProjectSettings.globalize_path(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	# --- Generate all 4 Eye States ---
	_save_image("eyes_default.png", _draw_eyes_default())
	_save_image("eyes_happy.png",   _draw_eyes_happy())
	_save_image("eyes_closed.png",  _draw_eyes_closed())
	_save_image("eyes_wide.png",    _draw_eyes_wide())

	# --- Generate all 4 Mouth States ---
	_save_image("mouth_default.png", _draw_mouth_default())
	_save_image("mouth_smile.png",   _draw_mouth_smile())
	_save_image("mouth_flat.png",    _draw_mouth_flat())
	_save_image("mouth_open.png",    _draw_mouth_open())

	print("--- FACE ENGINE NOTICE ---")
	print("All 8 expression assets generated successfully inside: ", SAVE_DIR)
	print("--------------------------")
	get_editor_interface().get_resource_filesystem().scan()

# ---------------------------------------------------------------------------
# DRAW FUNCTIONS (EYES)
# ---------------------------------------------------------------------------

func _draw_eyes_default() -> Image:
	var img := _create_blank_canvas()
	# Two clean, dark oval anime-style eyes with small cute pupils
	var left_center := Vector2(44, 48)
	var right_center := Vector2(84, 48)
	
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			var p := Vector2(x, y)
			# Outer Eye
			if p.distance_to(left_center) <= 8.0 or p.distance_to(right_center) <= 8.0:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
			# Eye Highlights
			if p.distance_to(left_center + Vector2(-3, -3)) <= 2.5 or p.distance_to(right_center + Vector2(-3, -3)) <= 2.5:
				img.set_pixel(x, y, Color.WHITE)
	return img

func _draw_eyes_happy() -> Image:
	var img := _create_blank_canvas()
	# Curved inverted "V" arcs (^^) for happy waving expressions
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			# Left Eye Arc
			var left_arc := y - (-0.4 * pow(x - 44, 2) + 48)
			# Right Eye Arc
			var right_arc := y - (-0.4 * pow(x - 84, 2) + 48)
			
			if (abs(left_arc) <= 2.5 and x >= 34 and x <= 54) or (abs(right_arc) <= 2.5 and x >= 74 and x <= 94):
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
	return img

func _draw_eyes_closed() -> Image:
	var img := _create_blank_canvas()
	# Flat horizontal slit lines for a content, sleeping, or sighing look
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			if (y >= 46 and y <= 49) and ((x >= 34 and x <= 54) or (x >= 74 and x <= 94)):
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
	return img

func _draw_eyes_wide() -> Image:
	var img := _create_blank_canvas()
	# Massive panic circles for when the pet is grabbed and dragged around
	var left_center := Vector2(42, 48)
	var right_center := Vector2(86, 48)
	
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			var p := Vector2(x, y)
			var d_l := p.distance_to(left_center)
			var d_r := p.distance_to(right_center)
			
			# White eyeballs
			if d_l <= 14.0 or d_r <= 14.0:
				img.set_pixel(x, y, Color.WHITE)
			# Dark Outer Rim
			if (d_l > 12.5 and d_l <= 14.5) or (d_r > 12.5 and d_r <= 14.5):
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
			# Small Shrunk Pupils in the center
			if d_l <= 4.0 or d_r <= 4.0:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
	return img

# ---------------------------------------------------------------------------
# DRAW FUNCTIONS (MOUTHS)
# ---------------------------------------------------------------------------

func _draw_mouth_default() -> Image:
	var img := _create_blank_canvas()
	# A clean, slightly curved tiny neutral smile line
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			var smile_arc := y - (0.15 * pow(x - 64, 2) + 68)
			if abs(smile_arc) <= 1.5 and x >= 56 and x <= 72:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
	return img

func _draw_mouth_smile() -> Image:
	var img := _create_blank_canvas()
	# A wide open, joyful crescent-shaped open smile showing a pink tongue
	var mouth_center := Vector2(64, 66)
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			var p := Vector2(x, y)
			var d := p.distance_to(mouth_center)
			
			if d <= 12.0 and y >= 66:
				if p.distance_to(mouth_center + Vector2(0, 6)) <= 6.0:
					img.set_pixel(x, y, Color(1.0, 0.4, 0.5, 1.0)) # Tongue color
				else:
					img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0)) # Inner mouth dark tone
			# Clean outline frame across the top slice lip
			if y == 66 and x >= 52 and x <= 76:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
	return img

func _draw_mouth_flat() -> Image:
	var img := _create_blank_canvas()
	# A straight flat line for a direct, unimpressed, or sighing face
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			if (y >= 68 and y <= 70) and (x >= 56 and x <= 72):
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
	return img

func _draw_mouth_open() -> Image:
	var img := _create_blank_canvas()
	# A vertical gasp oval (O:) for surprised or panicked tracking states
	var mouth_center := Vector2(64, 70)
	for y in range(CANVAS_SIZE.y):
		for x in range(CANVAS_SIZE.x):
			var p := Vector2(x, y)
			# Scale the coordinate space vector vertically to create an oval shape matrix
			var oval_dist := sqrt(pow(p.x - mouth_center.x, 2) + pow((p.y - mouth_center.y) * 0.65, 2))
			
			if oval_dist <= 7.0:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, 1.0))
			if oval_dist > 5.5 and oval_dist <= 7.0:
				img.set_pixel(x, y, Color(0.05, 0.05, 0.08, 1.0))
	return img

# ---------------------------------------------------------------------------
# CORE WRITER UTILITIES
# ---------------------------------------------------------------------------

func _create_blank_canvas() -> Image:
	var img := Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Clean alpha slate
	return img

func _save_image(filename: String, img: Image) -> void:
	var full_path := SAVE_DIR + filename
	var global_path := ProjectSettings.globalize_path(full_path)
	img.save_png(global_path)
