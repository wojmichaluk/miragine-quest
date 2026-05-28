extends Node2D


# Player and enemy unit scenes
@export var player_unit_scene: PackedScene
@export var enemy_unit_scene: PackedScene

# Variables to control spawned units
@onready var unit_container = $MenuUnitsNode
var screen_width: float
var screen_height: float
var max_units: int = 20
var max_diff: int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_spawn_timer_timeout() -> void:
	var counts = count_units()
	var player_count = counts["player"]
	var enemy_count = counts["enemy"]
	
	# Random unit id, the same for both sides
	var unit_id = randi_range(0, 11)
	
	# Spawn player unit if possible
	if player_count < max_units and player_count <= enemy_count + max_diff:
		spawn_menu_unit(unit_id, true)
	
	# Spawn enemy unit if possible
	if enemy_count < max_units and enemy_count <= player_count + max_diff:
		spawn_menu_unit(unit_id, false)


func count_units():
	var counts = {"player": 0, "enemy": 0}
	
	for unit in unit_container.get_children():
		counts["player" if unit.is_player else "enemy"] += 1
	
	return counts


func spawn_menu_unit(unit_id: int, is_player: bool):
	var unit_data
	var new_unit
	
	if is_player:
		unit_data = GlobalData.player_units_data[str(unit_id)]
		new_unit = player_unit_scene.instantiate()
		new_unit.get_node("Sprite2D").texture = GlobalData.player_units_textures[unit_id]
	else:
		unit_data = GlobalData.enemy_units_data[str(unit_id)]
		new_unit = enemy_unit_scene.instantiate()
		new_unit.get_node("Sprite2D").texture = GlobalData.enemy_units_textures[unit_id]
	
	# Start position (outside the screen)
	var spawn_x = -100 if is_player else screen_width + 100
	var spawn_y = randf_range(screen_height * 0.3, screen_height * 0.8)
	
	# Setting unit orientation
	new_unit.position = Vector2(spawn_x, spawn_y)
	new_unit.direction = 1 if is_player else -1
	
	# Setting (a bit modified) unit attributes
	new_unit.is_player = is_player
	new_unit.unit_id = unit_id
	new_unit.unit_name = unit_data["name"]
	new_unit.speed = unit_data["speed"]
	new_unit.attack_speed = 0.8 * unit_data["atk_speed"]
	new_unit.max_health = 2 * unit_data["hp"]
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
	
	unit_container.add_child(new_unit)


func _on_cleanup_timer_timeout() -> void:
	var margin = 25
	
	for unit in unit_container.get_children():
		# Checking if player unit and has passed the right screen edge
		# or if enemy unit and has passed the left screen edge
		if unit.is_player and unit.global_position.x > screen_width + margin or \
			not unit.is_player and unit.global_position.x < -margin:
			unit.queue_free()
