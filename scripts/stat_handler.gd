@tool
extends Node
class_name StatsHandler

@export var stats_data: Stats: set = _set_stats_data

@export var level: int = 1: 
	set(v):
		level = v
		update_all_stats()
		notify_property_list_changed()

var current_health: int

func _ready():
	# In-game: Duplicate the resource so each enemy has unique live stats
	if not Engine.is_editor_hint() and stats_data:
		stats_data = stats_data.duplicate()
	
	update_all_stats()
	
	if not Engine.is_editor_hint() and stats_data:
		current_health = stats_data.max_health

func update_all_stats():
	if not stats_data: 
		return
	
	stats_data.set_block_signals(true)
	stats_data.calculate_for_level(level)
	stats_data.set_block_signals(false)
	
	notify_property_list_changed()
	
	if Engine.is_editor_hint() and is_inside_tree() and get_parent():
		var parent_name = get_parent().name
		var common_stats = "Lvl: %d | HP: %d | ATK: %d | DEF: %d" % [
			level, 
			stats_data.max_health, 
			stats_data.attack,
			stats_data.defence
		]
		
		# Check if this is a Player (has an XP requirement curve assigned)
		if stats_data.xp_required_curve != null:
			print("[%s] (Player) %s | XP Needed: %d" % [
				parent_name, 
				common_stats, 
				stats_data.xp_to_next_level
			])
		# Otherwise, assume it's an Enemy (has an XP reward)
		else:
			print("[%s] (Enemy) %s | XP Reward: %d" % [
				parent_name, 
				common_stats, 
				stats_data.xp_reward
			])

func _set_stats_data(v):
	# If we are swapping resources, disconnect the old one first
	if stats_data and stats_data.changed.is_connected(update_all_stats):
		stats_data.changed.disconnect(update_all_stats)
		
	stats_data = v
	
	if stats_data:
		if not stats_data.changed.is_connected(update_all_stats):
			stats_data.changed.connect(update_all_stats)
		update_all_stats()
