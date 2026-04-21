extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	ATTACK,
	BLOCK
}

@export_category("Stats")
@export var speed: int = 300
@export var attack_damage: int = 10

var state: State = State.IDLE
var facing_direction := 1 # 1 = right, -1 = left

func _physics_process(_delta: float) -> void:
	movement_loop()

func movement_loop() -> void:
	# 1. ATTACK LOCK
	if state == State.ATTACK:
		if $AnimationPlayer.is_playing():
			return 
		else:
			state = State.IDLE

	# 2. TRIGGER ATTACK
	if Input.is_action_just_pressed("Attack"):
		state = State.ATTACK
		velocity = Vector2.ZERO

		# ❌ IMPORTANT: reset flip so attack isn't affected
		$AnimatedSprite2D.flip_h = false

		# ✅ Play correct attack animation
		if facing_direction < 0:
			$AnimationPlayer.play("AttackLeft")
		else:
			$AnimationPlayer.play("Attack")

		return

	# 3. BLOCK LOGIC
	if Input.is_action_pressed("Block"):
		state = State.BLOCK
		velocity = Vector2.ZERO 
		$AnimatedSprite2D.play("Block")
		return 
	
	if state == State.BLOCK and not Input.is_action_pressed("Block"):
		state = State.IDLE

	# 4. MOVEMENT
	var input_direction := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_direction * speed
	move_and_slide()

	# ✅ Update direction + flip ONLY during movement
	if velocity.x != 0:
		facing_direction = sign(velocity.x)
		$AnimatedSprite2D.flip_h = facing_direction < 0

	# 5. ANIMATIONS
	if velocity.length() > 0:
		state = State.RUNNING
		$AnimatedSprite2D.play("Running")
	else:
		if state != State.ATTACK:
			state = State.IDLE
			$AnimatedSprite2D.play("Idle")

# DAMAGE
func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.has_method("take_damage"):
		area.owner.take_damage(attack_damage)
		print("+", attack_damage, " damage dealt to ", area.owner.name)
