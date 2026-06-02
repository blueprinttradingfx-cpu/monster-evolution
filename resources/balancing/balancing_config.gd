extends Resource
class_name BalancingConfig

@export_group("Memory Settings")
## Grid sizes per level. Index corresponds to boards_cleared.
@export var grid_scaling: Array[Vector2i] = [
	Vector2i(2, 2), # Level 0
	Vector2i(2, 3), # Level 1
	Vector2i(3, 3), # Level 2
	Vector2i(4, 3), # Level 3
	Vector2i(4, 4), # Level 4
	Vector2i(5, 4), # Level 5
	Vector2i(5, 5)  # Level 6+
]

@export_group("Reward Settings")
## Multiplier for coin rewards: int(total_cells * coin_multiplier)
@export var coin_multiplier: float = 2.5
## Thresholds for egg rewards based on total grid size (width * height)
@export var egg_thresholds: Dictionary = {
	16: 2, # 2 eggs if size >= 16
	25: 3  # 3 eggs if size >= 25
}

@export_group("Merge Settings")
## Merge requirements based on evolution stage
@export var merge_requirement_curve: Dictionary = {
	2: 2, # Stage <= 2: 2 required
	4: 3, # Stage <= 4: 3 required
	6: 4, # Stage <= 6: 4 required
	99: 5 # Stage > 6: 5 required
}

func get_grid_for_level(level: int) -> Vector2i:
	if grid_scaling.is_empty():
		return Vector2i(2, 2)
	var index = clampi(level, 0, grid_scaling.size() - 1)
	return grid_scaling[index]

func calculate_rewards(grid: Vector2i) -> Dictionary:
	var size = grid.x * grid.y
	var coins = int(size * coin_multiplier)
	var eggs = 1

	# Dictionary keys are strings when saved/loaded in some contexts,
	# but as a Resource in editor they should be ints.
	# We'll check both to be safe.
	for threshold in egg_thresholds:
		var t_val = int(threshold)
		if size >= t_val:
			eggs = max(eggs, int(egg_thresholds[threshold]))

	return {
		"coins": coins,
		"eggs": eggs
	}

func get_merge_required(stage: int) -> int:
	var keys = merge_requirement_curve.keys()
	keys.sort()

	for threshold in keys:
		if stage <= int(threshold):
			return int(merge_requirement_curve[threshold])

	return 5 # Fallback
