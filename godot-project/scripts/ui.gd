extends Control


var player_icons_textures = []
var enemy_icons_textures = []
var unit_button_scene = preload("res://scenes/UnitButton.tscn")
var active_unit_id = -1

@onready var left_group = $Panel/MarginContainer/HBoxContainer/GridLeft
@onready var right_group = $Panel/MarginContainer/HBoxContainer/GridRight
@onready var music_button = $Panel/MarginContainer/HBoxContainer/Space/MusicMuteButton
@onready var sfx_button = $Panel/MarginContainer/HBoxContainer/Space/SFXMuteButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_button.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	sfx_button.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX"))
	
	# Create buttons, enable player buttons and disable enemy buttons
	create_buttons()
	set_buttons()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func create_buttons():
	for i in range(24):
		var button = unit_button_scene.instantiate()
		var id = (i % 12)
		var is_player = i < 12
		
		# Setting button data and style options
		button.unit_id = id
		button.expand_icon = true
		button.icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
		
		var style = button.get_theme_stylebox("normal")
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		
		var atlas = AtlasTexture.new()
		
		if is_player:
			atlas.atlas = GlobalData.player_units_textures[id]
			atlas.region = Rect2(0, 10 * 64, 64, 64)
			button.icon = atlas
			left_group.add_child(button)
		else:
			atlas.atlas = GlobalData.enemy_units_textures[id]
			atlas.region = Rect2(0, 10 * 64, 64, 64)
			button.icon = atlas
			right_group.add_child(button)


func set_buttons():
	var player_unit_buttons = left_group.get_children()
	var enemy_unit_buttons = right_group.get_children()
	
	for button in player_unit_buttons:
		if button is Button:
			button.disabled = false
			button.modulate.a = 1.0
			
	for button in enemy_unit_buttons:
		if button is Button:
			button.disabled = true
			button.modulate.a = 0.5


func update_gold_display(amount: int, is_player: bool):
	if is_player:
		$Labels/PlayerGold.text = "Złoto: " + str(amount)
	else:
		$Labels/EnemyGold.text = "Złoto: " + str(amount)


func update_timer_display(seconds_left: int, is_shopping: bool):
	$Labels/TimerLabel.text = str(seconds_left)
	
	# Change text color if shopping phase
	if is_shopping:
		$Labels/TimerLabel.modulate = Color.GREEN
	else:
		$Labels/TimerLabel.modulate = Color.WHITE


func update_weight_display(current: int, maximum: int, is_player: bool):
	if is_player:
		$Labels/PlayerCapacity.text = "Armia: " + str(current) + " / " + str(maximum)
	else:
		$Labels/EnemyCapacity.text = "Armia: " + str(current) + " / " + str(maximum)


func update_base_hp(current: float, maximum: float, is_player: bool):
	var hp_bar = $ProgressBars/PlayerHealth if is_player else $ProgressBars/EnemyHealth
	var target_value = 100 * (current / maximum)
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", target_value, 0.3).set_trans(Tween.TRANS_SINE)


func update_unit_selection(unit_id, spawn_delay):
	var spawn_status = -1
	var player_unit_buttons = left_group.get_children()
	
	# Clear previous selection
	if active_unit_id != -1 and active_unit_id != unit_id:
		player_unit_buttons[active_unit_id].is_active = false
	
	active_unit_id = unit_id
	var button = player_unit_buttons[unit_id]
	button.is_active = true
	
	while spawn_status != 0 and unit_id == active_unit_id:
		spawn_status = get_tree().current_scene.spawn_unit(unit_id, true)
		
		# Flash if unit has been spawned
		if spawn_status == 2:
			button.trigger_flash(0.5 * spawn_delay)
		
		await get_tree().create_timer(spawn_delay).timeout


func _on_sfx_mute_button_toggled(toggled_on: bool) -> void:
	MusicPlayer.set_sfx_mute(toggled_on)
	update_button_visuals(sfx_button, toggled_on)


func _on_music_mute_button_toggled(toggled_on: bool) -> void:
	MusicPlayer.set_music_mute(toggled_on)
	update_button_visuals(music_button, toggled_on)


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func update_button_visuals(button: TextureButton, is_muted: bool):
	if is_muted:
		button.self_modulate = Color.RED
	else:
		button.self_modulate = Color.WHITE
