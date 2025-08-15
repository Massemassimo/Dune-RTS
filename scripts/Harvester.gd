extends "res://scripts/Unit.gd"
class_name Harvester

signal spice_collected(amount: int, faction: GlobalEnums.Faction)

@export var spice_capacity: int = 100
@export var collection_rate: int = 5
@export var collection_range: float = 50.0

var current_spice: int = 0
var target_spice_deposit = null
var target_refinery = null
var harvester_state: GlobalEnums.HarvesterState = GlobalEnums.HarvesterState.IDLE
var collection_timer: float = 0.0
var collection_interval: float = 1.0
var unload_timer: float = 0.0
var base_unload_time: float = 5.0
var was_manually_moved: bool = false
var is_frozen_for_unloading: bool = false
var waiting_for_refinery: bool = false
var spice_to_unload: int = 0
var spice_unloaded_so_far: int = 0

func _ready():
	# Harvester initialization
	super()
	# Parent class initialized
	unit_name = "Harvester"
	max_health = 120.0
	current_health = max_health
	move_speed = 80.0
	attack_damage = 0.0
	attack_range = 0.0
	cost = 300
	
	# Setting up harvester visuals
	setup_harvester_visuals()
	# Harvester ready

func setup_harvester_visuals():
	if sprite:
		sprite.queue_free()
	
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(40, 30, false, Image.FORMAT_RGBA8)
	var primary_color = get_faction_color()
	var dark_color = primary_color.darkened(0.4)
	var light_color = primary_color.lightened(0.3)
	var accent_color = Color(0.9, 0.6, 0.2)  # Orange for spice container
	create_harvester_texture(image, primary_color, dark_color, light_color, accent_color)
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func create_harvester_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Create harvester-specific visual (wider, with spice container)
	# Fill background
	image.fill(Color.TRANSPARENT)
	
	# Draw main body (rectangular)
	for y in range(5, 25):
		for x in range(3, 37):
			var edge_dist = min(min(x-3, 37-x), min(y-5, 25-y))
			if edge_dist >= 0:
				if edge_dist < 1:
					image.set_pixel(x, y, dark)  # Border
				else:
					image.set_pixel(x, y, primary)  # Fill
	
	# Draw spice container (back section)
	for y in range(8, 22):
		for x in range(25, 35):
			image.set_pixel(x, y, accent)  # Use accent color for spice container
	
	# Add front highlight
	for y in range(8, 15):
		for x in range(5, 20):
			image.set_pixel(x, y, light)

func _process(delta):
	# Don't process movement if frozen for unloading
	if not is_frozen_for_unloading:
		super(delta)
	
	handle_harvester_behavior(delta)

func handle_harvester_behavior(delta):
	match harvester_state:
		GlobalEnums.HarvesterState.IDLE:
			if current_spice > 0:
				find_refinery()
			else:
				find_spice_deposit()
		GlobalEnums.HarvesterState.MOVING_TO_SPICE:
			check_arrival_at_deposit()
		GlobalEnums.HarvesterState.COLLECTING_SPICE:
			handle_spice_collection(delta)
		GlobalEnums.HarvesterState.MOVING_TO_REFINERY:
			check_arrival_at_refinery()
		GlobalEnums.HarvesterState.UNLOADING_SPICE:
			handle_unloading(delta)

func handle_spice_collection(delta):
	# Check if we've been manually moved away from the deposit
	if was_manually_moved:
		harvester_state = GlobalEnums.HarvesterState.IDLE
		was_manually_moved = false
		return
	
	if not target_spice_deposit or not is_instance_valid(target_spice_deposit):
		harvester_state = GlobalEnums.HarvesterState.IDLE
		return
	
	# Check if we're still close enough to the deposit
	var distance = global_position.distance_to(target_spice_deposit.global_position)
	if distance > collection_range:
		harvester_state = GlobalEnums.HarvesterState.IDLE
		return
	
	# Check if we're at full capacity
	if current_spice >= spice_capacity:
		find_refinery()
		return
	
	collection_timer += delta
	if collection_timer >= collection_interval:
		collection_timer = 0.0
		var collected = target_spice_deposit.collect_spice(collection_rate)
		current_spice = min(current_spice + collected, spice_capacity)
		# Don't emit spice_collected - spice only increases when unloading
		
		# Check again if we're now full
		if current_spice >= spice_capacity:
			find_refinery()

func find_spice_deposit():
	# Searching for spice deposits
	var spice_deposits = get_tree().get_nodes_in_group("spice_deposits")
	# Found spice deposits in area
	
	var nearest_deposit = null
	var nearest_distance: float = INF
	
	for deposit in spice_deposits:
		# Evaluating spice deposit
		if deposit.remaining_spice > 0:
			var distance = global_position.distance_to(deposit.global_position)
			# Calculating distance to deposit
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_deposit = deposit
	
	if nearest_deposit:
		# Moving to selected spice deposit
		target_spice_deposit = nearest_deposit
		move_to(target_spice_deposit.global_position)
		harvester_state = GlobalEnums.HarvesterState.MOVING_TO_SPICE
	# If no deposits found, harvester stays idle

func check_arrival_at_deposit():
	if not target_spice_deposit or not is_instance_valid(target_spice_deposit):
		harvester_state = GlobalEnums.HarvesterState.IDLE
		return
	
	# Check if harvester is close enough to start collecting
	var distance = global_position.distance_to(target_spice_deposit.global_position)
	if distance <= collection_range:
		harvester_state = GlobalEnums.HarvesterState.COLLECTING_SPICE

func find_refinery():
	var refineries = get_tree().get_nodes_in_group("refineries")
	var nearest_refinery = null
	var nearest_distance: float = INF
	
	for refinery in refineries:
		if refinery.faction == faction:
			var distance = global_position.distance_to(refinery.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_refinery = refinery
	
	if nearest_refinery:
		target_refinery = nearest_refinery
		move_to(target_refinery.global_position)
		harvester_state = GlobalEnums.HarvesterState.MOVING_TO_REFINERY

func check_arrival_at_refinery():
	if not target_refinery or not is_instance_valid(target_refinery):
		harvester_state = GlobalEnums.HarvesterState.IDLE
		return
	
	var distance = global_position.distance_to(target_refinery.global_position)
	if distance <= 80.0:  # Close enough to refinery
		# Try to get an unload slot
		if target_refinery.request_unload_slot(self):
			# Slot available immediately
			start_unloading()
		else:
			# Added to queue, wait
			waiting_for_refinery = true
			is_frozen_for_unloading = true
			movement_path.clear()
			is_moving = false

func start_unloading():
	harvester_state = GlobalEnums.HarvesterState.UNLOADING_SPICE
	unload_timer = 0.0
	movement_path.clear()
	is_moving = false
	is_frozen_for_unloading = true
	waiting_for_refinery = false
	spice_to_unload = current_spice
	spice_unloaded_so_far = 0

func start_unloading_at_refinery():
	# Called by refinery when slot becomes available
	if current_spice > 0:
		start_unloading()

func handle_unloading(delta):
	if spice_to_unload <= 0:
		finish_unloading()
		return
	
	# Calculate unload time based on spice amount (50% full = 50% time)
	var spice_percentage = float(spice_to_unload) / float(spice_capacity)
	var required_unload_time = base_unload_time * spice_percentage
	
	unload_timer += delta
	
	# Calculate how much spice should have been unloaded by now
	var progress_percentage = min(unload_timer / required_unload_time, 1.0)
	var target_unloaded = int(progress_percentage * spice_to_unload)
	
	# Add the difference to game manager
	var spice_to_add_now = target_unloaded - spice_unloaded_so_far
	if spice_to_add_now > 0:
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			game_manager.add_spice(spice_to_add_now)
		spice_unloaded_so_far += spice_to_add_now
	
	if unload_timer >= required_unload_time:
		# Unload complete - ensure all spice is added
		var remaining = spice_to_unload - spice_unloaded_so_far
		if remaining > 0:
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager:
				game_manager.add_spice(remaining)
		
		current_spice = 0
		finish_unloading()

func finish_unloading():
	# Release the refinery slot
	if target_refinery and is_instance_valid(target_refinery):
		target_refinery.release_unload_slot(self)
	
	# Unfreeze and reset state
	is_frozen_for_unloading = false
	waiting_for_refinery = false
	harvester_state = GlobalEnums.HarvesterState.IDLE
	
	# Automatically find next spice deposit
	find_spice_deposit()

# Override move_to to detect manual movement
func move_to(target: Vector2):
	# If we're currently collecting and get a move command, mark as manually moved
	if harvester_state == GlobalEnums.HarvesterState.COLLECTING_SPICE:
		was_manually_moved = true
	
	# Check if we're being manually directed to a refinery
	var clicked_refinery = get_refinery_at_position(target)
	if clicked_refinery and current_spice > 0:
		target_refinery = clicked_refinery
		harvester_state = GlobalEnums.HarvesterState.MOVING_TO_REFINERY
	
	# Unfreeze if manually moved
	if is_frozen_for_unloading or waiting_for_refinery:
		is_frozen_for_unloading = false
		waiting_for_refinery = false
		if target_refinery:
			target_refinery.release_unload_slot(self)
	
	super.move_to(target)

func get_refinery_at_position(pos: Vector2):
	# Check if the target position is close to a refinery
	var refineries = get_tree().get_nodes_in_group("refineries")
	for refinery in refineries:
		if refinery.faction == faction:
			var distance = pos.distance_to(refinery.global_position)
			if distance <= 100.0:  # Close enough to be considered targeting the refinery
				return refinery
	return null

func attack_unit(_target):
	pass

func perform_attack():
	pass
