extends Node

# EconomyManager autoload - Coin tracking and transaction management
# Per Event Flow Section 3.2, Data Model, and TICKET-21

# --- SIGNALS ---
signal coins_changed(new_amount: int)
signal purchase_failed(reason: String)

# --- VARIABLES ---
var coins: int = 0
var reward_tables: Dictionary = {}  # table_id -> RewardTable
var transactions: Array = []  # Transaction log (debug only)
var balancing_config: Resource = null  # EconomyBalancingConfig

# --- INITIALIZATION ---
func _ready() -> void:
	_load_balancing_config()
	_load_reward_tables()
	print("EconomyManager initialized")

func _load_balancing_config() -> void:
	balancing_config = load("res://data/balancing/balancing.tres")
	if balancing_config:
		print("[Economy] Balancing config loaded")

func _load_reward_tables() -> void:
	# Load all RewardTable resources from data/rewards/
	var memory_easy: Resource = load("res://data/rewards/memory_easy.tres")
	if memory_easy and memory_easy is RewardTable:
		reward_tables[memory_easy.id] = memory_easy
	
	# Add more reward tables here as needed in the future

# --- REWARD TABLE MANAGEMENT ---
func get_reward_range(table_id: String) -> Dictionary:
	var reward: Dictionary = {
		"minimumCoins": 0,
		"maximumCoins": 0
	}
	
	if reward_tables.has(table_id):
		var table: RewardTable = reward_tables[table_id]
		reward["minimumCoins"] = table.minimumCoins
		reward["maximumCoins"] = table.maximumCoins
	
	return reward

# --- COIN MANAGEMENT ---
func _log_transaction(amount: int, source: String) -> void:
	if not OS.is_debug_build():
		return
	
	var transaction: Dictionary = {
		"id": "tx_%d" % Time.get_ticks_msec(),
		"source": source,
		"amount": amount,
		"timestamp": Time.get_datetime_string_from_system()
	}
	transactions.append(transaction)

func get_coins() -> int:
	return coins

func set_coins(amount: int) -> void:
	coins = amount
	coins_changed.emit(coins)

func add_coins(amount: int, source: String = "unknown") -> void:
	if amount <= 0:
		push_warning("add_coins: invalid amount %d (source: %s)" % [amount, source])
		return
	
	coins += amount
	coins_changed.emit(coins)
	
	if GameManager:
		GameManager.increment_coins_earned(amount)
	
	# Debug-only transaction logging
	_log_transaction(amount, source)
	if OS.is_debug_build():
		print("[Economy] Added %d coins from '%s'. Total: %d" % [amount, source, coins])
	
	# Trigger save
	if SaveManager:
		SaveManager.trigger_save_on_purchase()

func spend_coins(amount: int, source: String = "unknown") -> bool:
	if amount <= 0:
		push_warning("spend_coins: invalid amount %d (source: %s)" % [amount, source])
		purchase_failed.emit("Invalid amount")
		return false
	
	if coins < amount:
		var reason: String = "Insufficient coins (need %d, have %d)" % [amount, coins]
		push_warning("spend_coins: %s (source: %s)" % [reason, source])
		purchase_failed.emit(reason)
		return false
	
	coins -= amount
	coins_changed.emit(coins)
	
	# Debug-only transaction logging
	_log_transaction(-amount, source)
	if OS.is_debug_build():
		print("[Economy] Spent %d coins on '%s'. Remaining: %d" % [amount, source, coins])
	
	# Trigger save after purchase per Event Flow Section 12
	if SaveManager:
		SaveManager.trigger_save_on_purchase()
	
	return true

func get_balance() -> int:
	return coins

func can_afford(amount: int) -> bool:
	return coins >= amount

