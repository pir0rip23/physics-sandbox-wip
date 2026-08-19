extends Node

var links_array = []
var selected_link = null
var bodies_collide = true

@onready var selection = $"../SelectionManager"
@onready var length_spin = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Length_SpinBox"
@onready var stiffness_spin = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Stiffness_SpinBox"
@onready var auto_length_check = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/AutoLength_CheckBox"
@onready var nit_button = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Nit_Button"
@onready var pruzina_button = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/Pruzina_Button2"
@onready var colision_objects = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/HBoxContainer/collision_object"
@onready var label_collision_buton = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Связь/HBoxContainer/Длинна2"

func _ready():
	if length_spin:
		length_spin.value_changed.connect(func(_val): update_selected_link())
	if stiffness_spin:
		stiffness_spin.value_changed.connect(func(_val): update_selected_link())
	if nit_button:
		nit_button.pressed.connect(_on_nit_button_pressed)
	if pruzina_button:
		pruzina_button.pressed.connect(_on_pruzina_button_pressed)
	if colision_objects:
		colision_objects.toggled.connect(on_collision_object_pressed)

func _physics_process(_delta):
	for link in links_array:
		if is_instance_valid(link["a"]) and is_instance_valid(link["b"]) and is_instance_valid(link["line"]):
			var pos_a = link["a"].global_position
			var pos_b = link["b"].global_position
			if link.get("is_spring", false):
				update_spring_line(link["line"], pos_a, pos_b)
			else:
				link["line"].set_point_position(0, pos_a)
				link["line"].set_point_position(1, pos_b)
		else:
			if is_instance_valid(link["joint"]): link["joint"].queue_free()
			if is_instance_valid(link["line"]): link["line"].queue_free()
			if is_instance_valid(link.get("area")): link["area"].queue_free()

func _on_pruzina_button_pressed():
	try_create_connection(1)

func _on_nit_button_pressed():
	try_create_connection(2)

func on_collision_object_pressed(value):
	if selected_link != null:
		selected_link["collide"] = value
		selected_link["joint"].disable_collision = not value
	else:
		bodies_collide = value
	update_collision_label(value)

func update_collision_label(value):
	if value:
		label_collision_buton.text = "КОЛЛИЗИЯ ТЕЛ ВКЛ"
	else:
		label_collision_buton.text = "КОЛЛИЗИЯ ТЕЛ ВЫКЛ"

func try_create_connection(link_type: int):
	if selection.selected_objects.size() < 2:
		print("⚠️ Выделите как минимум 2 объекта (зажав Shift)!")
		return
	for i in range(selection.selected_objects.size() - 1):
		create_joint(selection.selected_objects[i], selection.selected_objects[i + 1], link_type)

func create_joint(object_a, object_b, link_type):
	var joint = DampedSpringJoint2D.new()
	var line = Line2D.new()
	
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	
	line.width = 3.0
	line.z_index = 10
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	
	shape.a = object_a.global_position
	shape.b = object_b.global_position
	collision.shape = shape
	area.add_child(collision)
	
	get_parent().add_child(line)   # ВАЖНО: в Main!
	get_parent().add_child(area)   # ВАЖНО: в Main!
	
	var dist = object_a.global_position.distance_to(object_b.global_position)
	var final_length = dist
	
	if not auto_length_check.button_pressed and length_spin:
		final_length = length_spin.value
	
	joint.global_position = object_a.global_position
	joint.length = final_length
	joint.rest_length = final_length
	
	if link_type == 1:
		joint.stiffness = stiffness_spin.value if stiffness_spin else 10.0
		joint.damping = 0.01
		joint.disable_collision = not bodies_collide
		line.default_color = Color.CYAN
		print("🔗 Создана Пружина. Длина: ", final_length, ", жесткость: ", joint.stiffness)
	elif link_type == 2:
		joint.stiffness = 64.0
		joint.damping = 2.0
		joint.disable_collision = not bodies_collide
		line.default_color = Color.WHITE
		print("🔗 Создана Нить. Длина: ", final_length)
	
	get_parent().add_child(joint)  # ВАЖНО: в Main!
	
	joint.node_a = object_a.get_path()
	joint.node_b = object_b.get_path()
	
	links_array.append({
		"joint": joint,
		"line": line,
		"area": area,
		"a": object_a,
		"b": object_b,
		"is_spring": (link_type == 1),
		"collide": bodies_collide
	})

func update_selected_link():
	if selected_link and is_instance_valid(selected_link["joint"]):
		var j = selected_link["joint"]
		if not auto_length_check.button_pressed:
			j.length = length_spin.value
			j.rest_length = length_spin.value
		if j.stiffness < 60:
			j.stiffness = stiffness_spin.value

func select_link(link):
	deselect_link()
	selected_link = link
	link["line"].default_color = Color.RED
	colision_objects.set_block_signals(true)
	colision_objects.button_pressed = link["collide"]
	colision_objects.set_block_signals(false)
	update_collision_label(link["collide"])
	print("Выбрана связь")

func deselect_link():
	if selected_link and is_instance_valid(selected_link["line"]):
		selected_link["line"].default_color = Color.WHITE
	colision_objects.set_block_signals(true)
	colision_objects.button_pressed = bodies_collide
	colision_objects.set_block_signals(false)
	update_collision_label(bodies_collide)
	selected_link = null

func update_spring_line(line: Line2D, a: Vector2, b: Vector2):
	var dir = b - a
	var length = dir.length()
	if length < 1.0: return
	
	var unit_dir = dir.normalized()
	var perp = Vector2(-unit_dir.y, unit_dir.x)
	
	var coil_width = 10.0
	var segments = 12
	
	if line.get_point_count() != segments + 1:
		line.clear_points()
		for i in range(segments + 1):
			line.add_point(Vector2.ZERO)
	
	line.set_point_position(0, a)
	line.set_point_position(segments, b)
	
	for i in range(1, segments):
		var t = float(i) / segments
		var base_pos = a + dir * t
		var sign_val = 1 if (i % 2 == 1) else -1
		var current_width = coil_width
		if i == 1 or i == segments - 1:
			current_width = coil_width * 0.5
		line.set_point_position(i, base_pos + perp * current_width * sign_val)
