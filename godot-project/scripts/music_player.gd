extends Node


var audio_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Loading background music (Glorious Mornings by Waterflame)
	audio_player.stream = load("res://assets/music/background_glorious_morning.ogg")
	audio_player.bus = "Music"
	audio_player.autoplay = true
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player.play()
	
	# Turn up the volume smoothly
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", 0, 1.5).set_trans(Tween.TRANS_SINE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_music_mute(is_muted: bool):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), is_muted)


func set_sfx_mute(is_muted: bool):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), is_muted)
