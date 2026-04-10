extends ColorRect


@onready var indicator = $ViewIndicator
@export var camera: Camera2D
@export var unit_dot_radius: float = 2.0

var world_width: float
var offset: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not camera: return
	
	# Dimensions based on camera
	world_width = camera.limit_right - camera.limit_left
	offset = camera.limit_left


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not camera: return
	
	# Calculating x coordinate ratio
	var ratio = (camera.global_position.x - offset) / world_width
	
	indicator.position.x = size.x * ratio - indicator.size.x / 2
	
	# Boundaries for indicator so that it fits within the minimap
	indicator.position.x = clamp(indicator.position.x, 0, size.x - indicator.size.x)
	
	# Redrawing the minimap
	queue_redraw()


func _draw():
	if not camera: return
	
	# Calculating world height
	var world_height = camera.limit_bottom - camera.limit_top
	
	# Drawing player units
	var player_units = get_tree().get_nodes_in_group("player")
	draw_units(player_units, world_height, Color.BLUE)
	
	# Drawing enemy units
	var enemy_units = get_tree().get_nodes_in_group("enemy")
	draw_units(enemy_units, world_height, Color.RED)


func draw_units(units, world_height, unit_color):
	for unit in units:
		if is_instance_valid(unit):
			# Calculating unit position on the minimap
			var ratio_x = (unit.global_position.x - offset) / world_width
			var ratio_y = unit.global_position.y / world_height
			var minimap_x = ratio_x * size.x
			var minimap_y = ratio_y * size.y
			
			# Drawing a dot representing a unit
			var dot_position = Vector2(minimap_x, minimap_y)
			draw_circle(dot_position, unit_dot_radius, unit_color)


func _gui_input(event):
	# Checking if event is click or drag
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			move_camera_to_click(event.position)


func move_camera_to_click(click_position: Vector2):
	if not camera: return
	
	# Boundaries for indicator so that it fits within the minimap
	var indicator_position_x = clamp(click_position.x, indicator.size.x / 2, size.x - indicator.size.x / 2)
	
	# Calculating x coordinate ratio
	var ratio = indicator_position_x / size.x
	
	# Calculating map (camera) position
	camera.global_position.x = world_width * ratio + offset
