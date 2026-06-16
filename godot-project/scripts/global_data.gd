extends Node


# Player and enemy textures
var player_units_textures = []
var enemy_units_textures = []

# Projectile textures
var projectile_textures: Dictionary = {}

# Units data
var player_units_data: Dictionary = {}
var enemy_units_data: Dictionary = {}

# Extreme values for unit statistics
var min_stats: Dictionary = {}
var max_stats: Dictionary = {}

# Sounds for different unit actions
var sounds: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load textures for player units and enemy units
	for i in range(1, 13):
		player_units_textures.append(load("res://assets/units/player/unit" + str(i) + ".png"))
		enemy_units_textures.append(load("res://assets/units/enemy/unit" + str(i) + ".png"))
	
	# Hardcoded (unit_id, is_player) tuples for projectile textures
	load_projectile_textures()
	
	# Load all units
	load_all_units()
	
	# Calculate extreme values
	calculate_extremes()
	
	# Load all sounds
	load_sounds()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func load_projectile_textures():
	projectile_textures[2] = Dictionary()
	projectile_textures[5] = Dictionary()
	projectile_textures[9] = Dictionary()
	projectile_textures[-1] = Dictionary() # for main bases
	
	projectile_textures[2][true] = load("res://assets/projectiles/wind.png")
	projectile_textures[2][false] = load("res://assets/projectiles/earth.png")
	projectile_textures[5][true] = load("res://assets/projectiles/water.png")
	projectile_textures[5][false] = load("res://assets/projectiles/fire.png")
	projectile_textures[9][true] = load("res://assets/projectiles/plasma.png")
	projectile_textures[9][false] = load("res://assets/projectiles/doom.png")
	projectile_textures[-1][true] = load("res://assets/projectiles/arrow.png")
	projectile_textures[-1][false] = load("res://assets/projectiles/spell.png")


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


func calculate_extremes():
	# Initializing extreme values
	var min_speed = INF
	var max_speed = 0
	var min_atk_speed = INF
	var max_atk_speed = 0
	var min_hp = INF
	var max_hp = 0
	var min_damage = INF
	var max_damage = 0
	var min_atk_range = INF
	var max_atk_range = 0
	
	for unit_data in player_units_data.values():
		# Getting unit statistics
		var speed = unit_data["speed"]
		var atk_speed = unit_data["atk_speed"]
		var hp = unit_data["hp"]
		var damage = unit_data["damage"]
		var atk_range = unit_data["atk_range"]
		
		min_speed = min(speed, min_speed)
		max_speed = max(speed, max_speed)
		
		min_atk_speed = min(atk_speed, min_atk_speed)
		max_atk_speed = max(atk_speed, max_atk_speed)
		
		min_hp = min(hp, min_hp)
		max_hp = max(hp, max_hp)
		
		min_damage = min(damage, min_damage)
		max_damage = max(damage, max_damage)
		
		min_atk_range = min(atk_range, min_atk_range)
		max_atk_range = max(atk_range, max_atk_range)
	
	# Filling the dictionaries
	min_stats["speed"] = min_speed
	min_stats["atk_speed"] = min_atk_speed
	min_stats["hp"] = min_hp
	min_stats["damage"] = min_damage
	min_stats["atk_range"] = min_atk_range
	
	max_stats["speed"] = max_speed
	max_stats["atk_speed"] = max_atk_speed
	max_stats["hp"] = max_hp
	max_stats["damage"] = max_damage
	max_stats["atk_range"] = max_atk_range
	
	# "Hardcoded" values for resistances
	min_stats["res_phys"] = 0
	min_stats["res_mag"] = 0
	max_stats["res_phys"] = 10
	max_stats["res_mag"] = 10


func load_sounds():
	# Sounds for attack (physical)
	sounds["atk_phys"] = [
		preload("res://assets/music/sounds/sword_armor.wav"),
		preload("res://assets/music/sounds/sword_clash.wav"),
		preload("res://assets/music/sounds/sword_slice.wav")
	]
	
	# Sounds for attack (magical)
	sounds["atk_mag"] = [
		preload("res://assets/music/sounds/magic_v1.wav"),
		preload("res://assets/music/sounds/magic_v2.wav")
	]
	
	# Sounds for death
	sounds["death"] = [
		preload("res://assets/music/sounds/death_v1.wav"),
		preload("res://assets/music/sounds/death_v2.wav")
	]
	
	# Sound for spawning a unit
	sounds["spawn"] = preload("res://assets/music/sounds/spawn_roar.wav")
	
	# Sounds for bases actions
	sounds["player_base_attack"] = preload("res://assets/music/sounds/player_base_attack.wav")
	sounds["enemy_base_attack"] = preload("res://assets/music/sounds/enemy_base_attack.wav")
	sounds["player_base_death"] = preload("res://assets/music/sounds/player_base_death.wav")
	sounds["enemy_base_death"] = preload("res://assets/music/sounds/enemy_base_death.wav")
