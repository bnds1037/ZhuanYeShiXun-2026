extends Camera2D

## 遵循规范：通过导出路径获取真主角节点
@export var player_node: CharacterBody2D

var _world_connected: bool = false

func _process(_delta: float) -> void:
	if is_instance_valid(player_node):
		global_position = player_node.global_position
		
		if not _world_connected:
			var parent_viewport: SubViewport = get_parent() as SubViewport
			if parent_viewport and player_node.is_inside_tree():
				parent_viewport.world_2d = player_node.get_viewport().world_2d
				_world_connected = true
