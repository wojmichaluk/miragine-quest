extends Control


@export var health_gradient: Gradient
var player_icons_textures = []
var enemy_icons_textures = []
var unit_button_scene = preload("res://scenes/UnitButton.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load icon textures for player units and enemy units
	for i in range(1, 13):
		player_icons_textures.append(load("res://assets/units/player/unit" + str(i) + ".png"))
		enemy_icons_textures.append(load("res://assets/units/enemy/unit" + str(i) + ".png"))
	
	create_buttons()
	setup_health_bar($ProgressBars/PlayerHealth)
	setup_health_bar($ProgressBars/EnemyHealth)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func create_buttons():
	var left_group = $Panel/MarginContainer/HBoxContainer/GridLeft
	var right_group = $Panel/MarginContainer/HBoxContainer/GridRight
	
	for i in range(24):
		var button = unit_button_scene.instantiate()
		var id = (i % 12)
		var is_player = i < 12
		
		# Setting button data
		button.unit_id = id
		button.is_player_side = is_player
		
		# Setting button style options
		button.expand_icon = true
		button.icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
		var style = button.get_theme_stylebox("normal")
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		
		if is_player:
			button.icon = player_icons_textures[id]
			left_group.add_child(button)
		else:
			button.icon = enemy_icons_textures[id]
			right_group.add_child(button)


func setup_health_bar(bar: TextureProgressBar):
	var tex = bar.texture_progress
	tex.width = 720
	tex.height = 40
	bar.tint_progress = health_gradient.sample(1.0)


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


func set_buttons_enabled(enabled: bool):
	var player_unit_buttons = $Panel/MarginContainer/HBoxContainer/GridLeft.get_children()
	var enemy_unit_buttons = $Panel/MarginContainer/HBoxContainer/GridRight.get_children()
	
	# Joining unit buttons together
	var unit_buttons = player_unit_buttons + enemy_unit_buttons
	
	for button in unit_buttons:
		if button is Button:
			button.disabled = !enabled
			button.modulate.a = 1.0 if enabled else 0.5


func update_base_hp(current: float, maximum: float, is_player: bool):
	var hp_bar = $ProgressBars/PlayerHealth if is_player else $ProgressBars/EnemyHealth
	hp_bar.max_value = maximum
	hp_bar.value = current
	
	# Display health bar as a gradient
	hp_bar.tint_progress = health_gradient.sample(current / maximum)
