extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	ATTACK,
	BLOCK
}

@export_category("Stats")
@export var speed: int = 300

var state:State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	movement_loop()
	
	
	
func movement_loop() -> void:
	# 1. ATTACK LOCK (Highest Priority)
	if state == State.ATTACK:
		if $AnimatedSprite2D.is_playing() and $AnimatedSprite2D.animation == "Attack":
			return 
		else:
			state = State.IDLE

	# 2. TRIGGER ATTACK
	if Input.is_action_just_pressed("Attack"):
		state = State.ATTACK
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("Attack")
		return

	# 3. BLOCK LOGIC (Hold to Block)
	if Input.is_action_pressed("Block"):
		state = State.BLOCK
		velocity = Vector2.ZERO # Usually you stay still while blocking
		$AnimatedSprite2D.play("Block") # Ensure you have a "Block" animation
		return 
	
	# Reset state if we just stopped blocking
	if state == State.BLOCK and not Input.is_action_pressed("Block"):
		state = State.IDLE

	# 4. MOVEMENT & NORMAL ANIMATIONS
	var input_direction := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_direction * speed
	move_and_slide()

	if velocity.length() > 0:
		state = State.RUNNING
		$AnimatedSprite2D.play("Running")
		$AnimatedSprite2D.flip_h = velocity.x < 0 if velocity.x != 0 else $AnimatedSprite2D.flip_h
	else:
		state = State.IDLE
		$AnimatedSprite2D.play("Idle")
