extends CharacterBody2D


@export_category("Stats")
@export var hitpoints: int = 20

const SPEED = 300.0
var is_dead: bool = false
#const JUMP_VELOCITY = -400.0


#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)

	#move_and_slide()





func take_damage(damage_taken:int) -> void:
	if is_dead: return
	
	hitpoints -= damage_taken
	if hitpoints <= 0:
		death()
	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func death() -> void:
	is_dead = true 
	
	# 1. Disable the physical body (stops bumping into the player)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 2. Disable the damage-taking area (stops the 'ghost' hits)
	# Replace "HurtBox" with the actual name of your Area2D node
	if has_node("HurtBox"):
		$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	
	$AnimatedSprite2D.play("Death")
	
	await $AnimatedSprite2D.animation_finished
	queue_free()
