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
	var texture = create_harvester_texture()
	sprite.texture = texture
	add_child(sprite)

func create_harvester_texture() -> ImageTexture:
	# Create harvester-specific visual (wider, with spice container)
	var texture = ImageTexture.new()
	var image = Image.create(40, 30, false, Image.FORMAT_RGBA8)
	
	var primary_color = get_faction_color()
	var dark_color = primary_color.darkened(0.4)
	var light_color = primary_color.lightened(0.3)
	var spice_color = Color(0.9, 0.6, 0.2)  # Orange for spice container
	
	# Fill background
	image.fill(Color.TRANSPARENT)
	
	# Draw main body (rectangular)
	for y in range(5, 25):
		for x in range(3, 37):
			var edge_dist = min(min(x-3, 37-x), min(y-5, 25-y))
			if edge_dist >= 0:
				if edge_dist < 1:
					image.set_pixel(x, y, dark_color)  # Border
				else:
					image.set_pixel(x, y, primary_color)  # Fill
	
	# Draw spice container (back section)
	for y in range(8, 22):
		for x in range(25, 35):
			image.set_pixel(x, y, spice_color)
	
	# Add front highlight
	for y in range(8, 15):
		for x in range(5, 20):
			image.set_pixel(x, y, light_color)
	
	texture.set_image(image)
	return texture

func _process(delta):
	super(delta)
	
	# Harvester operating normally
	
	handle_harvester_behavior(delta)

func handle_harvester_behavior(delta):
	match harvester_state:
		GlobalEnums.HarvesterState.IDLE:
			find_spice_deposit()
		GlobalEnums.HarvesterState.MOVING_TO_SPICE:
			check_arrival_at_deposit()
		GlobalEnums.HarvesterState.COLLECTING_SPICE:
			handle_spice_collection(delta)

func handle_spice_collection(delta):
	if not target_spice_deposit or not is_instance_valid(target_spice_deposit):
		harvester_state = GlobalEnums.HarvesterState.IDLE
		return
	
	collection_timer += delta
	if collection_timer >= collection_interval:
		collection_timer = 0.0
		var collected = target_spice_deposit.collect_spice(collection_rate)
		current_spice += collected
		spice_collected.emit(collected, faction)
		# Spice collected successfully

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

func attack_unit(_target):
	pass

func perform_attack():
	pass
