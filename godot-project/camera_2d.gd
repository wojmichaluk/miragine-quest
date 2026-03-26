extends Camera2D


var speed = 750


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var half_visible_screen = get_viewport_rect().size.x / (2 * zoom.x)
	var min_pos = limit_left + half_visible_screen
	var max_pos = limit_right - half_visible_screen
	
	if Input.is_action_pressed("ui_right"):
		position.x += speed * delta
	
	if Input.is_action_pressed("ui_left"):
		position.x -= speed * delta
	
	position.x = clamp(position.x, min_pos, max_pos)
