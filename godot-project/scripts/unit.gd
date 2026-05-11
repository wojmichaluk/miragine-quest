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
@export var attack_range: int
@export var res_phys: int
@export var res_mag: int
@export var direction: int

# Animation attributes
@export var walk_row: int
@export var walk_frames: Array[int] = []
@export var wide_walk: int
@export var attack_row: int
@export var attack_frames: Array[int] = []
@export var wide_atk: int
var attack_tween: Tween

var is_player: bool
var attack_timer: float
var current_health: float
var state: String = "walk"

# Used only for magical attack type units
var projectile_sent: bool = false
var projectile_time: float = 0.8
var projectile_scene = preload("res://scenes/Projectile.tscn")

@onready var sprite = $Sprite2D
@onready var attack_zone = $AttackZone

# Standard frame size in LPC
const FRAME_SIZE = 64

# Common animation spritesheet frames
var death_row = 20
var death_frames = [0, 1, 2, 3, 4, 5]

var timer = 0.0
var frame_time = 0.1
var current_frame_index = 0
var is_ready = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health
	reset_attack_timer()
	
	if wide_walk == 0:
		set_sprite_frames_normal()
	else:
		set_sprite_frames_wide()
	
	sprite.flip_h = not is_player
	is_ready = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_ready or state != "walk": return
	
	timer += delta
	
	if timer >= frame_time:
		timer = 0.0
		var frame = walk_frames[current_frame_index]
		
		if wide_walk == 0:
			sprite.frame = (walk_row * sprite.hframes) + frame
		else:
			sprite.region_rect = Rect2(frame * FRAME_SIZE, walk_row * FRAME_SIZE, 2 * FRAME_SIZE, FRAME_SIZE)
		
		current_frame_index = (current_frame_index + 1) % walk_frames.size()


func reset_attack_timer():
	attack_timer = attack_speed
	
	if attack_type == "magical":
		attack_timer -= projectile_time


func set_sprite_frames_normal():
	# Calculating animation hframes and vframes, resetting region_enabled
	sprite.hframes = sprite.texture.get_width() / FRAME_SIZE
	sprite.vframes = sprite.texture.get_height() / FRAME_SIZE
	sprite.region_enabled = false


func set_sprite_frames_wide():
	# Setting hframes and vframes to 1, setting region_enabled
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.region_enabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if state == "dead": return
	
	var closest_target = find_closest_target()
	var target_to_attack = closest_target["target"]
	var distance_to_target = closest_target["dist"]
	
	# Conditional movement
	var should_move = true
	
	if target_to_attack != null and is_instance_valid(target_to_attack):
		# Calculating direction to the target (approaching)
		var direction_to_target = shifted_direction_to_target(target_to_attack)
		
		# Rotating the right side (so that character does not moonwalk)
		sprite.flip_h = target_to_attack.global_position.x - global_position.x < 0
		
		if distance_to_target > attack_range or \
			(attack_type == "physical" and \
			abs(target_to_attack.global_position.y - global_position.y) > 0.25 * FRAME_SIZE):
			velocity = direction_to_target * 0.67 * speed
			
			# Return to "walk" state
			if state == "attack":
				if wide_atk == 1 and wide_walk == 0:
					set_sprite_frames_normal()
				
				current_frame_index = 0
				sprite.flip_h = not is_player
				state = "walk"
		else:
			should_move = false
			velocity = Vector2.ZERO
			state = "attack"
			
			if wide_atk == 1 and wide_walk == 0:
				set_sprite_frames_wide()
			
			attack_target(target_to_attack, delta)
	else:
		reset_attack_timer()
		velocity.x = speed * direction
		velocity.y = 0
		
		# Return to "walk" state
		if state == "attack":
			if wide_atk == 1 and wide_walk == 0:
				set_sprite_frames_normal()
			
			current_frame_index = 0
			sprite.flip_h = not is_player
			state = "walk"
	
	if should_move:
		move_and_slide()


func find_closest_target():
	# Get all objects in attack zone
	var bodies = attack_zone.get_overlapping_bodies()
	
	var target = null
	var base = null
	var min_metric_dist = INF
	var min_real_dist = INF
	
	# Finding the closest enemy
	for body in bodies:
		if body == self:
			continue
		elif body.is_in_group("base"):
			base = body
			continue
		
		# Checking if it is an enemy
		if (is_in_group("player") and body.is_in_group("enemy")) or \
			(is_in_group("enemy") and body.is_in_group("player")):
			var metric_dist = metric_distance(body)
			
			if metric_dist < min_metric_dist:
				target = body
				min_metric_dist = metric_dist
				min_real_dist = global_position.distance_to(body.global_position)
	
	# Return base as a target only if there is no unit target
	if target == null and base != null:
		return {
			"target": base,
			"dist": global_position.distance_to(base.global_position)
		}
	
	return {
		"target": target,
		"dist": min_real_dist
	}


func metric_distance(target):
	var diff_x = abs(global_position.x - target.global_position.x)
	var diff_y = abs(global_position.y - target.global_position.y)
	
	return diff_x + 4 * diff_y


func shifted_direction_to_target(target):
	var vector_to_target = target.global_position - global_position
	var angle_to_target = abs(vector_to_target.angle())
	
	if is_player:
		vector_to_target.x -= 3 * FRAME_SIZE * angle_to_target / PI
	else:
		vector_to_target.x += 3 * FRAME_SIZE * (PI - angle_to_target) / PI
	
	return vector_to_target.normalized()


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
	var frames_num = attack_frames.size()
	
	if attack_tween:
		attack_tween.kill()
	
	# Creating tween engine
	attack_tween = create_tween()
	
	if wide_atk == 1:
		attack_tween.tween_method(
			func(index):
				var frame = attack_frames[index]
				sprite.region_rect = Rect2(frame * FRAME_SIZE, attack_row * FRAME_SIZE, 2 * FRAME_SIZE, FRAME_SIZE),
			0,
			frames_num - 1,
			frames_num * frame_time
		)
	else:
		attack_tween.tween_method(
			func(index):
				var frame = attack_frames[index]
				sprite.frame = (attack_row * sprite.hframes) + frame,
			0,
			frames_num - 1, 
			frames_num * frame_time
		)


func take_damage(amount: float, atk_type: String):
	if atk_type == "physical":
		current_health -= amount * (10.0 - res_phys) / 10.0
	else:
		current_health -= amount * (10.0 - res_mag) / 10.0

	if current_health <= 0 and state != "dead":
		state = "dead"
		die()


func die():
	# Stop the animation attack if it currently happens
	if attack_tween:
		attack_tween.kill()
	
	# Ensure that hframes and vframes are set 'normally'
	set_sprite_frames_normal()
	
	var frames_num = death_frames.size()
	
	# Play death animation
	var tween = create_tween()
	
	tween.tween_method(
		func(index):
			var frame = death_frames[index]
			sprite.frame = (death_row * sprite.hframes) + frame,
		0,
		frames_num - 1, 
		frames_num * frame_time
	)
	
	# Call queue_free() after animation has ended
	tween.finished.connect(queue_free)


func set_attack_zone(atk_range: float):
	# Set range for both directions (horizontally)
	$AttackZone/CollisionShape2D.shape.size.x = 2 * atk_range


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
