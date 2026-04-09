extends Control

var player_textures = []
var enemy_textures = []
var unit_button_scene = preload("res://UnitButton.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load textures for player units and enemy units
	for i in range(1, 13):
		player_textures.append(load("res://art/units/player/unit" + str(i) + ".png"))
		enemy_textures.append(load("res://art/units/enemy/unit" + str(i) + ".png"))
	
	create_buttons()


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
			button.icon = player_textures[id]
			button.unit_texture = player_textures[id]
			left_group.add_child(button)
		else:
			button.icon = enemy_textures[id]
			button.unit_texture = enemy_textures[id]
			right_group.add_child(button)


func update_gold_display(amount: int, is_player: bool):
	if is_player:
		$PlayerGold.text = "Złoto: " + str(amount)
	else:
		$EnemyGold.text = "Złoto: " + str(amount)
