extends Node2D

# Выделение объектов
var selected_objects = []
var selected_object = null

var info_color: Color = Color(0.9, 0.95, 1.0)   

var object_editing = false
var handle_angle: float = 0.0
var typed_text: String = ""

var typed_armed: bool = true   
var nach: float = 0.0          
var kon: float = 0.0           
var size_tween: Tween = null

var _snap: Array = []

var poly_channel: int = 0      # 0 = угол, 1 = левое ребро, 2 = правое ребро
var poly_tween: Tween = null

var locked_angle: float = -1.0   # -1 = нет замка

var grabbed_axis: String = ""  
var active_axis: String = ""    
var grabbed_index: int = -1   # какую вершину полигона держим
var grabbed_sign: int = 1
var grab_offset: Vector2 = Vector2.ZERO

@onready var camera = $"../Camera2D"
@onready var drawer = $"../Shape_drawer"
@onready var sim = $"../SimulationController"
@onready var right_tabs = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer
@onready var Mass_SpinBox = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/SpinBox
@onready var Scale_SpinBox = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Scale_SpinBox
@onready var Color_picedbuton_object = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/ColorPickerButton
@onready var Static_CheckBox = $/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Static_CheckBox
@onready var Height_SpinBox = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Height_SpinBox"
@onready var Angle_SpinBox = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Angle_SpinBox"
@onready var LeftEdge_SpinBox = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/LeftEdge_SpinBox"
@onready var RightEdge_SpinBox = $"/root/Main/CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/RightEdge_SpinBox"
@onready var Height_Label =$"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Label5"
@onready var Size_Label = $"../CanvasLayer/VBoxContainer/VSplitContainer/HSplitContainer/RightPanel/TabContainer/Object/Label2"

func _ready():
	z_index = 2
	if Mass_SpinBox:
		Mass_SpinBox.value_changed.connect(on_mass_changed)
	if Scale_SpinBox:
		Scale_SpinBox.value_changed.connect(on_scale_changed)
	if Color_picedbuton_object:
		Color_picedbuton_object.color_changed.connect(on_color_object_chanded)
	if Static_CheckBox:
		Static_CheckBox.toggled.connect(on_static_toggled)
	if Height_SpinBox:
		Height_SpinBox.value_changed.connect(on_height_changed)
	for sb in [Angle_SpinBox, LeftEdge_SpinBox, RightEdge_SpinBox]:
		if sb:
			sb.visible = false
	if Angle_SpinBox:
		Angle_SpinBox.min_value = 1.0
		Angle_SpinBox.max_value = 179.0
		Angle_SpinBox.step = 0.1
		Angle_SpinBox.value_changed.connect(on_poly_angle_changed)
	if LeftEdge_SpinBox:
		LeftEdge_SpinBox.min_value = 5.0
		LeftEdge_SpinBox.max_value = 9999.0
		LeftEdge_SpinBox.value_changed.connect(on_poly_left_changed)
	if RightEdge_SpinBox:
		RightEdge_SpinBox.min_value = 5.0
		RightEdge_SpinBox.max_value = 9999.0
		RightEdge_SpinBox.value_changed.connect(on_poly_right_changed)

func _draw():
	if drawer.is_active() or sim.state != "EDIT":
		return
	var zoom_level = camera.zoom.x if camera else 1.0
	var obj = _selected_circle()
	if obj:
		_draw_circle_overlay(obj, zoom_level)
	var rect = _selected_rect()
	if rect:
		_draw_rect_overlay(rect, zoom_level)
	var poly = _selected_poly()
	if poly:
		_draw_poly_overlay(poly, zoom_level)

func _draw_circle_overlay(obj, zoom_level: float):
	var pos = handle_position(obj)
	var typed_r = typed_text.to_float() if typed_text.is_valid_float() else 0.0
	
	if object_editing or typed_r > 0:
		var show_r = typed_r if typed_r > 0 else obj.get_size_px()
		var show_pos = obj.global_position + Vector2(show_r, 0).rotated(handle_angle)
		draw_dashed_line(obj.global_position, show_pos, Color(0.05, 0.05, 0.05, 0.7), 2.0 / zoom_level, 6.0 / zoom_level)
		if typed_r > 0:
			draw_dashed_circle(obj.global_position, typed_r, Color(0.05, 0.05, 0.05, 0.9), 4.0 / zoom_level)
		var label = typed_text if typed_text != "" else "%.2f" % obj.get_size_px()
		var outward = (show_pos - obj.global_position).normalized()
		var label_pos = show_pos + outward * (18.0 / zoom_level)
		draw_label(label_pos, label, zoom_level)
	
	draw_cad_handle(pos, 4.5)

func _draw_rect_overlay(rect, zoom_level: float):
	for h in _rect_handles(rect):
		var active = (object_editing and grabbed_axis == h["axis"]) or (not object_editing and active_axis == h["axis"])
		draw_cad_handle(h["pos"], 4.5, active)
	
	var axis = grabbed_axis if object_editing else active_axis
	if axis != "" and (object_editing or typed_text != "" or active_axis != ""):
		var s = rect.get_size_px()
		# пунктир от середины стороны до противоположной середины
		var a: Vector2
		var b: Vector2
		if axis == "W":
			a = rect.to_global(Vector2(-s.x / 2, 0))
			b = rect.to_global(Vector2(s.x / 2, 0))
		else:
			a = rect.to_global(Vector2(0, -s.y / 2))
			b = rect.to_global(Vector2(0, s.y / 2))
		draw_dashed_line(a, b, info_color, 1.5 / zoom_level, 6.0 / zoom_level)
		
		var value = s.x if axis == "W" else s.y
		var label = axis + " " + (typed_text if typed_text != "" else "%.2f" % value)
		var outward = (Vector2(1, 0) if axis == "W" else Vector2(0, 1)).rotated(rect.global_rotation)
		draw_label(b + outward * (18.0 / zoom_level), label, zoom_level)

func _draw_poly_overlay(poly, zoom_level: float):
	for i in range(poly.get_points_count()):
		draw_cad_handle(poly.get_point_world(i), 4.5, object_editing and grabbed_index == i)
	
	# табло: угол в вершине + длины двух рёбер, которые сейчас меняются
	if grabbed_index >= 0 and grabbed_index < poly.get_points_count():
		var n = poly.get_points_count()
		var i = grabbed_index
		var prev_i = (i - 1 + n) % n
		var next_i = (i + 1) % n
		var show = [i, prev_i, next_i]
		
		for k in show:
			var vk = poly.get_point_world(k)
			var pk = poly.get_point_world((k - 1 + n) % n)
			var nk = poly.get_point_world((k + 1) % n)
			var degk = abs(rad_to_deg((pk - vk).angle_to(nk - vk)))
			var outk = (vk - poly.global_position).normalized()
			var base = 11.0
			var text = "%.1f°" % degk
			if k == i:
				base = 15.0 if poly_channel == 0 else 12.0
				if poly_channel == 0 and typed_text != "":
					text = typed_text
			var col = Color(1.0, 0.75, 0.2) if locked_angle >= 0.0 else info_color
			draw_label(vk + outk * (18.0 / zoom_level), text, zoom_level, base, col)
		
		var v = poly.get_point_world(i)
		_draw_edge_label(poly.global_position, v, poly.get_point_world(prev_i), zoom_level, 13.0 if poly_channel == 1 else 11.0, typed_text if poly_channel == 1 and typed_text != "" else "")
		_draw_edge_label(poly.global_position, v, poly.get_point_world(next_i), zoom_level, 13.0 if poly_channel == 2 else 11.0, typed_text if poly_channel == 2 and typed_text != "" else "")

func draw_label(pos: Vector2, text: String, zoom_level: float, base_size: float = 13.0, color: Color = info_color):
	const RASTER = 64.0   # всегда растеризуем крупно — даунскейл хрустит
	var s = (base_size / zoom_level) / RASTER
	var font = ThemeDB.fallback_font
	draw_set_transform(pos, 0.0, Vector2(s, s))
	draw_string_outline(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, RASTER, RASTER / 3 + 1, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, RASTER, color)   # info_color
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  

func _process(delta):
	if object_editing:
		if sim.state != "EDIT":
			object_editing = false
			grabbed_axis = ""
			queue_redraw()
			return
		locked_angle = -1.0
		var mouse = get_global_mouse_position()
		var target = mouse + grab_offset   # ← мышь + куда схватили
		var circ = _selected_circle()
		if circ:
			handle_angle = (target - circ.global_position).angle()
			circ.set_size_px(target.distance_to(circ.global_position))
			sync_inspector_ui(circ)
			queue_redraw()
			return
		var rect = _selected_rect()
		if rect:
			var local = rect.to_local(target) 
			var s = rect.get_size_px()
			if grabbed_axis == "W":
				var fixed = -grabbed_sign * s.x / 2.0
				var new_w = max(5.0, grabbed_sign * (local.x - fixed))
				rect.set_size_px(new_w, s.y)
				rect.global_position += Vector2(grabbed_sign * (new_w - s.x) / 2.0, 0).rotated(rect.global_rotation)
			else:
				var fixed = -grabbed_sign * s.y / 2.0
				var new_h = max(5.0, grabbed_sign * (local.y - fixed))
				rect.set_size_px(s.x, new_h)
				rect.global_position += Vector2(0, grabbed_sign * (new_h - s.y) / 2.0).rotated(rect.global_rotation)
			sync_inspector_ui(rect)
			queue_redraw()
			return
		var poly = _selected_poly()
		if poly and grabbed_index >= 0:
			poly.set_point_world(grabbed_index, target)
			_sync_poly_ui(poly)
			queue_redraw()
			return

	var obj = selected_object if is_instance_valid(selected_object) else null
	var snap = [
		obj.get_instance_id() if obj else 0,
		obj.get_size_px() if obj and obj.has_method("get_size_px") else -1,
		obj.global_position if obj else Vector2.ZERO,
		obj.global_rotation if obj else 0.0,
		camera.zoom.x if camera else 1.0,
		sim.state,
		drawer.is_active(),
		active_axis,
	]
	if snap != _snap:
		_snap = snap
		queue_redraw()

func _unhandled_input(event: InputEvent):
	if drawer.is_active() or sim.state != "EDIT":
		return
	if not _selected_circle() and not _selected_rect() and not _selected_poly():
		return
	if event is InputEventKey and event.pressed:
		var c = event.unicode
		if (c >= 48 and c <= 57) and typed_text.length() < 7:
			if typed_armed:              
				typed_text = ""
				typed_armed = false
			if size_tween:             
				size_tween.kill()
			typed_text += char(c)
			_apply_typed()
		elif (c == 46 or c == 44) and not "." in typed_text:     # точка или запятая
			typed_text += "."
		elif event.keycode == KEY_BACKSPACE:                     # стереть символ
			typed_text = typed_text.left(typed_text.length() - 1)
			_apply_typed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			var circ = _selected_circle()
			var rect = _selected_rect()
			var poly = _selected_poly()
			if typed_text.is_valid_float():
				var v = max(1.0, typed_text.to_float())
				if circ:
					kon = v
					animate_size(circ)
				elif rect:
					var axis = grabbed_axis if object_editing else active_axis
					var s = rect.get_size_px()
					if axis == "W":
						rect.set_size_px(v, s.y)
					elif axis == "H":
						rect.set_size_px(s.x, v)
					sync_inspector_ui(rect)
				elif _poly_active():
					_apply_poly_channel(poly_channel, typed_text.to_float())
			typed_text = ""
			typed_armed = true
			queue_redraw()
		elif event.keycode == KEY_W and not object_editing and _selected_rect():
			active_axis = "W"
			typed_armed = true
			queue_redraw()
		elif event.keycode == KEY_H and not object_editing and _selected_rect():
			active_axis = "H"
			typed_armed = true
			queue_redraw()
		elif event.keycode == KEY_ESCAPE:
			typed_text = ""
			typed_armed = true
			locked_angle = -1.0
			queue_redraw()

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and _poly_active():
		if event.keycode == KEY_DOWN or event.keycode == KEY_UP:
			poly_channel = (poly_channel + (1 if event.keycode == KEY_DOWN else 2)) % 3
			typed_armed = true
			queue_redraw()
			get_viewport().set_input_as_handled()   # интерфейсу не достаётся

func _apply_typed():
	queue_redraw()

func add_to_selection(object):
	if not object in selected_objects:
		selected_objects.append(object)
		object.select_object()
		selected_object = object
		handle_angle = object.global_rotation
		sync_inspector_ui(object)
		right_tabs.current_tab = 1
		typed_text = ""
		typed_armed = true
		active_axis = "W" if _selected_rect() else ""
		grabbed_axis = ""
		grabbed_index = -1
		locked_angle = -1.0
		_poly_ui_visible(false)

func deselect_single_object(object):
	if object in selected_objects:
		object.deselect_object()
		selected_objects.erase(object)
		typed_text = ""
		locked_angle = -1.0
		if selected_object == object:
			selected_object = selected_objects.back() if selected_objects.size() > 0 else null

func deselect_all_objects():
	for obj in selected_objects:
		if is_instance_valid(obj):
			obj.deselect_object()
	selected_objects.clear()
	selected_object = null
	reset_inspector_ui()
	right_tabs.current_tab = 0
	typed_text = ""
	locked_angle = -1.0
	_poly_ui_visible(false)

func sync_inspector_ui(object):
	Mass_SpinBox.set_block_signals(true)
	Scale_SpinBox.set_block_signals(true)
	Color_picedbuton_object.set_block_signals(true)
	Static_CheckBox.set_block_signals(true)
	
	Mass_SpinBox.value = object.custom_mass
	if object.has_method("get_size_px"):
		var size = object.get_size_px()
		if size is Vector2:                      # прямоугольник
			Scale_SpinBox.value = size.x
			Height_SpinBox.value = size.y
			Height_SpinBox.visible = true
			Height_Label.visible = true
			Size_Label.text = "ШИРИНА (W)"
		else:                                     # круг
			Scale_SpinBox.value = size
			Height_SpinBox.visible = false
			Height_Label.visible = false
			Size_Label.text = "РАДИУС"
	else:                                         # треугольник и прочие
		Scale_SpinBox.value = object.custom_scale
		Height_SpinBox.visible = false
		Height_Label.visible = false
		Size_Label.text = "РАЗМЕР"
	Color_picedbuton_object.color = object.custom_color
	Static_CheckBox.button_pressed = object.is_static
	
	Mass_SpinBox.set_block_signals(false)
	Scale_SpinBox.set_block_signals(false)
	Color_picedbuton_object.set_block_signals(false)
	Static_CheckBox.set_block_signals(false)

func reset_inspector_ui():
	Mass_SpinBox.set_block_signals(true)
	Scale_SpinBox.set_block_signals(true)
	Color_picedbuton_object.set_block_signals(true)
	Static_CheckBox.set_block_signals(true)
	
	Mass_SpinBox.value = 0
	Scale_SpinBox.value = 0
	Color_picedbuton_object.color = Color.WHITE
	Static_CheckBox.button_pressed = false
	
	Mass_SpinBox.set_block_signals(false)
	Scale_SpinBox.set_block_signals(false)
	Color_picedbuton_object.set_block_signals(false)
	Static_CheckBox.set_block_signals(false)

func on_mass_changed(value):
	if selected_object is RigidBody2D:
		selected_object.custom_mass = value
		if sim.state == "PAUSE" or sim.state == "EDIT":
			selected_object.mass = value

func on_scale_changed(value):
	if size_tween: size_tween.kill()
	if not selected_object:
		return
	if selected_object.has_method("set_size_px"):
		if selected_object.has_method("get_size_px") and selected_object.get_size_px() is Vector2:
			var s = selected_object.get_size_px()
			selected_object.set_size_px(value, s.y)
		else:
			selected_object.set_size_px(value)
	else:
		selected_object.custom_scale = value
		if selected_object.has_method("update_size"):
			selected_object.update_size()

func on_height_changed(value):
	if size_tween: size_tween.kill()
	if not selected_object:
		return
	if selected_object.has_method("get_size_px") and selected_object.get_size_px() is Vector2:
		var s = selected_object.get_size_px()
		selected_object.set_size_px(s.x, value)

func on_color_object_chanded(new_color):
	if selected_object:
		selected_object.custom_color = new_color
		if sim.state == "PAUSE" or sim.state == "EDIT":
			selected_object.set_color(new_color)

func on_static_toggled(toggled_on: bool):
	if selected_object:
		selected_object.set_static(toggled_on)
		if sim.state == "PLAY":
			selected_object.freeze = toggled_on
		else:
			selected_object.freeze = true

func handle_position(obj):
	return obj.global_position + Vector2(obj.get_size_px(), 0).rotated(handle_angle)

func _selected_circle():
	var obj = selected_object
	if obj and is_instance_valid(obj) and obj.has_method("get_size_px") and not (obj.get_size_px() is Vector2):
		return obj
	return null

func try_grab_handle(pos) -> bool:
	if sim.state != "EDIT":
		return false
	var cam = get_viewport().get_camera_2d()
	var zoom_level = cam.zoom.x if cam else 1.0
	var grab_radius = 12.0 / zoom_level
	
	var circ = _selected_circle()
	if circ and pos.distance_to(handle_position(circ)) <= grab_radius:
		if size_tween: size_tween.kill()
		typed_text = ""
		typed_armed = true
		grabbed_axis = ""
		poly_channel = 0  
		grab_offset = handle_position(circ) - pos
		object_editing = true
		return true
	
	var rect = _selected_rect()
	if rect:
		for h in _rect_handles(rect):
			if pos.distance_to(h["pos"]) <= grab_radius:
				if size_tween: size_tween.kill()
				typed_text = ""
				typed_armed = true
				active_axis = h["axis"]
				grabbed_axis = h["axis"]
				grabbed_sign = h["sign"]
				grab_offset = h["pos"] - pos 
				object_editing = true
				return true
	var poly = _selected_poly()
	if poly:
		for i in range(poly.get_points_count()):
			if pos.distance_to(poly.get_point_world(i)) <= grab_radius:
				typed_text = ""
				typed_armed = true
				locked_angle = -1.0
				grabbed_index = i
				grab_offset = poly.get_point_world(i) - pos
				object_editing = true
				_poly_ui_visible(true)   # показать спинбоксы
				_sync_poly_ui(poly)      # заполнить текущими значениями
				return true
	return false

func draw_cad_handle(pos: Vector2, screen_half: float, active: bool = false):
	var z = camera.zoom.x if camera else 1.0
	var half = screen_half / z
	var halo = 1.5 / z
	var points = PackedVector2Array([
		pos + Vector2(0, -half),
		pos + Vector2(half, 0),
		pos + Vector2(0, half),
		pos + Vector2(-half, 0),
	])
	var halo_points = PackedVector2Array([
		pos + Vector2(0, -(half + halo)),
		pos + Vector2(half + halo, 0),
		pos + Vector2(0, half + halo),
		pos + Vector2(-(half + halo), 0),
	])
	draw_colored_polygon(halo_points, Color(0.1, 0.1, 0.1, 0.9))
	# активная ручка — ярче, чтобы было видно, какую держишь
	draw_colored_polygon(points, Color(0.45, 0.8, 1.0) if active else Color(0.15, 0.55, 1.0))

func release_handle():
	if grabbed_axis != "":
		active_axis = grabbed_axis
	if poly_tween: poly_tween.kill()
	object_editing = false
	grabbed_axis = ""
	grabbed_sign = 1
	grab_offset = Vector2.ZERO
	queue_redraw()

func animate_size(obj):
	nach = obj.get_size_px()               # текущий размер (даже посреди анимации!)
	if size_tween:
		size_tween.kill()
	var delta = abs(kon - nach)
	# маленькое изменение — плавно (~0.35с), огромное — почти мгновенно (~0.08с)
	var duration = clamp(0.4 - delta / 4000.0, 0.15, 0.4)
	size_tween = create_tween()
	size_tween.set_trans(Tween.TRANS_CUBIC)   
	size_tween.set_ease(Tween.EASE_OUT) 
	size_tween.tween_method(_smooth_set.bind(obj), nach, kon, duration)
	size_tween.tween_callback(func():
		if is_instance_valid(obj):
			sync_inspector_ui(obj)
	)

func _smooth_set(value: float, obj):
	if is_instance_valid(obj):
		obj.set_size_px(value)
	queue_redraw()

func draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float):
	var z = camera.zoom.x if camera else 1.0
	# штрихи ~8 экранных пикселей, промежутки ~6 — независимо от зума и радиуса
	var screen_len = TAU * radius * z
	var count = clampi(int(screen_len / 14.0), 8, 80)
	var step = TAU / count
	for i in range(count):
		draw_arc(center, radius, i * step, i * step + step * 0.6, 6, color, width)

func _selected_rect():
	var obj = selected_object
	if obj and is_instance_valid(obj) and obj.has_method("get_size_px") and obj.get_size_px() is Vector2:
		return obj
	return null

func _rect_handles(obj) -> Array:
	var s = obj.get_size_px()
	return [
		{"pos": obj.to_global(Vector2(s.x / 2, 0)), "axis": "W", "sign": 1},
		{"pos": obj.to_global(Vector2(-s.x / 2, 0)), "axis": "W", "sign": -1},
		{"pos": obj.to_global(Vector2(0, s.y / 2)), "axis": "H", "sign": 1},
		{"pos": obj.to_global(Vector2(0, -s.y / 2)), "axis": "H", "sign": -1},
	]

func _selected_poly():
	var obj = selected_object
	if obj and is_instance_valid(obj) and obj.has_method("get_point_world"):
		return obj
	return null

func _draw_edge_label(center: Vector2, a: Vector2, b: Vector2, zoom_level: float, base_size: float = 12.0, override_text: String = ""):
	var mid = (a + b) / 2.0
	var dir = (b - a).normalized()
	var perp = Vector2(-dir.y, dir.x)
	if perp.dot(center - mid) > 0:
		perp = -perp
	var text = override_text if override_text != "" else "%.2f" % a.distance_to(b)
	draw_label(mid + perp * (16.0 / zoom_level), text, zoom_level, base_size)

func _poly_editing() -> bool:
	return object_editing and grabbed_index >= 0 and _selected_poly() != null

func _animate_poly_vertex(poly, i: int, target: Vector2):
	if poly_tween: poly_tween.kill()
	var from = poly.get_point_world(i)
	var delta = (target - from).length()
	var duration = clamp(0.4 - delta / 4000.0, 0.15, 0.4)
	poly_tween = create_tween()
	poly_tween.set_trans(Tween.TRANS_CUBIC)
	poly_tween.set_ease(Tween.EASE_OUT)
	poly_tween.tween_method(_set_poly_point.bind(poly, i), from, target, duration)

func _set_poly_point(p: Vector2, poly, i: int):
	if is_instance_valid(poly):
		poly.set_point_world(i, p)
		_sync_poly_ui(poly) 
	queue_redraw()

func _poly_active() -> bool:
	return grabbed_index >= 0 and _selected_poly() != null

func _poly_target_for_channel(poly, i: int, channel: int, value: float) -> Vector2:
	var n = poly.get_points_count()
	var v = poly.get_point_world(i)
	var prev = poly.get_point_world((i - 1 + n) % n)
	var next = poly.get_point_world((i + 1) % n)
	if channel == 1:
		if locked_angle < 0.0:
			return prev + (v - prev).normalized() * value
		return _with_angle_lock(prev, value, v, prev, next)
	if channel == 2:
		if locked_angle < 0.0:
			return next + (v - next).normalized() * value
		return _with_angle_lock(next, value, v, prev, next)
	# канал 0 — угол (старая математика дуги)
	var chord = (next - prev).length()
	var a = deg_to_rad(clamp(value, 1.0, 179.0))
	var R = chord / (2.0 * sin(a))
	var mid = (prev + next) / 2.0
	var h = sqrt(max(0.0, R * R - chord * chord / 4.0))
	var dir_chord = (next - prev).normalized()
	var perp = Vector2(-dir_chord.y, dir_chord.x)
	var side = sign((v - prev).cross(next - prev))
	var center_side = side if value < 90.0 else -side
	var O = mid + perp * center_side * h
	return O + (v - O).normalized() * R
# пересечение «окружность длины» и «дуга залоченного угла»
func _with_angle_lock(fixed_neighbor: Vector2, length: float, v: Vector2, prev: Vector2, next: Vector2) -> Vector2:
	var chord = (next - prev).length()
	var a = deg_to_rad(clamp(locked_angle, 1.0, 179.0))
	var R = chord / (2.0 * sin(a))
	var mid = (prev + next) / 2.0
	var h0 = sqrt(max(0.0, R * R - chord * chord / 4.0))
	var dir_chord = (next - prev).normalized()
	var perp = Vector2(-dir_chord.y, dir_chord.x)
	var side = sign((v - prev).cross(next - prev))
	var center_side = side if locked_angle < 90.0 else -side
	var O = mid + perp * center_side * h0
	var d_vec = O - fixed_neighbor
	var d = d_vec.length()
	if d > length + R or d < abs(length - R) or d < 0.0001:
		return v   # длина и угол несовместимы — стоим на месте
	var aa = (length * length - R * R + d * d) / (2.0 * d)
	var hh = sqrt(max(0.0, length * length - aa * aa))
	var p2 = fixed_neighbor + d_vec.normalized() * aa
	var pn = Vector2(-d_vec.y, d_vec.x).normalized()
	var s1 = p2 + pn * hh
	var s2 = p2 - pn * hh
	return s1 if s1.distance_to(v) < s2.distance_to(v) else s2

func on_poly_angle_changed(v): _apply_poly_channel(0, v)
func on_poly_left_changed(v): _apply_poly_channel(1, v)
func on_poly_right_changed(v): _apply_poly_channel(2, v)

func _apply_poly_channel(channel: int, value: float):
	var poly = _selected_poly()
	if not _poly_active():
		return
	if channel == 0:
		value = clamp(value, 1.0, 179.0)
	else:
		value = max(5.0, value)
	var target = _poly_target_for_channel(poly, grabbed_index, channel, value)
	if target.distance_to(poly.get_point_world(grabbed_index)) < 0.001 and locked_angle >= 0.0 and channel != 0:
		print("⚠️ Такая длина несовместима с углом ", locked_angle)
	elif poly.can_move_point(grabbed_index, target):
		if channel == 0:
			locked_angle = value
		object_editing = false
		_animate_poly_vertex(poly, grabbed_index, target)
	else:
		print("⚠️ Так полигон завяжется")

func _sync_poly_ui(poly):
	if not poly or grabbed_index < 0 or grabbed_index >= poly.get_points_count():
		return
	var n = poly.get_points_count()
	var i = grabbed_index
	var v = poly.get_point_world(i)
	var prev = poly.get_point_world((i - 1 + n) % n)
	var next = poly.get_point_world((i + 1) % n)
	for sb in [Angle_SpinBox, LeftEdge_SpinBox, RightEdge_SpinBox]:
		if sb: sb.set_block_signals(true)
	if Angle_SpinBox:
		Angle_SpinBox.value = abs(rad_to_deg((prev - v).angle_to(next - v)))
	if LeftEdge_SpinBox:
		LeftEdge_SpinBox.value = v.distance_to(prev)
	if RightEdge_SpinBox:
		RightEdge_SpinBox.value = v.distance_to(next)
	for sb in [Angle_SpinBox, LeftEdge_SpinBox, RightEdge_SpinBox]:
		if sb: sb.set_block_signals(false)

func _poly_ui_visible(show: bool):
	for sb in [Angle_SpinBox, LeftEdge_SpinBox, RightEdge_SpinBox]:
		if sb: sb.visible = show

func try_delete_vertex(pos) -> bool:
	var poly = _selected_poly()
	if not poly:
		return false
	var cam = get_viewport().get_camera_2d()
	var z = cam.zoom.x if cam else 1.0
	var best = -1
	var best_d = 12.0 / z
	for i in range(poly.get_points_count()):
		var d = pos.distance_to(poly.get_point_world(i))
		if d <= best_d:
			best_d = d
			best = i
	if best < 0:
		return false
	if poly.get_points_count() <= 3:
		print("⚠️ Минимум три вершины")
		return true
	if not poly.can_remove_point(best):
		print("⚠️ Нельзя удалить: полигон завяжется")
		return true
	poly.remove_point(best)
	if grabbed_index >= 0:
		if best == grabbed_index:
			grabbed_index = -1
		elif best < grabbed_index:
			grabbed_index -= 1
	locked_angle = -1.0
	_sync_poly_ui(poly)
	queue_redraw()
	return true

func try_add_vertex(pos) -> bool:
	var poly = _selected_poly()
	if not poly:
		return false
	var cam = get_viewport().get_camera_2d()
	var z = cam.zoom.x if cam else 1.0
	var best = -1
	var best_d = 8.0 / z
	var n = poly.get_points_count()
	for j in range(n):
		var a = poly.get_point_world(j)
		var b = poly.get_point_world((j + 1) % n)
		var closest = Geometry2D.get_closest_point_to_segment_uncapped(pos, a, b)
		var d = pos.distance_to(closest)
		if d <= best_d:
			best_d = d
			best = j
	if best < 0:
		return false
	poly.add_point_at(pos, best)
	grabbed_index = best + 1   # новая вершина сразу активна
	locked_angle = -1.0
	_poly_ui_visible(true)
	_sync_poly_ui(poly)
	queue_redraw()
	return true
	
	
	
	
	
	
	
	
	
