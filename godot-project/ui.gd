extends Control


var unit_button_scene = preload("res://UnitButton.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(5):
		var new_button = unit_button_scene.instantiate()
		$Panel/HBoxContainer.add_child(new_button)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
