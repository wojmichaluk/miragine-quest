extends Node2D


# Player and enemy unit scenes
var player_unit_scene = preload("res://PlayerUnit.tscn")
var enemy_unit_scene = preload("res://EnemyUnit.tscn")

# Currency
var player_gold: int = 100
var enemy_gold: int = 100

# Signal to notify UI about gold change
signal gold_changed(new_amount, is_player)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gold_changed.connect($CanvasLayer/UI.update_gold_display)
	
	# Displaying start values
	gold_changed.emit(player_gold, true)
	gold_changed.emit(enemy_gold, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func spawn_unit(unit_id: int, unit_texture: Texture2D, is_player: bool):
	# Check if can afford that unit
	if not can_afford(unit_id, is_player):
		return
	
	# Calculating currency change
	var cost = 10
	
	if is_player:
		player_gold -= cost
		gold_changed.emit(player_gold, true)
	else:
		enemy_gold -= cost
		gold_changed.emit(enemy_gold, false)
	
	# Instantiating a new unit
	var new_unit
	var dir = 1 if is_player else -1
	
	if is_player:
		new_unit = player_unit_scene.instantiate()
	else:
		new_unit = enemy_unit_scene.instantiate()
		
	new_unit.get_node("Sprite2D").texture = unit_texture
	new_unit.position = Vector2(-dir * 4000, randf_range(100, 600))
	new_unit.direction = dir
	
	$UnitsNode.add_child(new_unit)
	
	
func can_afford(id: int, is_player: bool) -> bool:
	# var cost = unit_data[id]["cost"]
	var cost = 10
	if is_player:
		return player_gold >= cost
	else:
		return enemy_gold >= cost


func _on_income_timer_timeout() -> void:
	player_gold += 50
	enemy_gold += 50
	gold_changed.emit(player_gold, true)
	gold_changed.emit(enemy_gold, false)
