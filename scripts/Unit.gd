extends CharacterBody2D
class_name Unit

# Unit signals
signal unit_died(unit)
# spice_collected signal moved to Harvester.gd where it's actually used
signal unit_attacked(attacker, target)

# Unit properties
@export var unit_name: String = "Unit"
@export var max_health: float = 100.0
@export var move_speed: float = 100.0
@export var attack_damage: float = 25.0
@export var attack_range: float = 150.0
@export var armor: float = 0.0
@export var cost: int = 100

# Unit state
var current_health: float
var faction: GlobalEnums.Faction = GlobalEnums.Faction.NEUTRAL
var is_selected: bool = false
var is_moving: bool = false
var is_attacking: bool = false

# Movement
var target_position: Vector2
var movement_path: Array[Vector2] = []
var path_index: int = 0

# Combat
var attack_target = null
var last_attack_time: float = 0.0
var attack_cooldown: float = 1.5

# Visual components
var sprite: Sprite2D
var selection_indicator: Node2D
var health_bar: ProgressBar

# AI behavior
var ai_behavior_timer: float = 0.0
var ai_behavior_interval: float = 1.0

func _ready():
	# Unit initialization
	current_health = max_health
	setup_visuals()
	setup_collision()
	# Unit ready

func setup_visuals():
	# Create better looking unit sprite
	sprite = Sprite2D.new()
	var texture = create_unit_texture()
	sprite.texture = texture
	add_child(sprite)

func create_unit_texture() -> ImageTexture:
	# Create a more detailed unit visual
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Get faction color
	var primary_color = get_faction_color()
	var dark_color = primary_color.darkened(0.3)
	var light_color = primary_color.lightened(0.2)
	
	# Fill background (transparent)
	image.fill(Color.TRANSPARENT)
	
	# Draw unit shape (rounded rectangle for basic unit)
	for y in range(4, 28):
		for x in range(4, 28):
			var distance_from_edge = min(min(x-4, 28-x), min(y-4, 28-y))
			if distance_from_edge >= 0:
				if distance_from_edge < 2:
					image.set_pixel(x, y, dark_color)  # Border
				else:
					image.set_pixel(x, y, primary_color)  # Fill
	
	# Add highlight
	for y in range(6, 12):
		for x in range(6, 26):
			image.set_pixel(x, y, light_color)
	
	texture.set_image(image)
	return texture

func get_faction_color() -> Color:
	match faction:
		GlobalEnums.Faction.ATREIDES:
			return Color(0.2, 0.4, 0.8)  # Blue
		GlobalEnums.Faction.HARKONNEN:
			return Color(0.8, 0.2, 0.2)  # Red  
		GlobalEnums.Faction.ORDOS:
			return Color(0.2, 0.7, 0.3)  # Green
		_:
			return Color(0.5, 0.5, 0.5)  # Gray
	
	# Create health bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(40, 8)
	health_bar.position = Vector2(-20, -25)
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = false
	add_child(health_bar)

func setup_collision():
	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	collision.shape = shape
	add_child(collision)
	
	# Set collision layer and mask
	collision_layer = 1  # Units layer
	collision_mask = 1 | 2 | 4  # Can collide with units, buildings, terrain

func _process(delta):
	handle_movement(delta)
	handle_combat(delta)
	handle_ai(delta)

func _physics_process(_delta):
	move_and_slide()

func handle_movement(_delta):
	if movement_path.size() > 0 and path_index < movement_path.size():
		is_moving = true
		var target = movement_path[path_index]
		var direction = (target - global_position).normalized()
		
		velocity = direction * move_speed
		
		# Debug movement every few frames
		# Unit moving towards target
		
		# Check if we've reached the current waypoint
		if global_position.distance_to(target) < 10.0:
			# Waypoint reached
			path_index += 1
			if path_index >= movement_path.size():
				# Reached final destination
				# Final destination reached
				movement_path.clear()
				path_index = 0
				is_moving = false
				velocity = Vector2.ZERO
	else:
		is_moving = false
		velocity = Vector2.ZERO

func handle_combat(_delta):
	if attack_target and is_instance_valid(attack_target):
		var distance = global_position.distance_to(attack_target.global_position)
		
		if distance <= attack_range:
			# Stop moving and attack
			movement_path.clear()
			is_moving = false
			
			if Time.get_unix_time_from_system() - last_attack_time >= attack_cooldown:
				perform_attack()
		else:
			# Target out of range, move closer
			move_to(attack_target.global_position)
	else:
		attack_target = null
		is_attacking = false

func handle_ai(delta):
	# Basic AI behavior for non-player units
	if faction != GlobalEnums.Faction.ATREIDES:  # Assuming player is Atreides for now
		ai_behavior_timer += delta
		if ai_behavior_timer >= ai_behavior_interval:
			ai_behavior_timer = 0.0
			perform_ai_behavior()

func perform_ai_behavior():
	# Simple AI: Find nearest enemy and attack
	var nearest_enemy = find_nearest_enemy()
	if nearest_enemy:
		attack_unit(nearest_enemy)

func find_nearest_enemy():
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return null
	
	var nearest = null
	var nearest_distance: float = INF
	
	for unit in game_manager.all_units:
		if unit.faction != faction and unit != self:
			var distance = global_position.distance_to(unit.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = unit
	
	return nearest

func move_to(target: Vector2):
	# Unit movement ordered
	# Simple pathfinding - direct line for now
	movement_path = [target]
	path_index = 0
	target_position = target
	# Movement path configured

func attack_unit(target):
	if target and is_instance_valid(target):
		attack_target = target
		is_attacking = true

func perform_attack():
	if attack_target and is_instance_valid(attack_target):
		last_attack_time = Time.get_unix_time_from_system()
		attack_target.take_damage(attack_damage)
		unit_attacked.emit(self, attack_target)
		# Unit attacks target

func take_damage(damage: float):
	var actual_damage = max(damage - armor, 0)
	current_health -= actual_damage
	health_bar.value = current_health
	health_bar.visible = current_health < max_health
	
	# Unit takes damage
	
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	health_bar.value = current_health
	if current_health >= max_health:
		health_bar.visible = false

func die():
	# Unit has died
	unit_died.emit(self)
	queue_free()

func set_selected(selected: bool):
	is_selected = selected
	update_selection_indicator()

func update_selection_indicator():
	if selection_indicator:
		selection_indicator.queue_redraw()

func _draw():
	if is_selected:
		# Draw animated selection circle
		var time = Time.get_unix_time_from_system()
		var pulse = sin(time * 4.0) * 0.2 + 0.8  # Pulsing effect
		var radius = 28.0
		var color = Color.WHITE
		color.a = pulse
		
		# Draw double ring for better visibility
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, 2.0)
		draw_arc(Vector2.ZERO, radius - 3, 0, TAU, 32, color * 0.6, 1.0)

func set_faction(new_faction: GlobalEnums.Faction):
	faction = new_faction
	if sprite:
		setup_visuals()  # Update color

func get_unit_info() -> Dictionary:
	return {
		"name": unit_name,
		"health": current_health,
		"max_health": max_health,
		"faction": faction,
		"position": global_position,
		"is_moving": is_moving,
		"is_attacking": is_attacking
	}

# Input handling for selection
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager:
				if Input.is_action_pressed("ui_accept"):  # Shift key
					game_manager.select_unit(self)
				else:
					game_manager.deselect_all_units()
					game_manager.select_unit(self)
