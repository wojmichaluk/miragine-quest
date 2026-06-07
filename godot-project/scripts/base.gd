extends CharacterBody2D


# Base attributes
@export var base_name: String
@export var attack_speed: float
@export var max_health: float
@export var attack_damage: float
@export var attack_type: String
@export var attack_range: int
@export var direction: int

# Animation attributes
@export var idle_row: int
@export var idle_frames: Array[int] = []
@export var wide_idle: int
@export var attack_row: int
@export var attack_frames: Array[int] = []
@export var wide_atk: int
var attack_tween: Tween

var is_player: bool
var attack_timer: float
var current_health: float
var state: String = "idle"

# Both bases have ranged attack
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

# Signals to notify main script about the base health and death
signal base_health_changed(current, maximum, is_player)
signal base_destroyed(is_player)

# Called when the node enters the scene tree for the first time.
func _ready():
	current_health = max_health
	reset_attack_timer()
	
	if is_player:
		collision_layer = 1
		collision_mask = 2
		attack_zone.collision_layer = 1
		attack_zone.collision_mask = 2
	else:
		collision_layer = 2
		collision_mask = 1
		attack_zone.collision_layer = 2
		attack_zone.collision_mask = 1
	
	add_to_group("player" if is_player else "enemy")
	add_to_group("base")
	
	if wide_idle == 0:
		set_sprite_frames_normal()
	else:
		set_sprite_frames_wide()
	
	sprite.flip_h = not is_player
	is_ready = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_ready or state != "idle": return
	
	timer += delta
	
	if timer >= frame_time:
		timer = 0.0
		var frame = idle_frames[current_frame_index]
		
		if wide_idle == 0:
			sprite.frame = (idle_row * sprite.hframes) + frame
		else:
			sprite.region_rect = Rect2(frame * FRAME_SIZE, idle_row * FRAME_SIZE, 2 * FRAME_SIZE, FRAME_SIZE)
		
		current_frame_index = (current_frame_index + 1) % idle_frames.size()


func reset_attack_timer():
	attack_timer = attack_speed - projectile_time


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
	
	var target_to_attack = find_closest_target()
	
	if target_to_attack != null and is_instance_valid(target_to_attack):
		state = "attack"
		
		if wide_atk == 1 and wide_idle == 0:
			set_sprite_frames_wide()
		
		attack_target(target_to_attack, delta)
	elif state == "attack": # return to idle state
		if wide_atk == 1 and wide_idle == 0:
			set_sprite_frames_normal()
		
		current_frame_index = 0
		sprite.flip_h = not is_player
		state = "idle"
		reset_attack_timer()


func find_closest_target():
	# Get all objects in attack zone
	var bodies = attack_zone.get_overlapping_bodies()
	var target = null
	var min_dist = INF
	
	# Finding the closest enemy
	for body in bodies:
		if body == self:
			continue
		
		# Checking if it is an enemy
		if (is_in_group("player") and body.is_in_group("enemy")) or \
			(is_in_group("enemy") and body.is_in_group("player")):
			var dist = global_position.distance_to(body.global_position)
			
			if dist < min_dist:
				target = body
				min_dist = dist
	
	return target


func attack_target(target, delta):
	if not is_instance_valid(target): 
		return
	
	attack_timer += delta
	
	# Projectile flies for some time
	if not projectile_sent and attack_timer >= attack_speed - projectile_time:
		# Animate & play SFX
		play_attack_animation()
		play_attack_sound()
		
		# Color dependent on the side
		var color = Color.AZURE if is_player else Color.FIREBRICK
		
		# Send projectile
		spawn_projectile(target, color)
		projectile_sent = true
	
	# Waiting until attack_timer reaches attack_speed
	if attack_timer >= attack_speed:
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
	var sound
	
	# Getting sound for attack
	if is_player:
		sound = GlobalData.sounds["player_base_attack"]
	else:
		sound = GlobalData.sounds["enemy_base_attack"]
	
	sfx_player.stream = sound
	sfx_player.volume_db = randf_range(-2.0, 2.0)
	sfx_player.pitch_scale = randf_range(0.8, 1.2) # a little bit of randomness
	sfx_player.play()


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


func take_damage(amount: float, atk_type: String):
	current_health -= amount
	base_health_changed.emit(current_health, max_health, is_player)
	
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
	
	# Emit death signal and call queue_free() after animation has ended
	tween.finished.connect(func():
		base_destroyed.emit(is_player)
		queue_free()
	)


func play_death_sound():
	var sound
	
	# Getting sound for death
	if is_player:
		sound = GlobalData.sounds["player_base_death"]
	else:
		sound = GlobalData.sounds["enemy_base_death"]
	
	sfx_player.stream = sound
	sfx_player.volume_db = randf_range(-2.0, 2.0)
	sfx_player.pitch_scale = randf_range(0.9, 1.1) # a little bit of randomness
	sfx_player.play()
