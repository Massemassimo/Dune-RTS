extends Node2D
class_name GameManager

# Signals for game events
signal spice_changed(new_amount: int)
signal unit_selected(unit)
signal unit_deselected(unit)
signal game_state_changed(new_state: GlobalEnums.GameState)

# Game state
var current_state: GlobalEnums.GameState = GlobalEnums.GameState.MENU
var player_faction: GlobalEnums.Faction = GlobalEnums.Faction.ATREIDES
var ai_faction: GlobalEnums.Faction = GlobalEnums.Faction.HARKONNEN

# Resources
var player_spice: int = 1000
var ai_spice: int = 1000

# Unit management
var selected_units: Array = []
var selected_building = null
var all_units: Array = []
var all_buildings: Array = []

# References to key nodes
var camera: Camera2D
var ui_manager: CanvasLayer
var input_manager: InputManager

# Game settings
const SPICE_COLLECTION_RATE: int = 25
const STARTING_SPICE: int = 1000

func _ready():
	# Game Manager initialized
	setup_game()

# Game loop processing can be added here if needed
# func _process(_delta):
#	pass

func setup_game():
	# Initialize game systems
	current_state = GlobalEnums.GameState.PLAYING
	player_spice = STARTING_SPICE
	ai_spice = STARTING_SPICE
	
	# Find key nodes
	camera = get_node_or_null("../Camera2D")
	ui_manager = get_node_or_null("../UI")
	input_manager = get_node_or_null("../InputManager")
	
	# Connect signals (spice_changed is handled directly by UI)
	game_state_changed.emit(current_state)
	
	# Setup input manager
	if input_manager and camera:
		input_manager.set_camera(camera)
	
	# Spawn initial units for testing
	spawn_test_units()

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

func select_unit(unit):
	if unit not in selected_units:
		# Deselect any building when selecting units
		deselect_building()
		selected_units.append(unit)
		unit.set_selected(true)
		unit_selected.emit(unit)

func deselect_unit(unit):
	if unit in selected_units:
		selected_units.erase(unit)
		unit.set_selected(false)
		unit_deselected.emit(unit)

func deselect_all_units():
	for unit in selected_units:
		unit.set_selected(false)
	selected_units.clear()

func select_building(building):
	deselect_all_units()
	deselect_building() # Deselect any previously selected building
	selected_building = building
	building.set_selected(true)
	
	# Tell UI about building selection
	var local_ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if local_ui_manager:
		local_ui_manager.select_building(building)

func deselect_building():
	if selected_building:
		selected_building.set_selected(false)
		selected_building = null
		var local_ui_manager = get_tree().get_first_node_in_group("ui_manager")
		if local_ui_manager:
			local_ui_manager.deselect_building()

func move_selected_units(target_position: Vector2):
	for unit in selected_units:
		unit.move_to(target_position)

func add_spice(amount: int):
	player_spice += amount
	spice_changed.emit(player_spice)

func spend_spice(amount: int) -> bool:
	if player_spice >= amount:
		player_spice -= amount
		spice_changed.emit(player_spice)
		return true
	return false

# spice_changed signal is handled directly by UIManager

func get_player_spice() -> int:
	return player_spice

func get_ai_spice() -> int:
	return ai_spice

func pause_game():
	current_state = GlobalEnums.GameState.PAUSED
	get_tree().paused = true
	game_state_changed.emit(current_state)

func resume_game():
	current_state = GlobalEnums.GameState.PLAYING
	get_tree().paused = false
	game_state_changed.emit(current_state)

func end_game(player_won: bool):
	current_state = GlobalEnums.GameState.GAME_OVER
	game_state_changed.emit(current_state)
	if player_won:
		print("Victory! Player wins!")
	else:
		print("Defeat! AI wins!")
