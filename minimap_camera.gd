extends Camera2D

## 遵循规范：通过导出路径获取真主角节点
@export var player_node: CharacterBody2D

var _world_connected: bool = false

func _ready() -> void:
	# 💡 自动保底机制：如果在编辑器里忘了拖入 Player 节点，它会自动在主场景里搜索
	if not is_instance_valid(player_node):
		player_node = get_tree().current_scene.find_child("Player", true, false) as CharacterBody2D

func _process(_delta: float) -> void:
	if is_instance_valid(player_node):
		# 1. 丝滑跟随主角的物理位置（因为主角还是那个 CharacterBody2D，所以位置百分之百精准！）
		global_position = player_node.global_position
		
		# 2. 动态共享 2D 世界视口（确保小地图能渲染出大地图上的墙壁和瓷砖）
		if not _world_connected:
			var parent_viewport: SubViewport = get_parent() as SubViewport
			if parent_viewport and player_node.is_inside_tree():
				parent_viewport.world_2d = player_node.get_viewport().world_2d
				_world_connected = true
