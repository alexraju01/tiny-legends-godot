@tool
extends Resource
class_name Stats

@export_group("Base Stats")
@export var base_max_health: int = 100: set = _set_base_max_health
@export var base_defence: int = 10: set = _set_base_defence
@export var base_attack: int = 10: set = _set_base_attack
@export var base_move_speed: int = 300: set = _set_base_move_speed
@export var base_xp_reward: int = 50: set = _set_base_xp_reward

@export_group("Calculated Stats (Read Only)")
@export var max_health: int
@export var attack: int
@export var defence: int
@export var xp_reward: int
@export var xp_to_next_level: int # Moved here so it shows in Inspector

@export_group("Curves")
@export var health_curve: Curve
@export var defence_curve: Curve
@export var attack_curve: Curve
@export var xp_curve: Curve

@export_group("Player Leveling")
@export var base_xp_required: int = 100: set = _set_base_xp_required
@export var xp_required_curve: Curve: set = _set_xp_required_curve

signal health_depleted 
signal health_changed(cur_health: int, max_health: int)

func calculate_for_level(level: int, silent: bool = false) -> void:
	# Calculate all stats first
	max_health = get_stat_for_level(base_max_health, health_curve, level)
	attack = get_stat_for_level(base_attack, attack_curve, level)
	defence = get_stat_for_level(base_defence, defence_curve, level)
	
	# Calculate XP Reward (for enemies)
	xp_reward = get_stat_for_level(base_xp_reward, xp_curve, level)
	
	# Calculate XP Threshold (for player)
	xp_to_next_level = get_stat_for_level(base_xp_required, xp_required_curve, level)
	
	# Emit signal once everything is calculated
	if not silent:
		emit_changed()

func get_stat_for_level(base_val, curve: Curve, level: int) -> int:
	# Check for null or Nil to prevent "Invalid type" error
	if base_val == null: 
		return 0
		
	var pos = clampf(float(level - 1) / 100.0, 0.0, 1.0)
	var multiplier = curve.sample(pos) if curve else 1.0
	
	# Ensure the result is at least 0 to avoid string formatting errors
	return max(0, int(base_val * multiplier))

# --- Setters ---

func _set_base_max_health(v): base_max_health = v; emit_changed()
func _set_base_defence(v): base_defence = v; emit_changed()
func _set_base_attack(v): base_attack = v; emit_changed()
func _set_base_move_speed(v): base_move_speed = v; emit_changed()
func _set_base_xp_reward(v): base_xp_reward = v; emit_changed()
func _set_base_xp_required(v): base_xp_required = v; emit_changed()
func _set_xp_required_curve(v): xp_required_curve = v; emit_changed()
