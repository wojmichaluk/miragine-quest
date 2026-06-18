extends Node2D


# Player and enemy unit & base scenes
@export var player_unit_scene: PackedScene
@export var enemy_unit_scene: PackedScene
@export var base_scene: PackedScene

# Game over scene
@export var game_over_scene: PackedScene

@onready var battle_button = $CanvasLayer/UI/BattleButton

# Gold currency
var player_gold: int = 0
var enemy_gold: int = 0
var player_gold_round: int = 1000
var enemy_gold_round: int = 1000
var player_gold_gain: float = 0.0
var enemy_gold_gain: float = 0.0

# Unit weights
var player_weight: int = 0
var enemy_weight: int = 0
var player_weight_limit: int = 20
var enemy_weight_limit: int = 20
var player_weight_gain: float = 0.0
var enemy_weight_gain: float = 0.0

# Maximum currency limits (per round)
var MAX_GOLD_LIMIT = 8000
var MAX_WEIGHT_LIMIT = 120

# Timers
var round_time: float = 40.0
var current_time: float
var shopping_phase_duration: float = 5.0

# Signals to notify UI
signal gold_changed(new_amount, is_player)
signal time_changed(seconds_left, is_shopping)
signal weight_changed(current, maximum, is_player)

# Spawn unit utility
var active_player_unit_id
var active_enemy_unit_id

# Preparation phase before actual start of the game
var start_cooldown = 5

# Round number
var round_no = -1

# Analyzed units data for AI
var analyzed_data: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	
	# Setup bases
	setup_bases()
	
	# Analyze enemy units (for AI's sake)
	analyze_enemy_units()
	
	# Connect time and currency signals
	gold_changed.connect($CanvasLayer/UI.update_gold_display)
	time_changed.connect($CanvasLayer/UI.update_timer_display)
	weight_changed.connect($CanvasLayer/UI.update_weight_display)
	
	# Initial player unit selection
	select_active_unit(0, true)
	
	# Possibility to prepare before starting the game
	prepare()
	
	# Wait for the button click and start the game
	await battle_button.pressed
	battle_button.hide()
	$GameTimer.start()
	
	# Displaying start values
	gold_changed.emit(player_gold, true)
	gold_changed.emit(enemy_gold, false)
	weight_changed.emit(player_weight, player_weight_limit, true)
	weight_changed.emit(enemy_weight, enemy_weight_limit, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func setup_bases():
	# Initialize player and enemy bases
	var player_base = initialize_base(GlobalData.bases_data["player"], "player", true)
	var enemy_base = initialize_base(GlobalData.bases_data["enemy"], "enemy", false)
	var enemy_bases_mid = initialize_base_mid(
		GlobalData.bases_data["enemy_mid_main"],
		GlobalData.bases_data["enemy_mid_aux"]
	)
	
	# Adding bases to scene
	add_child(player_base)
	add_child(enemy_base)
	
	for base_mid in enemy_bases_mid:
		add_child(base_mid)
	
	# Connecting (main) bases signals to UI
	player_base.base_health_changed.connect($CanvasLayer/UI.update_base_hp)
	player_base.base_destroyed.connect(end_game)
	enemy_base.base_health_changed.connect($CanvasLayer/UI.update_base_hp)
	enemy_base.base_destroyed.connect(end_game)


func initialize_base(base_data, base_id, is_player):
	var base = base_scene.instantiate()
	base.base_id = base_id
	base.is_player = is_player
	base.position = Vector2(-4600 if is_player else 4600, 350)
	base.is_main = true
	
	# Setting base attributes based on base_data
	base.name = base_data["name"]
	base.attack_speed = base_data["atk_speed"]
	base.max_health = base_data["hp"]
	base.attack_damage = base_data["damage"]
	base.attack_type = base_data["atk_type"]
	base.attack_range = base_data["atk_range"]
	
	# Setting animation frames for idle and attack
	base.idle_row = base_data["idle_row"]
	base.wide_idle = base_data["wide_idle"]
	
	for frame in base_data["idle_frames"]:
		base.idle_frames.append(int(frame))
	
	base.attack_row = base_data["atk_row"]
	base.wide_atk = base_data["wide_atk"]
	
	for frame in base_data["atk_frames"]:
		base.attack_frames.append(int(frame))
	
	# Set base texture
	if is_player:
		base.get_node("Sprite2D").texture = load("res://assets/bases/player.png")
	else:
		base.get_node("Sprite2D").texture = load("res://assets/bases/enemy.png")
	
	return base


func initialize_base_mid(base_data_main, base_data_aux):
	# Main mid base
	var base_mid_main = base_scene.instantiate()
	base_mid_main.base_id = "enemy_mid_main"
	base_mid_main.is_player = false
	base_mid_main.position = Vector2(2300, 350)
	base_mid_main.is_main = false
	
	# Setting base attributes
	base_mid_main.name = base_data_main["name"]
	base_mid_main.attack_speed = base_data_main["atk_speed"]
	base_mid_main.max_health = base_data_main["hp"]
	base_mid_main.attack_damage = base_data_main["damage"]
	base_mid_main.attack_type = base_data_main["atk_type"]
	base_mid_main.attack_range = base_data_main["atk_range"]
	base_mid_main.res_phys = base_data_main["res_phys"]
	base_mid_main.res_mag = base_data_main["res_mag"]
	
	# Setting animation frames for idle and attack
	base_mid_main.idle_row = base_data_main["idle_row"]
	base_mid_main.wide_idle = base_data_main["wide_idle"]
	
	for frame in base_data_main["idle_frames"]:
		base_mid_main.idle_frames.append(int(frame))
	
	base_mid_main.attack_row = base_data_main["atk_row"]
	base_mid_main.wide_atk = base_data_main["wide_atk"]
	
	for frame in base_data_main["atk_frames"]:
		base_mid_main.attack_frames.append(int(frame))
	
	# Set base texture
	base_mid_main.get_node("Sprite2D").texture = load("res://assets/bases/enemy_mid_main.png")
	base_mid_main.get_node("Sprite2D").scale = Vector2(1.25, 1.25)
	
	# Auxiliary mid bases
	var xs = [2250, 2300, 2350, 2350, 2300, 2250]
	var ys = [250, 270, 310, 390, 430, 450]
	var aux_bases = []
	
	for i in range(6):
		var base_mid_aux = base_scene.instantiate()
		base_mid_aux.base_id = "enemy_mid_aux"
		base_mid_aux.is_player = false
		base_mid_aux.position = Vector2(xs[i], ys[i])
		base_mid_aux.is_main = false
		base_mid_aux.is_aux = true
		
		# Setting base attributes
		base_mid_aux.name = base_data_aux["name"]
		base_mid_aux.attack_speed = base_data_aux["atk_speed"]
		base_mid_aux.max_health = base_data_aux["hp"]
		base_mid_aux.attack_damage = base_data_aux["damage"]
		base_mid_aux.attack_type = base_data_aux["atk_type"]
		base_mid_aux.attack_range = base_data_aux["atk_range"]
		base_mid_aux.res_phys = base_data_aux["res_phys"]
		base_mid_aux.res_mag = base_data_aux["res_mag"]
		
		# Setting animation frames for idle and attack
		base_mid_aux.idle_row = base_data_aux["idle_row"]
		base_mid_aux.wide_idle = base_data_aux["wide_idle"]
		
		for frame in base_data_aux["idle_frames"]:
			base_mid_aux.idle_frames.append(int(frame))
		
		base_mid_aux.attack_row = base_data_aux["atk_row"]
		base_mid_aux.wide_atk = base_data_aux["wide_atk"]
		
		for frame in base_data_aux["atk_frames"]:
			base_mid_aux.attack_frames.append(int(frame))
		
		# Set base texture
		base_mid_aux.get_node("Sprite2D").texture = load("res://assets/bases/enemy_mid_aux.png")
		base_mid_aux.get_node("Sprite2D").scale = Vector2(1.1, 1.1)
		
		aux_bases.append(base_mid_aux)
	
	# Return all bases
	return [base_mid_main] + aux_bases


func analyze_enemy_units():
	# Get all enemy units data
	var enemy_units_data = GlobalData.enemy_units_data
	
	# Calculate chosen statisics (per weight)
	for key in enemy_units_data:
		var unit_data = enemy_units_data[key]
		var weight = unit_data["weight"]
		
		analyzed_data[key] = Dictionary()
		analyzed_data[key]["type"] = unit_data["atk_type"]
		analyzed_data[key]["dps"] = (unit_data["damage"] / unit_data["atk_speed"]) / weight
		analyzed_data[key]["hp_phys"] = (unit_data["hp"] / (1.0 - unit_data["res_phys"])) / weight
		analyzed_data[key]["hp_mag"] = (unit_data["hp"] / (1.0 - unit_data["res_mag"])) / weight
		analyzed_data[key]["cost"] = unit_data["cost"] / weight


func select_active_unit(unit_id, is_player):
	var unit_data
	var remaining_weight
	
	if is_player:
		active_player_unit_id = unit_id
		unit_data = GlobalData.player_units_data[str(unit_id)]
		remaining_weight = player_weight_limit - player_weight
	else:
		active_enemy_unit_id = unit_id
		unit_data = GlobalData.enemy_units_data[str(unit_id)]
		remaining_weight = enemy_weight_limit - enemy_weight
	
	var time = current_time + shopping_phase_duration - round_time
	var units_to_send = floor(remaining_weight / unit_data["weight"])
	
	# A little time shift
	var spawn_delay = (time - 2) / (units_to_send + 1)
	spawn_delay = max(min(spawn_delay, 0.5), 0.0)
	$CanvasLayer/UI.update_unit_selection(unit_id, is_player, spawn_delay)


func prepare():
	current_time = start_cooldown
	time_changed.emit(current_time, false)
	
	# Show popup with information
	var info_popup_scene = preload("res://scenes/StartPopup.tscn")
	var popup = info_popup_scene.instantiate()
	$CanvasLayer/UI.add_child(popup)


func spawn_unit(unit_id: int, is_player: bool):
	# Check if can buy unit (shopping_phase)
	if not is_shopping_phase():
		return 0
	
	# Check if can buy unit (can afford it and respect weight limit)
	if not within_currency_limits(unit_id, is_player):
		return 1
	
	# Choosing proper unit data
	var new_unit
	var unit_data
	var dir = 1 if is_player else -1
	
	if is_player:
		unit_data = GlobalData.player_units_data[str(unit_id)]
		new_unit = player_unit_scene.instantiate()
		new_unit.get_node("Sprite2D").texture = GlobalData.player_units_textures[unit_id]
	else:
		unit_data = GlobalData.enemy_units_data[str(unit_id)]
		new_unit = enemy_unit_scene.instantiate()
		new_unit.get_node("Sprite2D").texture = GlobalData.enemy_units_textures[unit_id]
	
	# Calculating currency and weight change
	if is_player:
		player_gold -= unit_data["cost"]
		player_weight += unit_data["weight"]
		gold_changed.emit(player_gold, true)
		weight_changed.emit(player_weight, player_weight_limit, true)
	else:
		enemy_gold -= unit_data["cost"]
		enemy_weight += unit_data["weight"]
		gold_changed.emit(enemy_gold, false)
		weight_changed.emit(enemy_weight, enemy_weight_limit, false)
	
	# Setting unit orientation
	new_unit.position = Vector2(-dir * 4500, randf_range(120, 580))
	new_unit.direction = dir
	
	# Connect unit death signal
	new_unit.unit_died.connect(update_currency_gain)
	
	# Setting unit attributes
	new_unit.is_player = is_player
	new_unit.unit_id = unit_id
	new_unit.unit_name = unit_data["name"]
	new_unit.cost = unit_data["cost"]
	new_unit.weight = unit_data["weight"]
	new_unit.speed = unit_data["speed"]
	new_unit.attack_speed = unit_data["atk_speed"]
	new_unit.max_health = unit_data["hp"]
	new_unit.attack_damage = unit_data["damage"]
	new_unit.attack_type = unit_data["atk_type"]
	new_unit.attack_range = unit_data["atk_range"]
	new_unit.res_phys = unit_data["res_phys"]
	new_unit.res_mag = unit_data["res_mag"]
	
	# Setting animation frames for walk and attack
	new_unit.walk_row = unit_data["walk_row"]
	new_unit.wide_walk = unit_data["wide_walk"]
	
	for frame in unit_data["walk_frames"]:
		new_unit.walk_frames.append(int(frame))
	
	new_unit.attack_row = unit_data["atk_row"]
	new_unit.wide_atk = unit_data["wide_atk"]
	
	for frame in unit_data["atk_frames"]:
		new_unit.attack_frames.append(int(frame))
	
	$UnitsNode.add_child(new_unit)
	
	# OK status
	return 2


func is_shopping_phase() -> bool:
	return current_time > (round_time - shopping_phase_duration)


func within_currency_limits(unit_id: int, is_player: bool) -> bool:
	if is_player:
		return player_gold >= GlobalData.player_units_data[str(unit_id)]["cost"] and \
			player_weight + GlobalData.player_units_data[str(unit_id)]["weight"] <= player_weight_limit
	else:
		return enemy_gold >= GlobalData.enemy_units_data[str(unit_id)]["cost"] and \
			enemy_weight + GlobalData.enemy_units_data[str(unit_id)]["weight"] <= enemy_weight_limit


func _on_game_timer_timeout() -> void:
	current_time -= 1.0
	time_changed.emit(int(current_time), is_shopping_phase())
	
	if current_time <= 0:
		start_new_round()


func update_currency_gain(unit_weight, unit_cost, is_player):
	if is_player:
		enemy_weight_gain += unit_weight
		enemy_gold_gain += unit_cost
	else:
		player_weight_gain += unit_weight
		player_gold_gain += unit_cost


func end_game(is_player):
	var game_over = game_over_scene.instantiate()
	add_child(game_over)
	game_over.setup(not is_player)
	
	# Pause the game
	get_tree().paused = true


func start_new_round():
	# Update time and round number
	current_time = round_time
	round_no += 1
	
	# Update weight and gold limits based on round number
	update_currency_schedule()
	
	# Adding gold at the start of the round
	player_gold += player_gold_round
	enemy_gold += enemy_gold_round
	gold_changed.emit(player_gold, true)
	gold_changed.emit(enemy_gold, false)
	
	# Reset weights
	player_weight = 0
	enemy_weight = 0
	player_weight_gain = 0.0
	enemy_weight_gain = 0.0
	weight_changed.emit(player_weight, player_weight_limit, true)
	weight_changed.emit(enemy_weight, enemy_weight_limit, false)
	
	# Reset gold gain
	player_gold_gain = 0.0
	enemy_gold_gain = 0.0
	
	# Player unit selection
	select_active_unit(active_player_unit_id, true)
	
	# Let the 'AI' make a purchase
	enemy_ai_purchase()


func update_currency_schedule():
	var factor = int(round_no / 5) + 1
	player_weight_limit += int(player_weight_gain / (5.0 * factor))
	enemy_weight_limit += int(enemy_weight_gain / (5.0 * factor))
	player_gold_round += int(player_gold_gain / (5.0 * factor))
	enemy_gold_round += int(enemy_gold_gain / (5.0 * factor))
	
	# Respect the limits
	player_weight_limit = min(player_weight_limit, MAX_WEIGHT_LIMIT)
	enemy_weight_limit = min(enemy_weight_limit, MAX_WEIGHT_LIMIT)
	player_gold_round = min(player_gold_round, MAX_GOLD_LIMIT)
	enemy_gold_round = min(enemy_gold_round, MAX_GOLD_LIMIT)


func enemy_ai_purchase():
	var stats = analyze_current_player_units()
	var best_units = choose_units_by_profit(stats)
	
	# 20% chance for random selection
	if randf() <= 0.2:
		best_units.shuffle()
		
		# Buy "top 4" units
		for i in range(4):
			select_active_unit(best_units[i], false)
			await get_tree().create_timer(1.0).timeout
	else:
		# Buy top 2 best units
		for i in range(2):
			select_active_unit(best_units[i], false)
			await get_tree().create_timer(2.0 / (i+1)).timeout


func analyze_current_player_units():
	var all_units = $UnitsNode.get_children()
	var player_units = []
	
	# Filter player units
	for unit in all_units:
		if unit.is_in_group("player"):
			player_units.append(unit)
	
	# Analyzing statistics
	var stats: Dictionary
	
	stats["physical_units"] = 0
	stats["avg_res_phys"] = 0.0
	stats["magical_units"] = 0
	stats["avg_res_mag"] = 0.0
	
	for unit in player_units:
		if unit.attack_type == "physical":
			stats["physical_units"] += unit.weight
			stats["avg_res_phys"] += unit.weight * unit.res_phys
		else:
			stats["magical_units"] += unit.weight
			stats["avg_res_mag"] += unit.weight * unit.res_mag
	
	# If no data, use default values
	if stats["physical_units"] == 0:
		stats["physical_units"] = 1
	
	if stats["magical_units"] == 0:
		stats["magical_units"] = 1
	
	# Averaging resistances
	stats["avg_res_phys"] /= stats["physical_units"]
	stats["avg_res_mag"] /= stats["magical_units"]
	
	return stats


func choose_units_by_profit(player_stats):
	var units_no = len(GlobalData.player_units_data.keys())
	var scores: Dictionary
	
	for i in range(units_no):
		scores[i] = 0
	
	# Sorting by DPS
	var sorted_keys = analyzed_data.keys()
	sorted_keys.sort_custom(func(a, b):
		return analyzed_data[a]["dps"] > analyzed_data[b]["dps"]
	)
	
	# Updating scores
	for i in range(units_no):
		scores[int(sorted_keys[i])] += 10.0 - 0.5 * i
	
	# Sorting by effective hitpoints (physical)
	sorted_keys = analyzed_data.keys()
	sorted_keys.sort_custom(func(a, b):
		return analyzed_data[a]["hp_phys"] > analyzed_data[b]["hp_phys"]
	)
	
	# Updating scores
	var mult = player_stats["physical_units"] / (player_stats["physical_units"] + player_stats["magical_units"])
	
	for i in range(units_no):
		scores[int(sorted_keys[i])] += mult * (10.0 - 0.5 * i)
	
	# Sorting by effective hitpoints (magical)
	sorted_keys = analyzed_data.keys()
	sorted_keys.sort_custom(func(a, b):
		return analyzed_data[a]["hp_mag"] > analyzed_data[b]["hp_mag"]
	)
	
	# Updating scores
	mult = player_stats["magical_units"] / (player_stats["physical_units"] + player_stats["magical_units"])
	
	for i in range(units_no):
		scores[int(sorted_keys[i])] += mult * (10.0 - 0.5 * i)
	
	# Update scores based on average resistances
	for i in range(units_no):
		if analyzed_data[str(i)]["type"] == "physical":
			scores[i] *= (1 - player_stats["avg_res_phys"] / 10.0)
		else:
			scores[i] *= (1 - player_stats["avg_res_mag"] / 10.0)
	
	# Update scores based on costs
	var avg_funds = enemy_gold / enemy_weight_limit
	
	# Apply penalty for being "too expensive"
	for i in range(units_no):
		if analyzed_data[str(i)]["cost"] > avg_funds:
			scores[i] -= (analyzed_data[str(i)]["cost"] - avg_funds)
	
	# Sort by scores
	sorted_keys = scores.keys()
	sorted_keys.sort_custom(func(a, b):
		return scores[a] > scores[b]
	)
	
	return sorted_keys
