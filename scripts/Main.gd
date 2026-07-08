extends Node2D

@onready var paddle = $Paddle
@onready var ball = $Ball
@onready var bricks_container = $Bricks
@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel
@onready var start_label = $StartLabel

var score = 0
var lives = 3
var game_running = false
var brick_count = 0
var ball_speed = 300

func _ready():
    load_bricks()

func load_bricks():
    var colors = [
        Color(1, 0.3, 0.3),
        Color(1, 0.6, 0.3),
        Color(1, 0.9, 0.3),
        Color(0.6, 1, 0.3),
        Color(0.3, 1, 0.6)
    ]
    
    for row in range(5):
        for col in range(10):
            var brick = StaticBody2D.new()
            brick.position = Vector2(35 + col * 78, 60 + row * 28)
            
            var sprite = Sprite2D.new()
            var texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
            texture.get_image().set_pixel(0, 0, colors[row])
            sprite.texture = texture
            sprite.scale = Vector2(70, 20)
            brick.add_child(sprite)
            
            var collision = CollisionShape2D.new()
            var shape = RectangleShape2D.new()
            shape.size = Vector2(70, 20)
            collision.shape = shape
            brick.add_child(collision)
            
            brick.name = "Brick_" + str(row) + "_" + str(col)
            brick.body_entered.connect(_on_brick_hit)
            bricks_container.add_child(brick)
            brick_count += 1

func _input(event):
    if Input.is_action_just_pressed("ui_accept") and not game_running:
        start_game()

func start_game():
    game_running = true
    score = 0
    lives = 3
    update_ui()
    start_label.visible = false
    
    for child in bricks_container.get_children():
        child.queue_free()
    load_bricks()
    
    reset_ball()

func reset_ball():
    ball.position = Vector2(400, 540)
    ball.linear_velocity = Vector2(0, 0)
    paddle.position = Vector2(400, 560)
    
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var direction = Vector2(rng.rand_range(-0.7, 0.7), -1).normalized()
    ball.linear_velocity = direction * ball_speed

func update_ui():
    score_label.text = "Score: %d" % score
    lives_label.text = "Lives: %d" % lives

func _physics_process(delta):
    if not game_running:
        return
    
    var input_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    paddle.velocity.x = input_dir * 500
    
    if paddle.position.x - 60 < 15:
        paddle.position.x = 75
        paddle.velocity.x = 0
    elif paddle.position.x + 60 > 785:
        paddle.position.x = 725
        paddle.velocity.x = 0
    
    paddle.move_and_collide(paddle.velocity * delta)
    
    if ball.position.y > 620:
        lives -= 1
        update_ui()
        
        if lives <= 0:
            game_running = false
            start_label.text = "Game Over! Press ENTER to Restart"
            start_label.visible = true
        else:
            reset_ball()

func _on_brick_hit(body):
    if body.name == "Ball":
        score += 10
        brick_count -= 1
        update_ui()
        
        for child in bricks_container.get_children():
            if child.has_node("CollisionShape2D"):
                if child.get_node("CollisionShape2D").is_colliding():
                    child.queue_free()
                    break
        
        if brick_count <= 0:
            game_running = false
            start_label.text = "Level Complete! Press ENTER to Restart"
            start_label.visible = true