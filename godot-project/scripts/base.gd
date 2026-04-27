extends CharacterBody2D


@export var max_health: float = 10000.0
var current_health: float = 10000.0
var is_player_base: bool = true

signal base_health_changed(current, maximum, is_player)
signal base_destroyed(is_player)

# Called when the node enters the scene tree for the first time.
func _ready():
	current_health = max_health
	add_to_group("player" if is_player_base else "enemy")
	add_to_group("base")
	
	if is_player_base:
		$AttackZone.collision_layer = 1
		$AttackZone.collision_mask = 2
	else:
		$AttackZone.collision_layer = 2
		$AttackZone.collision_mask = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func take_damage(amount: float, atk_type: String):
	current_health -= amount
	base_health_changed.emit(current_health, max_health, is_player_base)
	
	if current_health <= 0:
		base_destroyed.emit(is_player_base)
