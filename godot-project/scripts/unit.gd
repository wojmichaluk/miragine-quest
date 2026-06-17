extends CharacterBody2D


# Unit attributes
@export var unit_id: int
@export var unit_name: String
@export var cost: int
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
var attack_timer: float = 0.0
var current_health: float
var state: String = "walk"

# Used only for magical attack type units
var projectile_sent: bool = false
var projectile_time: float = 0.8
var projectile_scene = preload("res://scenes/Projectile.tscn")

@onready var sprite = $Sprite2D
@onready var attack_zone = $AttackZone
@onready var sfx_player = $AudioStreamPlayer2D

# Standard frame size in LPC
const FRAME_SIZE = 64

# Common animation spritesheet frames
var death_row = 20
var death_frames = [0, 1, 2, 3, 4, 5]

var timer = 0.0
var frame_time = 0.1
var current_frame_index = 0
var is_ready = false

# Signal to notify main script about the unit death
signal unit_died(unit_weight, unit_cost, is_player)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health
	
	# Larger attack zone for magical units
	if attack_type == "magical":
		$AttackZone/CollisionShape2D.shape.size.x = 800
	
	if wide_walk == 0:
		set_sprite_frames_normal()
	else:
		set_sprite_frames_wide()
	
	play_spawn_sound()
	sprite.flip_h = not is_player
	sprite.scale = Vector2(pow(1.01, unit_id), pow(1.01, unit_id))
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


func play_spawn_sound():
	# Getting sound for spawn
	var sound = GlobalData.sounds["spawn"]
	
	sfx_player.stream = sound
	sfx_player.volume_db = randf_range(2.0, 6.0)
	sfx_player.pitch_scale = randf_range(0.9, 1.1) # a little bit of randomness
	sfx_player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if state == "dead": return
	
	var closest_target = find_closest_target()
	var target_to_attack = closest_target["target"]
	var distance_to_target = closest_target["dist"]
	
	# Conditional movement
	var should_move = true
	
	if target_to_attack != null and is_instance_valid(target_to_attack):
		if distance_to_target > attack_range or \
			(attack_type == "physical" and \
			abs(target_to_attack.global_position.y - global_position.y) > 0.25 * FRAME_SIZE):
			# Calculating direction to the target (approaching)
			var direction_to_target = shifted_direction_to_target(target_to_attack)
			velocity = direction_to_target * 0.75 * speed
			
			# Rotating the right side (so that character does not moonwalk)
			sprite.flip_h = direction_to_target.x < 0
			
			# Return to "walk" state
			if state == "attack":
				if wide_atk == 1 and wide_walk == 0:
					set_sprite_frames_normal()
				
				current_frame_index = 0
				state = "walk"
				attack_timer = 0.0
		else:
			should_move = false
			sprite.flip_h = target_to_attack.global_position.x - global_position.x < 0
			velocity = Vector2.ZERO
			state = "attack"
			
			if wide_atk == 1 and wide_walk == 0:
				set_sprite_frames_wide()
			
			sprite.region_rect = Rect2(attack_frames[0] * FRAME_SIZE, attack_row * FRAME_SIZE, 2 * FRAME_SIZE, FRAME_SIZE)
			attack_target(target_to_attack, delta)
	else:
		velocity.x = speed * direction
		velocity.y = 0
		sprite.flip_h = not is_player
		
		# Return to "walk" state
		if state == "attack":
			if wide_atk == 1 and wide_walk == 0:
				set_sprite_frames_normal()
			
			current_frame_index = 0
			state = "walk"
			attack_timer = 0.0
	
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
		
		# Checking if it is an enemy
		if (is_in_group("player") and body.is_in_group("enemy")) or \
			(is_in_group("enemy") and body.is_in_group("player")):
			# Checking if it is a base
			if body.is_in_group("base"):
				base = body
				break
				
			var metric_dist = metric_distance(body)
			
			if metric_dist < min_metric_dist:
				target = body
				min_metric_dist = metric_dist
				min_real_dist = global_position.distance_to(body.global_position)
	
	# Return base as a target whenever possible
	if base != null:
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
	
	# Strengthen the diff_y weight for close-range attack units
	if attack_type == "physical":
		return diff_x + 4 * diff_y
	else:
		return diff_x + diff_y


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
		# Animate & play SFX
		play_attack_animation()
		play_attack_sound()
		
		# Send projectile
		spawn_projectile(target, is_player)
		projectile_sent = true
	
	# Waiting until attack_timer reaches attack_speed
	if attack_timer >= attack_speed:
		# Do not repeat animation & SFX for magical type attack units
		if attack_type == "physical":
			play_attack_animation()
			play_attack_sound()
		
		target.take_damage(attack_damage, attack_type)
		
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


func play_attack_sound():
	var sounds
	
	# Getting sounds for attack type
	if attack_type == "physical":
		sounds = GlobalData.sounds["atk_phys"]
	else:
		sounds = GlobalData.sounds["atk_mag"]
	
	sfx_player.stream = sounds.pick_random()
	sfx_player.volume_db = randf_range(-2.0, 2.0)
	sfx_player.pitch_scale = randf_range(0.8, 1.2) # a little bit of randomness
	sfx_player.play()


func spawn_projectile(target, is_player):
	var projectile = projectile_scene.instantiate()
	
	# Setup the projectile attributes
	projectile.start_position = global_position
	projectile.target = target
	projectile.lifetime = projectile_time
	
	# Set position and texture
	projectile.global_position = global_position
	projectile.texture = GlobalData.projectile_textures[unit_id][is_player]
	
	get_tree().root.add_child(projectile)


func take_damage(amount: float, atk_type: String):
	if atk_type == "physical":
		current_health -= amount * (10.0 - res_phys) / 10.0
	elif atk_type == "magical":
		current_health -= amount * (10.0 - res_mag) / 10.0
	else:
		current_health -= amount

	if current_health <= 0 and state != "dead":
		state = "dead"
		die()


func die():
	# Stop the animation attack if it currently happens
	if attack_tween:
		attack_tween.kill()
	
	# Emit death signal
	unit_died.emit(weight, cost, is_player)
	
	# Ensure that hframes and vframes are set 'normally'
	set_sprite_frames_normal()
	
	var frames_num = death_frames.size()
	
	# Produce the death sound
	play_death_sound()
	
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


func play_death_sound():
	# Getting sounds for death
	var sounds = GlobalData.sounds["death"]
	
	sfx_player.stream = sounds.pick_random()
	sfx_player.volume_db = randf_range(-2.0, 2.0)
	sfx_player.pitch_scale = randf_range(0.9, 1.1) # a little bit of randomness
	sfx_player.play()
