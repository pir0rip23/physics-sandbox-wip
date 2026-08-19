extends Node

var state = "EDIT"
@onready var play_pause_button = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/Play_Pause_Button"
@onready var edit_button = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/edit_button"
@onready var speed_slider = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/VSplitContainer/BottomPanel/MarginContainer/HBoxContainer/HSlider"
signal state_changed(new_state: String)

func _ready():
	if play_pause_button:
		play_pause_button.pressed.connect(on_play_pause_pressed)
	if edit_button:
		edit_button.pressed.connect(on_edit_pressed)
	if speed_slider:
		speed_slider.value_changed.connect(on_speed_changed)
	update_ui()

func can_edit() -> bool:
	return state != "PLAY"

func start_simulation():
	for child in get_parent().get_children():
		if child is RigidBody2D and not child.is_static:
			child.freeze = false
			child.mass = child.custom_mass
			child.set_color(child.custom_color)
	state = "PLAY"
	state_changed.emit(state)
	update_ui()

func stop_simulation():
	for child in get_parent().get_children():
		if child is RigidBody2D:
			child.freeze = true
			child.linear_velocity = Vector2.ZERO
			child.angular_velocity = 0
	state = "EDIT"
	state_changed.emit(state)
	update_ui()

func pause_simulation():
	for child in get_parent().get_children():
		if child is RigidBody2D:
			child.freeze = true
	state = "PAUSE"
	state_changed.emit(state)
	update_ui()

func resume_simulation():
	for child in get_parent().get_children():
		if child is RigidBody2D and not child.is_static:
			child.freeze = false
	state_changed.emit(state)

func on_play_pause_pressed():
	if state == "EDIT":
		start_simulation()
	elif state == "PLAY":
		pause_simulation()
	else: 
		resume_simulation()
		state = "PLAY"
		state_changed.emit(state)
		update_ui()

func on_edit_pressed():
	if state == "PAUSE":
		stop_simulation()

func on_speed_changed(value):
	Engine.time_scale = value 

func update_ui():
	if state == "PLAY":
		play_pause_button.text = "⏸️"
		play_pause_button.add_theme_color_override("font_color", Color.YELLOW)
		edit_button.disabled = true
		edit_button.text = "❌"
		edit_button.add_theme_color_override("font_color", Color.WEB_GRAY)
	elif state == "PAUSE":
		play_pause_button.text = "▶️"
		play_pause_button.add_theme_color_override("font_color", Color.LIME_GREEN)
		edit_button.disabled = false
		edit_button.text = "🔧"
		edit_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		play_pause_button.text = "▶️"
		play_pause_button.add_theme_color_override("font_color", Color.BLUE)
		edit_button.disabled = true
		edit_button.text = "❌"
		edit_button.add_theme_color_override("font_color", Color.WEB_GRAY)
