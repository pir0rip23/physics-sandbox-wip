extends RigidBody2D

@export var is_static = false
@export var custom_mass = 1.0
@export var custom_color = Color.WHITE
@export var custom_scale = 1.0

const BASE_SCALE = 0.1 
const OUTLINE_WIDTH = 4.0
const DEBUG_OUTLINE = true

var is_selected = false
var selection_outline = null
var orig_color
var orig_texture

func _ready() -> void:
	orig_color = custom_color
	orig_texture = $Sprite2D.texture
	$Sprite2D.modulate = orig_color
	mass = custom_mass 
	update_size()

func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_parent().ball_clicked(self)

func _outline_add() -> float:
	var base_size = $Sprite2D.texture.get_size().x
	return (2.0 * OUTLINE_WIDTH) / base_size

func refresh_outline():
	if selection_outline == null:
		return
	
	var base_size: float = $Sprite2D.texture.get_size().x
	var obj_size: float = base_size * $Sprite2D.scale.x  
	var width: float = min(OUTLINE_WIDTH, obj_size / 4.0) 
	var add: float = (2.0 * width) / base_size
	selection_outline.scale = Vector2($Sprite2D.scale.x + add, $Sprite2D.scale.y + add)
	
	if DEBUG_OUTLINE:
		if is_static:
			selection_outline.modulate = Color.WEB_MAROON # Если статичный - красная обводка
		else:
			selection_outline.modulate = Color(0, 0, 0) # Если обычный - желтая обводка
		var real_border = (selection_outline.scale.x - $Sprite2D.scale.x) * base_size / 2.0
		#print("base=", base_size, " | add=", real_border, "px должно быть ", OUTLINE_WIDTH)

func update_size():
	var s = BASE_SCALE * custom_scale
	$Sprite2D.scale = Vector2(s, s)
	$CollisionShape2D.scale = Vector2(s, s)
	refresh_outline()

func get_base_radius():
	var base_radius = $Sprite2D.texture.get_size().x / 2.0 * BASE_SCALE
	return base_radius

func get_size_px():
	var base_radius_in_pixels = custom_scale * get_base_radius()
	return base_radius_in_pixels

func set_size_px(v):
	custom_scale = v / get_base_radius()
	update_size()

func select_object():
	if is_selected:
		return
	is_selected = true
	
	var temp_color = orig_color
	temp_color.a = 0.85
	$Sprite2D.modulate = temp_color
	
	var outline = Sprite2D.new()
	outline.texture = $Sprite2D.texture
	outline.position = Vector2(0, 0)
	outline.name = "SelectionOutline"
	
	add_child(outline)
	move_child(outline, 0)
	
	selection_outline = outline
	refresh_outline()  # ← ДОБАВЛЕНО: пересчёт обводки

func deselect_object():
	is_selected = false
	$Sprite2D.modulate = orig_color
	
	if selection_outline:
		selection_outline.queue_free()
		selection_outline = null

func set_color(color):
	orig_color = color
	custom_color = color
	$Sprite2D.modulate = color

func set_static(value: bool):
	is_static = value
	refresh_outline()

	if is_static:
		freeze = true
