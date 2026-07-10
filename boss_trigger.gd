extends Area2D

# 镜头缩放配置
@export var zoom_in_value: Vector2 = Vector2(5, 5)
var default_zoom: Vector2 = Vector2(2.5, 2.5)

# 内部状态变量
var _player_ref: Node2D = null
var _dialog: ConfirmationDialog = null

func _ready() -> void:
	# 监听玩家走过来的信号
	body_entered.connect(_on_body_entered)
	
	# 动态创建一个确认对话框
	_create_trigger_dialog()

# 创建“是否战斗”的弹窗（初始预留，后续会动态改名）
func _create_trigger_dialog() -> void:
	_dialog = ConfirmationDialog.new()
	_dialog.title = "遭遇强敌"
	_dialog.dialog_text = "前方妖气冲天，是否进入战斗？"
	_dialog.ok_button_text = "誓死一战"
	_dialog.cancel_button_text = "暂且撤退"
	
	# 连接对话框的信号
	_dialog.confirmed.connect(_on_choose_battle)         # 点击确认
	_dialog.canceled.connect(_on_choose_retreat)         # 点击取消或点叉
	
	# 将对话框添加为子节点
	add_child(_dialog)

# 玩家进入触发圈
func _on_body_entered(body: Node2D) -> void:
	# 检查进来的节点是不是玩家
	if body.name == "Player":
		_player_ref = body
		
		# 1. 视角平滑拉近
		_zoom_camera(_player_ref, zoom_in_value)
		
		# 2. 动态读取肉鸽系统决定的 Boss 名字和场景路径
		var run_manager = get_tree().current_scene.find_child("RunManager", true, false)
		if not run_manager and get_node_or_null("/root/RunManager"):
			run_manager = get_node("/root/RunManager")
			
		if run_manager and run_manager.current_run_boss_name != "":
			# 【高级肉鸽特性】：根据抽到的不同 Boss 动态修改弹窗文本
			_dialog.dialog_text = "前方妖气冲天，是否进入与【" + run_manager.current_run_boss_name + "】的战斗？"
		
		# 3. 弹出选择框
		_dialog.popup_centered()

# 选项 A：选择战斗（走向肉鸽决定的独立关卡）
func _on_choose_battle() -> void:
	print("【系统】玩家选择战斗！准备加载本局肉鸽锁定的对战场景...")
	
	var run_manager = get_tree().current_scene.find_child("RunManager", true, false)
	if not run_manager and get_node_or_null("/root/RunManager"):
		run_manager = get_node("/root/RunManager")
		
	if run_manager and run_manager.current_run_boss_path != "":
		print("【战斗系统】即将无缝切入独立卡牌战斗关卡场景：", run_manager.current_run_boss_path)
		get_tree().change_scene_to_file(run_manager.current_run_boss_path)
	else:
		# 兼容你测试：如果队友还没给独立 .tscn 或者 RunManager 路径没配
		OS.alert("战斗场景未配置！(请检查 RunManager 检查器中是否拖入了 BOSS 战斗关卡 .tscn 文件)", "提示")
		_on_choose_retreat()

# 选项 B：选择撤退（拒绝战斗，还原视角，短暂冷却触发器）
func _on_choose_retreat() -> void:
	print("【系统】玩家选择撤退，视角还原。")
	if _player_ref:
		_zoom_camera(_player_ref, default_zoom)
		
		# 短暂关闭碰撞再开启，防止玩家站在原地无限弹窗
		monitoring = false
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func(): monitoring = true)

# 相机平滑缩放控制
func _zoom_camera(player: Node2D, target_zoom: Vector2) -> void:
	var cam = player.find_child("Camera2D", true, false)
	if cam is Camera2D:
		var tween = create_tween()
		tween.tween_property(cam, "zoom", target_zoom, 0.8).set_trans(Tween.TRANS_CUBIC)
