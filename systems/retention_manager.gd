extends Node
## RetentionManager.gd
## Tracks login days and session frequency.

func _ready() -> void:
	_track_login()

func _track_login() -> void:
	var save_data = SaveSystem.get_data()
	var progression = save_data.get("progression", {})

	var now = Time.get_unix_time_from_system()
	var date_dict = Time.get_date_dict_from_system()
	var today = "%d-%d-%d" % [date_dict.year, date_dict.month, date_dict.day]

	# Set first launch if not exists
	if progression.get("first_launch_date", 0) == 0:
		SaveSystem.set_progression_value("first_launch_date", now)
		_on_milestone(0) # Day 0

	# Check if new day
	var last_login_date = progression.get("last_login_date", "")
	if last_login_date != today:
		var total_days = progression.get("total_login_days", 0) + 1
		SaveSystem.set_progression_value("total_login_days", total_days)
		SaveSystem.set_progression_value("last_login_date", today)
		SaveSystem.save_game()
		print("[Retention] New day login tracked: ", total_days)
		_check_milestones(total_days)

func _check_milestones(days: int) -> void:
	match days:
		1: _on_milestone(1) # D1
		3: _on_milestone(3) # D3
		7: _on_milestone(7) # D7
		14: _on_milestone(14)
		30: _on_milestone(30)

func _on_milestone(day: int) -> void:
	print("[Retention] Milestone reached: Day ", day)
	# Trigger special juice or reward modifiers
	var juice = get_node_or_null("/root/UIJuiceLayer")
	if juice:
		juice.float_text("DAY %d LOGIN STREAK!" % day, Vector2(540, 300), Color.GOLD, true)

func get_day_number() -> int:
	var save_data = SaveSystem.get_data()
	return int(save_data.get("progression", {}).get("total_login_days", 0))
