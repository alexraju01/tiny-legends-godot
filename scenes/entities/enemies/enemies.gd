extends CharacterBody2D

signal died(exp:int)

enum State{
	IDLE,
	CHASE,
	RETURN,
	ATTACK,
	DEAD,
}



@export_category("Stats")
@export var speed: int = 120
@export var attack_damage: int = 10
@export var attack_speed: float = 1.0
@export var hitpoints: int = 20
@export var aggro_range: float = 256
@export var attack_range: float = 80
@export var exp_reward: int = 600
@export_category("Related Scenes")
@export var death_packed:PackedScene


var state: State = State.IDLE
@onready var spawn_point: Vector2 = global_position
#@onready var animation_tree: AnimationTree = $AnimationTree
# Remove the old animation_tree and animation_playback lines
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
#@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]


const SPEED = 300.0
var is_dead: bool = false
#const JUMP_VELOCITY = -400.0



func take_damage(damage_taken:int) -> void:
	if is_dead: return
	
	hitpoints -= damage_taken
	if hitpoints <= 0:
		death()
		
func death() -> void:
	died.emit(exp_reward)
	var death_scene: Node2D = death_packed.instantiate()
	death_scene.position = global_position + Vector2(0.0, -32.0)
	%Effects.add_child(death_scene)
	queue_free()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return
	
	if state == State.ATTACK:
		return
		
	if distance_to_player() <= attack_range:
		state = State.ATTACK
		attack()
	elif distance_to_player() <= aggro_range:
		state = State.CHASE
		move()
	elif global_position.distance_to(spawn_point) > 32:
		state = State.RETURN
		move()
	elif state != State.IDLE:
		state = State.IDLE
		update_animation()


func distance_to_player() -> float:
	# is_instance_valid checks if the player node still exists in memory
	if is_instance_valid(player):
		return global_position.distance_to(player.global_position)
	else:
		return 10000.0 # Return a large number so the enemy thinks player is far away
func update_animation():
	match state:
		State.IDLE:
			sprite.play("Idle")
		State.CHASE, State.RETURN:
			sprite.play("Running")
		State.ATTACK:
			sprite.play("Attack")

func move():
	var target_pos = player.global_position if state == State.CHASE else spawn_point
	var direction = (target_pos - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	# Flip sprite to face movement direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		
	update_animation()
	
func attack() -> void:
	var player_pos: Vector2 = player.global_position
	var attack_dir: Vector2 = (player_pos - global_position).normalized()
	
	if attack_dir.x != 0:
		sprite.flip_h = attack_dir.x < 0
	
	state = State.ATTACK
	
	# ✅ Use AnimationPlayer so the HitBox tracks actually move
	$AnimationPlayer.play("Attack")
	
	# Wait for the animation to finish instead of a generic timer
	await $AnimationPlayer.animation_finished
	
	if state != State.DEAD:
		state = State.IDLE
		update_animation()


# Connect this signal from the Enemy's HitBox Area2D
#func _on_hit_box_area_entered(area: Area2D) -> void:
	##if area.owner and area.owner.has_method("player_take_damage"):
	#
		#area.owner.take_damage(attack_damage)
		#print("Enemy dealt ", attack_damage, " damage to Player")

func _on_hit_box_area_entered(area: Area2D) -> void:
	var victim = area.owner
	
	# 1. Check if victim exists
	# 2. Check if victim is player
	# 3. CRITICAL: Check if the player is already dead!
	if victim and victim.is_in_group("player"):
		if victim.is_dead: 
			print("Enemy ignores dead player.")
			return
			
		if victim.has_method("take_damage"):
			victim.take_damage(attack_damage)
			print("Enemy dealt ", attack_damage, " damage to Player")
