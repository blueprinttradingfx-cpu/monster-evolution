extends Node
## ProgressionSimulator.gd
## Headless utility for simulating player progress over time.

func run_simulation(config: Resource, days: int, sessions_per_day: int, runs_per_session: int) -> String:
	var output = "=== START PROGRESSION SIMULATION ===\n"
	output += "Config: %s\n" % config.resource_path
	output += "Days: %d, Sessions/Day: %d, Runs/Session: %d\n" % [days, sessions_per_day, runs_per_session]
	output += "Assumed Session Length: %d min\n\n" % (runs_per_session * 2) # Estimate 2 min per run

	var total_coins = 0
	var total_eggs = 0
	var boards_cleared = 0

	# Creature inventory simulation
	var inventory = {
		"egg": 0,
		"blob": 0,
		"slime": 0,
		"raptor": 0,
		"dino": 0,
		"dragon": 0
	}

	# Creature IDs for indexing (based on evolution_chains.json)
	var stages = ["egg", "blob", "slime", "raptor", "dino", "dragon"]

	for day in range(1, days + 1):
		var day_coins = 0
		var day_eggs = 0

		for session in range(sessions_per_day):
			for run in range(runs_per_session):
				var grid = config.get_grid_for_level(boards_cleared)
				var rewards = config.calculate_rewards(grid)

				day_coins += rewards["coins"]
				day_eggs += rewards["eggs"]
				boards_cleared += 1

		total_coins += day_coins
		total_eggs += day_eggs
		inventory["egg"] += day_eggs

		# Perform merges
		var merge_results = _perform_merges(inventory, stages, config)

		output += "Day %d:\n" % day
		output += "  Runs: %d (Total: %d)\n" % [sessions_per_day * runs_per_session, boards_cleared]
		output += "  Eggs Earned: %d (Total: %d)\n" % [day_eggs, total_eggs]

		if not merge_results.is_empty():
			output += "  NEW UNLOCKS: %s\n" % ", ".join(merge_results)

		output += "  Inventory: %s\n" % str(inventory)
		output += "-----------------------------------\n"

	output += "\n=== SIMULATION COMPLETE ===\n"
	output += "Total Coins: %d\n" % total_coins
	output += "Total Eggs Earned: %d\n" % total_eggs
	output += "Final Inventory: %s\n" % str(inventory)

	return output

func _perform_merges(inventory: Dictionary, stages: Array, config: BalancingConfig) -> Array:
	var new_unlocks = []

	# Simple ripple: run a few times to catch cascading merges
	for loop in range(stages.size()):
		for i in range(stages.size() - 1):
			var current_id = stages[i]
			var next_id = stages[i + 1]
			var required = config.get_merge_required(i + 1)

			if inventory[current_id] >= required:
				var merge_count = inventory[current_id] / required
				inventory[current_id] %= required

				# Track if this is a "first time" or significant unlock in this sim run
				if inventory[next_id] == 0 and merge_count > 0:
					new_unlocks.append(next_id.to_upper())

				inventory[next_id] += merge_count

	return new_unlocks
