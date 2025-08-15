extends Node
class_name InputManager

# Input handling for the game
# Unused signals - kept for future functionality

# Mouse state
var mouse_position: Vector2
var is_dragging: bool = false
var drag_start_position: Vector2
var is_box_selecting: bool = false
var box_select_start: Vector2
var box_select_end: Vector2
var selection_box: Control

# Camera movement
var camera_move_speed: float = 300.0
var camera_edge_threshold: float = 20.0

# References
var game_manager
var camera: Camera2D

func _ready():
	# Find game manager and camera
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Create selection box
	setup_selection_box()
	
func set_camera(cam: Camera2D):
	camera = cam

func set_game_manager(gm):
	game_manager = gm

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
	box_select_start = get_screen_mouse_position()
	
	# Check if we clicked on a unit or building
	var clicked_object = get_object_at_position(world_pos)
	
	if clicked_object:
		if clicked_object is Unit:
			handle_unit_selection(clicked_object as Unit, event)
		elif clicked_object is Building:
			handle_building_selection(clicked_object as Building, event)
		# Don't start box select if we clicked on an object
		return
	else:
		# Clicked on empty space - prepare for potential box select
		if not event.ctrl_pressed:
			game_manager.deselect_all_units()
			game_manager.deselect_building()
		
		# Start potential box select
		is_box_selecting = false  # Will become true if we drag

func handle_right_click(world_pos: Vector2, _event: InputEventMouseButton):
	# Right click = move or attack command
	var selected_units = game_manager.get_selected_units()
	if selected_units.size() > 0:
		var target_object = get_object_at_position(world_pos)
		
		if target_object and target_object is Unit:
			var target_unit = target_object as Unit
			# Attack command if target is enemy
			if target_unit.faction != game_manager.player_faction:
				for unit in selected_units:
					unit.attack_unit(target_unit)
				return
		
		# Move command
		game_manager.move_selected_units(world_pos)

func handle_left_release(world_pos: Vector2, event: InputEventMouseButton):
	is_dragging = false
	
	# Handle box select completion
	if is_box_selecting:
		complete_box_selection(event)
		is_box_selecting = false
		hide_selection_box()
	elif box_select_start.distance_to(get_screen_mouse_position()) > 5.0:
		# We dragged but didn't box select - this was a move command attempt
		pass

func handle_unit_selection(unit, event: InputEventMouseButton):
	if unit.faction != game_manager.player_faction:
		return  # Can't select enemy units
	
	if event.ctrl_pressed or event.shift_pressed:
		# Add to selection
		if unit in game_manager.get_selected_units():
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

func handle_mouse_motion(event: InputEventMouseMotion):
	mouse_position = event.position
	
	# Handle box selection
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_dragging:
		var drag_distance = box_select_start.distance_to(mouse_position)
		
		if drag_distance > 10.0 and not is_box_selecting:
			# Start box select
			is_box_selecting = true
			show_selection_box()
		
		if is_box_selecting:
			update_selection_box()

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
		return get_tree().get_root().get_global_mouse_position()

func get_object_at_position(world_pos: Vector2):
	# Get space state through the main viewport
	var main_viewport = get_tree().get_root()
	var space_state = main_viewport.get_world_2d().direct_space_state
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

func setup_selection_box():
	selection_box = Control.new()
	selection_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_box.visible = false
	selection_box.z_index = 100
	selection_box.draw.connect(_draw_selection_box)
	
	# Add to UI layer
	var ui_layer = get_tree().get_first_node_in_group("ui_manager")
	if ui_layer:
		ui_layer.add_child(selection_box)

func show_selection_box():
	if selection_box:
		selection_box.visible = true

func hide_selection_box():
	if selection_box:
		selection_box.visible = false

func update_selection_box():
	if not selection_box:
		return
	
	box_select_end = get_screen_mouse_position()
	
	var start_pos = Vector2(min(box_select_start.x, box_select_end.x), min(box_select_start.y, box_select_end.y))
	var end_pos = Vector2(max(box_select_start.x, box_select_end.x), max(box_select_start.y, box_select_end.y))
	
	selection_box.position = start_pos
	selection_box.size = end_pos - start_pos
	
	# Clear and redraw selection box
	selection_box.queue_redraw()

func _draw_selection_box():
	if not selection_box or not selection_box.visible:
		return
	
	var rect = Rect2(Vector2.ZERO, selection_box.size)
	# Fill
	selection_box.draw_rect(rect, Color(0.2, 0.8, 0.2, 0.3), true)
	# Border
	selection_box.draw_rect(rect, Color(0.2, 0.8, 0.2, 0.8), false, 2.0)

func complete_box_selection(event: InputEventMouseButton):
	if not game_manager:
		return
	
	var start_world = get_world_position_from_screen(box_select_start)
	var end_world = get_world_position_from_screen(box_select_end)
	
	var selection_rect = Rect2(
		Vector2(min(start_world.x, end_world.x), min(start_world.y, end_world.y)),
		Vector2(abs(end_world.x - start_world.x), abs(end_world.y - start_world.y))
	)
	
	var selected_count = 0
	
	# Select all units in the rectangle
	for unit in game_manager.all_units:
		if unit.faction == game_manager.player_faction:
			if selection_rect.has_point(unit.global_position):
				if not event.ctrl_pressed and selected_count == 0:
					# First selection without ctrl - clear previous selections
					game_manager.deselect_all_units()
				
				game_manager.select_unit(unit)
				selected_count += 1
	
	if selected_count > 0:
		pass

func get_screen_mouse_position() -> Vector2:
	return get_viewport().get_mouse_position()

func get_world_position_from_screen(screen_pos: Vector2) -> Vector2:
	if camera:
		var viewport = get_viewport()
		var canvas_transform = viewport.get_canvas_transform()
		var world_pos = canvas_transform.affine_inverse() * screen_pos
		return world_pos
	else:
		return screen_pos

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
