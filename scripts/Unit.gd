extends CharacterBody2D
class_name Unit

## Base Unit Class for RTS Game
##
## Core class for all military and civilian units in the game. Handles movement,
## combat, health, visual effects, and basic AI behavior. Units are faction-based
## and can be controlled by players or AI.
##
## Key Features:
## - Movement with pathfinding support
## - Combat system with projectiles and visual effects
## - Health and damage system with armor
## - Visual selection indicators and faction colors
## - Basic AI behavior for enemy units
## - Screen shake and particle effects
##
## Usage Example:
## [codeblock]
## # Usually created through UnitFactory
## var tank = unit_factory.create_unit("tank", GlobalEnums.Faction.ATREIDES, Vector2(300, 300))
## game_world.add_child(tank)
## 
## # Direct control
## tank.move_to(Vector2(500, 400))
## tank.attack_unit(enemy_unit)
## tank.take_damage(25.0)
## [/codeblock]

## Emitted when unit dies (health reaches zero)
## @param unit: The unit that died
signal unit_died(unit)

## Emitted when unit attacks another unit
## @param attacker: The unit performing the attack
## @param target: The unit being attacked
signal unit_attacked(attacker, target)

## Display name for this unit type
@export var unit_name: String = "Unit"

## Maximum health points - unit dies when current_health reaches 0
@export var max_health: float = 100.0

## Movement speed in pixels per second
@export var move_speed: float = 100.0

## Base damage dealt per attack (before armor reduction)
@export var attack_damage: float = 25.0

## Maximum attack range in pixels
@export var attack_range: float = 150.0

## Damage reduction applied to incoming attacks
@export var armor: float = 0.0

## Resource cost to produce this unit
@export var cost: int = 100

## Current health points (starts at max_health, unit dies at 0)
var current_health: float

## Which faction this unit belongs to (determines AI behavior and visual color)
var faction: GlobalEnums.Faction = GlobalEnums.Faction.NEUTRAL

## Whether this unit is currently selected by the player
var is_selected: bool = false

## Whether this unit is currently moving along a path
var is_moving: bool = false

## Whether this unit is currently engaged in combat
var is_attacking: bool = false

## Final destination for current move order
var target_position: Vector2

## Array of waypoints for pathfinding (currently simple direct movement)
var movement_path: Array[Vector2] = []

## Current waypoint index in movement_path
var path_index: int = 0

## Current combat target (Unit or null)
var attack_target = null

## Timestamp of last attack for cooldown management
var last_attack_time: float = 0.0

## Time in seconds between attacks
var attack_cooldown: float = 1.5

## Visual sprite component showing faction colors
var sprite: Sprite2D

## Visual indicator shown when unit is selected
var selection_indicator: Node2D

## Health bar shown when unit is damaged
var health_bar: ProgressBar

## Timer for AI decision making
var ai_behavior_timer: float = 0.0

## How often AI makes decisions (in seconds)
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
	
	# Create health bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(40, 8)
	health_bar.position = Vector2(-20, -25)
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = false
	add_child(health_bar)

func create_unit_texture() -> ImageTexture:
	# Create unit-specific visual based on unit type
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Get faction color
	var primary_color = get_faction_color()
	var dark_color = primary_color.darkened(0.4)
	var light_color = primary_color.lightened(0.3)
	var accent_color = Color(0.8, 0.8, 0.8)  # Gray for details
	
	# Fill background (transparent)
	image.fill(Color.TRANSPARENT)
	
	# Create unit-specific shape based on unit name
	match unit_name:
		"Tank":
			create_tank_texture(image, primary_color, dark_color, light_color, accent_color)
		"Infantry":
			create_infantry_texture(image, primary_color, dark_color, light_color, accent_color)
		"Harvester":
			create_harvester_texture(image, primary_color, dark_color, light_color, accent_color)
		_:
			create_generic_unit_texture(image, primary_color, dark_color, light_color)
	
	texture.set_image(image)
	return texture

func create_tank_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Tank: Rectangular hull with turret
	# Main hull (rectangular)
	for y in range(8, 24):
		for x in range(6, 26):
			if x == 6 or x == 25 or y == 8 or y == 23:
				image.set_pixel(x, y, dark)  # Hull border
			else:
				image.set_pixel(x, y, primary)  # Hull fill
	
	# Turret (smaller rectangle on top)
	for y in range(12, 20):
		for x in range(10, 22):
			if x == 10 or x == 21 or y == 12 or y == 19:
				image.set_pixel(x, y, accent)  # Turret border
			else:
				image.set_pixel(x, y, light)  # Turret fill
	
	# Gun barrel
	for x in range(22, 28):
		image.set_pixel(x, 15, dark)
		image.set_pixel(x, 16, dark)
	
	# Tracks (treads)
	for y in range(9, 23):
		image.set_pixel(5, y, accent)   # Left track
		image.set_pixel(26, y, accent)  # Right track

func create_infantry_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Infantry: Human-like figure
	# Body (vertical oval)
	for y in range(10, 22):
		for x in range(13, 19):
			var distance_from_center = abs(x - 16)
			if distance_from_center <= 2:
				if x == 13 or x == 18:
					image.set_pixel(x, y, dark)  # Body outline
				else:
					image.set_pixel(x, y, primary)  # Body fill
	
	# Head (small circle)
	for y in range(6, 10):
		for x in range(14, 18):
			var dx = x - 15.5
			var dy = y - 8
			if dx*dx + dy*dy <= 4:
				if dx*dx + dy*dy <= 1:
					image.set_pixel(x, y, light)  # Head fill
				else:
					image.set_pixel(x, y, accent)  # Head outline
	
	# Arms
	for x in range(11, 13):
		image.set_pixel(x, 14, dark)  # Left arm
	for x in range(19, 21):
		image.set_pixel(x, 14, dark)  # Right arm
	
	# Weapon
	for x in range(19, 23):
		image.set_pixel(x, 13, accent)  # Rifle
	
	# Legs
	image.set_pixel(14, 22, dark)  # Left leg
	image.set_pixel(17, 22, dark)  # Right leg
	image.set_pixel(14, 23, dark)
	image.set_pixel(17, 23, dark)

func create_harvester_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Harvester: Large industrial vehicle with mining equipment
	# Main body (large rectangle)
	for y in range(6, 26):
		for x in range(4, 28):
			if x == 4 or x == 27 or y == 6 or y == 25:
				image.set_pixel(x, y, dark)  # Body border
			else:
				image.set_pixel(x, y, primary)  # Body fill
	
	# Mining scoop at front
	for y in range(12, 20):
		for x in range(28, 31):
			image.set_pixel(x, y, accent)  # Scoop
	
	# Storage compartments (stripes)
	for y in range(8, 24, 3):
		for x in range(6, 26):
			image.set_pixel(x, y, light)  # Storage lines
	
	# Tracks
	for y in range(7, 25):
		image.set_pixel(3, y, accent)   # Left track
		image.set_pixel(28, y, accent)  # Right track
	
	# Exhaust pipe
	for y in range(6, 10):
		image.set_pixel(20, y, dark)
		image.set_pixel(21, y, dark)

func create_generic_unit_texture(image: Image, primary: Color, dark: Color, light: Color):
	# Generic unit: Original rounded rectangle design
	for y in range(4, 28):
		for x in range(4, 28):
			var distance_from_edge = min(min(x-4, 28-x), min(y-4, 28-y))
			if distance_from_edge >= 0:
				if distance_from_edge < 2:
					image.set_pixel(x, y, dark)  # Border
				else:
					image.set_pixel(x, y, primary)  # Fill
	
	# Add highlight
	for y in range(6, 12):
		for x in range(6, 26):
			image.set_pixel(x, y, light)

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
	# AI behavior for both player and AI units
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		ai_behavior_timer += delta
		if ai_behavior_timer >= ai_behavior_interval:
			ai_behavior_timer = 0.0
			if faction != game_manager.player_faction:
				# AI units: aggressive behavior
				perform_ai_behavior()
			else:
				# Player units: auto-attack enemies in range
				perform_player_auto_attack()

func perform_ai_behavior():
	# Simple AI: Find nearest enemy and attack
	var nearest_enemy = find_nearest_enemy()
	if nearest_enemy:
		attack_unit(nearest_enemy)

func perform_player_auto_attack():
	# Auto-attack behavior for player units
	# Only attack if not already attacking and not currently moving
	if attack_target or is_moving:
		return
	
	var nearest_enemy = find_nearest_enemy_in_range()
	if nearest_enemy:
		attack_unit(nearest_enemy)

func find_nearest_enemy():
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return null
	
	var nearest = null
	var nearest_distance: float = INF
	
	# Check enemy units
	for unit in game_manager.all_units:
		if unit.faction != faction and unit != self:
			var distance = global_position.distance_to(unit.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = unit
	
	# Check enemy buildings
	for building in game_manager.all_buildings:
		if building.faction != faction:
			var distance = global_position.distance_to(building.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = building
	
	return nearest

func find_nearest_enemy_in_range():
	# Find nearest enemy within attack range for auto-attack
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return null
	
	var nearest = null
	var nearest_distance: float = INF
	
	# Check enemy units within attack range
	for unit in game_manager.all_units:
		if unit.faction != faction and unit != self:
			var distance = global_position.distance_to(unit.global_position)
			if distance <= attack_range and distance < nearest_distance:
				nearest_distance = distance
				nearest = unit
	
	# Check enemy buildings within attack range
	for building in game_manager.all_buildings:
		if building.faction != faction:
			var distance = global_position.distance_to(building.global_position)
			if distance <= attack_range and distance < nearest_distance:
				nearest_distance = distance
				nearest = building
	
	return nearest

## Order unit to move to a specific world position
## @param target: World position (Vector2) to move to
##
## Sets up movement path and begins movement. Currently uses simple direct-line
## pathfinding, but can be extended for more sophisticated pathfinding algorithms.
##
## Side Effects:
## - Clears any existing movement path
## - Sets is_moving to true during movement
## - Interrupts any current combat
##
## Example:
## [codeblock]
## unit.move_to(Vector2(500, 300))  # Move to coordinates
## [/codeblock]
func move_to(target: Vector2):
	# Unit movement ordered
	# Simple pathfinding - direct line for now
	movement_path = [target]
	path_index = 0
	target_position = target
	# Movement path configured

## Order unit to attack another unit
## @param target: Enemy Unit to attack
##
## Sets the unit to attack mode. Unit will move into range if necessary
## and begin attacking once in range. Combat continues until target dies
## or a new order is given.
##
## Side Effects:
## - Sets attack_target and is_attacking
## - May interrupt movement to pursue target
## - Unit will move into range automatically
##
## Example:
## [codeblock]
## unit.attack_unit(enemy_harvester)
## [/codeblock]
func attack_unit(target):
	if target and is_instance_valid(target):
		attack_target = target
		is_attacking = true

func perform_attack():
	if attack_target and is_instance_valid(attack_target):
		last_attack_time = Time.get_unix_time_from_system()
		
		# Create muzzle flash effect
		create_muzzle_flash()
		
		# Create projectile or instant hit
		if attack_range > 150.0:  # Long range units use projectiles
			create_projectile(attack_target)
		else:  # Short range units have instant damage
			attack_target.take_damage(attack_damage, self)
			create_hit_effect(attack_target.global_position)
		
		unit_attacked.emit(self, attack_target)

func create_muzzle_flash():
	# Simple muzzle flash effect
	var flash = ColorRect.new()
	flash.size = Vector2(8, 8)
	flash.position = Vector2(-4, -4)
	flash.color = Color(1, 1, 0, 0.8)  # Yellow flash
	add_child(flash)
	
	# Remove flash after short time
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(flash.queue_free)

func create_projectile(target):
	# Create projectile for long-range attacks
	var projectile = ColorRect.new()
	projectile.size = Vector2(4, 2)
	projectile.color = Color(1, 0.8, 0)  # Orange projectile
	projectile.global_position = global_position
	get_parent().add_child(projectile)
	
	# Animate projectile to target
	var tween = create_tween()
	tween.tween_property(projectile, "global_position", target.global_position, 0.3)
	tween.tween_callback(func(): 
		if is_instance_valid(target):
			target.take_damage(attack_damage, self)
			create_hit_effect(target.global_position)
		projectile.queue_free()
	)

func create_hit_effect(pos: Vector2):
	# Create hit effect
	var hit_effect = ColorRect.new()
	hit_effect.size = Vector2(12, 12)
	hit_effect.position = Vector2(-6, -6)
	hit_effect.color = Color(1, 0.3, 0.1, 0.8)  # Red explosion
	hit_effect.global_position = pos
	get_parent().add_child(hit_effect)
	
	# Animate hit effect
	var tween = create_tween()
	tween.parallel().tween_property(hit_effect, "scale", Vector2(2, 2), 0.2)
	tween.parallel().tween_property(hit_effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(hit_effect.queue_free)

## Apply damage to this unit
## @param damage: Raw damage amount before armor reduction
##
## Applies damage with armor reduction and handles death if health reaches zero.
## Creates visual effects for heavy damage and updates health bar display.
##
## Side Effects:
## - Reduces current_health by (damage - armor)
## - Shows health bar when damaged
## - Creates screen shake for heavy damage
## - Calls die() if health reaches zero
## - Emits unit_died signal on death
##
## Example:
## [codeblock]
## enemy_unit.take_damage(35.0)  # Apply 35 damage
## [/codeblock]
func take_damage(damage: float, attacker = null):
	var actual_damage = max(damage - armor, 0)
	current_health -= actual_damage
	
	# Update health bar if it exists
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = current_health < max_health
	
	# Retaliation logic - attack back if not already attacking and attacker is valid
	if attacker and is_instance_valid(attacker) and not attack_target and attacker.faction != faction:
		attack_target = attacker
		is_attacking = true
	
	# Screen shake effect for heavy damage
	if actual_damage > 20:
		create_screen_shake()
	
	if current_health <= 0:
		die()

## Restore health to this unit
## @param amount: Health points to restore
##
## Restores health up to max_health and updates visual health bar.
## Hides health bar when unit reaches full health.
##
## Example:
## [codeblock]
## damaged_unit.heal(25.0)  # Restore 25 health
## [/codeblock]
func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	
	# Update health bar if it exists
	if health_bar:
		health_bar.value = current_health
		if current_health >= max_health:
			health_bar.visible = false

func create_screen_shake():
	# Get camera and shake it slightly
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		var original_pos = camera.global_position
		var tween = create_tween()
		for i in range(6):
			var shake_offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
			tween.tween_property(camera, "global_position", original_pos + shake_offset, 0.05)
		tween.tween_property(camera, "global_position", original_pos, 0.1)

func die():
	
	# Create death explosion effect
	create_death_explosion()
	
	# Screen shake for death
	create_screen_shake()
	
	unit_died.emit(self)
	
	# Fade out and remove
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_callback(queue_free)

func create_death_explosion():
	# Create multiple explosion particles
	for i in range(5):
		var explosion = ColorRect.new()
		explosion.size = Vector2(6, 6)
		explosion.color = Color(1, 0.5, 0.1, 0.9)
		explosion.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		get_parent().add_child(explosion)
		
		# Animate each explosion particle
		var tween = create_tween()
		var random_scale = randf_range(1.5, 3.0)
		tween.parallel().tween_property(explosion, "scale", Vector2(random_scale, random_scale), 0.4)
		tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.4)
		tween.tween_callback(explosion.queue_free)

## Set unit selection state and update visual indicators
## @param selected: Whether unit should be selected
##
## Updates visual selection indicators and internal state.
## Called by SelectionManager when unit selection changes.
##
## Side Effects:
## - Updates is_selected property
## - Shows/hides selection indicator visual
## - Triggers redraw of selection circle
##
## Example:
## [codeblock]
## unit.set_selected(true)   # Select unit
## unit.set_selected(false)  # Deselect unit
## [/codeblock]
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

## Get comprehensive information about this unit's current state
## @return: Dictionary containing unit status and properties
##
## Returns all relevant unit information for UI display or game logic.
## Useful for status panels, debugging, and game state queries.
##
## Returns:
## [codeblock]
## {
##     "name": String,          # Unit display name
##     "health": float,         # Current health points  
##     "max_health": float,     # Maximum health points
##     "faction": Faction,      # Which faction owns this unit
##     "position": Vector2,     # Current world position
##     "is_moving": bool,       # Whether unit is moving
##     "is_attacking": bool     # Whether unit is in combat
## }
## [/codeblock]
##
## Example:
## [codeblock]
## var info = unit.get_unit_info()
## print("Unit %s health: %d/%d" % [info["name"], info["health"], info["max_health"]])
## [/codeblock]
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
