extends Unit
class_name Tank

# Tank-specific properties
@export var tank_type: String = "Light"

func _ready():
	super._ready()
	setup_tank_properties()
	setup_tank_visuals()

func setup_tank_properties():
	unit_name = "Tank"
	
	match tank_type:
		"Light":
			max_health = 150.0
			move_speed = 120.0
			attack_damage = 35.0
			attack_range = 200.0
			armor = 2.0
			cost = 400
			unit_name = "Light Tank"
		
		"Heavy":
			max_health = 250.0
			move_speed = 80.0
			attack_damage = 60.0
			attack_range = 220.0
			armor = 5.0
			cost = 700
			unit_name = "Heavy Tank"
		
		"Sonic":  # Atreides special
			max_health = 200.0
			move_speed = 100.0
			attack_damage = 45.0
			attack_range = 180.0
			armor = 3.0
			cost = 600
			unit_name = "Sonic Tank"
		
		"Devastator":  # Harkonnen special
			max_health = 400.0
			move_speed = 60.0
			attack_damage = 80.0
			attack_range = 250.0
			armor = 8.0
			cost = 1000
			unit_name = "Devastator"
		
		"Deviator":  # Ordos special
			max_health = 180.0
			move_speed = 110.0
			attack_damage = 30.0
			attack_range = 200.0
			armor = 2.0
			cost = 750
			unit_name = "Deviator"
	
	current_health = max_health
	attack_cooldown = 2.0

func setup_tank_visuals():
	if sprite:
		sprite.queue_free()
	
	# Create tank sprite
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	
	# Size based on tank type
	var size = Vector2(36, 24)
	if tank_type == "Heavy" or tank_type == "Devastator":
		size = Vector2(42, 30)
	
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGB8)
	
	var color: Color
	match faction:
		GameManager.Faction.ATREIDES:
			color = Color(0.3, 0.5, 0.9)  # Blue
		GameManager.Faction.HARKONNEN:
			color = Color(0.9, 0.3, 0.3)  # Red
		GameManager.Faction.ORDOS:
			color = Color(0.3, 0.9, 0.3)  # Green
		_:
			color = Color.GRAY
	
	# Darken for heavy units
	if tank_type in ["Heavy", "Devastator"]:
		color = color.darkened(0.3)
	
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func perform_attack():
	if not attack_target or not is_instance_valid(attack_target):
		return
	
	super.perform_attack()
	
	# Special attack effects based on tank type
	match tank_type:
		"Sonic":
			perform_sonic_attack()
		"Deviator":
			perform_deviator_attack()
		"Devastator":
			perform_devastator_attack()

func perform_sonic_attack():
	# Sonic tanks have area damage
	var nearby_enemies = find_units_in_range(attack_target.global_position, 80.0)
	for enemy in nearby_enemies:
		if enemy != attack_target and enemy.faction != faction:
			enemy.take_damage(attack_damage * 0.5)  # Half damage to secondary targets
	
	print("%s sonic attack affects %d units" % [unit_name, nearby_enemies.size()])

func perform_deviator_attack():
	# Deviator converts enemy units temporarily
	if attack_target.faction != faction:
		# For now, just do regular damage
		# Could implement mind control later
		print("%s attempts to convert %s" % [unit_name, attack_target.unit_name])

func perform_devastator_attack():
	# Devastator has explosive damage
	create_explosion_effect(attack_target.global_position)

func create_explosion_effect(pos: Vector2):
	# Simple explosion effect - could be enhanced with particles
	var nearby_units = find_units_in_range(pos, 60.0)
	for unit in nearby_units:
		if unit.faction != faction:
			unit.take_damage(attack_damage * 0.3)  # Splash damage

func find_units_in_range(center: Vector2, range: float) -> Array[Unit]:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	var units_in_range: Array[Unit] = []
	
	if game_manager:
		for unit in game_manager.all_units:
			if unit.global_position.distance_to(center) <= range:
				units_in_range.append(unit)
	
	return units_in_range

func get_tank_info() -> Dictionary:
	var info = get_unit_info()
	info["tank_type"] = tank_type
	info["armor"] = armor
	return info