extends PanelContainer


# Labels for stats
@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var cost_label = $MarginContainer/VBoxContainer/Labels/CostLabel
@onready var weight_label = $MarginContainer/VBoxContainer/Labels/WeightLabel
@onready var atk_type_label = $MarginContainer/VBoxContainer/Labels/AtkTypeLabel
@onready var speed_label = $MarginContainer/VBoxContainer/SpeedContainer/Label
@onready var atk_speed_label = $MarginContainer/VBoxContainer/AtkSpeedContainer/Label
@onready var hp_label = $MarginContainer/VBoxContainer/HPContainer/Label
@onready var damage_label = $MarginContainer/VBoxContainer/DamageContainer/Label
@onready var atk_range_label = $MarginContainer/VBoxContainer/AtkRangeContainer/Label
@onready var res_phys_label = $MarginContainer/VBoxContainer/ResPhysContainer/Label
@onready var res_mag_label = $MarginContainer/VBoxContainer/ResMagContainer/Label

# Progress bars for stats
@onready var speed_bar = $MarginContainer/VBoxContainer/SpeedContainer/ProgressBar
@onready var atk_speed_bar = $MarginContainer/VBoxContainer/AtkSpeedContainer/ProgressBar
@onready var hp_bar = $MarginContainer/VBoxContainer/HPContainer/ProgressBar
@onready var damage_bar = $MarginContainer/VBoxContainer/DamageContainer/ProgressBar
@onready var atk_range_bar = $MarginContainer/VBoxContainer/AtkRangeContainer/ProgressBar
@onready var res_phys_bar = $MarginContainer/VBoxContainer/ResPhysContainer/ProgressBar
@onready var res_mag_bar = $MarginContainer/VBoxContainer/ResMagContainer/ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func display_info(unit_data: Dictionary):
	# Name info
	name_label.text = str(unit_data["name"])
	
	# Cost info
	cost_label.text = "🪙 " + str(int(unit_data["cost"]))
	
	# Weight info
	weight_label.text = "⚖️ " + str(int(unit_data["weight"]))
	
	# Attack type info
	atk_type_label.text = "Rodzaj ataku: " + ("⚔️" if str(unit_data["atk_type"]) == "physical" else "🪄")
	
	# Speed info
	speed_label.text = "💨 " + str(int(unit_data["speed"]))
	speed_bar.min_value = GlobalData.min_stats["speed"]
	speed_bar.max_value = GlobalData.max_stats["speed"]
	speed_bar.value = unit_data["speed"]
	
	# Attack speed info
	atk_speed_label.text = "⚡ " + str(unit_data["atk_speed"])
	atk_speed_bar.min_value = 0.0
	atk_speed_bar.max_value = GlobalData.max_stats["atk_speed"] - GlobalData.min_stats["atk_speed"]
	atk_speed_bar.value = GlobalData.max_stats["atk_speed"] - unit_data["atk_speed"]
	
	# Health info
	hp_label.text = "❤️ " + str(int(unit_data["hp"]))
	hp_bar.min_value = GlobalData.min_stats["hp"]
	hp_bar.max_value = GlobalData.max_stats["hp"]
	hp_bar.value = unit_data["hp"]
	
	# Damage info
	damage_label.text = "💥 " + str(int(unit_data["damage"]))
	damage_bar.min_value = GlobalData.min_stats["damage"]
	damage_bar.max_value = GlobalData.max_stats["damage"]
	damage_bar.value = unit_data["damage"]
	
	# Attack range info
	atk_range_label.text = "🎯 " + str(int(unit_data["atk_range"]))
	atk_range_bar.min_value = GlobalData.min_stats["atk_range"]
	atk_range_bar.max_value = GlobalData.max_stats["atk_range"]
	atk_range_bar.value = unit_data["atk_range"]
	
	# Physical resistance info
	res_phys_label.text = "Odporność 🛡️ " + str(int(unit_data["res_phys"]))
	res_phys_bar.min_value = GlobalData.min_stats["res_phys"]
	res_phys_bar.max_value = GlobalData.max_stats["res_phys"]
	res_phys_bar.value = unit_data["res_phys"]
	
	# Magical resistance info
	res_mag_label.text = "Odporność 🔮 " + str(int(unit_data["res_mag"]))
	res_mag_bar.min_value = GlobalData.min_stats["res_mag"]
	res_mag_bar.max_value = GlobalData.max_stats["res_mag"]
	res_mag_bar.value = unit_data["res_mag"]
	
	# Display the window
	show()
