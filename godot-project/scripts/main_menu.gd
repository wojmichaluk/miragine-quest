extends Control


var tutorial_scene = preload("res://scenes/Tutorial.tscn")
var credits_scene = preload("res://scenes/Credits.tscn")

@onready var music_button = $MusicMuteButton
@onready var sfx_button = $SFXMuteButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_button.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	sfx_button.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_game_pressed() -> void:
	# Switch to the main game scene
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_tutorial_pressed() -> void:
	var tutorial = tutorial_scene.instantiate()
	add_child(tutorial)


func _on_credits_pressed() -> void:
	var credits = credits_scene.instantiate()
	add_child(credits)


func _on_sfx_mute_button_toggled(toggled_on: bool) -> void:
	MusicPlayer.set_sfx_mute(toggled_on)
	update_button_visuals(sfx_button, toggled_on)


func _on_music_mute_button_toggled(toggled_on: bool) -> void:
	MusicPlayer.set_music_mute(toggled_on)
	update_button_visuals(music_button, toggled_on)


func update_button_visuals(button: TextureButton, is_muted: bool):
	if is_muted:
		button.self_modulate = Color.RED
	else:
		button.self_modulate = Color.WHITE
