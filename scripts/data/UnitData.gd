extends Resource
class_name UnitData

# Data-Driven Unit Configuration
# Single Responsibility: Store unit statistics and configuration

@export var unit_id: String
@export var unit_name: String
@export var description: String
@export var unit_type: String  # "ground", "air", "structure"

# Stats
@export var max_health: float = 100.0
@export var armor: float = 0.0
@export var move_speed: float = 100.0
@export var attack_damage: float = 25.0
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 1.5
@export var sight_range: float = 200.0

# Costs
@export var spice_cost: int = 100
@export var build_time: float = 5.0
@export var power_required: int = 1
@export var population_cost: int = 1

# Special Abilities
@export var abilities: Array[String] = []
@export var special_properties: Dictionary = {}

# Visual/Audio
@export var texture_path: String
@export var sounds: Dictionary = {}

# Prerequisites
@export var required_buildings: Array[String] = []
@export var required_tech: Array[String] = []

func can_be_built(faction_buildings: Array, faction_tech: Array) -> bool:
	# Check building requirements
	for required_building in required_buildings:
		var has_building = false
		for building in faction_buildings:
			if building.building_name == required_building:
				has_building = true
				break
		if not has_building:
			return false
	
	# Check tech requirements
	for required_tech_item in required_tech:
		if required_tech_item not in faction_tech:
			return false
	
	return true

func get_costs() -> Dictionary:
	return {
		"spice": spice_cost,
		"power": power_required,
		"population": population_cost
	}

func get_stat(stat_name: String) -> float:
	match stat_name.to_lower():
		"health", "max_health":
			return max_health
		"armor":
			return armor
		"speed", "move_speed":
			return move_speed
		"damage", "attack_damage":
			return attack_damage
		"range", "attack_range":
			return attack_range
		"cooldown", "attack_cooldown":
			return attack_cooldown
		"sight", "sight_range":
			return sight_range
		_:
			if special_properties.has(stat_name):
				return special_properties[stat_name]
			return 0.0
