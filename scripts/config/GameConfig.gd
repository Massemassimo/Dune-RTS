extends Resource
class_name GameConfig

# Game Configuration System
# Single Responsibility: Centralized game balance and configuration

@export_group("Game Balance")
@export var starting_resources: Dictionary = {
	ResourceManager.ResourceType.SPICE: 1000,
	ResourceManager.ResourceType.POWER: 100,
	ResourceManager.ResourceType.POPULATION: 50
}

@export var resource_collection_rates: Dictionary = {
	"spice_per_second": 25,
	"power_decay_rate": 0.1
}

@export_group("Unit Defaults")
@export var default_unit_stats: Dictionary = {
	"health": 100.0,
	"armor": 0.0,
	"speed": 100.0,
	"damage": 25.0,
	"range": 150.0,
	"cooldown": 1.5,
	"sight_range": 200.0
}

@export_group("Combat")
@export var damage_variance: float = 0.1  # ±10% damage variance
@export var armor_effectiveness: float = 1.0
@export var critical_hit_chance: float = 0.05  # 5% crit chance
@export var critical_hit_multiplier: float = 1.5

@export_group("Economy")
@export var inflation_rate: float = 1.0
@export var trade_efficiency: float = 0.95
@export var resource_storage_multiplier: float = 1.0

@export_group("UI Settings")
@export var ui_scale: float = 1.0
@export var show_debug_info: bool = false
@export var auto_save_interval: int = 300  # seconds

@export_group("Performance")
@export var max_units_per_faction: int = 200
@export var max_buildings_per_faction: int = 50
@export var unit_culling_distance: float = 1000.0
@export var pathfinding_update_frequency: float = 0.1

# Faction-specific modifiers
@export_group("Faction Modifiers")
@export var faction_modifiers: Dictionary = {
	GlobalEnums.Faction.ATREIDES: {
		"unit_cost_multiplier": 1.0,
		"building_cost_multiplier": 1.0,
		"unit_health_multiplier": 1.0,
		"special_abilities": ["sonic_tank", "fremen_warriors"]
	},
	GlobalEnums.Faction.HARKONNEN: {
		"unit_cost_multiplier": 0.9,
		"building_cost_multiplier": 1.1,
		"unit_health_multiplier": 1.1,
		"special_abilities": ["devastator", "death_hand"]
	},
	GlobalEnums.Faction.ORDOS: {
		"unit_cost_multiplier": 1.1,
		"building_cost_multiplier": 0.9,
		"unit_health_multiplier": 0.9,
		"special_abilities": ["deviator", "saboteur"]
	}
}

# Tech tree configuration
@export_group("Technology")
@export var tech_tree: Dictionary = {
	"concrete": {
		"cost": {"spice": 50},
		"time": 30,
		"unlocks": ["gun_turret", "rocket_turret"]
	},
	"hi_tech": {
		"cost": {"spice": 200},
		"time": 120,
		"prerequisites": ["concrete"],
		"unlocks": ["ornithopter", "sonic_tank"]
	}
}

# Map generation settings
@export_group("World Generation")
@export var map_size: Vector2 = Vector2(64, 64)
@export var spice_deposit_count: int = 15
@export var spice_deposit_size_range: Vector2 = Vector2(50, 200)
@export var rock_formation_density: float = 0.3

func get_faction_modifier(faction: GlobalEnums.Faction, modifier_name: String) -> float:
	if faction_modifiers.has(faction) and faction_modifiers[faction].has(modifier_name):
		return faction_modifiers[faction][modifier_name]
	return 1.0

func get_unit_stat_modified(base_stat: float, stat_name: String, faction: GlobalEnums.Faction) -> float:
	var modifier_name = stat_name + "_multiplier"
	var modifier = get_faction_modifier(faction, modifier_name)
	return base_stat * modifier

func has_faction_ability(faction: GlobalEnums.Faction, ability_name: String) -> bool:
	if faction_modifiers.has(faction) and faction_modifiers[faction].has("special_abilities"):
		return ability_name in faction_modifiers[faction]["special_abilities"]
	return false