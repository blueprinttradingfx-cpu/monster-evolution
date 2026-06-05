@tool
extends EditorScript

func _run() -> void:
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

	# Save assets
	var global_dir = ProjectSettings.globalize_path("res://assets/sprites")
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	img_thigh.save_png(ProjectSettings.globalize_path("res://assets/sprites/leg_root_default.png"))
	img_foot.save_png(ProjectSettings.globalize_path("res://assets/sprites/leg_tip_default.png"))
	
	print("--- LEG ASSET NOTIFICATION ---")
	print("Leg components generated cleanly inside res://assets/sprites/")
	print("------------------------------")
	get_editor_interface().get_resource_filesystem().scan()

func _dist_to_line_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
