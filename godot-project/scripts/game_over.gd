extends CanvasLayer

@onready var title_label = $CenterContainer/VBoxContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func setup(is_win: bool):
	if is_win:
		title_label.text = "ZWYCIĘSTWO"
		title_label.modulate = Color.GREEN
	else:
		title_label.text = "PRZEGRANA"
		title_label.modulate = Color.RED


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
