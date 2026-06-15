extends Node2D


# Player and enemy unit & base scenes
@export var player_unit_scene: PackedScene
@export var enemy_unit_scene: PackedScene
@export var base_scene: PackedScene

# Game over scene
@export var game_over_scene: PackedScene

# Gold currency
var player_gold: int = 1000
var enemy_gold: int = 1000
var player_gold_round: int = 800
var enemy_gold_round: int = 800
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
var current_time: float = 40.0
var shopping_phase_duration: float = 5.0

# Signals to notify UI
signal gold_changed(new_amount, is_player)
signal time_changed(seconds_left, is_shopping)
signal weight_changed(current, maximum, is_player)

# Spawn unit utility
var active_player_unit_id
var active_enemy_unit_id

# Round number
var round_no = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup bases
	setup_bases()
	
	# Connect time and currency signals
	gold_changed.connect($CanvasLayer/UI.update_gold_display)
	time_changed.connect($CanvasLayer/UI.update_timer_display)
	weight_changed.connect($CanvasLayer/UI.update_weight_display)
	
	# Displaying start values
	gold_changed.emit(player_gold, true)
	gold_changed.emit(enemy_gold, false)
	time_changed.emit(current_time, is_shopping_phase())
	weight_changed.emit(player_weight, player_weight_limit, true)
	weight_changed.emit(enemy_weight, enemy_weight_limit, false)
	
	# Initial player unit selection
	select_active_unit(0, true)
	
	# Initial AI purchase
	enemy_ai_purchase()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func setup_bases():
	var bases_data_path = "res://data/bases.json"
	var bases_data: Dictionary = {}
	
	# Load bases data
	if FileAccess.file_exists(bases_data_path):
		var file = FileAccess.open(bases_data_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		
		if error == OK:
			bases_data = json.data
	
	# Initialize player and enemy bases
	var player_base = initialize_base(bases_data["player"], true)
	var enemy_base = initialize_base(bases_data["enemy"], false)
	
	# Adding bases to scene
	add_child(player_base)
	add_child(enemy_base)
	
	# Connecting bases signals to UI
	player_base.base_health_changed.connect($CanvasLayer/UI.update_base_hp)
	player_base.base_destroyed.connect(end_game)
	enemy_base.base_health_changed.connect($CanvasLayer/UI.update_base_hp)
	enemy_base.base_destroyed.connect(end_game)


func initialize_base(base_data, is_player):
	var base = base_scene.instantiate()
	base.is_player = is_player
	base.position = Vector2(-4600 if is_player else 4600, 350)
	
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
	# Simple AI: buy random units
	for i in range(5):
		var unit_id = randi_range(0, 11)
		select_active_unit(unit_id, false)
		await get_tree().create_timer(0.8).timeout
