extends Node

@onready var menu_button: MenuButton = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/MenuButton
@onready var mechanics_panel = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel
@onready var molecular_panel = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MolecularPanel
@onready var electricity_panel = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/ElectricityPanel
@onready var gravity_button = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/World/GRAVITY

func _ready():
	if menu_button:
		menu_button.custom_minimum_size = Vector2(60, 60)
		menu_button.text = "☰"
		menu_button.get_popup().id_pressed.connect(_on_menu_selected)
	if gravity_button:
		gravity_button.toggled.connect(on_gravity_pressed)
	_show_panel(0)

func _on_menu_selected(id):
	_show_panel(id)

func _show_panel(index):
	mechanics_panel.visible = (index == 0)
	molecular_panel.visible = (index == 1)
	electricity_panel.visible = (index == 2)

func on_gravity_pressed(value):
	if value == true:
		gravity_button.text = "ГРАВИТАЦИЯ ВКЛ"
	else:
		gravity_button.text = "ГРАВИТАЦИЯ ВЫКЛ"
	for child in get_parent().get_children():
		if child is RigidBody2D:
			child.gravity_scale = 1 if value else 0
