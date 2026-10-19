extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -500
const GRAVITY = 980


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("Movibles"):
			collider.apply_central_impulse(collision.get_normal()*-10)
	if (Input.is_action_pressed("ui_up") or Input.is_action_pressed("up_second")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("left_second"):
		direction = -1
	if Input.is_action_pressed("right_second") or Input.is_action_pressed("ui_right"):
		direction = 1
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		$Sprite2D.play("idle")
		
	if velocity.y < 0:
		$Sprite2D.play("jump")
	elif velocity.y > 0:
		$Sprite2D.play("fall")
	elif velocity.y == 0 and direction == 1:
		$Sprite2D.play("walk")
		$Sprite2D.flip_h = false
	elif velocity.y == 0 and direction == -1:
		$Sprite2D.play("walk")
		$Sprite2D.flip_h = true
	

	move_and_slide()
