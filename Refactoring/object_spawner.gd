extends Node

# Прелоады сцен
var new_ball = preload("res://tscn obj  + his script/круг.tscn")
var new_rectangle = preload("res://tscn obj  + his script/прямоугольник.tscn")
var new_triangle = preload("res://tscn obj  + his script/треугольник.tscn")

# Какая фигура выбрана для спавна
var number_selected_object = 0

@onready var drawer = $"../Shape_drawer"
@onready var sim = $"../SimulationController"
@onready var circle_button = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/CircleButton
@onready var rectangle_button = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/RectangleButton
@onready var triangle_button = $/root/Main/CanvasLayer/VBoxContainer/HBoxContainer/ToolsContainer/MechanicsPanel/HBoxContainer/TriangleButton
@onready var gravity_button = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/World/GRAVITY
@onready var equilateral_button = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/ravnostorony_CheckBox"


func _ready():
	if circle_button:
		circle_button.pressed.connect(_on_circle_pressed)
	if rectangle_button:
		rectangle_button.pressed.connect(_on_rectangle_pressed)
	if triangle_button:
		triangle_button.pressed.connect(_on_triangle_pressed)
	if equilateral_button:
		equilateral_button.pressed.connect(_on_equilateral_pressed)
	print("equilateral_button exists: ", equilateral_button != null)


func _on_circle_pressed():
	number_selected_object = 0
	print("Выбран: Круг")

func _on_rectangle_pressed():
	number_selected_object = 1
	print("Выбран: Прямоугольник")

func _on_triangle_pressed():
	number_selected_object = 2
	print("Выбран: Треугольник")

func spawn_selected(position):
	create_object(number_selected_object, position)

func create_object(type, position):
	if not sim.can_edit():
		return
	var scene
	match type:
		0: scene = new_ball
		1: scene = new_rectangle
		2: scene = new_triangle
	
	if scene:
		var new_object = scene.instantiate()
		new_object.position = position
		get_parent().add_child(new_object)  # ВАЖНО: в Main, не в спавнер!
		new_object.mass = new_object.custom_mass
		new_object.set_color(new_object.custom_color)
		new_object.update_size()
		new_object.freeze = true
		new_object.gravity_scale = 1 if gravity_button.button_pressed else 0
		print("Объект создан в позиции: ", position)

func create_circle(center, radius):
	if not sim.can_edit():
		return
	var new_object = new_ball.instantiate()
	new_object.position = center
	get_parent().add_child(new_object)  
	new_object.mass = new_object.custom_mass
	new_object.set_color(new_object.custom_color)
	new_object.custom_scale = radius/25.6
	new_object.update_size()
	new_object.freeze = true
	new_object.gravity_scale = 1 if gravity_button.button_pressed else 0
	print("Объект создан в позиции: ", center)
	return new_object

func create_rectangle(a, c):
	if not sim.can_edit():
		return
	var W = abs(c.x - a.x)
	var H = abs(c.y - a.y)
	var position = (a + c) / 2
	var new_object = new_rectangle.instantiate()   # ← прямоугольник!
	new_object.position = position
	get_parent().add_child(new_object)
	new_object.mass = new_object.custom_mass
	new_object.set_color(new_object.custom_color)
	new_object.set_size_px(W, H)                   # ← это делает всю работу
	new_object.freeze = true
	new_object.gravity_scale = 1 if gravity_button.button_pressed else 0
	print("Объект создан в позиции: ", position)
	return new_object

func create_polygon(world_points):
	if not sim.can_edit():
		return
	var new_object = new_triangle.instantiate()
	var center = Vector2.ZERO
	for p in world_points:
		center += p
	center /= world_points.size()
	new_object.position = center
	get_parent().add_child(new_object)
	var local = PackedVector2Array()
	for p in world_points:
		local.append(p - center)
	for node in new_object.get_children():
		if node is Polygon2D:
			node.polygon = local
		if node is CollisionPolygon2D:
			node.polygon = local
	var col = new_object.get_node_or_null("CollisionPolygon2D")
	if col != null:
		col.polygon = local
	new_object.mass = new_object.custom_mass
	new_object.set_color(new_object.custom_color)
	new_object.freeze = true
	new_object.gravity_scale = 1 if gravity_button.button_pressed else 0
	new_object.update_size()   # в конце! чтобы обводка пересчиталась от НОВОЙ формы
	print("Объект-полигон создан: ", world_points.size(), " вершин")
	return new_object	

func _on_equilateral_pressed():
	print("КНОПКА НАЖАТА!")
	drawer.make_equilateral()
