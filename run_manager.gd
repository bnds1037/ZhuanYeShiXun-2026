extends Node

# 预留三个 Boss 场景的文件路径接口（在检查器里把你的 BOSS1.tscn, BOSS2.tscn, BOSS3.tscn 拖进来）
@export_file("*.tscn") var boss_1_path: String = ""
@export_file("*.tscn") var boss_2_path: String = ""
@export_file("*.tscn") var boss_3_path: String = ""

# 存储这把肉鸽游戏（Run）最终决定的 Boss 数据
var current_run_boss_path: String = ""
var current_run_boss_name: String = ""

func _ready() -> void:
	# 游戏刚启动时，自动初始化一局
	generate_new_run()

# 核心方法：新开局时调用，完全随机选择一个 Boss 并更换大地图立绘
func generate_new_run() -> void:
	randomize()
	
	var boss_pool = []
	if boss_1_path != "": 
		boss_pool.append({
			"name": "青铜巨兽·饕餮", 
			"path": boss_1_path,
			"texture": "res://青铜巨兽.png"
		})
	if boss_2_path != "": 
		boss_pool.append({
			"name": "百战僵尸统领", 
			"path": boss_2_path,
			"texture": "res://僵尸.png"
		})
	if boss_3_path != "": 
		boss_pool.append({
			"name": "上古荒兽·烛九阴", 
			"path": boss_3_path,
			"texture": "res://烛九阴.png"
		})
	
	if boss_pool.size() > 0:
		var lucky_boss = boss_pool[randi() % boss_pool.size()]
		current_run_boss_path = lucky_boss["path"]
		current_run_boss_name = lucky_boss["name"]
		print("【肉鸽系统】本局最终Boss已锁定为: ", current_run_boss_name)
		
		# 更换大地图贴图
		_update_map_boss_texture(lucky_boss["texture"])
	else:
		print("【警告】Boss池为空，请在RunManager的检查器中配置Boss场景路径！")

# 更换大地图贴图的内部函数
func _update_map_boss_texture(texture_path: String) -> void:
	# 等待一帧，确保大地图上的节点都已经加载完毕
	await get_tree().process_frame
	
	# 动态寻找刚才建立的 BossSprite 节点
	var boss_sprite = get_tree().current_scene.find_child("BossSprite", true, false)
	
	if boss_sprite is Sprite2D:
		boss_sprite.texture = load(texture_path)
		print("【肉鸽系统】大地图 Boss 贴图已成功更换为: ", texture_path)
	else:
		print("【提示】未在大地图中找到名为 'BossSprite' 的 Sprite2D 节点，无法更换贴图。")
