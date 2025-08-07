extends Unit
class_name Harvester

# Harvester-specific properties
@export var spice_capacity: int = 100
@export var collection_rate: int = 5
@export var collection_range: float = 50.0

# Harvester state
var current_spice: int = 0
var target_spice_deposit: SpiceDeposit = null
var target_refinery = null
var harvester_state: GlobalEnums.HarvesterState = GlobalEnums.HarvesterState.IDLE

# Collection timer
var collection_timer: float = 0.0
var collection_interval: float = 1.0

func _ready():
	super._ready()
	unit_name = "Harvester"
	max_health = 120.0
	current_health = max_health
	move_speed = 80.0
	attack_damage = 0.0  # Harvesters don't attack
	attack_range = 0.0
	cost = 300
	
	# Update visuals to show it's a harvester
	setup_harvester_visuals()

func setup_harvester_visuals():
	if sprite:
		sprite.queue_free()
	
	# Create harvester sprite (larger rectangle)
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(40, 30, false, Image.FORMAT_RGB8)
	
	var color: Color
	match faction:
		GlobalEnums.Faction.ATREIDES:
			color = Color(0.2, 0.4, 0.8)  # Dark blue
		GlobalEnums.Faction.HARKONNEN:
			color = Color(0.8, 0.2, 0.2)  # Dark red
		GlobalEnums.Faction.ORDOS:
			color = Color(0.2, 0.8, 0.2)  # Dark green
		_:
			color = Color.GRAY
	
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func _process(delta):
	super._process(delta)
	handle_harvester_behavior(delta)

func handle_harvester_behavior(delta):
	match harvester_state:
		GlobalEnums.HarvesterState.IDLE:
			find_spice_deposit()
		
		GlobalEnums.HarvesterState.MOVING_TO_SPICE:
			if not is_moving and target_spice_deposit:
				var distance = global_position.distance_to(target_spice_deposit.global_position)
				if distance <= collection_range:
					harvester_state = GlobalEnums.HarvesterState.COLLECTING_SPICE
					print("%s reached spice deposit" % unit_name)
		
		GlobalEnums.HarvesterState.COLLECTING_SPICE:
			handle_spice_collection(delta)
		
		GlobalEnums.HarvesterState.MOVING_TO_REFINERY:
			if not is_moving and target_refinery:
				var distance = global_position.distance_to(target_refinery.global_position)
				if distance <= 80.0:  # Close to refinery
					harvester_state = GlobalEnums.HarvesterState.UNLOADING_SPICE
					print("%s reached refinery" % unit_name)
		
		GlobalEnums.HarvesterState.UNLOADING_SPICE:
			handle_spice_unloading(delta)

func handle_spice_collection(delta):
	if not target_spice_deposit or not is_instance_valid(target_spice_deposit):
		harvester_state = GlobalEnums.HarvesterState.IDLE
		return
	
	collection_timer += delta
	if collection_timer >= collection_interval:
		collection_timer = 0.0
		
		var collected = target_spice_deposit.collect_spice(collection_rate)
		current_spice += collected
		
		print("%s collected %d spice (total: %d/%d)" % [unit_name, collected, current_spice, spice_capacity])
		
		# Check if harvester is full or spice deposit is empty
		if current_spice >= spice_capacity or collected == 0:
			# Find refinery to unload
			find_refinery()

func handle_spice_unloading(delta):
	collection_timer += delta
	if collection_timer >= collection_interval:
		collection_timer = 0.0
		
		if current_spice > 0:
			# Unload spice
			var unload_amount = min(current_spice, collection_rate * 3)
			current_spice -= unload_amount
			
			# Notify game manager of collected spice
			spice_collected.emit(unload_amount, faction)
			print("%s unloaded %d spice" % [unit_name, unload_amount])
		
		if current_spice <= 0:
			# Finished unloading, return to spice collection
			if target_spice_deposit and is_instance_valid(target_spice_deposit) and target_spice_deposit.remaining_spice > 0:
				move_to(target_spice_deposit.global_position)
				harvester_state = GlobalEnums.HarvesterState.RETURNING_TO_SPICE
			else:
				harvester_state = GlobalEnums.HarvesterState.IDLE

func find_spice_deposit():
	var spice_deposits = get_tree().get_nodes_in_group("spice_deposits")
	var nearest_deposit: SpiceDeposit = null
	var nearest_distance: float = INF
	
	for deposit in spice_deposits:
		if deposit.remaining_spice > 0:
			var distance = global_position.distance_to(deposit.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_deposit = deposit
	
	if nearest_deposit:
		target_spice_deposit = nearest_deposit
		move_to(target_spice_deposit.global_position)
		harvester_state = GlobalEnums.HarvesterState.MOVING_TO_SPICE
		print("%s moving to spice deposit" % unit_name)

func find_refinery():
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return
	
	var nearest_refinery = null
	var nearest_distance: float = INF
	
	for building in game_manager.all_buildings:
		if building.faction == faction and building.building_name == "Refinery":
			var distance = global_position.distance_to(building.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_refinery = building
	
	if nearest_refinery:
		target_refinery = nearest_refinery
		move_to(target_refinery.global_position)
		harvester_state = GlobalEnums.HarvesterState.MOVING_TO_REFINERY
		print("%s moving to refinery" % unit_name)
	else:
		print("No refinery found for %s" % unit_name)
		harvester_state = GlobalEnums.HarvesterState.IDLE

func get_harvester_info() -> Dictionary:
	var info = get_unit_info()
	info["spice_carried"] = current_spice
	info["spice_capacity"] = spice_capacity
	info["state"] = GlobalEnums.HarvesterState.keys()[harvester_state]
	return info

# Override attack behavior - harvesters don't attack
func attack_unit(target):
	pass

func perform_attack():
	pass

func handle_combat(delta):
	# Harvesters don't engage in combat
	pass