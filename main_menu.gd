extends Control

@onready var background = $Background
@onready var video_player = $Panel/VideoStreamPlayer
@onready var settings_menu = $Panel/SettingsMenu
#текст 
@onready var themes =$Panel/theme
@onready var glavnii = $Background/name

var bg_bee = preload("res://texturs/Frame 2.png") 
var bg_peach = preload("res://texturs/white ui.png")

func _ready():
	# Автоматически выставляем центр кнопок (ровно половина от их размера)
	$VBoxContainer/CreateButton.pivot_offset = $VBoxContainer/CreateButton.size / 2.0
	$NastroikiButton.pivot_offset = $NastroikiButton.size / 2.0
	$VBoxContainer/StoryButton.pivot_offset = $VBoxContainer/StoryButton.size / 2.0
	$VBoxContainer/LevelsButton.pivot_offset = $VBoxContainer/LevelsButton.size / 2.0
	
	# Твой код, который уже был написан:
	$VBoxContainer/StoryButton.pressed.connect(_on_story_button_pressed)
	$VBoxContainer/LevelsButton.pressed.connect(_on_levels_button_pressed)
	$NastroikiButton.pressed.connect(_on_nastroiki_button_pressed)
	$Panel/SettingsMenu/BeeButton.pressed.connect(_on_bee_theme_pressed)
	$Panel/SettingsMenu/PeachButton.pressed.connect(_on_peach_theme_pressed)
	
	# Наведение мыши на кнопку «СЮЖЕТ»
	$VBoxContainer/StoryButton.mouse_entered.connect(_on_story_button_mouse_entered)
	$VBoxContainer/StoryButton.mouse_exited.connect(_on_story_button_mouse_exited)
	
	# Наведение мыши на кнопку создать
	$VBoxContainer/CreateButton.mouse_entered.connect(_on_create_button_mouse_entered)
	$VBoxContainer/CreateButton.mouse_exited.connect(_on_create_button_mouse_exited)
	
	# Наведение мыши на кнопку «настройки»
	$NastroikiButton.mouse_entered.connect(_on_nastroiki_button_mouse_entered)
	$NastroikiButton.mouse_exited.connect(_on_nastroiki_button_mouse_exited)
	
	
	# Наведение мыши на кнопку «ВСЕ УРОВНИ»
	$VBoxContainer/LevelsButton.mouse_entered.connect(_on_levels_button_mouse_entered)
	$VBoxContainer/LevelsButton.mouse_exited.connect(_on_levels_button_mouse_exited)
	


func _on_story_button_pressed():
	print("Нажали на кнопку СЮЖЕТ!")

func _on_levels_button_pressed():
	# Обращаемся напрямую к окну игры и включаем полный экран
	get_window().mode = Window.MODE_FULLSCREEN
	
	# Меняем сцену
	get_tree().call_deferred("change_scene_to_file", "res://main.tscn")

func _on_exit_to_menu_pressed():
	# Возвращаем оконный режим
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Возвращаемся в сцену главного меню
	get_tree().change_scene_to_file("res://main_menu.tscn")

# === АНИМАЦИИ  ===

func _on_story_button_mouse_entered():
	# Создаем плавную анимацию
	var tween = create_tween()
	# Увеличиваем масштаб кнопки до 110% за 0.1 секунды
	tween.tween_property($VBoxContainer/StoryButton, "scale", Vector2(1.1, 1.1), 0.1)
	

func _on_story_button_mouse_exited():
	var tween = create_tween()
	# Возвращаем исходный масштаб 100% за 0.1 секунды
	tween.tween_property($VBoxContainer/StoryButton, "scale", Vector2(1.0, 1.0), 0.1)

func _on_levels_button_mouse_entered():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/LevelsButton, "scale", Vector2(1.1, 1.1), 0.1)
	
func _on_levels_button_mouse_exited():
	var tween = create_tween()
	tween.tween_property($VBoxContainer/LevelsButton, "scale", Vector2(1.0, 1.0), 0.1)
	
func _on_nastroiki_button_mouse_entered():
	# Создаем плавную анимацию
	var tween = create_tween()
	# Увеличиваем масштаб кнопки до 110% за 0.1 секунды
	tween.tween_property($NastroikiButton, "scale", Vector2(1.1, 1.1), 0.1)
	
func _on_nastroiki_button_mouse_exited():
	var tween = create_tween()
	# Возвращаем исходный масштаб 100% за 0.1 секунды
	tween.tween_property($NastroikiButton, "scale", Vector2(1.0, 1.0), 0.1)
	
func _on_create_button_mouse_entered():
	var tween = create_tween()
	# Возвращаем исходный масштаб 100% за 0.1 секунды
	tween.tween_property($VBoxContainer/CreateButton, "scale", Vector2(1.1, 1.1), 0.1)
	
func _on_create_button_mouse_exited():
	var tween = create_tween()
	# Возвращаем исходный масштаб 100% за 0.1 секунды
	tween.tween_property($VBoxContainer/CreateButton, "scale", Vector2(1.0, 1.0), 0.1)
	
	# === ЛОГИКА НАСТРОЕК И ТЕМ ===

func _on_nastroiki_button_pressed():
	# Проверяем, открыты ли настройки прямо сейчас
	var is_open = settings_menu.visible and themes.visible
	# Меняем состояние на противоположное:
	settings_menu.visible = !is_open # Если были закрыты — откроются
	themes.visible = !is_open
	video_player.visible = is_open   # Если настройки открываются, видео прячется, и наоборот

func _on_bee_theme_pressed():
	background.texture = bg_bee
	# Задаем цвет для темы Bee (подставь свой HEX-код из Figma)
	var bee_color = Color("000000ff") 
	
	if has_node("Background/name"):
		$Background/name.modulate = bee_color
	if has_node("Panel/theme"):
		$Panel/theme.modulate = bee_color

func _on_peach_theme_pressed():
	background.texture = bg_peach
	# Задаем цвет для темы Bee (подставь свой HEX-код из Figma)
	var peach_color = Color("FF5D60") 
	
	if has_node("Background/name"):
		$Background/name.modulate = peach_color
	if has_node("Panel/theme"):
		$Panel/theme.modulate = peach_color
	
