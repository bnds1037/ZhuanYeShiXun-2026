extends Node2D

var paddle: CharacterBody2D
var ball: CharacterBody2D
var bricks: Node2D

var paddle_speed = 600.0
var ball_speed = 400.0
var brick_rows = 5
var brick_cols = 10
var brick_width = 60
var brick_height = 20
var brick_padding = 5
var brick_offset_x = 35
var brick_offset_y = 60

var ball_direction = Vector2(1, -1).normalized()
var ball_is_moving = false
var screen_size: Vector2

func _ready():
    paddle = $Paddle
    ball = $Ball
    bricks = $Bricks
    
    screen_size = get_viewport_rect().size
    
    setup_paddle()
    setup_ball()
    create_bricks()

func setup_paddle():
    var collider = paddle.get_node("PaddleCollider")
    collider.shape = RectangleShape2D.new()
    collider.shape.size = Vector2(120, 15)
    
    var sprite = paddle.get_node("PaddleSprite")
    var texture = create_rectangle_texture(0.3, 0.6, 1.0)
    sprite.texture = texture
    sprite.scale = Vector2(120, 15)
    
    paddle.position = Vector2(screen_size.x / 2, screen_size.y - 50)

func setup_ball():
    var collider = ball.get_node("BallCollider")
    collider.shape = CircleShape2D.new()
    collider.shape.radius = 10
    
    var sprite = ball.get_node("BallSprite")
    var texture = create_circle_texture(1.0, 0.3, 0.3)
    sprite.texture = texture
    sprite.scale = Vector2(20, 20)
    
    reset_ball()

func create_rectangle_texture(r: float, g: float, b: float) -> ImageTexture:
    var image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
    image.fill(Color(r, g, b))
    var texture = ImageTexture.create_from_image(image)
    return texture

func create_circle_texture(r: float, g: float, b: float) -> ImageTexture:
    var size = 32
    var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
    image.fill(Color(0, 0, 0, 0))
    
    for x in range(size):
        for y in range(size):
            var dx = x - size / 2
            var dy = y - size / 2
            var dist = sqrt(dx * dx + dy * dy)
            if dist <= size / 2:
                image.set_pixel(x, y, Color(r, g, b))
    
    var texture = ImageTexture.create_from_image(image)
    return texture

func create_bricks():
    var color_list = [
        [1.0, 0.2, 0.2],
        [1.0, 0.6, 0.2],
        [1.0, 1.0, 0.2],
        [0.2, 1.0, 0.2],
        [0.2, 0.6, 1.0]
    ]
    
    for row in range(brick_rows):
        for col in range(brick_cols):
            var brick = StaticBody2D.new()
            brick.name = "Brick_%d_%d" % [row, col]
            
            var collider = CollisionShape2D.new()
            collider.name = "BrickCollider"
            var shape = RectangleShape2D.new()
            shape.size = Vector2(brick_width, brick_height)
            collider.shape = shape
            brick.add_child(collider)
            
            var sprite = Sprite2D.new()
            sprite.name = "BrickSprite"
            var texture = create_rectangle_texture(color_list[row][0], color_list[row][1], color_list[row][2])
            sprite.texture = texture
            sprite.scale = Vector2(brick_width, brick_height)
            brick.add_child(sprite)
            
            brick.position = Vector2(
                brick_offset_x + col * (brick_width + brick_padding),
                brick_offset_y + row * (brick_height + brick_padding)
            )
            
            bricks.add_child(brick)

func reset_ball():
    ball.position = Vector2(screen_size.x / 2, screen_size.y - 80)
    ball_direction = Vector2(1, -1).normalized()
    ball_is_moving = false

func _input(event):
    if event.is_action("ui_accept") and not ball_is_moving:
        ball_is_moving = true

func _physics_process(delta):
    move_paddle(delta)
    if ball_is_moving:
        move_ball(delta)

func move_paddle(delta):
    var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    
    paddle.velocity = Vector2(input_dir * paddle_speed, 0)
    paddle.move_and_slide()
    
    paddle.position.x = clamp(paddle.position.x, 60, screen_size.x - 60)

func move_ball(delta):
    var next_pos = ball.position + ball_direction * ball_speed * delta
    
    if next_pos.x - 10 <= 0 or next_pos.x + 10 >= screen_size.x:
        ball_direction.x *= -1
    
    if next_pos.y - 10 <= 0:
        ball_direction.y *= -1
    
    if next_pos.y + 10 >= screen_size.y:
        reset_ball()
        return
    
    var paddle_rect = Rect2(
        paddle.position - Vector2(60, 7.5),
        Vector2(120, 15)
    )
    var ball_next_rect = Rect2(
        next_pos - Vector2(10, 10),
        Vector2(20, 20)
    )
    
    if paddle_rect.intersects(ball_next_rect) and ball_direction.y > 0:
        ball_direction.y *= -1
        var hit_pos = (next_pos.x - paddle.position.x) / 60
        ball_direction.x = hit_pos
        ball_direction = ball_direction.normalized()
    
    ball.position += ball_direction * ball_speed * delta
    
    check_brick_collisions()

func check_brick_collisions():
    var ball_rect = Rect2(
        ball.position - Vector2(10, 10),
        Vector2(20, 20)
    )
    
    for brick in bricks.get_children():
        var brick_rect = Rect2(
            brick.position - Vector2(brick_width / 2, brick_height / 2),
            Vector2(brick_width, brick_height)
        )
        
        if ball_rect.intersects(brick_rect):
            ball_direction.y *= -1
            brick.queue_free()
            break