extends Node2D

enum State { IDLE, DRAW, ADJUST}
var state: State = State.IDLE

var draw_tool: int = 0
var first_point: Vector2 = Vector2.ZERO
var current_point: Vector2 = Vector2.ZERO
var pen_position: Vector2 = Vector2.ZERO
var defolt_punctir_color: Color = Color.AZURE
var defolt_punctir_tolshina: float = 2.0
var defolt_prizrac_color: Color = Color(1, 1, 1, 0.3)
var defolt_prizrak_tolshina = 5

var first_point_of_object 
var second_point_of_object 
var thirt_point_of_object 
var fourth_point_of_object

var poly_points: PackedVector2Array

var is_adjusting = false
var adjust_index: int = -1

var typed_text: String = ""

var breath: float = 0.0
var breath_tween: Tween = null

@onready var spawner = $"../ObjectSpawner"
@onready var selection = $"../SelectionManager"

@onready var Ravnostorony_button = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/ravnostorony_CheckBox"

func _ready() -> void:
	if Ravnostorony_button:
		Ravnostorony_button.pressed.connect(make_equilateral)

func is_active() -> bool:
	return state != State.IDLE

func begin_draw(pos:Vector2):
	first_point = pos
	current_point = pos
	state = State.DRAW
	visible = true
	typed_text = ""
	if draw_tool == 2:
		poly_points.clear()
		poly_points.append(pos)
	print("✏️ DRAW: начали с точки ", pos)

func _process(delta: float):
	if state == State.DRAW:
		current_point = get_global_mouse_position()
		queue_redraw()
	elif state == State.IDLE:
		visible = false
	elif state == State.ADJUST:
		if is_adjusting:
			typed_text = "" 
			if draw_tool == 2:
				if not _would_tangle(poly_points, adjust_index, get_global_mouse_position()):
					poly_points[adjust_index] = get_global_mouse_position()
			else:
				current_point = get_global_mouse_position()
		queue_redraw()

func _unhandled_input(event: InputEvent):
	var distance_to_pen = get_global_mouse_position().distance_to(pen_position)
	if state == State.IDLE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and state == State.DRAW and draw_tool != 2:
			state = State.ADJUST
			start_breathing()
		
		if event.pressed and state == State.DRAW and draw_tool == 2:
			if is_magnet():
				close_polygon()
			elif get_global_mouse_position().distance_to(poly_points[poly_points.size() - 1]) > 3:
				if not _new_seg_crosses(poly_points, get_global_mouse_position()):
					poly_points.append(get_global_mouse_position())
			
		if event.pressed and state == State.ADJUST:
			if draw_tool == 2:
				adjust_index = -1
				is_adjusting = false
				for idx in range(poly_points.size()):
					if get_global_mouse_position().distance_to(poly_points[idx]) <= 12:
						adjust_index = idx
						is_adjusting = true
						stop_breathing()
						break
			if draw_tool == 0 or draw_tool == 1:
				if distance_to_pen <= 12:
					is_adjusting = true
					stop_breathing()
		elif not event.pressed and state == State.ADJUST:
			is_adjusting = false
			adjust_index = -1
			start_breathing()
	
	if event is InputEventKey and event.pressed and (event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE):
		cancel()
	if event.is_action_pressed("ui_cancel"): 
		cancel()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if state == State.ADJUST:
			if typed_text != "":
				if typed_text.is_valid_float():
					var dir = (current_point - first_point).normalized()
					if dir == Vector2.ZERO:
						dir = Vector2.RIGHT
					current_point = first_point + dir * max(1.0, typed_text.to_float())
				typed_text = ""
				queue_redraw()
			else:
				confirm()  
	if event is InputEventKey and event.pressed and state == State.ADJUST and draw_tool == 0:
		var c = event.unicode
		if (c >= 48 and c <= 57) and typed_text.length() < 7:
			typed_text += char(c)
			_apply_typed_radius()
		elif (c == 46 or c == 44) and not "." in typed_text:
			typed_text += "."
		elif event.keycode == KEY_BACKSPACE:
			typed_text = typed_text.left(typed_text.length() - 1)
			_apply_typed_radius()

func cancel():
	stop_breathing()
	state = State.IDLE
	print("❌ Чертёж отменён")
	typed_text = ""

func confirm():
	stop_breathing()
	if draw_tool == 0:
		var distance = first_point.distance_to(current_point)
		if distance<0.01:
			print("⚠️ Слишком маленький - пропускаю")
			state = State.IDLE
			return
		var obj = spawner.create_circle(first_point, distance)
		selection.add_to_selection(obj)
		print("✅ СОЗДАТЬ: tool=", draw_tool, " p1=", first_point, " p2=", current_point)
	elif draw_tool == 1:
		var W = abs(current_point.x - first_point.x)
		var H = abs(current_point.y - first_point.y)
		if W < 5 or H < 5:
			print("⚠️ Слишком маленький - пропускаю")
			state = State.IDLE
			return
		var obj = spawner.create_rectangle(first_point, current_point)
		selection.add_to_selection(obj)
	elif draw_tool == 2:
		var obj = spawner.create_polygon(poly_points)
		selection.add_to_selection(obj)
		poly_points.clear()
	state = State.IDLE
	typed_text = ""

func _draw():
	var glow = Color(1, 1, 1, 0.35 + breath * 0.3)  
	if draw_tool == 0:
		var radius = first_point.distance_to(current_point)
		var napravlenie = (current_point - first_point).normalized()
		draw_punktir(first_point, current_point)
		var points = PackedVector2Array()
		for i in range(48):
			var angle = i / 48.0 * TAU
			points.append(first_point + Vector2(cos(angle), sin(angle))*radius)
		draw_colored_polygon(points, defolt_prizrac_color)         
		draw_arc(first_point,radius, 0, TAU, 48, glow, defolt_prizrak_tolshina)
		var center_of_radius = (first_point + current_point)/2
		var text_radius = typed_text if typed_text != "" else ("R = %.2f" % radius)
		draw_string(ThemeDB.fallback_font, center_of_radius + Vector2(8, -8), text_radius, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
		pen_position = first_point + (napravlenie*radius)
		draw_circle(pen_position, 4, Color.WHITE)
	elif draw_tool == 1:
		var dioganal = first_point.distance_to(current_point)
		var napravlenie = (current_point - first_point).normalized()
		draw_punktir(first_point, current_point)
		var points = PackedVector2Array()
		first_point_of_object = first_point
		second_point_of_object = Vector2(first_point.x, current_point.y)
		thirt_point_of_object = current_point
		fourth_point_of_object = Vector2(current_point.x, first_point.y)
		points.append(first_point_of_object)
		points.append(second_point_of_object)
		points.append(thirt_point_of_object)
		points.append(fourth_point_of_object)
		draw_colored_polygon(points, glow)
		points.append(points[0]) 
		draw_polyline(points, Color(1, 1, 1, 0.6), 2.0)
		var w = second_point_of_object.distance_to(thirt_point_of_object)
		var h = first_point_of_object.distance_to(second_point_of_object)
		var center_of_w = (second_point_of_object + thirt_point_of_object) / 2
		var center_of_h = (first_point_of_object + second_point_of_object) / 2
		var text_w = "W = %.2f" % w
		var text_h = "H = %.2f" % h
		draw_string(ThemeDB.fallback_font, center_of_h + Vector2(8, -8), text_h, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
		draw_string(ThemeDB.fallback_font, center_of_w + Vector2(8, -8), text_w, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
		pen_position = first_point + (napravlenie*dioganal)
		draw_circle(pen_position, 4, Color.WHITE)
	elif draw_tool == 2:
		var n = poly_points.size()
		if state == State.DRAW:
			var target = poly_points[0] if is_magnet() else current_point
			if n >= 2:
				var preview = PackedVector2Array(poly_points)   
				preview.append(target)
				draw_colored_polygon(preview, defolt_prizrac_color)
			if n >= 2:
				draw_polyline(poly_points, Color(1, 1, 1, 0.6), 2.0)
			draw_punktir(poly_points[n - 1], target)
			for i in range(1, n - 1):
				var v = poly_points[i]
				var deg = abs(rad_to_deg((poly_points[i - 1] - v).angle_to(poly_points[i + 1] - v)))
				draw_string(ThemeDB.fallback_font, v + Vector2(8, -8), "%.1f°" % deg, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
			if n >= 2:
				var v = poly_points[n - 1]
				var deg = abs(rad_to_deg((poly_points[n - 2] - v).angle_to(target - v)))
				draw_string(ThemeDB.fallback_font, v + Vector2(8, -8), "%.1f°" % deg, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, defolt_prizrac_color)
			if is_magnet():
				draw_circle(poly_points[0], 4.5, Color.WHITE)
		elif state == State.ADJUST:
			draw_colored_polygon(poly_points, defolt_prizrac_color)
			var closed = PackedVector2Array(poly_points)
			closed.append(poly_points[0])
			draw_polyline(closed, Color(1, 1, 1, 0.6), 2.0)
			for i in range(n):
				draw_circle(poly_points[i], 2.5, Color.AQUA)

func start_breathing():
	if breath_tween:
		breath_tween.kill()
	breath_tween = create_tween().set_loops()
	breath_tween.tween_property(self, "breath", 1.0, 1.2)
	breath_tween.tween_property(self, "breath", 0.0, 1.2)

func stop_breathing():
	if breath_tween:
		breath_tween.kill()
		breath_tween = null
	breath = 0.0

func is_magnet() -> bool:
	if poly_points.size() < 3:
		return false
	return Input.is_key_pressed(KEY_SHIFT) or current_point.distance_to(poly_points[0]) <= 12

func draw_punktir(a: Vector2, b: Vector2):
	var length = a.distance_to(b)
	var napravlenie = (b - a).normalized()
	var t = 0.0
	while t < length:
		var nachalo = a + napravlenie * t
		var konec = a + napravlenie * min(t + 10.0, length)
		draw_line(nachalo, konec, defolt_punctir_color, defolt_punctir_tolshina)
		t += 10.0 + 6.0

func make_equilateral():
	print("draw_tool: ", draw_tool)
	print("STATE: ", state) 
	print("ФУНКЦИЯ ВЫЗВАНА, вершин: ", poly_points.size())
	var n = poly_points.size()
	if poly_points.size() <3:
		return
	if state == State.IDLE:
		state = State.ADJUST   # ← призрак оживает из последнего нарисованного
		visible = true
		start_breathing()
	# центр — среднее всех вершин
	var center = Vector2.ZERO
	for p in poly_points:
		center += p
	center /= n
	# радиус — среднее расстояние до вершин
	var R = 0.0
	for p in poly_points:
		R += center.distance_to(p)
	R /= n
	# сохраняем поворот первой вершины
	var start_angle = (poly_points[0] - center).angle()
	# пересобираем правильный n-угольник
	poly_points.clear()
	for i in range(n):
		var a = start_angle + i * TAU / n
		poly_points.append(center + Vector2(cos(a), sin(a)) * R)
	print("ПОСЛЕ ИЗМЕНЕНИЯ, вершин: ", poly_points.size())  # ← добавь
	queue_redraw()

func _apply_typed_radius():
	if typed_text.is_valid_float():
		var dir = (current_point - first_point).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		current_point = first_point + dir * max(1.0, typed_text.to_float())
	queue_redraw()

func _seg_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var o1 = sign((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
	var o2 = sign((b.x - a.x) * (d.y - a.y) - (b.y - a.y) * (d.x - a.x))
	var o3 = sign((d.x - c.x) * (a.y - c.y) - (d.y - c.y) * (a.x - c.x))
	var o4 = sign((d.x - c.x) * (b.y - c.y) - (d.y - c.y) * (b.x - c.x))
	return o1 != o2 and o3 != o4

# не завяжется ли замкнутый контур, если вершину i поставить в new_p
func _would_tangle(points: PackedVector2Array, i: int, new_p: Vector2) -> bool:
	var n = points.size()
	if n < 4:
		return false
	var prev_i = (i - 1 + n) % n
	var next_i = (i + 1) % n
	var prev = points[prev_i]
	var next = points[next_i]
	for j in range(n):
		var j2 = (j + 1) % n
		if j != i and j2 != i and j != prev_i and j2 != prev_i:
			if _seg_cross(prev, new_p, points[j], points[j2]):
				return true
		if j != i and j2 != i and j != next_i and j2 != next_i:
			if _seg_cross(new_p, next, points[j], points[j2]):
				return true
	return false

# не пересечёт ли новое ребро (последняя точка → new_p) уже нарисованную цепь
func _new_seg_crosses(points: PackedVector2Array, new_p: Vector2) -> bool:
	var last = points[points.size() - 1]
	for j in range(points.size() - 2):
		if _seg_cross(last, new_p, points[j], points[j + 1]):
			return true
	return false

# не завяжется ли при замыкании контура
func _closing_crosses(points: PackedVector2Array) -> bool:
	var n = points.size()
	for j in range(1, n - 2):
		if _seg_cross(points[n - 1], points[0], points[j], points[j + 1]):
			return true
	return false

func close_polygon():
	if _closing_crosses(poly_points):
		print("⚠️ Нельзя замкнуть: контур завяжется")
		return
	state = State.ADJUST
	start_breathing()
	print("🔒 Контур замкнут")
