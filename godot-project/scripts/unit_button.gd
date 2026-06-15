extends Button


var unit_id: int
var is_player: bool
var is_active = false
var flash_timer = 0.0
@onready var selection_frame = $SelectionFrame

var info_window_scene = preload("res://scenes/UnitInfoWindow.tscn")
var current_window = null

# Signal to notify about active unit selection
signal unit_selected(selected_unit_id, is_player)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit_selected.connect(get_tree().current_scene.select_active_unit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Flashing green when spawning unit
	if is_active:
		selection_frame.visible = true
		
		if flash_timer > 0:
			flash_timer -= delta
			selection_frame.self_modulate = Color.GREEN
		else:
			selection_frame.self_modulate = Color.WHITE
	else:
		selection_frame.visible = false


func _on_pressed():
	unit_selected.emit(unit_id, is_player)


func trigger_flash(duration):
	flash_timer = duration


func _gui_input(event: InputEvent):
	# Toggle the info window on right mouseclick
	if event is InputEventMouseButton and \
	event.button_index == MOUSE_BUTTON_RIGHT and \
	event.pressed:
		toggle_info_window()


func toggle_info_window():
	# Close the window if already opened
	if current_window and current_window.visible:
		current_window.queue_free()
		return
	
	var stats
	
	# Getting unit statistics from GlobalData
	if is_player:
		stats = GlobalData.player_units_data[str(unit_id)]
	else:
		stats = GlobalData.enemy_units_data[str(unit_id)]
	
	# Instantiating a popup window
	current_window = info_window_scene.instantiate()
	add_child(current_window)
	current_window.display_info(stats)
	
	# Positioning above the unit window
	if is_player:
		current_window.global_position = global_position + Vector2(40, -420)
	else:
		current_window.global_position = global_position + Vector2(-360, -420)


func _on_mouse_exited() -> void:
	# Destroy the popup upon exiting
	if current_window:
		current_window.queue_free()
