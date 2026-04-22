extends Sprite2D


@export var start_position: Vector2
@export var target: CharacterBody2D
@export var lifetime: float
var progress: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progress = 0.0
	
	# Self-destruction
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(target):
		progress += delta * 1.0 / lifetime
		look_at(target.global_position)
		global_position = start_position.lerp(target.global_position, clamp(progress, 0.0, 1.0))
	else:
		queue_free()
