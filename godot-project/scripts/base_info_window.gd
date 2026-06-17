extends PanelContainer


# Labels for stats
@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var atk_type_label = $MarginContainer/VBoxContainer/AtkTypeLabel
@onready var atk_speed_label = $MarginContainer/VBoxContainer/Labels/AtkSpeedLabel
@onready var hp_label = $MarginContainer/VBoxContainer/Labels/HpLabel
@onready var damage_label = $MarginContainer/VBoxContainer/Labels/DamageLabel
@onready var atk_range_label = $MarginContainer/VBoxContainer/Labels/AtkRangeLabel
@onready var res_phys_label = $MarginContainer/VBoxContainer/ResPhysContainer/Label
@onready var res_mag_label = $MarginContainer/VBoxContainer/ResMagContainer/Label

# Progress bars for stats
@onready var res_phys_bar = $MarginContainer/VBoxContainer/ResPhysContainer/ProgressBar
@onready var res_mag_bar = $MarginContainer/VBoxContainer/ResMagContainer/ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func display_base_info(base_data: Dictionary):
	var max_width = 360
	var text_width = name_label.get_theme_font("font").get_string_size(
		base_data["name"], 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		name_label.get_theme_font_size("font_size")
	).x
	
	if text_width > max_width:
		var font_scale = max_width / text_width
		var current_font_size = name_label.get_theme_font_size("font_size")
		name_label.add_theme_font_size_override("font_size", current_font_size * font_scale)
	
	# Name info
	name_label.text = base_data["name"]
	
	# Attack type info
	atk_type_label.text = "Rodzaj ataku: " + (
		"⚔️" if base_data["atk_type"] == "physical" \
		else "🏹" if base_data["atk_type"] == "magical" \
		else "🪄 (specjalny)"
	)
	
	# Attack speed info
	atk_speed_label.text = "⚡ " + str(base_data["atk_speed"])
	
	# Health info
	hp_label.text = "❤️ " + str(int(base_data["hp"]))
	
	# Damage info
	damage_label.text = "💥 " + str(int(base_data["damage"]))
	
	# Attack range info
	atk_range_label.text = "🎯 " + str(int(base_data["atk_range"]))
	
	# Physical resistance info
	res_phys_label.text = "Odporność 🛡️ " + str(int(base_data["res_phys"]))
	res_phys_bar.min_value = GlobalData.min_stats["res_phys"]
	res_phys_bar.max_value = GlobalData.max_stats["res_phys"]
	res_phys_bar.value = base_data["res_phys"]
	
	# Magical resistance info
	res_mag_label.text = "Odporność 🔮 " + str(int(base_data["res_mag"]))
	res_mag_bar.min_value = GlobalData.min_stats["res_mag"]
	res_mag_bar.max_value = GlobalData.max_stats["res_mag"]
	res_mag_bar.value = base_data["res_mag"]
	
	# Display the window
	show()
