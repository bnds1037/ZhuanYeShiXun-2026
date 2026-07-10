extends Node2D

# 强类型规范：默认名字，如果读取全局肉鸽系统失败，则使用此后备名字
@export var boss_name: String = "古墓妖兽"

func _ready() -> void:
	# 核心：自动去大地图或全局内存中抓取本局唯一的肉鸽随机结果
	_load_current_run_boss_data()
	
	print("【战斗系统】成功切入战斗！当前面对的强敌是: ", boss_name)
	# 💡 这里预留给你的队友以后编写具体的卡牌战斗界面和血条

func _load_current_run_boss_data() -> void:
	# 1. 尝试从大树的根目录中，寻找刚才大地图留下的 RunManager 节点
	var run_manager = get_tree().root.find_child("RunManager", true, false)
	
	# 2. 如果你的 RunManager 是作为 Autoload（全局单例）注册的，则直接用全局节点获取
	if not run_manager and get_node_or_null("/root/RunManager"):
		run_manager = get_node("/root/RunManager")
		
	# 3. 成功拿到肉鸽管家，把本局的真实 Boss 名字同步过来
	if run_manager and run_manager.current_run_boss_name != "":
		boss_name = run_manager.current_run_boss_name
