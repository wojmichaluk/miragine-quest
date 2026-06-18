extends PanelContainer


@onready var pages = [
	$MarginContainer/VBoxContainer/PagesContainer/Page1,
	$MarginContainer/VBoxContainer/PagesContainer/Page2,
	$MarginContainer/VBoxContainer/PagesContainer/Page3,
	$MarginContainer/VBoxContainer/PagesContainer/Page4,
	$MarginContainer/VBoxContainer/PagesContainer/Page5
]

@onready var prev_button = $MarginContainer/VBoxContainer/HBoxContainer/PrevButton
@onready var page_label = $MarginContainer/VBoxContainer/HBoxContainer/PageNumberLabel
@onready var next_button = $MarginContainer/VBoxContainer/HBoxContainer/NextButton

var current_page: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_tutorial_ui()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_tutorial_ui():
	# Display only the current page
	for i in range(pages.size()):
		pages[i].visible = (i == current_page)
	
	page_label.text = "Strona: " + str(current_page + 1) + "/" + str(pages.size())
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page == pages.size() - 1)


func _on_prev_button_pressed():
	if current_page > 0:
		current_page -= 1
		update_tutorial_ui()


func _on_next_button_pressed():
	if current_page < pages.size() - 1:
		current_page += 1
		update_tutorial_ui()


func _on_close_button_pressed():
	queue_free()
