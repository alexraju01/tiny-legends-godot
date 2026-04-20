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

func _physics_process(_delta: float) -> void:
	movement_loop()

func movement_loop() -> void:
	# 1. ATTACK LOCK
	# We now check the AnimationPlayer instead of the Sprite
	if state == State.ATTACK:
		if $AnimationPlayer.is_playing():
			return 
		else:
			state = State.IDLE
#@onready var animation_player: AnimationPlayer = $HitBox/AnimationPlayer

	# 2. TRIGGER ATTACK
	if Input.is_action_just_pressed("Attack"):
		state = State.ATTACK
		velocity = Vector2.ZERO
		# FIX: Use AnimationPlayer so the HitBox actually moves!
		$AnimationPlayer.play("Attack")
		#$AnimatedSprite2D.play("Attack")
		return

	# 3. BLOCK LOGIC
	if Input.is_action_pressed("Block"):
		state = State.BLOCK
		velocity = Vector2.ZERO 
		$AnimatedSprite2D.play("Block")
		return 
	
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
		if state != State.ATTACK: # Don't override attack animation
			state = State.IDLE
			$AnimatedSprite2D.play("Idle")

# 5. DAMAGE LOGIC
func _on_hit_box_area_entered(area: Area2D) -> void:
	# Safeguard: only call take_damage if the enemy actually has the function
	if area.owner and area.owner.has_method("take_damage"):
		area.owner.take_damage(attack_damage)
		print("+", attack_damage, " damage dealt to ", area.owner.name)
	#else:
		#print("Hit something, but it has no take_damage function!")
