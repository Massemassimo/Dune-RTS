extends StaticBody2D
class_name Building

# Building signals
signal building_destroyed(building)
signal unit_produced(unit)
signal construction_complete(building)

# Building properties
@export var building_name: String = "Building"
@export var max_health: float = 200.0
@export var armor: float = 5.0
@export var cost: int = 300
@export var power_required: int = 10
@export var power_generated: int = 0

# Building state
var current_health: float
var faction: GlobalEnums.Faction = GlobalEnums.Faction.NEUTRAL
var is_selected: bool = false
var is_constructed: bool = false
var construction_progress: float = 0.0
var construction_time: float = 5.0

# Production
var production_queue: Array[Dictionary] = []
var current_production: Dictionary = {}
var production_progress: float = 0.0

# Visual components
var sprite: Sprite2D
var selection_indicator: Node2D
var health_bar: ProgressBar
var construction_bar: ProgressBar

# Prerequisites and tech requirements
@export var required_buildings: Array[String] = []

func _ready():
	current_health = max_health
	setup_visuals()
	setup_collision()
	
	# Start construction process
	if not is_constructed:
		start_construction()

func setup_visuals():
	# Create sprite with building-specific design
	sprite = Sprite2D.new()
	var texture = create_building_texture()
	sprite.texture = texture
	add_child(sprite)
	
	# Create selection indicator
	selection_indicator = Node2D.new()
	add_child(selection_indicator)
	
	# Create health bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(60, 8)
	health_bar.position = Vector2(-30, -40)
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = false
	add_child(health_bar)
	
	# Create construction bar
	construction_bar = ProgressBar.new()
	construction_bar.size = Vector2(60, 6)
	construction_bar.position = Vector2(-30, -30)
	construction_bar.max_value = 100.0
	construction_bar.value = 0.0
	construction_bar.modulate = Color.YELLOW
	construction_bar.visible = not is_constructed
	add_child(construction_bar)

func setup_collision():
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	collision.shape = shape
	add_child(collision)
	
	collision_layer = 2  # Buildings layer
	collision_mask = 1  # Can be hit by units

func _process(delta):
	handle_construction(delta)
	handle_production(delta)

func handle_construction(delta):
	if not is_constructed:
		construction_progress += delta
		var progress_percent = (construction_progress / construction_time) * 100.0
		construction_bar.value = progress_percent
		
		if construction_progress >= construction_time:
			complete_construction()

func complete_construction():
	is_constructed = true
	construction_bar.visible = false
	construction_complete.emit(self)

func handle_production(delta):
	if not is_constructed:
		return
	
	if current_production.size() > 0:
		production_progress += delta
		
		var production_time = current_production.get("time", 5.0)
		if production_progress >= production_time:
			complete_production()

func start_construction():
	construction_progress = 0.0
	construction_bar.visible = true
	print("Starting construction of %s" % building_name)

func add_to_production_queue(unit_type: String, unit_data: Dictionary):
	if not is_constructed:
		print("Cannot produce units - building not constructed")
		return false
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return false
	
	var unit_cost = unit_data.get("cost", 100)
	if not game_manager.spend_spice(unit_cost):
		print("Not enough spice to produce %s" % unit_type)
		return false
	
	production_queue.append({
		"type": unit_type,
		"data": unit_data,
		"time": unit_data.get("production_time", 5.0)
	})
	
	if current_production.size() == 0:
		start_next_production()
	
	return true

func start_next_production():
	if production_queue.size() > 0:
		current_production = production_queue.pop_front()
		production_progress = 0.0
		print("Started producing %s" % current_production["type"])

func complete_production():
	var unit_type = current_production["type"]
	var _unit_data = current_production["data"]
	
	# Spawn the unit near the building
	var spawn_position = find_spawn_position()
	var unit = create_unit(unit_type, spawn_position)
	
	if unit:
		unit.faction = faction
		get_tree().current_scene.add_child(unit)
		
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			game_manager.register_unit(unit)
		
		unit_produced.emit(unit)
		print("%s produced %s" % [building_name, unit_type])
	
	current_production.clear()
	production_progress = 0.0
	
	# Start next production if queue has items
	if production_queue.size() > 0:
		start_next_production()

func create_unit(unit_type: String, spawn_pos: Vector2):
	var unit_scene_path = "res://scenes/units/%s.tscn" % unit_type
	var unit_scene = load(unit_scene_path)
	
	if unit_scene:
		var unit = unit_scene.instantiate()
		unit.position = spawn_pos
		return unit
	else:
		print("Could not load unit scene: %s" % unit_scene_path)
		return null

func find_spawn_position() -> Vector2:
	# Find a position near the building that's not blocked
	var spawn_offset = Vector2(80, 0)
	var spawn_position = global_position + spawn_offset
	
	# Simple spawn position - could be improved with proper pathfinding
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = spawn_position
	query.collision_mask = 1 | 2  # Units and buildings
	
	var result = space_state.intersect_point(query)
	if result.size() > 0:
		# Position blocked, try different angles
		for angle in range(0, 360, 45):
			var angle_rad = deg_to_rad(angle)
			var offset = Vector2(cos(angle_rad), sin(angle_rad)) * 80
			spawn_position = global_position + offset
			
			query.position = spawn_position
			result = space_state.intersect_point(query)
			if result.size() == 0:
				break
	
	return spawn_position

func take_damage(damage: float, attacker = null):
	var actual_damage = max(damage - armor, 0)
	current_health -= actual_damage
	
	# Update health bar if it exists
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = current_health < max_health
	
	
	if current_health <= 0:
		destroy()

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	health_bar.value = current_health
	if current_health >= max_health:
		health_bar.visible = false

func destroy():
	print("%s has been destroyed" % building_name)
	building_destroyed.emit(self)
	queue_free()

func set_selected(selected: bool):
	is_selected = selected
	update_selection_indicator()

func update_selection_indicator():
	if selection_indicator:
		selection_indicator.queue_redraw()

func _draw():
	if is_selected and selection_indicator:
		# Draw selection rectangle
		draw_rect(Rect2(-35, -35, 70, 70), Color.WHITE, false, 2.0)

func create_building_texture() -> ImageTexture:
	# Create building-specific visual based on building type
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# Get faction color
	var primary_color = get_building_faction_color()
	var dark_color = primary_color.darkened(0.3)
	var light_color = primary_color.lightened(0.2)
	var accent_color = Color(0.6, 0.6, 0.6)  # Gray for structural details
	
	# Fill background (transparent)
	image.fill(Color.TRANSPARENT)
	
	# Create building-specific shape
	match building_name:
		"Barracks":
			create_barracks_texture(image, primary_color, dark_color, light_color, accent_color)
		"Refinery":
			create_refinery_texture(image, primary_color, dark_color, light_color, accent_color)
		"Heavy Factory":
			create_factory_texture(image, primary_color, dark_color, light_color, accent_color)
		_:
			create_generic_building_texture(image, primary_color, dark_color, light_color)
	
	texture.set_image(image)
	return texture

func create_barracks_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Barracks: Military compound with main building and smaller structures
	# Main building (large rectangle)
	for y in range(8, 56):
		for x in range(8, 56):
			if x == 8 or x == 55 or y == 8 or y == 55:
				image.set_pixel(x, y, dark)  # Outer walls
			elif x < 12 or x > 51 or y < 12 or y > 51:
				image.set_pixel(x, y, accent)  # Wall thickness
			else:
				image.set_pixel(x, y, primary)  # Interior
	
	# Entrance
	for y in range(30, 34):
		for x in range(8, 16):
			image.set_pixel(x, y, Color.BLACK)  # Entrance door
	
	# Windows
	for window_x in [20, 32, 44]:
		for window_y in [16, 24, 40, 48]:
			for wy in range(window_y, window_y + 4):
				for wx in range(window_x, window_x + 4):
					image.set_pixel(wx, wy, light)

func create_refinery_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Refinery: Industrial complex with pipes and tanks
	# Main structure
	for y in range(4, 60):
		for x in range(4, 60):
			if x == 4 or x == 59 or y == 4 or y == 59:
				image.set_pixel(x, y, dark)
			elif x < 8 or x > 55 or y < 8 or y > 55:
				image.set_pixel(x, y, accent)
			else:
				image.set_pixel(x, y, primary)
	
	# Storage tanks (circles)
	for tank_x in [16, 48]:
		for tank_y in [16, 48]:
			for y in range(tank_y - 8, tank_y + 8):
				for x in range(tank_x - 8, tank_x + 8):
					var dx = x - tank_x
					var dy = y - tank_y
					if dx*dx + dy*dy <= 36:
						if dx*dx + dy*dy <= 25:
							image.set_pixel(x, y, light)  # Tank interior
						else:
							image.set_pixel(x, y, accent)  # Tank rim
	
	# Pipes connecting tanks
	for x in range(24, 40):
		image.set_pixel(x, 16, accent)
		image.set_pixel(x, 48, accent)
	for y in range(24, 40):
		image.set_pixel(16, y, accent)
		image.set_pixel(48, y, accent)

func create_factory_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Heavy Factory: Large industrial building with smokestacks
	# Main building (large rectangle)
	for y in range(2, 62):
		for x in range(2, 62):
			if x == 2 or x == 61 or y == 2 or y == 61:
				image.set_pixel(x, y, dark)
			elif x < 6 or x > 57 or y < 6 or y > 57:
				image.set_pixel(x, y, accent)
			else:
				image.set_pixel(x, y, primary)
	
	# Smokestacks
	for stack_x in [16, 32, 48]:
		for y in range(0, 8):
			for x in range(stack_x - 2, stack_x + 3):
				image.set_pixel(x, y, accent)
		# Smoke effect
		image.set_pixel(stack_x - 1, 0, Color.GRAY)
		image.set_pixel(stack_x, 0, Color.GRAY)
		image.set_pixel(stack_x + 1, 0, Color.GRAY)
	
	# Large factory door
	for y in range(40, 56):
		for x in range(20, 44):
			if x == 20 or x == 43 or y == 40:
				image.set_pixel(x, y, dark)
			else:
				image.set_pixel(x, y, Color.BLACK)

func create_generic_building_texture(image: Image, primary: Color, dark: Color, light: Color):
	# Generic building: Simple rectangular structure
	for y in range(8, 56):
		for x in range(8, 56):
			if x == 8 or x == 55 or y == 8 or y == 55:
				image.set_pixel(x, y, dark)
			elif x < 12 or x > 51 or y < 12 or y > 51:
				image.set_pixel(x, y, primary)
			else:
				image.set_pixel(x, y, light)

func get_building_faction_color() -> Color:
	match faction:
		GlobalEnums.Faction.ATREIDES:
			return Color(0.3, 0.5, 0.9)  # Blue
		GlobalEnums.Faction.HARKONNEN:
			return Color(0.9, 0.3, 0.3)  # Red  
		GlobalEnums.Faction.ORDOS:
			return Color(0.3, 0.8, 0.4)  # Green
		_:
			return Color(0.6, 0.6, 0.6)  # Gray

func set_faction(new_faction: GlobalEnums.Faction):
	faction = new_faction
	if sprite:
		setup_visuals()

func get_building_info() -> Dictionary:
	return {
		"name": building_name,
		"health": current_health,
		"max_health": max_health,
		"faction": faction,
		"position": global_position,
		"is_constructed": is_constructed,
		"construction_progress": construction_progress,
		"production_queue_size": production_queue.size(),
		"current_production": current_production.get("type", "")
	}

func get_production_queue_info() -> Array:
	return production_queue

func get_production_progress() -> Dictionary:
	if current_production.size() == 0:
		return {"percentage": 0, "remaining_time": 0}
	
	var total_time = current_production.get("time", 5.0)
	var percentage = (production_progress / total_time) * 100.0
	var remaining_time = total_time - production_progress
	
	return {
		"percentage": percentage,
		"remaining_time": remaining_time
	}

func can_produce_unit(_unit_type: String) -> bool:
	# Override in specific buildings to define what they can produce
	return false

# Input handling is done by InputManager
