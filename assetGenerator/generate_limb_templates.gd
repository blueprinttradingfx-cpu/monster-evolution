@tool
extends EditorScript

func _run() -> void:
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

	# Save both files
	var global_dir = ProjectSettings.globalize_path("res://assets/sprites")
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	img_root.save_png(ProjectSettings.globalize_path("res://assets/sprites/arm_root_default.png"))
	img_tip.save_png(ProjectSettings.globalize_path("res://assets/sprites/arm_tip_default.png"))
	
	print("--- LIMB SCRIPT NOTICE ---")
	print("Limb assets successfully written to res://assets/sprites/")
	print("--------------------------")
	get_editor_interface().get_resource_filesystem().scan()

# Helper math function to generate clean procedural line capsules
func _dist_to_line_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := p - a
	var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
