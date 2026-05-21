extends Node2D


# Player and enemy unit & base scenes
var player_unit_scene = preload("res://scenes/PlayerUnit.tscn")
var enemy_unit_scene = preload("res://scenes/EnemyUnit.tscn")
var base_scene = preload("res://scenes/Base.tscn")

# Player and enemy textures
var player_units_textures = []
var enemy_units_textures = []

# Currency
var player_gold: int = 5000
var enemy_gold: int = 5000

# Unit weights
var player_current_weight: int = 0
var enemy_current_weight: int = 0
var max_weight_limit: int = 50

# Units data
var player_units_data: Dictionary = {}
var enemy_units_data: Dictionary = {}

# Timers
var round_time: float = 40.0
var current_time: float = 40.0
var shopping_phase_duration: float = 5.0

# Signals to notify UI
signal gold_changed(new_amount, is_player)
signal time_changed(seconds_left, is_shopping)
signal weight_changed(current, maximum, is_player)

# Spawn unit utility
var active_unit_id
var spawn_delay_per_weight = 0.05

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load textures for player units and enemy units
	for i in range(1, 13):
		player_units_textures.append(load("res://assets/units/player/unit" + str(i) + ".png"))
		enemy_units_textures.append(load("res://assets/units/enemy/unit" + str(i) + ".png"))
	
	# Setup bases and load all units
	setup_bases()
	load_all_units()
	
	# Connect time and currency signals
	gold_changed.connect($CanvasLayer/UI.update_gold_display)
	time_changed.connect($CanvasLayer/UI.update_timer_display)
	weight_changed.connect($CanvasLayer/UI.update_weight_display)
	
	# Displaying start values
	gold_changed.emit(player_gold, true)
	gold_changed.emit(enemy_gold, false)
	time_changed.emit(current_time, is_shopping_phase())
	weight_changed.emit(player_current_weight, max_weight_limit, true)
	weight_changed.emit(enemy_current_weight, max_weight_limit, false)
	
	# Initial player unit selection
	select_active_unit(0)
	
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
	
	# Connecting signals to UI
	player_base.base_health_changed.connect($CanvasLayer/UI.update_base_hp)
	enemy_base.base_health_changed.connect($CanvasLayer/UI.update_base_hp)


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


func load_all_units():
	var player_file_path = "res://data/player_units.json"
	var enemy_file_path = "res://data/enemy_units.json"
	
	# Load units data for player and enemy
	load_units_data(player_file_path, true)
	load_units_data(enemy_file_path, false)


func load_units_data(file_path, is_player):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		
		if error == OK:
			if is_player:
				player_units_data = json.data
			else:
				enemy_units_data = json.data


func select_active_unit(unit_id):
	active_unit_id = unit_id
	var unit_data = player_units_data[str(unit_id)]
	var spawn_delay = spawn_delay_per_weight * unit_data["weight"]
	$CanvasLayer/UI.update_unit_selection(unit_id, spawn_delay)


func spawn_unit(unit_id: int, is_player: bool):
	# Check if can buy unit (shopping_phase)
	if not is_shopping_phase():
		return 0
	
	# Check if can buy unit (afford and respect weight limit)
	if not can_afford(unit_id, is_player) or not weight_fits(unit_id, is_player):
		return 1
	
	# Choosing proper unit data
	var unit_data: Dictionary
	
	if is_player:
		unit_data = player_units_data[str(unit_id)]
	else:
		unit_data = enemy_units_data[str(unit_id)]
	
	# Calculating currency and weight change
	if is_player:
		player_gold -= unit_data["cost"]
		player_current_weight += unit_data["weight"]
		gold_changed.emit(player_gold, true)
		weight_changed.emit(player_current_weight, max_weight_limit, true)
	else:
		enemy_gold -= unit_data["cost"]
		enemy_current_weight += unit_data["weight"]
		gold_changed.emit(enemy_gold, false)
		weight_changed.emit(enemy_current_weight, max_weight_limit, false)
	
	# Instantiating a new unit
	var new_unit
	var dir = 1 if is_player else -1
	
	if is_player:
		new_unit = player_unit_scene.instantiate()
	else:
		new_unit = enemy_unit_scene.instantiate()
		
	new_unit.is_player = is_player
	
	# Setting unit orientation
	new_unit.position = Vector2(-dir * 1500, randf_range(120, 580))
	new_unit.direction = dir
	
	# Setting unit attributes
	new_unit.unit_id = unit_id
	new_unit.unit_name = unit_data["name"]
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
	
	# Set sprite texture
	if is_player:
		new_unit.get_node("Sprite2D").texture = player_units_textures[unit_id]
	else:
		new_unit.get_node("Sprite2D").texture = enemy_units_textures[unit_id]
	
	$UnitsNode.add_child(new_unit)
	
	# OK status
	return 2


func is_shopping_phase() -> bool:
	return current_time > (round_time - shopping_phase_duration)


func can_afford(unit_id: int, is_player: bool) -> bool:
	if is_player:
		return player_gold >= player_units_data[str(unit_id)]["cost"]
	else:
		return enemy_gold >= enemy_units_data[str(unit_id)]["cost"]


func weight_fits(unit_id: int, is_player: bool) -> bool:
	if is_player:
		return player_current_weight + player_units_data[str(unit_id)]["weight"] <= max_weight_limit
	else:
		return enemy_current_weight + enemy_units_data[str(unit_id)]["weight"] <= max_weight_limit


func _on_game_timer_timeout() -> void:
	current_time -= 1.0
	time_changed.emit(int(current_time), is_shopping_phase())
	
	if current_time <= 0:
		start_new_round()


func start_new_round():
	current_time = round_time
	
	# Adding gold at the start of the round
	var income_amount = 5000
	player_gold += income_amount
	enemy_gold += income_amount
	gold_changed.emit(player_gold, true)
	gold_changed.emit(enemy_gold, false)
	
	# Reset weight limits
	player_current_weight = 0
	enemy_current_weight = 0
	weight_changed.emit(player_current_weight, max_weight_limit, true)
	weight_changed.emit(enemy_current_weight, max_weight_limit, false)
	
	# Player unit selection
	select_active_unit(active_unit_id)
	
	# Let the 'AI' make a purchase
	enemy_ai_purchase()


func enemy_ai_purchase():
	# Simple AI: buy random units
	for i in range(50):
		spawn_unit(randi_range(0, 11), false)
		await get_tree().create_timer(0.2).timeout
