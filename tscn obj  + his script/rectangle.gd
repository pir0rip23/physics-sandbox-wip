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

func _base_height() -> float:
	var min_y: float = INF
	var max_y: float = -INF
	for p in $Polygon2D.polygon:
		if p.y < min_y:
			min_y = p.y
		if p.y > max_y:
			max_y = p.y
	return max_y - min_y

func _outline_add() -> float:
	return (2.0 * OUTLINE_WIDTH) / _base_size()

func refresh_outline():
	if selection_outline == null:
		return
	var base_size: float = _base_size()
	var obj_size: float = base_size * $Polygon2D.scale.x
	var width: float = min(OUTLINE_WIDTH, obj_size / 4.0)
	var add: float = (2.0 * width) / base_size
	selection_outline.scale = Vector2($Polygon2D.scale.x + add, $Polygon2D.scale.y + add)
	if DEBUG_OUTLINE:
		if is_static:
			selection_outline.modulate = Color.RED # Если статичный - красная обводка
		else:
			selection_outline.modulate = Color(1, 1, 0) # Если обычный - желтая обводка
		#print("RECT base=", _base_size(), " add=", add, " scale=", $Polygon2D.scale)

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
	var outline = Polygon2D.new()
	outline.polygon = $Polygon2D.polygon
	outline.position = Vector2(0, 0)
	outline.name = "SelectionOutline"
	add_child(outline)
	move_child(outline, 0)
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

func set_size_px(w, h):
	var s: Vector2
	s.x = w/ _base_size()
	s.y = h/ _base_height()
	$Polygon2D.scale = Vector2(s.x, s.y)
	var col = get_node_or_null("CollisionShape2D")
	if col == null:
		col = get_node_or_null("CollisionPolygon2D")
	if col != null:
		col.scale = Vector2(s.x, s.y)
	refresh_outline()

func get_size_px():
	return Vector2(_base_size() * $Polygon2D.scale.x, _base_height() * $Polygon2D.scale.y)
