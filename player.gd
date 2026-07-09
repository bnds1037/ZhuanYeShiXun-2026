extends CharacterBody2D

# 强类型规范：移动速度
@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
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
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()
