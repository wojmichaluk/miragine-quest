extends Button

var unit_id: int
var is_player_side: bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _on_pressed():
	get_tree().current_scene.spawn_unit(unit_id, is_player_side)
