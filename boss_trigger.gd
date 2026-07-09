extends Area2D

# ==================== 1. 镜头缩放配置（完全保留您的原版数值） ====================
@export var zoom_in_value: Vector2 = Vector2(5, 5)
var default_zoom: Vector2 = Vector2(2.5, 2.5)

# ==================== 2. 内部变量 ====================
var _player_ref: Node2D = null
var _dialog: ConfirmationDialog = null
var _run_manager_ref: Node = null  # 缓存大管家节点的引用

func _ready() -> void:
	# 1. 自动绑定碰撞检测信号
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 2. 在大地图中动态寻找你刚刚重建的 RunManager 节点
	_run_manager_ref = get_tree().current_scene.find_child("RunManager", true, false)
	
	# 3. 动态创建一个确认对话框
	_create_trigger_dialog()

# 创建“是否战斗”的弹窗
func _create_trigger_dialog() -> void:
	_dialog = ConfirmationDialog.new()
	_dialog.title = "遭遇强敌"
	
	# 动态从大地图的 RunManager 节点中获取这局随机到的 Boss 名字
	var boss_name = "未知妖兽"
	if _run_manager_ref and "current_run_boss_name" in _run_manager_ref:
		if _run_manager_ref.current_run_boss_name != "":
			boss_name = _run_manager_ref.current_run_boss_name
			
	_dialog.dialog_text = "前方妖气冲天，是否进入与【" + boss_name + "】的战斗？"
	_dialog.ok_button_text = "誓死一战"
	_dialog.cancel_button_text = "暂且撤退"
	
	# 连接对话框的按钮信号
	_dialog.confirmed.connect(_on_choose_battle)          # 点击确认
	_dialog.canceled.connect(_on_choose_retreat)         # 点击取消或点叉
	
	# 将对话框添加为触发器的子节点
	add_child(_dialog)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		_player_ref = body
		
		# 每次玩家走过来踩到触发器时，都实时刷新一下弹窗里的 Boss 名字，确保文本完全对齐
		var boss_name = "未知妖兽"
		if _run_manager_ref and "current_run_boss_name" in _run_manager_ref:
			if _run_manager_ref.current_run_boss_name != "":
				boss_name = _run_manager_ref.current_run_boss_name
		_dialog.dialog_text = "前方妖气冲天，是否进入与【" + boss_name + "】的战斗？"
		
		# 1. 触发您调好的原版相机 Zoom (5, 5) 视角变换
		_zoom_camera(_player_ref, zoom_in_value)
		# 2. 弹出选择框
		_dialog.popup_centered()

# 选项 A：选择战斗
func _on_choose_battle() -> void:
	print("【系统】玩家选择战斗！准备加载本局限定的战斗场景...")
	
	var target_scene = ""
	if _run_manager_ref and "current_run_boss_path" in _run_manager_ref:
		target_scene = _run_manager_ref.current_run_boss_path
	
	if target_scene != "":
		print("【系统】正在加载战斗关卡文件：", target_scene)
		get_tree().change_scene_to_file(target_scene)
	else:
		# 如果你在 RunManager 节点的检查器里忘记拖入文件，就会弹这个提示
		OS.alert("本局随机到的 Boss 场景文件路径未正确配置！(请检查大地图中的 RunManager 节点)", "提示")
		# 没文件的话，暂时先还原视角，方便你继续在大地图测试游戏
		_on_choose_retreat()

# 选项 B：选择撤退（拒绝战斗）
func _on_choose_retreat() -> void:
	print("【系统】玩家选择撤退，视角还原。")
	if _player_ref:
		# 还原回您原本的常态视角 (2.5, 2.5)
		_zoom_camera(_player_ref, default_zoom)
		
		# 短暂关闭 1 秒钟的碰撞监测，防止玩家站在原地的物理边界上导致弹窗无限死循环弹出
		# 玩家需要走开并重新走近才会再次触发
		monitoring = false
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func(): monitoring = true)

# 相机平滑变换控制（Tween 动画）
func _zoom_camera(player: Node2D, target_zoom: Vector2) -> void:
	var cam = player.find_child("Camera2D", true, false)
	if cam is Camera2D:
		var tween = create_tween()
		tween.tween_property(cam, "zoom", target_zoom, 0.8).set_trans(Tween.TRANS_CUBIC)
