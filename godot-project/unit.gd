extends CharacterBody2D

# Unit attributes
@export var unit_name: String
@export var speed: int = 500
@export var direction: int = 1
@export var max_health: float = 100.0
@export var attack_damage: float = 20.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 40.0

var current_health: float = 100.0
var is_dead: bool = false
var attack_timer: float = 0.0

@onready var attack_zone = $AttackZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_dead: return
	
	var closest_target = find_closest_target()
	var target_to_attack = closest_target["target"]
	var distance_to_target = closest_target["min_dist"]
	
	if target_to_attack != null and is_instance_valid(target_to_attack):
		# Calculating direction to the target (approaching)
		var direction_to_target = (target_to_attack.global_position - global_position).normalized()
		
		if distance_to_target > attack_range:
			velocity = direction_to_target * 0.5 * speed
		else:
			velocity = Vector2.ZERO
			attack_target(target_to_attack, delta)
	else:
		attack_timer = 0.0
		velocity.x = speed * direction
		velocity.y = 0

	move_and_slide()
	
	
func find_closest_target():
	# Get all objects in attack zone
	var bodies = attack_zone.get_overlapping_bodies()
	
	var target = null
	var min_dist = INF
	
	# Finding the closest enemy
	for body in bodies:
		if body == self: continue
		
		# Checking if it is an enemy
		if (is_in_group("player") and body.is_in_group("enemy")) or \
			(is_in_group("enemy") and body.is_in_group("player")):
			var distance_to_enemy = global_position.distance_to(body.global_position)
			
			if distance_to_enemy < min_dist:
				target = body
				min_dist = distance_to_enemy
	
	return {
		"target": target,
		"min_dist": min_dist
	}

	
	
func attack_target(target, delta):
	if not is_instance_valid(target): 
		return
	
	attack_timer += delta

	# Waiting until attack_timer reaches attack_speed
	if attack_timer >= attack_speed:
		# Animate
		play_attack_animation()
		
		target.take_damage(attack_damage)
		
		# Reset the counter
		attack_timer = 0.0
		
		
func play_attack_animation():
	# Creating tween engine
	var tween = create_tween()
	
	var sprite = $Sprite2D
	
	# Lean 15 (-15) degrees, towards enemy
	var target_rotation = deg_to_rad(15 * direction)
	
	# Animation - lean and go back
	tween.tween_property(sprite, "rotation", target_rotation, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)


func take_damage(amount: float):
	current_health -= amount

	if current_health <= 0 and not is_dead:
		die()


func die():
	is_dead = true
	queue_free()
