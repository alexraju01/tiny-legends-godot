extends CharacterBody2D

enum State { IDLE, RUNNING, ATTACK, BLOCK }

var current_state: State = State.IDLE
var hitbox_offset: Vector2 
var health_bar: TextureProgressBar

# --- XP & Leveling Variables ---
var current_xp: int = 0
var current_level: int = 1

@export_group("Leveling")
@export var xp_curve: Curve # Drag your exponential curve here in the Inspector
@export var max_level: int = 100
@export var base_xp_requirement: int = 50 # This matches the "50" in your image_5855fc.png

# --- Node References ---
@onready var stats_handler: StatsHandler = $StatsHandler
@onready var hitbox: Area2D = $HitBox
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export_group("Visuals")
@export var death_effect_scene: PackedScene
@export_group("UI")
@export var health_bar_scene: PackedScene

func _ready() -> void:
	if stats_handler:
		if stats_handler.stats_data.has_signal("health_depleted"):
			stats_handler.stats_data.health_depleted.connect(die)
		
		stats_handler.stats_data.health_changed.connect(_on_stats_health_changed)
		stats_handler.update_all_stats()

	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	hitbox_offset = hitbox.position
	hitbox.monitoring = false
	
	if health_bar_scene:
		setup_health_bar()

# --- Experience Logic ---

func add_experience(amount: int) -> void:
	current_xp += amount
	print("Gained %d XP. Total: %d" % [amount, current_xp])
	_check_level_up()

func _check_level_up() -> void:
	var xp_required = get_xp_required_for_level(current_level)
	
	# Loop in case we gain enough XP to level up multiple times at once
	while current_xp >= xp_required and current_level < max_level:
		current_xp -= xp_required
		current_level += 1
		_perform_level_up()
		
		# Update requirement for the next loop iteration
		xp_required = get_xp_required_for_level(current_level)

func get_xp_required_for_level(level: int) -> int:
	if not xp_curve:
		return base_xp_requirement * level # Fallback if curve isn't assigned
	
	# Sample the curve based on level progress (0.0 to 1.0)
	var sample_pos = float(level) / float(max_level)
	var curve_value = xp_curve.sample(sample_pos)
	
	# Multiply curve value (0-1) by a large number or scale it by base XP
	# Based on image_5855fc.png, your Max Value is 200.0
	return int(curve_value * 200.0) + base_xp_requirement

func _perform_level_up() -> void:
	print("LEVEL UP! Reached Level: %d" % current_level)
	
	# 1. Update Stats (Example: +10 Max Health per level)
	stats_handler.stats_data.max_health += 10
	stats_handler.current_health = stats_handler.stats_data.max_health
	
	# 2. Update UI
	if health_bar:
		health_bar.max_value = stats_handler.stats_data.max_health
		health_bar.value = stats_handler.current_health
	
	# 3. Show Level Up Visual (Optional)
	# If you have a Label or AnimationPlayer, trigger it here:
	# $UI/LevelUpLabel.text = "LEVEL UP!"
	# $UI/AnimationPlayer.play("LevelUpGlow")

# --- Existing Logic ---

func _on_stats_health_changed(cur_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = cur_health

func setup_health_bar() -> void:
	var bar_instance = health_bar_scene.instantiate()
	if bar_instance is TextureProgressBar:
		health_bar = bar_instance
	else:
		health_bar = bar_instance.find_child("*", true) as TextureProgressBar
		
	add_child(bar_instance)
	bar_instance.position = Vector2(-50, 0)
	
	health_bar.max_value = stats_handler.stats_data.max_health
	health_bar.value = stats_handler.current_health

func _physics_process(_delta: float) -> void:
	if current_state == State.ATTACK:
		return 

	if Input.is_action_just_pressed("Attack"):
		attack()
		return 

	process_movement()
	move_and_slide()

func process_movement() -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = direction * stats_handler.stats_data.base_move_speed
	current_state = State.IDLE if direction == Vector2.ZERO else State.RUNNING
	
	if direction.x != 0:
		animated_sprite_2d.flip_h = (direction.x < 0)
		print(direction.x < 0)
		update_hitbox_direction()

	_play_state_animation()

func attack() -> void:
	current_state = State.ATTACK
	velocity = Vector2.ZERO 
	hitbox.monitoring = true 
	animated_sprite_2d.play("Attack")

func _play_state_animation() -> void:
	match current_state:
		State.IDLE: 
			animated_sprite_2d.play("Idle")
		State.RUNNING: 
			animated_sprite_2d.play("Running_Right")

func _on_animation_finished() -> void:
	if animated_sprite_2d.animation == "Attack":
		current_state = State.IDLE
		hitbox.monitoring = false

func update_hitbox_direction() -> void:
	var direction_multiplier := -1.0 if animated_sprite_2d.flip_h else 1.0
	hitbox.position.x = hitbox_offset.x * direction_multiplier

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(stats_handler.stats_data.attack, global_position)

func take_damage(amount: int, _attacker_position: Vector2 = Vector2.ZERO) -> void:
	var final_damage = max(1, amount - stats_handler.stats_data.defence)
	stats_handler.current_health -= final_damage
	
	if health_bar:
		health_bar.value = stats_handler.current_health
		
	if stats_handler.current_health <= 0:
		die()

func die() -> void:
	spawn_death_effect()
	queue_free()

func spawn_death_effect() -> void:
	if death_effect_scene:
		var effect = death_effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position + Vector2(0.0, -20.0)
