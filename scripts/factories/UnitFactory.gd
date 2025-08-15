extends Node
class_name UnitFactory

## Factory Pattern for Unit Creation
##
## Single Responsibility: Create and configure units from data-driven configuration files
## 
## This factory implements the Factory Pattern to create units based on configuration data
## stored in .tres resource files. It handles scene instantiation, data application, and
## provides validation for unit prerequisites (buildings, tech requirements).
##
## Usage Example:
## [codeblock]
## var factory = UnitFactory.new()
## var tank = factory.create_unit("tank", GlobalEnums.Faction.ATREIDES, Vector2(300, 300))
## if tank:
##     game_world.add_child(tank)
## [/codeblock]

## Cache of loaded UnitData resources indexed by unit_id
## Populated during load_unit_configurations()
var unit_data_cache: Dictionary = {}

## Cache of loaded scene resources for each unit type
## Indexed by unit_id, contains PackedScene objects ready for instantiation
var unit_scenes: Dictionary = {}

## Base path for unit configuration .tres files
const UNIT_DATA_PATH = "res://data/units/"

## Base path for unit scene .tscn files
const UNIT_SCENES_PATH = "res://scenes/units/"

func _ready():
	load_unit_configurations()

## Load and cache all unit configurations and their corresponding scenes
##
## Called automatically during _ready(). Loads all .tres configuration files
## and caches their corresponding .tscn scene files for fast unit creation.
##
## Side Effects:
## - Populates unit_data_cache with UnitData resources
## - Populates unit_scenes with PackedScene resources
## - Logs errors for missing files
func load_unit_configurations():
	# Load all unit data resources
	var unit_configs = [
		"infantry.tres",
		"tank.tres", 
		"harvester.tres"
	]
	
	for config_file in unit_configs:
		var unit_data = load(UNIT_DATA_PATH + config_file) as UnitData
		if unit_data:
			unit_data_cache[unit_data.unit_id] = unit_data
			
			# Cache scene references
			var scene_path = UNIT_SCENES_PATH + unit_data.unit_id.capitalize() + ".tscn"
			if ResourceLoader.exists(scene_path):
				unit_scenes[unit_data.unit_id] = load(scene_path)

## Create a fully configured unit from data configuration
## @param unit_id: Unit type identifier (e.g., "tank", "infantry", "harvester")
## @param faction: Which faction owns this unit
## @param position: World position to spawn the unit (defaults to Vector2.ZERO)
## @return: Configured Unit instance ready to add to scene, or null if creation failed
##
## This is the main factory method that handles:
## - Scene instantiation from cached PackedScene
## - Data application from cached UnitData
## - Position and faction assignment
##
## Example:
## [codeblock]
## var tank = unit_factory.create_unit("tank", GlobalEnums.Faction.ATREIDES, Vector2(300, 300))
## if tank:
##     game_world.add_child(tank)
##     GameEvents.emit_unit_created(tank)
## [/codeblock]
func create_unit(unit_id: String, faction: GlobalEnums.Faction, position: Vector2 = Vector2.ZERO) -> Unit:
	if not unit_data_cache.has(unit_id):
		push_error("Unknown unit type: " + unit_id)
		return null
	
	if not unit_scenes.has(unit_id):
		push_error("No scene found for unit: " + unit_id)
		return null
	
	var unit_data = unit_data_cache[unit_id]
	var scene = unit_scenes[unit_id]
	
	var unit = scene.instantiate() as Unit
	if not unit:
		push_error("Failed to instantiate unit: " + unit_id)
		return null
	
	# Configure unit with data
	configure_unit(unit, unit_data, faction)
	unit.global_position = position
	
	return unit

## Configure a unit instance with data from UnitData resource
## @param unit: Unit instance to configure
## @param data: UnitData resource containing stats and properties
## @param faction: Faction that will own this unit
##
## Applies all stats, properties, and special behaviors from the UnitData
## to the unit instance. Handles both standard properties and custom
## properties through reflection.
##
## Internal method used by create_unit()
func configure_unit(unit: Unit, data: UnitData, faction: GlobalEnums.Faction):
	# Apply stats from data
	unit.unit_name = data.unit_name
	unit.max_health = data.max_health
	unit.current_health = data.max_health
	unit.armor = data.armor
	unit.move_speed = data.move_speed
	unit.attack_damage = data.attack_damage
	unit.attack_range = data.attack_range
	unit.attack_cooldown = data.attack_cooldown
	unit.cost = data.spice_cost
	unit.faction = faction
	
	# Apply special properties
	for property_name in data.special_properties.keys():
		var property_value = data.special_properties[property_name]
		if unit.has_method("set_" + property_name):
			unit.call("set_" + property_name, property_value)
		elif property_name in unit:
			unit.set(property_name, property_value)

## Get the raw UnitData configuration for a unit type
## @param unit_id: Unit type identifier
## @return: UnitData resource or null if unit type doesn't exist
##
## Example:
## [codeblock]
## var tank_data = unit_factory.get_unit_data("tank")
## if tank_data:
##     print("Tank costs: %d spice" % tank_data.spice_cost)
## [/codeblock]
func get_unit_data(unit_id: String) -> UnitData:
	return unit_data_cache.get(unit_id, null)

## Get array of all available unit type identifiers
## @return: Array of String identifiers for all loaded unit types
##
## Example:
## [codeblock]
## var available = unit_factory.get_available_units()
## print("Available units: " + str(available))  # ["tank", "infantry", "harvester"]
## [/codeblock]
func get_available_units() -> Array[String]:
	return unit_data_cache.keys()

## Check if a faction meets prerequisites to build a unit type
## @param unit_id: Unit type identifier to check
## @param faction: Faction to check prerequisites for
## @return: true if faction has required buildings and tech, false otherwise
##
## Validates that the faction has the necessary buildings and technology
## to produce the specified unit type. Used by production buildings
## to determine what units can be built.
##
## Example:
## [codeblock]
## if unit_factory.can_build_unit("tank", player_faction):
##     # Show tank in production menu
##     add_production_option("tank")
## [/codeblock]
func can_build_unit(unit_id: String, faction: GlobalEnums.Faction) -> bool:
	var unit_data = get_unit_data(unit_id)
	if not unit_data:
		return false
	
	# Get faction's buildings and tech (would come from game state)
	var faction_buildings = get_faction_buildings(faction)
	var faction_tech = get_faction_tech(faction)
	
	return unit_data.can_be_built(faction_buildings, faction_tech)

## Get all buildings owned by a faction
## @param faction: Faction to query
## @return: Array of Building objects owned by the faction
##
## Helper method that queries the game state to find all buildings
## belonging to a specific faction. Used for prerequisite checking.
##
## Internal method used by can_build_unit()
func get_faction_buildings(faction: GlobalEnums.Faction) -> Array:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return []
	
	var faction_buildings = []
	for building in game_manager.all_buildings:
		if building.faction == faction:
			faction_buildings.append(building)
	
	return faction_buildings

## Get all researched technologies for a faction
## @param faction: Faction to query
## @return: Array of technology identifiers (currently empty - future feature)
##
## Placeholder for future tech tree system. Will return array of
## researched technology identifiers when tech system is implemented.
##
## Internal method used by can_build_unit()
func get_faction_tech(faction: GlobalEnums.Faction) -> Array:
	# Placeholder for tech tree system
	return []
