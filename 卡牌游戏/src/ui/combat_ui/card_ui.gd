class_name CardUI
extends Control

const CARD_WIDTH: float = 160.0
const CARD_HEIGHT: float = 240.0
const HOVER_SCALE: float = 1.2
const HOVER_LIFT: float = 40.0
const RELEASE_LINE_Y_RATIO: float = 0.65
const DRAG_Z_INDEX: int = 100

signal card_hovered(card_ui: CardUI)
signal card_unhovered(card_ui: CardUI)
signal card_played(card: CardBase, target: Node)
signal drag_started(card_ui: CardUI)
signal drag_ended(card_ui: CardUI, released: bool)

var card_data: CardBase = null
var hand_index: int = 0
var base_position: Vector2 = Vector2.ZERO
var base_rotation: float = 0.0
var _is_hovered: bool = false
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _can_play: bool = true

var _card_tex: TextureRect = null


func setup(card: CardBase, index: int) -> void:
	card_data = card
	hand_index = index
	_load_card_texture()


func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	_card_tex = get_node_or_null("CardTex") as TextureRect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if card_data != null:
		_load_card_texture()


func _load_card_texture() -> void:
	if _card_tex == null:
		_card_tex = get_node_or_null("CardTex") as TextureRect
	if _card_tex == null or card_data == null:
		return
	for ext in [".png", ".jpg"]:
		var file_path: String = "res://Assets/Card_img/" + card_data.card_id + ext
		if ResourceLoader.exists(file_path):
			var tex: Texture2D = load(file_path)
			if tex != null:
				_card_tex.texture = tex
				return


func set_hand_layout(pos: Vector2, rot: float) -> void:
	base_position = pos
	base_rotation = rot
	if not _is_dragging:
		position = pos - pivot_offset
		rotation = rot


func _on_mouse_entered() -> void:
	if _is_dragging:
		return
	_is_hovered = true
	z_index = 50
	card_hovered.emit(self)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.15)
	tween.tween_property(self, "position", base_position + Vector2(0, -HOVER_LIFT) - pivot_offset, 0.15)
	tween.tween_property(self, "rotation", 0.0, 0.15)


func _on_mouse_exited() -> void:
	if _is_dragging:
		return
	_is_hovered = false
	z_index = 0
	card_unhovered.emit(self)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.tween_property(self, "position", base_position - pivot_offset, 0.15)
	tween.tween_property(self, "rotation", base_rotation, 0.15)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_hovered:
				_start_drag(event.position)
			elif not event.pressed and _is_dragging:
				_end_drag()
	elif event is InputEventMouseMotion and _is_dragging:
		_update_drag()


func _start_drag(local_pos: Vector2) -> void:
	_is_dragging = true
	z_index = DRAG_Z_INDEX
	_drag_offset = local_pos
	drag_started.emit(self)


func _update_drag() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var parent_rect: Rect2 = get_parent_control().get_global_rect()
	position = mouse_pos - parent_rect.position - _drag_offset
	rotation = 0.0
	scale = Vector2(HOVER_SCALE, HOVER_SCALE)


func _end_drag() -> void:
	_is_dragging = false
	z_index = 0
	var screen_pos: Vector2 = get_global_mouse_position()
	var viewport_rect: Rect2 = get_viewport_rect()
	var release_line_y: float = viewport_rect.size.y * RELEASE_LINE_Y_RATIO
	var released: bool = screen_pos.y < release_line_y
	if released and _can_play:
		_on_release_success()
	else:
		_on_release_fail()
	drag_ended.emit(self, released)


func _on_release_success() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.2)
	tween.tween_callback(func() -> void:
		if card_data != null:
			card_played.emit(card_data, null)
			queue_free()
	)


func _on_release_fail() -> void:
	if not _can_play:
		_flash_red()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.tween_property(self, "position", base_position - pivot_offset, 0.2)
	tween.tween_property(self, "rotation", base_rotation, 0.2)


func _flash_red() -> void:
	if _card_tex == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_card_tex, "modulate", Color(1.0, 0.3, 0.3), 0.1)
	tween.tween_property(_card_tex, "modulate", Color.WHITE, 0.3)


func set_playable(affordable: bool) -> void:
	_can_play = affordable
	if not affordable:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color.WHITE


func get_card_data() -> CardBase:
	return card_data
