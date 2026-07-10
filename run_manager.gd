extends Node

# 预留三个独立战斗关卡场景的文件路径接口
@export_file("*.tscn") var boss_1_path: String = ""
@export_file("*.tscn") var boss_2_path: String = ""
@export_file("*.tscn") var boss_3_path: String = ""

# 存储这把肉鸽游戏（Run）最终决定的唯一 Boss 数据
var current_run_boss_path: String = ""
var current_run_boss_name: String = ""

func _ready() -> void:
	# 游戏启动时，自动初始化一局
	generate_new_run()

# 核心方法：新开局时调用，完全随机选择一个 Boss 并通知大地图触发器
func generate_new_run() -> void:
	randomize()
	
	var boss_pool = []
	if boss_1_path != "": 
		boss_pool.append({
			"name": "青铜巨兽·饕餮", 
			"path": boss_1_path
		})
	if boss_2_path != "": 
		boss_pool.append({
			"name": "百战僵尸统领", 
			"path": boss_2_path
		})
	if boss_3_path != "": 
		# 🛠️ 修复：把之前漏掉的 path 补上！
		boss_pool.append({
			"name": "上古荒兽·烛九阴", 
			"path": boss_3_path
		})
	
	if boss_pool.size() > 0:
		var lucky_boss = boss_pool[randi() % boss_pool.size()]
		current_run_boss_path = lucky_boss["path"]
		current_run_boss_name = lucky_boss["name"]
		
		print("【肉鸽系统】核心开局锁定成功，最终 Boss 为: ", current_run_boss_name)
		
		# 核心：直接加载你单独写好的独立 Boss 场景文件
		_update_map_boss_visual(current_run_boss_path)
	else:
		print("【警告】Boss池为空，请检查 RunManager 检查器中是否正确拖入了 BOSS 场景文件！")

# 全自动清洗大地图、并直接加载你做好的独立 BOSS 场景的外观
func _update_map_boss_visual(scene_path: String) -> void:
	# 强行等待一帧，确保大地图已经完全加载完毕
	await get_tree().process_frame
	
	# 1. 安全抓取大地图上的 BossTrigger 节点
	var trigger_node = get_tree().current_scene.find_child("BossTrigger", true, false)
	
	if not trigger_node:
		print("【肉鸽系统错误】未在大地图中找到名为 'BossTrigger' 的节点，请检查场景树名字！")
		return
		
	# 2. 清理旧外衣：如果触发器底下本来就有叫 BossSprite 的节点，统统强制清理释放
	var old_sprite = trigger_node.find_child("BossSprite", true, false)
	if old_sprite:
		old_sprite.queue_free()
		
	# 3. 动态加载并实例化独立场景（比如 BOSS3.tscn）
	var boss_scene = load(scene_path) as PackedScene
	if not boss_scene:
		print("【肉鸽系统错误】无法加载独立场景文件: ", scene_path)
		return
		
	var boss_instance = boss_scene.instantiate()
	
	# 4. 关键：把它改名为 BossSprite，无缝融入大地图触发器体系
	boss_instance.name = "BossSprite"
	
	# 5. 把整个独立的 Boss 场景实例作为子节点挂载到触发器（Area2D）正下方
	trigger_node.add_child(boss_instance)
	
	# 6. 坐标完全归零，让它完美居中
	if "position" in boss_instance:
		boss_instance.position = Vector2.ZERO
		
	# 7. ====【强行唤醒独立场景内的动画组件】====
	var anim_sprite: AnimatedSprite2D = null
	
	# 如果你的 BOSS3.tscn 根节点本身就是 AnimatedSprite2D
	if boss_instance is AnimatedSprite2D:
		anim_sprite = boss_instance
	else:
		# 如果根节点是 Node2D，就去它的子节点里地毯式搜索 AnimatedSprite2D
		for child in boss_instance.get_children():
			if child is AnimatedSprite2D:
				anim_sprite = child
				break
	
	# 8. 让它在大地图上狂飙动画
	if anim_sprite:
		# 自动获取你在独立场景里调好的动画名字（比如 "Boss" 或 "default"）
		var anim_name = anim_sprite.animation if anim_sprite.animation != "" else "Boss"
		
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
			anim_sprite.play(anim_name)
			print("【肉鸽系统】成功启动大地图 Boss 动画，正在播放: ", anim_name)
		else:
			# 保底：如果没有配置名字，直接播放第一个动画
			var list = anim_sprite.sprite_frames.get_animation_names()
			if list.size() > 0:
				anim_sprite.play(list[0])
				print("【肉鸽系统】未匹配到指定动画，已启动首项动画: ", list[0])
	else:
		print("【肉鸽系统警告】在加载的 Boss 场景中没有找到任何 AnimatedSprite2D 组件，动画无法播放！")
