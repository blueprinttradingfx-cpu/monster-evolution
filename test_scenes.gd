extends SceneTree

func _init() -> void:
	print("[TEST] Starting scene tests...")
	
	var scenes_to_test = [
		"res://scenes/screens/home/home.tscn",
		"res://scenes/screens/shop/shop.tscn",
		"res://scenes/screens/collection/collection.tscn",
		"res://scenes/screens/settings/settings.tscn",
		"res://scenes/screens/creature-detail/creature-detail.tscn",
		"res://scenes/screens/evolution/EvolutionConfirmation.tscn",
		"res://scenes/screens/hatch/HatchScene.tscn",
		"res://scenes/screens/mini_game_hub/MiniGameHub.tscn",
		"res://scenes/screens/memory-setup/memory-setup.tscn",
		"res://scenes/screens/memory/memory.tscn",
		"res://scenes/screens/tap-to-start/tap-to-start.tscn",
		"res://scenes/screens/splash/splash.tscn",
	]
	
	for scene_path in scenes_to_test:
		test_scene(scene_path)
	
	print("[TEST] All tests complete!")
	quit()


func test_scene(scene_path: String) -> void:
	print("\n[TEST] Testing: ", scene_path)
	
	var packed_scene = load(scene_path)
	if not packed_scene:
		print("\t[ERROR] Failed to load scene!")
		return
	
	var instance = packed_scene.instantiate()
	if not instance:
		print("\t[ERROR] Failed to instantiate scene!")
		return
	
	var script = instance.get_script()
	if script:
		print("\t[INFO] Script: ", script.resource_path)
		# Check @onready vars in script
		var script_source = load(script.resource_path).source_code if script.resource_path else ""
		if script_source:
			var onready_vars = []
			var lines = script_source.split("\n")
			for line in lines:
				var stripped = line.strip_edges()
				if stripped.begins_with("@onready"):
					var var_name_match = stripped.match("@onready var (\\w+):")
					if var_name_match:
						var var_name = var_name_match[1]
						var path_match = stripped.match("\\$([\\w/]+)")
						if path_match:
							var node_path = path_match[1]
							onready_vars.append({"name": var_name, "path": node_path})
			
			print("\t[INFO] Found ", onready_vars.size(), " @onready variables")
			for onready_var in onready_vars:
				var node = instance.get_node_or_null(onready_var.path)
				if node:
					print("\t[OK] ", onready_var.name, " (", onready_var.path, ")")
				else:
					print("\t[ERROR] Missing node: ", onready_var.name, " (", onready_var.path, ")")
