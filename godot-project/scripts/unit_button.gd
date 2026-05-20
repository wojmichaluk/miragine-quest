extends Button


var unit_id: int
var is_active = false
var flash_timer = 0.0
@onready var selection_frame = $SelectionFrame

# Signal to notify about active unit selection
signal unit_selected(selected_unit_id)

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
	unit_selected.emit(unit_id)


func trigger_flash(duration):
	flash_timer = duration
