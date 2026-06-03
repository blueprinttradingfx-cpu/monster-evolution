extends Resource
class_name EvolutionConfig

# EvolutionConfig Resource - Central configuration for evolution costs and stages
# Per TICKET-16

@export var stageCosts: Dictionary = {
	"stage_1": 100,   # Baby → Kid
	"stage_2": 500,   # Kid → Adult
	"stage_3": 1500   # Adult → Elder
}

@export var stageDefinitions: Dictionary = {
	"stage_0": "egg",
	"stage_1": "baby",
	"stage_2": "kid",
	"stage_3": "adult",
	"stage_4": "elder"
}

func get_evolution_cost(current_stage_id: String) -> int:
	return stageCosts.get(current_stage_id, 0)

func get_next_stage_id(current_stage_id: String) -> String:
	var stage_number: int = _get_stage_number(current_stage_id)
	var next_stage: int = stage_number + 1
	if next_stage > 4:
		return current_stage_id
	return "stage_%d" % next_stage

func _get_stage_number(stage_id: String) -> int:
	match stage_id:
		"stage_0":
			return 0
		"stage_1":
			return 1
		"stage_2":
			return 2
		"stage_3":
			return 3
		"stage_4":
			return 4
		_:
			return 0
