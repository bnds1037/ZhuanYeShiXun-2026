class_name ExploreScene
extends Node2D

const PLAYER_SCENE_PATH: String = "res://src/entities/player/player_move.tscn"
const MOB_SCENE_PATH: String = "res://src/entities/enemies/mob_zombie/mob_zombie.tscn"
const BATTLE_SCENE_PATH: String = "res://src/ui/combat_ui/battle_scene.tscn"
const MOB_COUNT: int = 3
const BOSS_POSITION: Vector2 = Vector2(1400, 500)

var player: Player = null
var mob_scene: PackedScene = null
var player_scene: PackedScene = null
var battle_scene: Control = null
var current_enemy_node: Node = null

@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD


func _ready() -> void:
	player_scene = load(PLAYER_SCENE_PATH)
	mob_scene = load(MOB_SCENE_PATH)
	_spawn_player()
	_spawn_mobs()
	SignalBus.encounter_started.connect(_on_encounter_started)
	SignalBus.encounter_ended.connect(_on_encounter_ended)
	hud.visible = true


func _spawn_player() -> void:
	player = player_scene.instantiate() as Player
	add_child(player)
	player.set_spawn_position(Vector2(200, 540))
	camera.position = player.position


func _spawn_mobs() -> void:
	for i in range(MOB_COUNT):
		var mob: CharacterBody2D = mob_scene.instantiate() as CharacterBody2D
		add_child(mob)
		var angle: float = TAU * float(i) / float(MOB_COUNT)
		mob.position = Vector2(600 + cos(angle) * 200, 400 + sin(angle) * 200)
	var boss_mob: CharacterBody2D = mob_scene.instantiate() as CharacterBody2D
	add_child(boss_mob)
	boss_mob.position = BOSS_POSITION
	if boss_mob.has_node("NameLabel"):
		boss_mob.get_node("NameLabel").text = "骨煞"


func _process(_delta: float) -> void:
	if player and is_instance_valid(player):
		camera.position = camera.position.lerp(player.position, 0.1)


func _on_encounter_started(enemy_node: Node) -> void:
	current_enemy_node = enemy_node
	var data: EnemyData = null
	if enemy_node.has_meta("enemy_data"):
		data = enemy_node.get_meta("enemy_data")
	if data == null:
		var path: String = "res://src/resources/enemy_data/mob_zombie.tres"
		if ResourceLoader.exists(path):
			data = load(path)
	if data:
		GameManager.start_battle(data, data.is_boss)
		_show_battle_overlay()


func _show_battle_overlay() -> void:
	var battle_packed: PackedScene = load(BATTLE_SCENE_PATH)
	battle_scene = battle_packed.instantiate() as Control
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "BattleOverlay"
	layer.layer = 10
	add_child(layer)
	layer.add_child(battle_scene)
	hud.visible = false
	if player:
		player.set_physics_process(false)


func _on_encounter_ended(victory: bool, enemy_node: Node) -> void:
	if battle_scene and is_instance_valid(battle_scene):
		var parent_layer: Node = battle_scene.get_parent()
		battle_scene.queue_free()
		battle_scene = null
		if parent_layer and is_instance_valid(parent_layer):
			parent_layer.queue_free()
	hud.visible = true
	if player:
		player.set_physics_process(true)
	if victory and current_enemy_node and is_instance_valid(current_enemy_node):
		current_enemy_node.queue_free()
	current_enemy_node = null
