extends Control

# 用一个临时变量记录玩家当前“点击选中”但还没点确认的英雄路径和名字
var temp_path: String = ""
var temp_name: String = ""

func _ready() -> void:
	# 1. 绑定 3 个英雄按钮的点击信号
	$HeroButton1.pressed.connect(_on_hero_clicked.bind(1, "巴巴托斯"))
	$HeroButton2.pressed.connect(_on_hero_clicked.bind(2, "兵长"))
	$HeroButton3.pressed.connect(_on_hero_clicked.bind(3, "猪灵"))
	
	# 2. 绑定确认按钮的点击信号
	$ConfirmButton.pressed.connect(_on_confirm_pressed)
	
	# 3. 游戏刚开始时，确认按钮不可点（因为还没选人）
	$ConfirmButton.disabled = true

# 玩家点击任意一个英雄按钮时触发
func _on_hero_clicked(index: int, hero_name: String) -> void:
	temp_name = hero_name
	
	# 根据索引，把对应的真实路径缓存起来
	if index == 1: temp_path = PlayerManager.HERO_1_PATH
	elif index == 2: temp_path = PlayerManager.HERO_2_PATH
	elif index == 3: temp_path = PlayerManager.HERO_3_PATH
	
	# 核心：实时把选中的名字显示在旁边的 Label 上！
	$NameLabel.text = "当前已选择: " + temp_name
	
	# 选了人之后，确认按钮激活可用
	$ConfirmButton.disabled = false
	print("【选人 UI】选中了: ", temp_name)

# 玩家最后点击“确认进入古墓”时触发
func _on_confirm_pressed() -> void:
	# 正式把结果登记到独立的全局管家里
	PlayerManager.selected_player_path = temp_path
	PlayerManager.selected_player_name = temp_name
	
	print("【选人 UI】携角色 [", temp_name, "] 正式切入大地图关卡！")
	
	# === 跨场景流转 ===
	# 销毁当前选人场景，完全跳转加载你的主大地图场景
	get_tree().change_scene_to_file("res://main_level.scn")
