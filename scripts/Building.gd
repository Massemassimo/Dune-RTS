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
	# Create sprite (placeholder colored rectangle)
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	
	# Color based on faction and building type
	var color: Color
	match faction:
		GlobalEnums.Faction.ATREIDES:
			color = Color.DARK_BLUE
		GlobalEnums.Faction.HARKONNEN:
			color = Color.DARK_RED
		GlobalEnums.Faction.ORDOS:
			color = Color.DARK_GREEN
		_:
			color = Color.DIM_GRAY
	
	image.fill(color)
	texture.set_image(image)
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
	print("%s construction completed" % building_name)

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
	var unit_data = current_production["data"]
	
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

func take_damage(damage: float):
	var actual_damage = max(damage - armor, 0)
	current_health -= actual_damage
	health_bar.value = current_health
	health_bar.visible = current_health < max_health
	
	print("%s takes %d damage, health: %d" % [building_name, actual_damage, current_health])
	
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

func can_produce_unit(unit_type: String) -> bool:
	# Override in specific buildings to define what they can produce
	return false

# Input handling for selection
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager:
				# Buildings can be selected but don't deselect units
				set_selected(true)