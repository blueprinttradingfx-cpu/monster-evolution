extends Node
## PerformanceLayer.gd
## Manages object pooling, event throttling, and task scheduling.

var pools := {
	"card": [],
	"float_text": [],
	"particle": [],
	"merge_fx": []
}

var last_event_time := {}
var cooldowns := {
	"screen_shake": 0.1,
	"camera_pulse": 0.08,
	"float_text": 0.05,
	"haptic": 0.1
}

var scheduled_tasks := []
var assets := {} # id -> Resource

func _process(_delta: float) -> void:
	_process_scheduled_tasks()

# ── 0. ASSET PRELOADING ───────────────────────────────────────────────

func preload_asset(id: String, path: String) -> void:
	if assets.has(id): return
	assets[id] = load(path)

func get_asset(id: String) -> Resource:
	return assets.get(id, null)

# ── 1. OBJECT POOLING ──────────────────────────────────────────────────

func get_from_pool(type: String, scene: PackedScene) -> Node:
	if not pools.has(type):
		pools[type] = []

	if pools[type].size() > 0:
		var node = pools[type].pop_back()
		if node.get_parent():
			node.get_parent().remove_child(node)
		node.visible = true
		node.process_mode = Node.PROCESS_MODE_INHERIT
		return node

	return scene.instantiate()

func return_to_pool(type: String, node: Node) -> void:
	if not pools.has(type):
		pools[type] = []

	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED

	# Reparent to ourselves to keep out of the active scene
	if node.get_parent():
		node.get_parent().remove_child(node)
	add_child(node)

	pools[type].append(node)

# ── 2. EVENT THROTTLING ───────────────────────────────────────────────

func can_emit(event: String) -> bool:
	var now = Time.get_ticks_msec()
	var cd = cooldowns.get(event, 0.0)

	if not last_event_time.has(event):
		last_event_time[event] = 0

	if now - last_event_time[event] < cd * 1000:
		return false

	last_event_time[event] = now
	return true

# ── 3. TASK SCHEDULING ────────────────────────────────────────────────

func schedule(delay: float, callable: Callable) -> void:
	scheduled_tasks.append({
		"time": Time.get_ticks_msec() + int(delay * 1000),
		"call": callable
	})

func _process_scheduled_tasks() -> void:
	var now = Time.get_ticks_msec()

	for i in range(scheduled_tasks.size() - 1, -1, -1):
		if now >= scheduled_tasks[i]["time"]:
			var task = scheduled_tasks[i]
			scheduled_tasks.remove_at(i)
			task["call"].call()
