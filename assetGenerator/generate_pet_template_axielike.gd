@tool
extends EditorScript

# =========================================================
# FLUFFY PET TEMPLATE GENERATOR  —  Axie-Style Chibi
# =========================================================
# Drop-in replacement for the original generate_pet_template.gd.
# No changes needed to PetDisplay.gd or PetDisplay.tscn.
#
# WHAT CHANGED vs ORIGINAL:
#  • Thick dark outline on every body part (Axie trademark)
#  • Head:  large chibi circle + round ear bumps + cheek blush
#  • Body:  wide horizontal oval/egg  (not the original tall capsule)
#  • Arms:  short stubby capsule + 3-toe paw blob at the tip
#  • Legs:  chunky vertical nub + flat oval pad + 3 toe bumps
#  • All:   warm peach/tan gradient + specular highlight + AA edges
#  • Eyes:  bigger iris rings with dual specular glints (chibi style)
#
# OPTIONAL — for even better Axie proportions, tweak bone
# offsets in PetDisplay.tscn (not required but recommended):
#
#   HeadBone     position (0,  -55)   ← bring head closer to body
#   FrontArmBone position (-68,  5)   ← sit at body oval edge (rx=65)
#   RearArmBone  position ( 68,  5)
#   FrontLegBone position (-22, 52)   ← hang from oval bottom (ry=48)
#   RearLegBone  position ( 22, 52)
# =========================================================

# --- Color Palette  (change these to reskin the entire pet) ---
const C_BASE      := Color(0.96, 0.80, 0.58, 1.0) # Warm peach / main fill
const C_SHADE     := Color(0.72, 0.52, 0.32, 1.0) # Darker shadow underside
const C_OUTLINE   := Color(0.14, 0.08, 0.04, 1.0) # Deep warm-brown outline
const C_HIGHLIGHT := Color(1.00, 0.97, 0.90, 1.0) # Specular top-left shine
const C_BLUSH     := Color(1.00, 0.60, 0.58, 1.0) # Cheek blush pink
const C_INNER_EAR := Color(1.00, 0.70, 0.73, 1.0) # Inner ear petal pink

# --- Rendering knobs ---
const OUTLINE_W := 3.2  # Outline thickness in pixels
const FEATHER_W := 1.5  # Anti-alias softness at outer edge

# ─────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────
func _run() -> void:
	_ensure_dir("res://assets/sprites")
	_ensure_dir("res://assets/sprites/face")
	_generate_head()
	_generate_body()
	_generate_limbs()
	_generate_legs()
	_generate_parts()
	print("--- FLUFFY CHIBI TEMPLATES GENERATED ---")
	print("Sprites saved to res://assets/sprites/ and face/")
	get_editor_interface().get_resource_filesystem().scan()

func _ensure_dir(path: String) -> void:
	var gp := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(gp):
		DirAccess.make_dir_recursive_absolute(gp)

func _save_image(path: String, img: Image) -> void:
	img.save_png(ProjectSettings.globalize_path(path))

# ─────────────────────────────────────────────────────────
# LOW-LEVEL PIXEL HELPERS
# ─────────────────────────────────────────────────────────

# Alpha-blend a colour over the existing pixel at (x, y).
func _blend(img: Image, x: int, y: int, col: Color, a: float) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height(): return
	if a <= 0.0: return
	var bg: Color = img.get_pixel(x, y)
	img.set_pixel(x, y, bg.blend(Color(col.r, col.g, col.b, col.a * clampf(a, 0.0, 1.0))))

# Compute the warm gradient+specular colour for a pixel inside a shape.
# center / r_approx are the shape's visual centre and approximate half-size.
# Pass Color.TRANSPARENT for blush to skip it.
func _body_colour(pv: Vector2, center: Vector2, r_approx: float,
		base: Color, shade: Color, high: Color,
		blush: Color = Color.TRANSPARENT) -> Color:
	# Top-to-bottom gradient
	var gy: float = clampf((pv.y - (center.y - r_approx)) / (r_approx * 2.0), 0.0, 1.0)
	var c: Color = base.lerp(shade, gy * 0.55)
	# Specular bubble (upper-left)
	var sd: float = pv.distance_to(center + Vector2(-r_approx * 0.30, -r_approx * 0.32))
	if sd < r_approx * 0.42:
		c = c.lerp(high, (1.0 - sd / (r_approx * 0.42)) * 0.72)
	# Cheek blush (two soft circles, lower-left and lower-right)
	if blush.a > 0.001:
		var br: float = r_approx * 0.30
		var bdl: float = pv.distance_to(center + Vector2(-r_approx * 0.44,  r_approx * 0.22))
		var bdr: float = pv.distance_to(center + Vector2( r_approx * 0.44,  r_approx * 0.22))
		if bdl < br: c = c.lerp(blush, (1.0 - bdl / br) * 0.40)
		if bdr < br: c = c.lerp(blush, (1.0 - bdr / br) * 0.40)
	return c

# ─────────────────────────────────────────────────────────
# SHAPE PRIMITIVES  — each draws: fill → solid outline → feathered AA edge
# ─────────────────────────────────────────────────────────

# CIRCLE — pass ow=0.0 for inner fills with no outline
func _draw_circle(img: Image, cx: float, cy: float, r: float,
		base: Color, shade: Color, high: Color,
		blush: Color = Color.TRANSPARENT,
		ow: float = OUTLINE_W, fw: float = FEATHER_W) -> void:
	var W: int = img.get_width()
	var H: int = img.get_height()
	var rt: float = r + ow + fw
	var cv: Vector2 = Vector2(cx, cy)
	for py in range(max(0, int(cy - rt - 1)), min(H, int(cy + rt + 2))):
		for px in range(max(0, int(cx - rt - 1)), min(W, int(cx + rt + 2))):
			var pv: Vector2 = Vector2(px, py)
			var d: float = pv.distance_to(cv)
			if   d <= r:           _blend(img, px, py, _body_colour(pv, cv, r, base, shade, high, blush), 1.0)
			elif d <= r + ow:      _blend(img, px, py, C_OUTLINE, 1.0)
			elif d <= rt:          _blend(img, px, py, C_OUTLINE, clampf((rt - d) / fw, 0.0, 1.0))

# HORIZONTAL ELLIPSE
func _draw_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float,
		base: Color, shade: Color, high: Color,
		ow: float = OUTLINE_W, fw: float = FEATHER_W) -> void:
	var W: int = img.get_width()
	var H: int = img.get_height()
	var ortx: float = rx + ow
	var orty: float = ry + ow
	var ftx: float = ortx + fw
	var fty: float = orty + fw
	var cv: Vector2 = Vector2(cx, cy)
	var ra: float = min(rx, ry)
	for py in range(max(0, int(cy - fty - 1)), min(H, int(cy + fty + 2))):
		for px in range(max(0, int(cx - ftx - 1)), min(W, int(cx + ftx + 2))):
			var pv: Vector2 = Vector2(px, py)
			var ed: float = sqrt(pow((px - cx) / rx,   2.0) + pow((py - cy) / ry,   2.0))
			var eo: float = sqrt(pow((px - cx) / ortx, 2.0) + pow((py - cy) / orty, 2.0))
			var ef: float = sqrt(pow((px - cx) / ftx,  2.0) + pow((py - cy) / fty,  2.0))
			if   ef > 1.0:  continue
			elif ed <= 1.0: _blend(img, px, py, _body_colour(pv, cv, ra, base, shade, high), 1.0)
			elif eo <= 1.0: _blend(img, px, py, C_OUTLINE, 1.0)
			else:           _blend(img, px, py, C_OUTLINE, clampf((1.0 - ef) * ra / fw, 0.0, 1.0))

# CAPSULE (rounded segment)
func _draw_capsule(img: Image, a: Vector2, b: Vector2, r: float,
		base: Color, shade: Color, high: Color,
		ow: float = OUTLINE_W, fw: float = FEATHER_W) -> void:
	var W: int = img.get_width()
	var H: int = img.get_height()
	var rt: float = r + ow + fw
	var center: Vector2 = a.lerp(b, 0.5)
	for py in range(max(0, int(min(a.y, b.y) - rt - 1)), min(H, int(max(a.y, b.y) + rt + 2))):
		for px in range(max(0, int(min(a.x, b.x) - rt - 1)), min(W, int(max(a.x, b.x) + rt + 2))):
			var pv: Vector2 = Vector2(px, py)
			var d: float = _seg_dist(pv, a, b)
			if   d <= r:      _blend(img, px, py, _body_colour(pv, center, r, base, shade, high), 1.0)
			elif d <= r + ow: _blend(img, px, py, C_OUTLINE, 1.0)
			elif d <= rt:     _blend(img, px, py, C_OUTLINE, clampf((rt - d) / fw, 0.0, 1.0))

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ap: Vector2 = p - a
	return p.distance_to(a + ab * clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0))

# =========================================================
# HEAD  —  Big chibi ball + round ear bumps + cheek blush
# Canvas: 128 × 128  (unchanged from original)
#
# World geometry (viewport 256×256, HeadBone at 128,68):
#   Head circle  → radius 50 px, centre (64, 68) on canvas
#   Ears stick out ~22 px above the head circle boundary
# =========================================================
func _generate_head() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Ears — drawn first; main head will overlap their bases
	_draw_circle(img, 27.0, 26.0, 14.0, C_BASE, C_SHADE, C_HIGHLIGHT)
	_draw_circle(img, 101.0, 26.0, 14.0, C_BASE, C_SHADE, C_HIGHLIGHT)
	# Inner ear petal — no outline, smaller pink circle
	_draw_circle(img, 27.0, 28.0, 7.5,
			C_INNER_EAR, C_INNER_EAR.darkened(0.18), Color(1.0, 0.92, 0.92, 1.0),
			Color.TRANSPARENT, 0.0)
	_draw_circle(img, 101.0, 28.0, 7.5,
			C_INNER_EAR, C_INNER_EAR.darkened(0.18), Color(1.0, 0.92, 0.92, 1.0),
			Color.TRANSPARENT, 0.0)

	# Main head ball — drawn on top of ears (covers their bases)
	_draw_circle(img, 64.0, 68.0, 50.0, C_BASE, C_SHADE, C_HIGHLIGHT, C_BLUSH)

	_save_image("res://assets/sprites/head_default.png", img)

# =========================================================
# BODY  —  Wide horizontal egg / oval shape
# Canvas: 256 × 256  (unchanged from original)
#
# Original was a tall two-circle capsule (radius 50).
# This is now a flat horizontal ellipse (65 × 48) giving
# the squat, round Axie torso silhouette.
# =========================================================
func _generate_body() -> void:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Wide horizontal oval, slightly below canvas centre
	_draw_ellipse(img, 128.0, 132.0, 65.0, 48.0, C_BASE, C_SHADE, C_HIGHLIGHT)
	_save_image("res://assets/sprites/body_default.png", img)

# =========================================================
# LIMBS  —  Stubby arm root + 3-toe paw tip
# Canvas: 64 × 64  (unchanged from original)
# =========================================================
func _generate_limbs() -> void:
	# Arm root — short chubby capsule, pivot at canvas centre (32, 32)
	var img_root := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img_root.fill(Color(0, 0, 0, 0))
	_draw_capsule(img_root,
			Vector2(16.0, 32.0), Vector2(42.0, 32.0), 13.0,
			C_BASE, C_SHADE, C_HIGHLIGHT)

	# Arm tip — shorter forearm stub + three rounded toe nubs
	var img_tip := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img_tip.fill(Color(0, 0, 0, 0))
	_draw_capsule(img_tip,
			Vector2(10.0, 32.0), Vector2(34.0, 32.0), 10.5,
			C_BASE, C_SHADE, C_HIGHLIGHT)
	# Three toe nubs fanning out from the right end
	_draw_circle(img_tip, 46.0, 23.0, 7.5,  C_BASE, C_SHADE.darkened(0.05), C_HIGHLIGHT)
	_draw_circle(img_tip, 51.0, 32.0, 8.0,  C_BASE, C_SHADE.darkened(0.05), C_HIGHLIGHT)
	_draw_circle(img_tip, 46.0, 41.0, 7.5,  C_BASE, C_SHADE.darkened(0.05), C_HIGHLIGHT)

	_save_image("res://assets/sprites/arm_root_default.png", img_root)
	_save_image("res://assets/sprites/arm_tip_default.png",  img_tip)

# =========================================================
# LEGS  —  Chunky vertical thigh + wide paw with toe bumps
# Canvas: 64 × 64  (unchanged from original)
# =========================================================
func _generate_legs() -> void:
	# Thigh — short, thick vertical capsule
	var img_thigh := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img_thigh.fill(Color(0, 0, 0, 0))
	_draw_capsule(img_thigh,
			Vector2(32.0, 16.0), Vector2(32.0, 42.0), 14.0,
			C_BASE, C_SHADE, C_HIGHLIGHT)

	# Foot — flat horizontal oval pad + three toe bubbles below it
	var img_foot := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img_foot.fill(Color(0, 0, 0, 0))
	_draw_ellipse(img_foot, 32.0, 28.0, 18.0, 11.0, C_BASE, C_SHADE, C_HIGHLIGHT)
	_draw_circle(img_foot, 17.0, 43.0, 7.5, C_BASE, C_SHADE.darkened(0.05), C_HIGHLIGHT)
	_draw_circle(img_foot, 32.0, 46.0, 8.0, C_BASE, C_SHADE.darkened(0.05), C_HIGHLIGHT)
	_draw_circle(img_foot, 47.0, 43.0, 7.5, C_BASE, C_SHADE.darkened(0.05), C_HIGHLIGHT)

	_save_image("res://assets/sprites/leg_root_default.png", img_thigh)
	_save_image("res://assets/sprites/leg_tip_default.png",  img_foot)

# =========================================================
# FACE PARTS  —  Expression sprites  (eyes & mouth)
# Canvas: 128 × 96  (unchanged from original)
# Eyes are slightly larger and have a dual-glint chibi style.
# =========================================================
const FACE_W   := 128
const FACE_H   := 96
const FACE_DIR := "res://assets/sprites/face/"
const EYE_DARK := Color(0.08, 0.05, 0.10, 1.0)
const MOUTH_DARK := Color(0.12, 0.07, 0.05, 1.0)

func _generate_parts() -> void:
	_save_image(FACE_DIR + "eyes_default.png", _draw_eyes_default())
	_save_image(FACE_DIR + "eyes_happy.png",   _draw_eyes_happy())
	_save_image(FACE_DIR + "eyes_closed.png",  _draw_eyes_closed())
	_save_image(FACE_DIR + "eyes_wide.png",    _draw_eyes_wide())
	_save_image(FACE_DIR + "mouth_default.png", _draw_mouth_default())
	_save_image(FACE_DIR + "mouth_smile.png",   _draw_mouth_smile())
	_save_image(FACE_DIR + "mouth_flat.png",    _draw_mouth_flat())
	_save_image(FACE_DIR + "mouth_open.png",    _draw_mouth_open())

func _create_blank_canvas() -> Image:
	var img: Image = Image.create(FACE_W, FACE_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Clean alpha slate
	return img

# Default — round anime eyes: white sclera, dark iris ring, pupil, 2 glints
func _draw_eyes_default() -> Image:
	var img: Image = _create_blank_canvas()
	var lc: Vector2 = Vector2(40.0, 52.0)
	var rc: Vector2 = Vector2(88.0, 52.0)
	var r: float = 11.0
	for py in range(FACE_H):
		for px in range(FACE_W):
			var p: Vector2 = Vector2(px, py)
			var dl: float = p.distance_to(lc)
			var dr: float = p.distance_to(rc)
			# White sclera
			if dl <= r or dr <= r:
				img.set_pixel(px, py, Color.WHITE)
			# Dark iris outer ring
			if (dl > r * 0.52 and dl <= r) or (dr > r * 0.52 and dr <= r):
				img.set_pixel(px, py, EYE_DARK)
			# Pupil
			if dl <= r * 0.38 or dr <= r * 0.38:
				img.set_pixel(px, py, EYE_DARK)
			# Primary glint (top-left)
			if p.distance_to(lc + Vector2(-4.0, -4.0)) <= 3.0 or \
					p.distance_to(rc + Vector2(-4.0, -4.0)) <= 3.0:
				img.set_pixel(px, py, Color.WHITE)
			# Secondary micro-glint (bottom-right)
			if p.distance_to(lc + Vector2(3.0, 3.5)) <= 1.5 or \
					p.distance_to(rc + Vector2(3.0, 3.5)) <= 1.5:
				img.set_pixel(px, py, Color(0.85, 0.85, 0.85, 1.0))
	return img

# Happy — ^^ upward arcs
func _draw_eyes_happy() -> Image:
	var img: Image = _create_blank_canvas()
	for py in range(FACE_H):
		for px in range(FACE_W):
			var lv: float = float(py) - (-0.38 * pow(px - 40.0, 2.0) + 52.0)
			var rv: float = float(py) - (-0.38 * pow(px - 88.0, 2.0) + 52.0)
			if (abs(lv) <= 2.5 and px >= 29 and px <= 51) or \
					(abs(rv) <= 2.5 and px >= 77 and px <= 99):
				img.set_pixel(px, py, EYE_DARK)
	return img

# Closed — horizontal slit (content / sleepy)
func _draw_eyes_closed() -> Image:
	var img: Image = _create_blank_canvas()
	for py in range(FACE_H):
		for px in range(FACE_W):
			if (py >= 50 and py <= 53) and \
					((px >= 29 and px <= 51) or (px >= 77 and px <= 99)):
				img.set_pixel(px, py, EYE_DARK)
	return img

# Wide — panic / drag large circles
func _draw_eyes_wide() -> Image:
	var img: Image = _create_blank_canvas()
	var lc: Vector2 = Vector2(40.0, 52.0)
	var rc: Vector2 = Vector2(88.0, 52.0)
	var r: float = 15.0
	for py in range(FACE_H):
		for px in range(FACE_W):
			var p: Vector2 = Vector2(px, py)
			var dl: float = p.distance_to(lc)
			var dr: float = p.distance_to(rc)
			if dl <= r or dr <= r: img.set_pixel(px, py, Color.WHITE)
			if (dl > r - 2.0 and dl <= r) or (dr > r - 2.0 and dr <= r):
				img.set_pixel(px, py, EYE_DARK)
			if dl <= 4.5 or dr <= 4.5:
				img.set_pixel(px, py, EYE_DARK)
			if p.distance_to(lc + Vector2(-5.0, -5.0)) <= 3.0 or \
					p.distance_to(rc + Vector2(-5.0, -5.0)) <= 3.0:
				img.set_pixel(px, py, Color.WHITE)
	return img

# Mouth neutral — tiny upward arc
func _draw_mouth_default() -> Image:
	var img: Image = _create_blank_canvas()
	for py in range(FACE_H):
		for px in range(FACE_W):
			var arc: float = float(py) - (0.11 * pow(px - 64.0, 2.0) + 68.0)
			if abs(arc) <= 2.0 and px >= 56 and px <= 72:
				img.set_pixel(px, py, MOUTH_DARK)
	return img

# Mouth smile — wide crescent with tongue peek
func _draw_mouth_smile() -> Image:
	var img: Image = _create_blank_canvas()
	var mc: Vector2 = Vector2(64.0, 66.0)
	for py in range(FACE_H):
		for px in range(FACE_W):
			var p: Vector2 = Vector2(px, py)
			var d: float = p.distance_to(mc)
			if d <= 13.0 and py >= 66:
				if p.distance_to(mc + Vector2(0.0, 7.0)) <= 7.0:
					img.set_pixel(px, py, Color(1.0, 0.45, 0.52, 1.0)) # Tongue
				else:
					img.set_pixel(px, py, MOUTH_DARK)
			if py == 66 and px >= 51 and px <= 77:
				img.set_pixel(px, py, MOUTH_DARK)
	return img

# Mouth flat — unimpressed straight line
func _draw_mouth_flat() -> Image:
	var img: Image = _create_blank_canvas()
	for py in range(FACE_H):
		for px in range(FACE_W):
			if (py >= 68 and py <= 71) and (px >= 56 and px <= 72):
				img.set_pixel(px, py, MOUTH_DARK)
	return img

# Mouth open — surprised O oval
func _draw_mouth_open() -> Image:
	var img: Image = _create_blank_canvas()
	var mc: Vector2 = Vector2(64.0, 70.0)
	for py in range(FACE_H):
		for px in range(FACE_W):
			var oval: float = sqrt(pow(px - mc.x, 2.0) + pow((py - mc.y) * 0.65, 2.0))
			if oval <= 8.0:
				img.set_pixel(px, py, MOUTH_DARK)
			elif oval <= 9.5:
				img.set_pixel(px, py, MOUTH_DARK.darkened(0.2))
	return img
