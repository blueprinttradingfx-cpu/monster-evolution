@tool
extends EditorScript

func _run() -> void:
	# Ensure all directories exist
	_ensure_dir("res://assets/sprites")
	_ensure_dir("res://assets/sprites/face")

	# --- Generate all assets ---
	_generate_head()
	_generate_body()
	_generate_limbs()
	_generate_legs()
	_generate_parts()

	print("--- ALL PET TEMPLATES GENERATED ---")
	print("All files saved to res://assets/sprites/ and res://assets/sprites/face/")
	print("If missing, press Ctrl+R to reload FileSystem panel.")
	get_editor_interface().get_resource_filesystem().scan()

func _ensure_dir(path: String) -> void:
	var global_dir := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

func _save_image(path: String, img: Image) -> void:
	var global_path := ProjectSettings.globalize_path(path)
	img.save_png(global_path)

# ---------------------------------------------------------------------------
# HEAD TEMPLATE
# ---------------------------------------------------------------------------
func _generate_head() -> void:
	var canvas_size := Vector2i(128, 128)
	var image := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	
	# Clear canvas with full transparency
	image.fill(Color(0, 0, 0, 0))
	
	# The head center will be positioned slightly higher in the 128x128 box 
	# to leave room at the bottom for the neck joint curve
	var head_center := Vector2(64, 55)
	var radius := 42.0
	
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			var current_pixel := Vector2(x, y)
			var dist := current_pixel.distance_to(head_center)
			
			# Draw head shape
			if dist <= radius:
				# Soft matching blue tone gradient
				var blend_factor := (y - 15.0) / 80.0
				var pixel_color := Color(0.25, 0.55, 0.95, 0.9).lerp(Color(0.12, 0.32, 0.72, 0.95), blend_factor)
				
				# Add a subtle rim highlight at the top to indicate a rounded skull curve
				if dist > radius - 2.5 and y < 55:
					pixel_color = Color(0.6, 0.85, 1.0, 1.0)
					
				image.set_pixel(x, y, pixel_color)

	_save_image("res://assets/sprites/head_default.png", image)

# ---------------------------------------------------------------------------
# BODY TEMPLATE
# ---------------------------------------------------------------------------
func _generate_body() -> void:
	var canvas_size := Vector2i(256, 256)
	var image := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	
	# Fill with alpha transparency
	image.fill(Color(0, 0, 0, 0))
	
	var body_center := Vector2(128, 128)
	var radius := 50.0
	
	# Build a clean capsule-shaped placeholder body template
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			var current_pixel := Vector2(x, y)
			var dist_top := current_pixel.distance_to(body_center + Vector2(0, -15))
			var dist_bottom := current_pixel.distance_to(body_center + Vector2(0, 20))
			
			if dist_top <= radius or dist_bottom <= (radius * 1.1):
				var blend_factor := (y - 60.0) / 140.0
				var pixel_color := Color(0.2, 0.5, 0.9, 0.85).lerp(Color(0.1, 0.3, 0.7, 0.95), blend_factor)
				
				if dist_top > radius - 3.0 and y < 128:
					pixel_color = Color(0.5, 0.8, 1.0, 1.0)
					
				image.set_pixel(x, y, pixel_color)

	_save_image("res://assets/sprites/body_default.png", image)

# ---------------------------------------------------------------------------
# LIMBS TEMPLATE
# ---------------------------------------------------------------------------
func _generate_limbs() -> void:
	var canvas_size := Vector2i(64, 64)
	
	# --- 1. GENERATE UPPER ARM (SHOULDER) ---
	var img_root := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	img_root.fill(Color(0, 0, 0, 0))
	
	# Draw an elongated capsule starting from the left (shoulder pivot) toward the right (elbow)
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			var current_pixel := Vector2(x, y)
			# Capsule centerline from (16, 32) to (48, 32)
			var distance_to_segment = _dist_to_line_segment(current_pixel, Vector2(16, 32), Vector2(48, 32))
			
			if distance_to_segment <= 14.0:
				var blend := float(x) / 64.0
				var pixel_color := Color(0.22, 0.52, 0.92, 0.9).lerp(Color(0.15, 0.35, 0.75, 0.95), blend)
				img_root.set_pixel(x, y, pixel_color)
				
	# --- 2. GENERATE LOWER ARM (HAND) ---
	var img_tip := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	img_tip.fill(Color(0, 0, 0, 0))
	
	# Draw a smaller tapering piece pointing towards a hand/paws shape at the right edge
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			var current_pixel := Vector2(x, y)
			var distance_to_segment = _dist_to_line_segment(current_pixel, Vector2(10, 32), Vector2(42, 32))
			var hand_bubble := current_pixel.distance_to(Vector2(45, 32))
			
			if distance_to_segment <= 10.0 or hand_bubble <= 13.0:
				var blend := float(x) / 64.0
				var pixel_color := Color(0.25, 0.55, 0.95, 0.9).lerp(Color(0.1, 0.3, 0.7, 0.95), blend)
				img_tip.set_pixel(x, y, pixel_color)

	_save_image("res://assets/sprites/arm_root_default.png", img_root)
	_save_image("res://assets/sprites/arm_tip_default.png", img_tip)

# ---------------------------------------------------------------------------
# LEGS TEMPLATE
# ---------------------------------------------------------------------------
func _generate_legs() -> void:
	var canvas_size := Vector2i(64, 64)
	
	# --- 1. GENERATE UPPER THIGH ---
	var img_thigh := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	img_thigh.fill(Color(0, 0, 0, 0))
	
	# Draw a thick, sturdy upper thigh circle tapering slightly downwards
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			var current_pixel := Vector2(x, y)
			var dist_to_joint = _dist_to_line_segment(current_pixel, Vector2(32, 16), Vector2(32, 44))
			
			if dist_to_joint <= 16.0 - (float(y) * 0.08):
				var blend := float(y) / 64.0
				var pixel_color := Color(0.20, 0.50, 0.90, 0.95).lerp(Color(0.12, 0.32, 0.70, 0.95), blend)
				img_thigh.set_pixel(x, y, pixel_color)
				
	# --- 2. GENERATE LOWER FOOT / PAW ---
	var img_foot := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	img_foot.fill(Color(0, 0, 0, 0))
	
	# Draw a flat-bottomed platform paw asset
	for y in range(canvas_size.y):
		for x in range(canvas_size.x):
			var current_pixel := Vector2(x, y)
			var dist_to_heel = _dist_to_line_segment(current_pixel, Vector2(24, 20), Vector2(44, 20))
			var toe_bubble = current_pixel.distance_to(Vector2(40, 36))
			
			if dist_to_heel <= 12.0 or (toe_bubble <= 14.0 and y >= 20):
				var blend := float(y) / 64.0
				var pixel_color := Color(0.22, 0.52, 0.92, 0.95).lerp(Color(0.10, 0.28, 0.65, 0.95), blend)
				img_foot.set_pixel(x, y, pixel_color)

	_save_image("res://assets/sprites/leg_root_default.png", img_thigh)
	_save_image("res://assets/sprites/leg_tip_default.png", img_foot)

# ---------------------------------------------------------------------------
# PARTS TEMPLATE (FACE PARTS)
# ---------------------------------------------------------------------------
const CANVAS_SIZE := Vector2i(128, 96)
const SAVE_DIR := "res://assets/sprites/face/"

func _generate_parts() -> void:
	# --- Generate all 4 Eye States ---
	_save_image(SAVE_DIR + "eyes_default.png", _draw_eyes_default())
	_save_image(SAVE_DIR + "eyes_happy.png",   _draw_eyes_happy())
	_save_image(SAVE_DIR + "eyes_closed.png",  _draw_eyes_closed())
	_save_image(SAVE_DIR + "eyes_wide.png",    _draw_eyes_wide())

	# --- Generate all 4 Mouth States ---
	_save_image(SAVE_DIR + "mouth_default.png", _draw_mouth_default())
	_save_image(SAVE_DIR + "mouth_smile.png",   _draw_mouth_smile())
	_save_image(SAVE_DIR + "mouth_flat.png",    _draw_mouth_flat())
	_save_image(SAVE_DIR + "mouth_open.png",    _draw_mouth_open())

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

func _create_blank_canvas() -> Image:
	var img := Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Clean alpha slate
	return img

# ---------------------------------------------------------------------------
# HELPER MATH FUNCTION
# ---------------------------------------------------------------------------
func _dist_to_line_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
