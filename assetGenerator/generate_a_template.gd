@tool
extends EditorScript

const SPRITES_PATH = "res://assets/sprites"
const FACE_PATH = "res://assets/sprites/face"

func _run() -> void:
	# Ensure directory pathways exist safely
	_ensure_dir(SPRITES_PATH)
	_ensure_dir(FACE_PATH)

	# --- Execute Full Axie-Style Generation Matrix ---
	_generate_axie_body()
	_generate_axie_head()
	_generate_axie_limbs()
	_generate_axie_legs()
	_generate_axie_faces()

	print("--- AXIE PET CHARACTER COMPONENT GENERATION COMPLETE ---")
	print("All vectors rendered to res://assets/sprites/ and face/ subfolders!")
	print("Press Ctrl + R over your FileSystem panel if Godot delays importing.")
	get_editor_interface().get_resource_filesystem().scan()

func _ensure_dir(path: String) -> void:
	var global_dir := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

func _save_image(path: String, img: Image) -> void:
	var global_path := ProjectSettings.globalize_path(path)
	img.save_png(global_path)

# ---------------------------------------------------------------------------
# 1. FLUFFY MAIN BODY LAYER
# ---------------------------------------------------------------------------
func _generate_axie_body() -> void:
	var size := Vector2i(256, 256)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0))
	
	var center := Vector2(128, 135)
	var base_radius := 66.0
	var tuft_count := 13
	var tuft_depth := 6.5
	var stroke := 4.0
	
	var stroke_color := Color(0.12, 0.12, 0.16, 1.0)
	var base_blue := Color(0.24, 0.58, 0.95, 1.0)
	var shadow_blue := Color(0.14, 0.35, 0.72, 1.0)

	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var to_center := p - center
			var dist := to_center.length()
			
			if dist > base_radius + tuft_depth + 6.0: continue
			
			var angle := to_center.angle()
			var fluff := sin(angle * tuft_count) * tuft_depth
			
			# Axie-style pear/blob distortion profile (wider at bottom, narrower at top)
			var pear_shape := 1.0 + (y - center.y) * 0.0016
			var dynamic_radius := (base_radius + fluff) * pear_shape
			
			if dist <= dynamic_radius:
				if dist > dynamic_radius - stroke:
					img.set_pixel(x, y, stroke_color)
				else:
					var blend := (y - (center.y - base_radius)) / (base_radius * 2.0)
					var col := base_blue.lerp(shadow_blue, clampf(blend, 0.0, 1.0))
					
					# Soft volume lighting core highlight
					var hi_dist := p.distance_to(center + Vector2(-12, -22))
					if hi_dist < base_radius * 0.55:
						var hi_factor := 1.0 - (hi_dist / (base_radius * 0.55))
						col = col.lerp(Color(0.6, 0.82, 1.0, 1.0), hi_factor * 0.35)
					img.set_pixel(x, y, col)
					
	_save_image(SPRITES_PATH + "/body_default.png", img)

# ---------------------------------------------------------------------------
# 2. FLUFFY OVERLAY HEAD LAYER
# ---------------------------------------------------------------------------
func _generate_axie_head() -> void:
	var size := Vector2i(128, 128)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0))
	
	var center := Vector2(64, 64)
	var base_radius := 38.0
	var tuft_count := 9
	var tuft_depth := 4.5
	var stroke := 3.5
	
	var stroke_color := Color(0.12, 0.12, 0.16, 1.0)
	var base_blue := Color(0.24, 0.58, 0.95, 1.0)
	var shadow_blue := Color(0.16, 0.38, 0.76, 1.0)

	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var to_center := p - center
			var dist := to_center.length()
			
			if dist > base_radius + tuft_depth + 5.0: continue
			
			var angle := to_center.angle()
			var fluff := sin(angle * tuft_count) * tuft_depth
			
			# To this (with explicit float types):
			var horizontal_skew: float = 1.0 + (1.0 - absf(to_center.y) / base_radius) * 0.12
			var dynamic_radius: float = (base_radius + fluff) * horizontal_skew
			
			if dist <= dynamic_radius:
				if dist > dynamic_radius - stroke:
					img.set_pixel(x, y, stroke_color)
				else:
					var blend := (y - (center.y - base_radius)) / (base_radius * 2.0)
					var col := base_blue.lerp(shadow_blue, clampf(blend, 0.0, 1.0))
					
					var hi_dist := p.distance_to(center + Vector2(-6, -10))
					if hi_dist < base_radius * 0.5:
						var hi_factor := 1.0 - (hi_dist / (base_radius * 0.5))
						col = col.lerp(Color(0.62, 0.84, 1.0, 1.0), hi_factor * 0.3)
					img.set_pixel(x, y, col)
					
	_save_image(SPRITES_PATH + "/head_default.png", img)

# ---------------------------------------------------------------------------
# 3. ARM SEGMENTS (ROOT & TAPERED FOREARMS)
# ---------------------------------------------------------------------------
func _generate_axie_limbs() -> void:
	var size := Vector2i(64, 64)
	var stroke_color := Color(0.12, 0.12, 0.16, 1.0)
	var fill_color := Color(0.24, 0.58, 0.95, 1.0)
	
	# --- UPPER ARM ROOT ---
	var img_root := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_root.fill(Color(0,0,0,0))
	# Draw a smooth structural horizontal joint socket capsule
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var dist := _dist_to_segment(p, Vector2(12, 32), Vector2(52, 32))
			if dist <= 14.0:
				if dist > 11.0: img_root.set_pixel(x, y, stroke_color)
				else: img_root.set_pixel(x, y, fill_color)
	_save_image(SPRITES_PATH + "/arm_root_default.png", img_root)

	# --- FOREARM HAND TIP ---
	var img_tip := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_tip.fill(Color(0,0,0,0))
	# Draw a teardrop nub containing vector separations for little fingers
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var dist := _dist_to_segment(p, Vector2(16, 32), Vector2(44, 32))
			var taper := 14.0 - (float(x - 16) * 0.12) # Taper outwards gently
			if dist <= taper:
				if dist > taper - 3.0: img_tip.set_pixel(x, y, stroke_color)
				else: img_tip.set_pixel(x, y, fill_color.lerp(Color.WHITE, 0.1))
	_save_image(SPRITES_PATH + "/arm_tip_default.png", img_tip)

# ---------------------------------------------------------------------------
# 4. MATCHING COMPACT PLATFORM LEGS
# ---------------------------------------------------------------------------
func _generate_axie_legs() -> void:
	var size := Vector2i(64, 64)
	var stroke_color := Color(0.12, 0.12, 0.16, 1.0)
	var root_color := Color(0.16, 0.38, 0.76, 1.0) # Sits behind body, uses shadow profile
	var foot_color := Color(0.24, 0.58, 0.95, 1.0)

	# --- UPPER THIGH / HIP JOINT ---
	var img_thigh := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_thigh.fill(Color(0,0,0,0))
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var dist := _dist_to_segment(p, Vector2(32, 12), Vector2(32, 52))
			if dist <= 15.0:
				if dist > 12.0: img_thigh.set_pixel(x, y, stroke_color)
				else: img_thigh.set_pixel(x, y, root_color)
	_save_image(SPRITES_PATH + "/leg_root_default.png", img_thigh)

	# --- LOWER FLAT-BOTTOMED FOOT PAW ---
	var img_foot := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_foot.fill(Color(0,0,0,0))
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var dist_heel := _dist_to_segment(p, Vector2(20, 24), Vector2(44, 24))
			var toe_nub := p.distance_to(Vector2(42, 38))
			
			if dist_heel <= 13.0 or (toe_nub <= 14.0 and y >= 24):
				# Combine shapes and inject a clean outer boundary
				var is_stroke := dist_heel > 10.0 and dist_heel <= 13.0
				if toe_nub > 11.0 and toe_nub <= 14.0 and y >= 24: is_stroke = true
				
				# Flatten baseline floor contact layout path
				if y >= 46 and y <= 49 and x >= 14 and x <= 46: is_stroke = true
				if y > 49: continue # Trim excess drop bleeding
				
				if is_stroke: img_foot.set_pixel(x, y, stroke_color)
				else: img_foot.set_pixel(x, y, foot_color)
	_save_image(SPRITES_PATH + "/leg_tip_default.png", img_foot)

# ---------------------------------------------------------------------------
# 5. DYNAMIC HIGH-CONTRAST EXPRESSION VECTOR MAPS
# ---------------------------------------------------------------------------
func _generate_axie_faces() -> void:
	var size := Vector2i(128, 128)
	var line_color := Color(0.12, 0.12, 0.16, 1.0)
	
	# --- DEFAULT BASLINE EYES ---
	var img_eyes := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_eyes.fill(Color(0,0,0,0))
	var left_eye := Vector2(44, 58)
	var right_eye := Vector2(84, 58)
	
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var d_l := p.distance_to(left_eye)
			var d_r := p.distance_to(right_eye)
			
			# Large round anime outer scleras
			if d_l <= 11.0 or d_r <= 11.0:
				if d_l > 9.5 or d_r > 9.5:
					img_eyes.set_pixel(x, y, line_color)
				else:
					# High-contrast dark iris vector tracking plates
					if d_l <= 7.0 or d_r <= 7.0:
						# Catchy white specular reflection dots
						var dot_l := p.distance_to(left_eye + Vector2(-3, -3))
						var dot_r := p.distance_to(right_eye + Vector2(-3, -3))
						if dot_l <= 2.2 or dot_r <= 2.2:
							img_eyes.set_pixel(x, y, Color.WHITE)
						else:
							img_eyes.set_pixel(x, y, Color(0.15, 0.15, 0.2, 1.0))
					else:
						img_eyes.set_pixel(x, y, Color.WHITE)
	_save_image(FACE_PATH + "/eyes_default.png", img_eyes)

	# --- WIDE SURPRISED EYES ---
	var img_wide := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_wide.fill(Color(0,0,0,0))
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var d_l := p.distance_to(left_eye)
			var d_r := p.distance_to(right_eye)
			if d_l <= 14.0 or d_r <= 14.0:
				if d_l > 12.0 or d_r > 12.0: img_wide.set_pixel(x, y, line_color)
				elif d_l <= 4.0 or d_r <= 4.0: img_wide.set_pixel(x, y, line_color) # Tiny pin-prick shocked pupils
				else: img_wide.set_pixel(x, y, Color.WHITE)
	_save_image(FACE_PATH + "/eyes_wide.png", img_wide)

	# --- CLOSED HAPPY / BLINKING EYES ---
	var img_closed := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_closed.fill(Color(0,0,0,0))
	# Curved inverted upward smile arches (^^)
	for y in range(size.y):
		for x in range(size.x):
			var dist_l := _dist_to_segment(Vector2(x, y), Vector2(34, 62), Vector2(44, 52))
			var dist_l2 := _dist_to_segment(Vector2(x, y), Vector2(44, 52), Vector2(54, 62))
			var dist_r := _dist_to_segment(Vector2(x, y), Vector2(74, 62), Vector2(84, 52))
			var dist_r2 := _dist_to_segment(Vector2(x, y), Vector2(84, 52), Vector2(94, 62))
			
			var final_d := minf(minf(dist_l, dist_l2), minf(dist_r, dist_r2))
			if final_d <= 2.2: img_closed.set_pixel(x, y, line_color)
	_save_image(FACE_PATH + "/eyes_closed.png", img_closed)

	# --- DEFAULT BASELINE MOUTH SMILE ---
	var img_mouth := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_mouth.fill(Color(0,0,0,0))
	var m_center := Vector2(64, 76)
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var dist := _dist_to_segment(p, Vector2(54, 74), Vector2(74, 74))
			# Curved downward arc check mapping matrices
			if p.y >= 74 and p.y <= 84 and abs(p.x - m_center.x) <= 10:
				var arc := 74.0 + pow(p.x - m_center.x, 2) * 0.08
				if abs(p.y - arc) <= 2.5: img_mouth.set_pixel(x, y, line_color)
	_save_image(FACE_PATH + "/mouth_default.png", img_mouth)

	# --- OPEN SURPRISED MOUTH ---
	var img_open := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_open.fill(Color(0,0,0,0))
	var mo_center := Vector2(64, 78)
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			var oval := sqrt(pow(p.x - mo_center.x, 2) + pow((p.y - mo_center.y) * 0.7, 2))
			if oval <= 7.5:
				if oval > 5.0: img_open.set_pixel(x, y, line_color)
				else: img_open.set_pixel(x, y, Color(0.85, 0.3, 0.35, 1.0)) # Cute pink inner tongue fill cavity
	_save_image(FACE_PATH + "/mouth_open.png", img_open)

	# --- FLAT SIGH / STRAIGHT LINE MOUTH ---
	var img_flat := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_flat.fill(Color(0,0,0,0))
	for y in range(size.y):
		for x in range(size.x):
			if (y >= 76 and y <= 78) and (x >= 55 and x <= 73):
				img_flat.set_pixel(x, y, line_color)
	_save_image(FACE_PATH + "/mouth_flat.png", img_flat)

	# --- HAPPY OPEN SMILE MOUTH ---
	var img_smile := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img_smile.fill(Color(0,0,0,0))
	for y in range(size.y):
		for x in range(size.x):
			var p := Vector2(x, y)
			if p.y >= 73 and p.y <= 85 and abs(p.x - 64) <= 12:
				var upper_lip := 73.0
				var lower_jaw := 73.0 + (12.0 - pow(abs(p.x - 64) * 0.28, 2))
				if p.y >= upper_lip and p.y <= lower_jaw:
					if p.y > lower_jaw - 2.5 or abs(p.x - 64) > 10 or p.y < upper_lip + 2.0:
						img_smile.set_pixel(x, y, line_color)
					else:
						img_smile.set_pixel(x, y, Color(0.85, 0.3, 0.35, 1.0))
	_save_image(FACE_PATH + "/mouth_smile.png", img_smile)

# --- Vector Helper Function ---
func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
