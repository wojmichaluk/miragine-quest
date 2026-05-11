extends Button


var unit_id: int
var is_player_side: bool

# Signal to notify about active unit selection
signal unit_selected(selected_unit_id)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit_selected.connect(get_tree().current_scene.select_active_unit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass # Replace with function body.


func _on_pressed():
	unit_selected.emit(unit_id)
