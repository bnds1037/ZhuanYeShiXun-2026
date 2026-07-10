extends CharacterBody2D

# 强类型规范：移动速度
@export var speed: float = 200.0

# ==== 【规范】声明四方向精致节点变量 ====
var anim_right: AnimatedSprite2D
var anim_left: AnimatedSprite2D
var anim_up: AnimatedSprite2D
var anim_down: AnimatedSprite2D

func _ready() -> void:
	# 开局立刻动态加载并穿上选人界面定好的皮肤
	_apply_selected_hero_skin()

func _apply_selected_hero_skin() -> void:
	# 💡 加一个防套娃锁：如果当前节点已经是动态生成的“皮肤包”，就绝对不执行换装
	if self.name == "Skin":
		return

	if PlayerManager.selected_player_path != "":
		# 1. 拔掉当前场景树里预览用的旧方向节点（如果在编辑器里没删干净的话）
		for child in get_children():
			if "Anim_" in child.name:
				child.queue_free()
		
		# 2. 动态实例化选人界面决定的那个人物总场景
		var hero_scene = load(PlayerManager.selected_player_path) as PackedScene
		if not hero_scene: 
			print("【换装错误】无法加载角色场景文件: ", PlayerManager.selected_player_path)
			return
		
		var hero_instance = hero_scene.instantiate()
		
		hero_instance.set_script(null)
		
		hero_instance.name = "Skin" # 给它一个统一的容器外壳叫 Skin
		add_child(hero_instance)
		
		if "position" in hero_instance:
			hero_instance.position = Vector2.ZERO
			
		# 3. ==== 【核心】重新将你的控制变量精准对齐到新产生的克隆皮肤上 ====
		anim_right = hero_instance.get_node("Anim_Right")
		anim_left = hero_instance.get_node("Anim_Left")
		anim_up = hero_instance.get_node("Anim_Up")
		anim_down = hero_instance.get_node("Anim_Down")
		
		# 4. 开局时默认只显示正面，隐藏其余方向
		anim_right.hide()
		anim_left.hide()
		anim_up.hide()
		anim_down.show()
		if anim_down and anim_down.sprite_frames.has_animation("default"):
			anim_down.play("default")
			anim_down.stop() # 停在正面第一帧，做静止站立状
			
		print("【换装系统】大地图成功加载新皮肤: ", PlayerManager.selected_player_name)
	else:
		#  保底机制：如果你直接在编辑器里运行大地图测试（没经过选人UI），就直接拿当前自带的节点，防止报错
		anim_right = get_node_or_null("Anim_Right")
		anim_left = get_node_or_null("Anim_Left")
		anim_up = get_node_or_null("Anim_Up")
		anim_down = get_node_or_null("Anim_Down")

func _physics_process(_delta: float) -> void:
	#  如果由于某种意外换装没成功，或者开局直接测试且删光了节点，则直接退出不执行移动，防止后台疯狂报错
	if not anim_right or not anim_left or not anim_up or not anim_down:
		return

	# 强类型规范：初始化向量
	var direction: Vector2 = Vector2.ZERO
	
	# 绕过系统键位名字，直接监听键盘硬件，确保100%能接收到输入
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
		
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * speed
		
		# ==== 【四方向节点显隐状态机】 ====
		# 1. 只要在移动，先让所有皮肤隐形
		anim_right.hide()
		anim_left.hide()
		anim_up.hide()
		anim_down.hide()
		
		# 2. 比较水平和垂直移动的绝对值，谁大就显示谁的方向
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				anim_right.show()
				anim_right.play("default") # 让它播放同学做好的跑步循环
			else:
				anim_left.show()
				anim_left.play("default")
		else:
			if direction.y > 0:
				anim_down.show()
				anim_down.play("default")
			else:
				anim_up.show()
				anim_up.play("default")
				
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		# ==== 【静止状态处理】 ====
		# 当角色停下时，让当前显示的方向动画停止在第一帧（站立状态）
		if anim_right.visible: anim_right.stop()
		if anim_left.visible: anim_left.stop()
		if anim_up.visible: anim_up.stop()
		if anim_down.visible: anim_down.stop()

	move_and_slide()
