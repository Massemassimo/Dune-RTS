extends Node2D
class_name GameManager

# Core Game Manager - Coordinates all game systems
# Single Responsibility: Game state management and system coordination

# Signals for game events
signal game_state_changed(new_state: GlobalEnums.GameState)
signal game_initialized()
signal game_ended(winner: GlobalEnums.Faction)

# Game state
var current_state: GlobalEnums.GameState = GlobalEnums.GameState.MENU
var player_faction: GlobalEnums.Faction = GlobalEnums.Faction.ATREIDES
var ai_factions: Array[GlobalEnums.Faction] = [GlobalEnums.Faction.HARKONNEN]

# Core Systems (Dependency Injection)
var resource_manager: ResourceManager
var selection_manager: SelectionManager
var command_manager: CommandManager
var unit_factory: UnitFactory

# Game Objects Registry
var all_units: Array[Unit] = []
var all_buildings: Array[Building] = []
var selected_units: Array[Unit] = []

# AI Resources
var ai_faction: GlobalEnums.Faction = GlobalEnums.Faction.HARKONNEN
var ai_spice: int = 1000

# References to key nodes
var camera: Camera2D
var ui_manager: UIManager
var input_manager: InputManager

func _ready():
	# Game Manager initialized
	setup_game()

# Game loop processing can be added here if needed
# func _process(_delta):
#	pass

func setup_game():
	# Initialize core systems
	initialize_managers()
	find_key_nodes()
	connect_systems()
	
	# Set game state
	current_state = GlobalEnums.GameState.PLAYING
	game_state_changed.emit(current_state)
	
	# Initialize game world
	spawn_test_units()
	game_initialized.emit()

func initialize_managers():
	# Create and initialize core systems
	resource_manager = ResourceManager.new()
	selection_manager = SelectionManager.new()
	command_manager = CommandManager.new()
	unit_factory = UnitFactory.new()
	
	# Add managers to scene tree
	add_child(resource_manager)
	add_child(selection_manager)
	add_child(command_manager)
	add_child(unit_factory)
	
	# Configure managers
	selection_manager.player_faction = player_faction

func find_key_nodes():
	camera = get_node_or_null("../Camera2D")
	ui_manager = get_node_or_null("../UI") as UIManager
	input_manager = get_node_or_null("../InputManager")

func connect_systems():
	# Connect manager signals to UI and other systems
	if resource_manager and ui_manager:
		resource_manager.resource_changed.connect(ui_manager._on_resource_changed)
	
	if selection_manager and ui_manager:
		selection_manager.selection_changed.connect(ui_manager._on_selection_changed)
		selection_manager.unit_selected.connect(ui_manager._on_unit_selected)
		selection_manager.unit_deselected.connect(ui_manager._on_unit_deselected)
		selection_manager.building_selected.connect(ui_manager._on_building_selected)
		selection_manager.building_deselected.connect(ui_manager._on_building_deselected)
	
	if command_manager:
		command_manager.command_executed.connect(_on_command_executed)
		command_manager.command_failed.connect(_on_command_failed)
	
	# Setup input manager
	if input_manager and camera:
		input_manager.set_camera(camera)
		input_manager.set_game_manager(self)

func _on_command_executed(command_name: String, success: bool):
	pass

func _on_command_failed(command_name: String, reason: String):
	pass

func spawn_test_units():
	# Spawn initial units for testing
	
	# Spawn a test harvester for the player
	var harvester_scene = preload("res://scenes/units/Harvester.tscn")
	if harvester_scene:
		var harvester = harvester_scene.instantiate()
		harvester.position = Vector2(200, 200)
		harvester.faction = player_faction
		get_parent().add_child.call_deferred(harvester)
		register_unit(harvester)
	
	# Spawn a test tank
	var tank_scene = preload("res://scenes/units/Tank.tscn")
	if tank_scene:
		var tank = tank_scene.instantiate()
		tank.position = Vector2(300, 200)
		tank.faction = player_faction
		get_parent().add_child.call_deferred(tank)
		register_unit(tank)
	
	# Spawn a refinery
	var refinery_scene = preload("res://scenes/buildings/Refinery.tscn")
	if refinery_scene:
		var refinery = refinery_scene.instantiate()
		refinery.position = Vector2(150, 300)
		refinery.faction = player_faction
		get_parent().add_child.call_deferred(refinery)
		register_building(refinery)
	
	# Spawn a barracks for unit production
	var barracks_scene = preload("res://scenes/buildings/Barracks.tscn")
	if barracks_scene:
		var barracks = barracks_scene.instantiate()
		barracks.position = Vector2(400, 300)
		barracks.faction = player_faction
		get_parent().add_child.call_deferred(barracks)
		register_building(barracks)
	
	# Spawn enemy units for combat testing
	spawn_enemy_units()

func register_unit(unit):
	all_units.append(unit)
	unit.unit_died.connect(_on_unit_died)
	
	# Only Harvesters have spice_collected signal
	if unit is Harvester:
		unit.spice_collected.connect(_on_spice_collected)

func register_building(building):
	all_buildings.append(building)
	building.building_destroyed.connect(_on_building_destroyed)

func _on_unit_died(unit):
	if unit in selected_units:
		deselect_unit(unit)
	all_units.erase(unit)

func _on_building_destroyed(building):
	all_buildings.erase(building)

func _on_spice_collected(amount: int, faction: GlobalEnums.Faction):
	if faction == player_faction:
		add_spice(amount)
	elif faction == ai_faction:
		ai_spice += amount

# Selection API - delegates to SelectionManager
func select_unit(unit: Unit, multi_select: bool = false) -> bool:
	return selection_manager.select_unit(unit, multi_select) if selection_manager else false

func deselect_unit(unit: Unit):
	if selection_manager:
		selection_manager.deselect_unit(unit)

func deselect_all_units():
	if selection_manager:
		selection_manager.clear_unit_selection()

func select_building(building: Building) -> bool:
	return selection_manager.select_building(building) if selection_manager else false

func deselect_building():
	if selection_manager:
		selection_manager.deselect_building()

func select_units_in_rect(world_rect: Rect2, multi_select: bool = false) -> int:
	return selection_manager.select_units_in_rect(world_rect, multi_select) if selection_manager else 0

func get_selected_units() -> Array[Unit]:
	return selection_manager.get_selected_units() if selection_manager else []

func get_selected_building() -> Building:
	return selection_manager.get_selected_building() if selection_manager else null

# Command API - delegates to CommandManager  
func move_selected_units(target_position: Vector2) -> bool:
	var units = get_selected_units()
	return command_manager.move_units(units, target_position) if command_manager else false

func attack_with_selected_units(target: Unit) -> bool:
	var units = get_selected_units()
	return command_manager.attack_with_units(units, target) if command_manager else false

func stop_selected_units() -> bool:
	var units = get_selected_units()
	return command_manager.stop_units(units) if command_manager else false

# Resource API - delegates to ResourceManager
func add_spice(amount: int, faction: GlobalEnums.Faction = GlobalEnums.Faction.ATREIDES):
	if resource_manager:
		resource_manager.add_resource(faction, ResourceManager.ResourceType.SPICE, amount)

func spend_spice(amount: int, faction: GlobalEnums.Faction = GlobalEnums.Faction.ATREIDES) -> bool:
	return resource_manager.spend_resource(faction, ResourceManager.ResourceType.SPICE, amount) if resource_manager else false

func get_player_spice() -> int:
	return resource_manager.get_resource(player_faction, ResourceManager.ResourceType.SPICE) if resource_manager else 0

func get_faction_resource(faction: GlobalEnums.Faction, resource_type: ResourceManager.ResourceType) -> int:
	return resource_manager.get_resource(faction, resource_type) if resource_manager else 0

# Unit Creation API - delegates to UnitFactory
func create_unit(unit_id: String, faction: GlobalEnums.Faction, position: Vector2) -> Unit:
	if not unit_factory:
		return null
	
	var unit = unit_factory.create_unit(unit_id, faction, position)
	if unit:
		register_unit(unit)
	
	return unit

func pause_game():
	current_state = GlobalEnums.GameState.PAUSED
	get_tree().paused = true
	game_state_changed.emit(current_state)

func resume_game():
	current_state = GlobalEnums.GameState.PLAYING
	get_tree().paused = false
	game_state_changed.emit(current_state)

func spawn_enemy_units():
	# Spawn enemy infantry
	var infantry_scene = preload("res://scenes/units/Infantry.tscn")
	if infantry_scene:
		for i in range(3):
			var infantry = infantry_scene.instantiate()
			infantry.position = Vector2(800 + i * 60, 200 + i * 30)
			infantry.faction = ai_faction
			get_parent().add_child.call_deferred(infantry)
			register_unit(infantry)
	
	# Spawn enemy tank
	var tank_scene = preload("res://scenes/units/Tank.tscn")
	if tank_scene:
		var tank = tank_scene.instantiate()
		tank.position = Vector2(900, 400)
		tank.faction = ai_faction
		get_parent().add_child.call_deferred(tank)
		register_unit(tank)

func end_game(player_won: bool):
	current_state = GlobalEnums.GameState.GAME_OVER
	game_state_changed.emit(current_state)
	if player_won:
		pass
	else:
		pass
