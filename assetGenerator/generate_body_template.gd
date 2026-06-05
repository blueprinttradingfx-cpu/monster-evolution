@tool
extends EditorScript

func _run() -> void:
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

	# Ensure the target directory physically exists
	var global_dir = ProjectSettings.globalize_path("res://assets/sprites")
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	# Save using an absolute global operating system path to force it through
	var global_save_path = ProjectSettings.globalize_path("res://assets/sprites/body_default.png")
	var error := image.save_png(global_save_path)
	
	if error == OK:
		print("--- SYSTEM NOTICE ---")
		print("File written successfully to: ", global_save_path)
		print("If it's missing in Godot, click 'FileSystem' panel and press Ctrl+R to manually reload!")
		print("---------------------")
	else:
		print("Write Failed! Error code: ", error)
