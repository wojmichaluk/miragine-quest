extends Node


# Player and enemy textures
var player_units_textures = []
var enemy_units_textures = []

# Units data
var player_units_data: Dictionary = {}
var enemy_units_data: Dictionary = {}

# Sounds for different unit actions
var sounds: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load textures for player units and enemy units
	for i in range(1, 13):
		player_units_textures.append(load("res://assets/units/player/unit" + str(i) + ".png"))
		enemy_units_textures.append(load("res://assets/units/enemy/unit" + str(i) + ".png"))
	
	# Load all units
	load_all_units()
	
	# Load all sounds
	load_sounds()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
	
