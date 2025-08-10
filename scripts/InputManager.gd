extends Node
class_name InputManager

# Input handling for the game
# Unused signals - kept for future functionality

# Mouse state
var mouse_position: Vector2
var is_dragging: bool = false
var drag_start_position: Vector2

# Camera movement
var camera_move_speed: float = 300.0
var camera_edge_threshold: float = 20.0

# References
var game_manager
var camera: Camera2D

func _ready():
	# Find game manager and camera
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
func set_camera(cam: Camera2D):
	camera = cam

func _process(delta):
	handle_camera_movement(delta)

func _input(event):
	# Check if the event is consumed by UI first
	if event is InputEventMouseButton and is_click_on_ui(event.position):
		return # Let UI handle the event
	
	if event is InputEventMouseButton:
		handle_mouse_click(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)
	elif event is InputEventKey:
		handle_keyboard_input(event)

func handle_mouse_click(event: InputEventMouseButton):
	if not game_manager:
		return
	
	mouse_position = event.position
	var world_position = get_world_mouse_position()
	
	if event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(world_position, event)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(world_position, event)
	else:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_release(world_position, event)

func handle_left_click(world_pos: Vector2, event: InputEventMouseButton):
	drag_start_position = world_pos
	
	# Check if we clicked on a unit or building
	var clicked_object = get_object_at_position(world_pos)
	
	if clicked_object:
		if clicked_object is Unit:
			handle_unit_selection(clicked_object as Unit, event)
		elif clicked_object is Building:
			handle_building_selection(clicked_object as Building, event)
	else:
		# Clicked on empty space
		if not event.ctrl_pressed:
			game_manager.deselect_all_units()
			game_manager.deselect_building()

func handle_right_click(world_pos: Vector2, _event: InputEventMouseButton):
	# Right click = move or attack command
	if game_manager.selected_units.size() > 0:
		var target_object = get_object_at_position(world_pos)
		
		if target_object and target_object is Unit:
			var target_unit = target_object as Unit
			# Attack command if target is enemy
			if target_unit.faction != game_manager.player_faction:
				for unit in game_manager.selected_units:
					unit.attack_unit(target_unit)
				print("Attack command issued")
				return
		
		# Move command
		game_manager.move_selected_units(world_pos)
		print("Move command issued to position: ", world_pos)

func handle_left_release(_world_pos: Vector2, _event: InputEventMouseButton):
	is_dragging = false

func handle_unit_selection(unit, event: InputEventMouseButton):
	if unit.faction != game_manager.player_faction:
		return  # Can't select enemy units
	
	if event.ctrl_pressed or event.shift_pressed:
		# Add to selection
		if unit in game_manager.selected_units:
			game_manager.deselect_unit(unit)
		else:
			game_manager.select_unit(unit)
	else:
		# Single selection
		game_manager.deselect_all_units()
		game_manager.select_unit(unit)

func handle_building_selection(building, _event: InputEventMouseButton):
	if building.faction != game_manager.player_faction:
		return  # Can't select enemy buildings
	
	# Select the building through game manager
	game_manager.select_building(building)
	print("Selected building: ", building.building_name)

func handle_mouse_motion(event: InputEventMouseMotion):
	mouse_position = event.position

func handle_keyboard_input(event: InputEventKey):
	if event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				game_manager.deselect_all_units()
				game_manager.deselect_building()
			KEY_A:
				select_all_units()
			KEY_S:
				stop_selected_units()

func handle_camera_movement(delta: float):
	if not camera:
		return
	
	var camera_velocity = Vector2.ZERO
	
	# Keyboard camera movement
	if Input.is_action_pressed("move_camera_left"):
		camera_velocity.x -= camera_move_speed
	if Input.is_action_pressed("move_camera_right"):
		camera_velocity.x += camera_move_speed
	if Input.is_action_pressed("move_camera_up"):
		camera_velocity.y -= camera_move_speed
	if Input.is_action_pressed("move_camera_down"):
		camera_velocity.y += camera_move_speed
	
	# Screen edge camera movement
	var viewport_size = get_viewport().get_visible_rect().size
	if mouse_position.x < camera_edge_threshold:
		camera_velocity.x -= camera_move_speed * 0.5
	elif mouse_position.x > viewport_size.x - camera_edge_threshold:
		camera_velocity.x += camera_move_speed * 0.5
	
	if mouse_position.y < camera_edge_threshold:
		camera_velocity.y -= camera_move_speed * 0.5
	elif mouse_position.y > viewport_size.y - camera_edge_threshold:
		camera_velocity.y += camera_move_speed * 0.5
	
	# Apply camera movement
	if camera_velocity.length() > 0:
		camera.global_position += camera_velocity * delta

func get_world_mouse_position() -> Vector2:
	if camera:
		return camera.get_global_mouse_position()
	else:
		return get_viewport().get_global_mouse_position()

func get_object_at_position(world_pos: Vector2):
	var space_state = get_viewport().get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 1 | 2  # Units and buildings
	
	var results = space_state.intersect_point(query)
	if results.size() > 0:
		return results[0].collider
	
	return null

func select_all_units():
	if not game_manager:
		return
	
	game_manager.deselect_all_units()
	for unit in game_manager.all_units:
		if unit.faction == game_manager.player_faction:
			game_manager.select_unit(unit)

func stop_selected_units():
	for unit in game_manager.selected_units:
		unit.movement_path.clear()
		unit.is_moving = false
		unit.attack_target = null

func is_click_on_ui(screen_pos: Vector2) -> bool:
	# Check if click is on any UI element
	var ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if not ui_manager:
		return false
	
	# Check if production panel is visible and if click is within it
	var production_panel = ui_manager.get_node_or_null("ProductionPanel")
	if production_panel and production_panel.visible:
		var panel_rect = Rect2(production_panel.global_position, production_panel.size)
		if panel_rect.has_point(screen_pos):
			return true
	
	# Check if click is on selection panel
	var selection_info = ui_manager.get_node_or_null("SelectionInfo")
	if selection_info:
		var selection_rect = Rect2(selection_info.global_position, selection_info.size)
		if selection_rect.has_point(screen_pos):
			return true
	
	# Check if click is on resource display
	var resource_display = ui_manager.get_node_or_null("ResourceDisplay")
	if resource_display:
		var resource_rect = Rect2(resource_display.global_position, resource_display.size)
		if resource_rect.has_point(screen_pos):
			return true
	
	return false
