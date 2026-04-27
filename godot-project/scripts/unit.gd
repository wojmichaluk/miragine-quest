extends CharacterBody2D


# Unit attributes
@export var unit_id: int
@export var unit_name: String
@export var weight: int
@export var speed: int
@export var attack_speed: float
@export var max_health: float
@export var attack_damage: float
@export var attack_type: String
@export var res_phys: int
@export var res_mag: int
@export var direction: int

var is_player: bool
var attack_timer: float = 0.0
var current_health: float
var attack_range: float
var state: String = "walk"
var is_dead: bool = false

# Used only for magical attack type units
var projectile_sent: bool = false
var projectile_time: float = 0.8
var projectile_scene = preload("res://scenes/Projectile.tscn")

@onready var sprite = $Sprite2D
@onready var attack_zone = $AttackZone

# Standard frame size in LPC
const FRAME_SIZE = 64

var timer = 0.0
var current_col = 0
var is_initialized = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health
	
	if attack_type == "physical":
		attack_range = 40.0
	else:
		attack_range = 200.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_initialized: return
	
	timer += delta
	
	if timer > 0.1:
		timer = 0.0
		current_col = (current_col + 1) % 9
		print(unit_name, " ", sprite.vframes, " ", sprite.hframes)
		
		var row = 11
		sprite.frame = (row * sprite.hframes) + current_col


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_dead: return
	
	var closest_target = find_closest_target()
	var target_to_attack = closest_target["target"]
	var distance_to_target = closest_target["min_dist"]
	
	# Conditional movement
	var should_move = true
	
	if target_to_attack != null and is_instance_valid(target_to_attack):
		# Calculating direction to the target (approaching)
		var direction_to_target = (target_to_attack.global_position - global_position).normalized()
		
		if distance_to_target > attack_range:
			velocity = direction_to_target * 0.75 * speed
		else:
			velocity = Vector2.ZERO
			attack_target(target_to_attack, delta)
			should_move = false
	else:
		attack_timer = 0.0
		velocity.x = speed * direction
		velocity.y = 0
	
	if should_move:
		move_and_slide()


func setup_sprite(texture):
	sprite = $Sprite2D
	
	# Calculating animation hframes and vframes
	sprite.hframes = texture.get_width() / FRAME_SIZE
	sprite.vframes = texture.get_height() / FRAME_SIZE
	sprite.texture = texture
	sprite.frame = 0
	
	is_initialized = true
	
	if not is_player:
		sprite.flip_h = true


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
	
	# Projectile flies for some time
	if attack_type == "magical" and not projectile_sent and attack_timer >= attack_speed - projectile_time:
		# Animate
		play_attack_animation()
		
		# Color dependent on the specific unit
		var color = Color.AZURE if unit_id == 2 else Color.AQUA if unit_id == 5 else Color.FIREBRICK
		
		# Send projectile
		spawn_projectile(target, color)
		projectile_sent = true
	
	# Waiting until attack_timer reaches attack_speed
	if attack_timer >= attack_speed:
		# Do not repeat animation for magical type attack units
		if attack_type == "physical":
			play_attack_animation()
		
		target.take_damage(attack_damage, "physical")
		
		# Reset the counter and projectile status
		attack_timer = 0.0
		projectile_sent = false


func play_attack_animation():
	# Creating tween engine
	var tween = create_tween()
	
	var sprite = $Sprite2D
	
	# Lean 15 (-15) degrees, towards enemy
	var target_rotation = deg_to_rad(15 * direction)
	
	# Animation - lean and go back
	tween.tween_property(sprite, "rotation", target_rotation, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)


func take_damage(amount: float, atk_type: String):
	if atk_type == "physical":
		current_health -= amount * (10.0 - res_phys) / 10.0
	else:
		current_health -= amount * (10.0 - res_mag) / 10.0

	if current_health <= 0 and not is_dead:
		die()


func die():
	is_dead = true
	queue_free()


func set_attack_zone(range: float):
	# Set range for both directions (horizontally)
	$AttackZone/CollisionShape2D.shape.size.x = 2 * range


func spawn_projectile(target, color):
	var projectile = projectile_scene.instantiate()
	
	# Setup the projectile attributes
	projectile.start_position = global_position
	projectile.target = target
	projectile.lifetime = projectile_time
	
	# Set position and color
	projectile.global_position = global_position
	projectile.modulate = color
	
	get_tree().root.add_child(projectile)
