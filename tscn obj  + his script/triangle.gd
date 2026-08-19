extends RigidBody2D

@export var is_static = false
@export var custom_mass = 1.0
@export var custom_color = Color.WHITE
@export var custom_scale = 1.0

const OUTLINE_WIDTH = 4.0
const DEBUG_OUTLINE = true

var is_selected = false
var selection_outline = null
var orig_color

func _ready() -> void:
	orig_color = custom_color
	$Polygon2D.modulate = orig_color

func set_static(value: bool):
	is_static = value
	refresh_outline()

func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_parent().object_clicked(self)

func _base_size() -> float:
	var min_x: float = INF
	var max_x: float = -INF
	for p in $Polygon2D.polygon:
		if p.x < min_x:
			min_x = p.x
		if p.x > max_x:
			max_x = p.x
	return max_x - min_x

func _outline_add() -> float:
	return (2.0 * OUTLINE_WIDTH) / _base_size()

func refresh_outline():
	if selection_outline == null:
		return
	selection_outline.points = _outline_points()
	if DEBUG_OUTLINE:
		selection_outline.default_color = Color.RED if is_static else Color(0, 0, 0)

func _outline_points() -> PackedVector2Array:
	var s = $Polygon2D.scale
	var res = PackedVector2Array()
	for p in $Polygon2D.polygon:
		res.append(p * s)
	return res

func update_size():
	$Polygon2D.scale = Vector2(custom_scale, custom_scale)
	# Ищем collision-ноду под любым именем — больше никаких крашей
	var col = get_node_or_null("CollisionShape2D")
	if col == null:
		col = get_node_or_null("CollisionPolygon2D")
	if col != null:
		col.scale = Vector2(custom_scale, custom_scale)
	refresh_outline()

func select_object():
	if is_selected:
		return
	is_selected = true

	# 1. Прозрачность
	var temp_color = orig_color
	temp_color.a = 0.85
	$Polygon2D.modulate = temp_color

	# 2. Обводка
	var outline = Line2D.new()
	outline.closed = true
	outline.width = OUTLINE_WIDTH 
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.points = _outline_points()
	outline.name = "SelectionOutline"
	add_child(outline)
	selection_outline = outline

	# 3. Пересчёт в конце
	refresh_outline()

func deselect_object():
	is_selected = false
	$Polygon2D.modulate = orig_color
	if selection_outline:
		selection_outline.queue_free()
		selection_outline = null

func set_color(color):
	orig_color = color
	custom_color = color
	$Polygon2D.modulate = color

func get_points_count() -> int:
	return $Polygon2D.polygon.size()

func get_point_world(i: int) -> Vector2:
	return to_global($Polygon2D.polygon[i] * $Polygon2D.scale)

func set_point_world(i: int, world_pos: Vector2):
	var local = to_local(world_pos) / $Polygon2D.scale
	if _would_self_intersect(i, local):
		return
	var pts = $Polygon2D.polygon
	pts[i] = local
	$Polygon2D.polygon = pts
	var col = get_node_or_null("CollisionPolygon2D")
	if col:
		var cp = col.polygon
		cp[i] = local
		col.polygon = cp
	refresh_outline()

func _would_self_intersect(i: int, new_p: Vector2) -> bool:
	var pts = $Polygon2D.polygon
	var n = pts.size()
	if n < 4:
		return false
	var prev_i = (i - 1 + n) % n
	var next_i = (i + 1) % n
	var prev = pts[prev_i]
	var next = pts[next_i]
	for j in range(n):
		var j2 = (j + 1) % n
		# ребро (prev → new): не проверяем против рёбер, касающихся prev или i
		if j != i and j2 != i and j != prev_i and j2 != prev_i:
			if _seg_cross(prev, new_p, pts[j], pts[j2]):
				return true
		# ребро (new → next): не проверяем против рёбер, касающихся next или i
		if j != i and j2 != i and j != next_i and j2 != next_i:
			if _seg_cross(new_p, next, pts[j], pts[j2]):
				return true
	return false

func _seg_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var o1 = sign((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
	var o2 = sign((b.x - a.x) * (d.y - a.y) - (b.y - a.y) * (d.x - a.x))
	var o3 = sign((d.x - c.x) * (a.y - c.y) - (d.y - c.y) * (a.x - c.x))
	var o4 = sign((d.x - c.x) * (b.y - c.y) - (d.y - c.y) * (b.x - c.x))
	return o1 != o2 and o3 != o4

func can_move_point(i: int, world_pos: Vector2) -> bool:
	return not _would_self_intersect(i, to_local(world_pos) / $Polygon2D.scale)

func add_point_at(world_pos: Vector2, edge_index: int):
	var local = to_local(world_pos) / $Polygon2D.scale
	var pts = $Polygon2D.polygon
	pts.insert(edge_index + 1, local)
	$Polygon2D.polygon = pts
	var col = get_node_or_null("CollisionPolygon2D")
	if col:
		var cp = col.polygon
		cp.insert(edge_index + 1, local)
		col.polygon = cp
	refresh_outline()

func remove_point(i: int):
	var pts = $Polygon2D.polygon
	pts.remove_at(i)
	$Polygon2D.polygon = pts
	var col = get_node_or_null("CollisionPolygon2D")
	if col:
		var cp = col.polygon
		cp.remove_at(i)
		col.polygon = cp
	refresh_outline()

func can_remove_point(i: int) -> bool:
	var pts = $Polygon2D.polygon
	var n = pts.size()
	var prev_i = (i - 1 + n) % n
	var next_i = (i + 1) % n
	var a = pts[prev_i]
	var b = pts[next_i]
	for j in range(n):
		var j2 = (j + 1) % n
		# пропускаем рёбра, которых коснётся удаление
		if j == i or j2 == i or j == prev_i or j2 == prev_i or j == next_i or j2 == next_i:
			continue
		if _seg_cross(a, b, pts[j], pts[j2]):
			return false
	return true
