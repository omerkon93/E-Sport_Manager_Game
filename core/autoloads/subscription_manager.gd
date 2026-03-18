extends Node

# Signals for the UI to listen to
signal subscription_added(item: SubscriptionItem)
signal subscription_removed(id: String)
signal bill_paid(item: SubscriptionItem, amount: float)
signal payment_failed(item: SubscriptionItem)

var active_subscriptions: Dictionary = {}

func _ready() -> void:
	# 1. Register for the new automatic SaveManager!
	add_to_group("persist")
	
	# 2. Listen to the global bus, not the TimeManager directly
	SignalBus.game_time_day_started.connect(_on_day_started)

# --- PUBLIC API ---
func subscribe(item: SubscriptionItem) -> void:
	if active_subscriptions.has(item.id): return
	
	# Using the global setting (assuming TimeManager still has a static getter or you track it)
	var current_day = TimeManager.current_day 
	var due_day = current_day + item.interval_days
	
	active_subscriptions[item.id] = {
		"item": item,
		"next_due_day": due_day
	}
	subscription_added.emit(item)
	print("📅 Subscribed to %s. Next bill: Day %d" % [item.display_name, due_day])

func unsubscribe(id: String) -> void:
	if active_subscriptions.has(id):
		active_subscriptions.erase(id)
		subscription_removed.emit(id)
		print("❌ Unsubscribed from %s." % id)

func get_days_until_due(id: String) -> int:
	if not active_subscriptions.has(id): return -1
	return active_subscriptions[id].next_due_day - TimeManager.current_day

# --- INTERNAL LOGIC ---
func _on_day_started(day: int) -> void:
	for id in active_subscriptions.keys():
		var data = active_subscriptions[id]
		if day >= data.next_due_day:
			_process_payment(id, data)

func _process_payment(id: String, data: Dictionary) -> void:
	var item: SubscriptionItem = data.item
	
	# Ask the Accountant to do the math and handle the flags!
	var success = TransactionManager.process_subscription(item)
	
	if success:
		if item.auto_renew:
			data.next_due_day += item.interval_days
		else:
			unsubscribe(id)
		bill_paid.emit(item, item.cost_amount)
	else:
		payment_failed.emit(item)

# ==============================================================================
# PERSISTENCE & RESET (Unchanged except it now triggers automatically!)
# ==============================================================================
func get_save_data() -> Dictionary:
	var save_data = {}
	for id in active_subscriptions:
		var data = active_subscriptions[id]
		save_data[id] = {
			"next_due_day": data.next_due_day,
			"resource_path": data.item.resource_path 
		}
	return save_data

func load_save_data(data: Dictionary) -> void:
	reset() 
	for id in data:
		var sub_data = data[id]
		var loaded_item = load(sub_data.resource_path) as SubscriptionItem
		if loaded_item:
			active_subscriptions[id] = {
				"item": loaded_item,
				"next_due_day": sub_data.next_due_day
			}
			subscription_added.emit(loaded_item)

func reset() -> void:
	for id in active_subscriptions.keys():
		subscription_removed.emit(id)
	active_subscriptions.clear()
	print("🧾 SubscriptionManager: All bills cleared.")
