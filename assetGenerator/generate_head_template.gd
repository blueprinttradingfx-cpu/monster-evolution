@tool
extends EditorScript

func _run() -> void:
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

	# Double check directory paths
	var global_dir = ProjectSettings.globalize_path("res://assets/sprites")
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	# Write out the physical file
	var global_save_path = ProjectSettings.globalize_path("res://assets/sprites/head_default.png")
	var error := image.save_png(global_save_path)
	
	if error == OK:
		print("--- HEAD SCRIPT NOTICE ---")
		print("Head asset generated successfully at: ", global_save_path)
		print("Click the FileSystem panel and press Ctrl+R if it doesn't appear immediately.")
		print("--------------------------")
		get_editor_interface().get_resource_filesystem().scan()
	else:
		print("Head Write Failed! Error code: ", error)
