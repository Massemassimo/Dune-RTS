extends CanvasLayer
class_name UIManager

# UI References
@onready var spice_label: Label = $ResourceDisplay/ResourceContainer/SpiceContainer/SpiceLabel
@onready var power_label: Label = $ResourceDisplay/ResourceContainer/PowerContainer/PowerLabel
@onready var population_label: Label = $ResourceDisplay/ResourceContainer/PopulationContainer/PopulationLabel
@onready var selection_label: Label = $SelectionInfo/SelectionPanel/SelectionLabel
@onready var unit_icons_container: GridContainer = null  # This node doesn't exist in the scene
@onready var production_panel: VBoxContainer = $ProductionPanel
@onready var production_button_container: VBoxContainer = $ProductionPanel/ProductionButtons
@onready var command_panel: Panel = $CommandPanel
@onready var command_button_container: GridContainer = $CommandPanel/CommandButtons
@onready var minimap: Panel = $Minimap
@onready var minimap_viewport: SubViewport = $Minimap/MinimapViewport
@onready var production_queue_panel: Panel = $ProductionQueuePanel
@onready var queue_items_container: VBoxContainer = $ProductionQueuePanel/QueueContainer/QueueList/QueueItems

# Game references
var game_manager
var selected_building

func _ready():
	setup_ui_styling()
	setup_production_panel()
	game_manager = get_tree().get_first_node_in_group("game_manager")

func setup_ui_styling():
	# Apply better styling to UI elements
	if spice_label:
		spice_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
		spice_label.add_theme_font_size_override("font_size", 16)
		spice_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		spice_label.add_theme_constant_override("shadow_offset_x", 1)
		spice_label.add_theme_constant_override("shadow_offset_y", 1)
	
	if selection_label:
		selection_label.add_theme_color_override("font_color", Color(1, 1, 1))
		selection_label.add_theme_font_size_override("font_size", 14)

func _on_spice_changed(new_amount: int):
	if spice_label:
		spice_label.text = "Spice: %d" % new_amount
	update_resource_display()

func _on_resource_changed(resource_type: String, amount: int, faction):
	# Handle resource changes from ResourceManager
	if resource_type == "spice":
		_on_spice_changed(amount)
	update_resource_display()

func _on_selection_changed(selected_units: Array, selected_building):
	update_selection_display()
	update_command_panel()

func _on_building_selected(building):
	select_building(building)

func _on_building_deselected():
	deselect_building()

func update_resource_display():
	if not game_manager:
		return
	
	# Update spice
	if spice_label:
		spice_label.text = "Spice: %d" % game_manager.get_player_spice()
	
	# Update power (calculate from buildings)
	var current_power = 0
	var max_power = 0
	for building in game_manager.all_buildings:
		if building.faction == game_manager.player_faction:
			current_power += building.power_required
			max_power += building.power_generated
	
	if power_label:
		power_label.text = "Power: %d/%d" % [max_power - current_power, max_power]
	
	# Update population
	var unit_count = 0
	for unit in game_manager.all_units:
		if unit.faction == game_manager.player_faction:
			unit_count += 1
	
	if population_label:
		population_label.text = "Units: %d/50" % unit_count

func _on_unit_selected(unit):
	update_selection_display()
	update_command_panel()

func _on_unit_deselected(unit):
	update_selection_display()
	update_command_panel()

func update_selection_display():
	if not game_manager or not selection_label:
		return
	
	# Clear unit icons
	if unit_icons_container:
		for child in unit_icons_container.get_children():
			child.queue_free()
	
	var selected_units = game_manager.get_selected_units()
	var selected_count = selected_units.size()
	
	if selected_count == 0:
		selection_label.text = "🔍 No Selection\n\nClick to select units\nRight-click to move"
	elif selected_count == 1:
		var unit = selected_units[0]
		var status = "Moving" if unit.is_moving else "Idle"
		if unit is Harvester:
			var harvester = unit as Harvester
			selection_label.text = "🚛 %s [%s]\n❤️ Health: %d/%d\n🧿 Spice: %d/%d" % [
				unit.unit_name, 
				status,
				unit.current_health, 
				unit.max_health,
				harvester.current_spice,
				harvester.spice_capacity
			]
		else:
			selection_label.text = "🎯 %s [%s]\n❤️ Health: %d/%d\n⚔️ Attack: %d" % [
				unit.unit_name,
				status, 
				unit.current_health,
				unit.max_health,
				unit.attack_damage
			]
	else:
		# Multiple units selected - show detailed breakdown
		var unit_types = {}
		var total_health = 0
		var max_health = 0
		
		for unit in selected_units:
			var unit_type = unit.unit_name
			if not unit_types.has(unit_type):
				unit_types[unit_type] = 0
			unit_types[unit_type] += 1
			total_health += unit.current_health
			max_health += unit.max_health
		
		var type_text = ""
		for unit_type in unit_types.keys():
			if type_text != "":
				type_text += ", "
			type_text += "%dx %s" % [unit_types[unit_type], unit_type]
		
		var health_percentage = int((float(total_health) / float(max_health)) * 100.0) if max_health > 0 else 0
		
		selection_label.text = "👥 %d units selected\n%s\n❤️ Total Health: %d%% (%d/%d)\n\nRight-click to move all" % [
			selected_count, 
			type_text,
			health_percentage,
			total_health, 
			max_health
		]
		
		# Create unit icons for multi-selection
		create_unit_icons_display()

func setup_production_panel():
	if production_panel:
		production_panel.visible = false
	
	setup_command_panel()
	setup_minimap()
	setup_production_queue()

func setup_command_panel():
	if not command_panel:
		return
	
	# Command panel starts hidden
	command_panel.visible = false
	
	# Style the command panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.15, 0.1, 0.9)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.8, 0.6, 0.3)
	command_panel.add_theme_stylebox_override("panel", style_box)

func setup_minimap():
	if not minimap:
		return
	
	# Style the minimap
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.8, 0.6, 0.3)
	minimap.add_theme_stylebox_override("panel", style_box)
	
	# Add minimap title
	var title = Label.new()
	title.text = "MINIMAP"
	title.position = Vector2(10, -20)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	title.add_theme_font_size_override("font_size", 12)
	minimap.add_child(title)
	
	# Create minimap display
	create_minimap_display()

func create_minimap_display():
	if not minimap_viewport:
		return
	
	# Create a simple map representation
	var map_display = Control.new()
	map_display.name = "MapDisplay"
	map_display.custom_minimum_size = Vector2(140, 140)
	minimap_viewport.add_child(map_display)
	
	# Update minimap periodically
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(_update_minimap)
	timer.autostart = true
	add_child(timer)

func _update_minimap():
	if not game_manager or not minimap_viewport:
		return
	
	var map_display = minimap_viewport.get_node_or_null("MapDisplay")
	if not map_display:
		return
	
	# Clear previous indicators
	for child in map_display.get_children():
		child.queue_free()
	
	# Map scale (world coordinates to minimap coordinates)
	var map_scale = 0.1
	var map_size = Vector2(140, 140)
	
	# Draw units
	for unit in game_manager.all_units:
		var minimap_pos = unit.global_position * map_scale
		minimap_pos = minimap_pos.clamp(Vector2.ZERO, map_size)
		
		var unit_dot = ColorRect.new()
		unit_dot.size = Vector2(3, 3)
		unit_dot.position = minimap_pos - Vector2(1.5, 1.5)
		
		# Color based on faction
		if unit.faction == game_manager.player_faction:
			unit_dot.color = Color(0.2, 0.8, 0.2)  # Green for player
		else:
			unit_dot.color = Color(0.8, 0.2, 0.2)  # Red for enemy
		
		map_display.add_child(unit_dot)
	
	# Draw buildings  
	for building in game_manager.all_buildings:
		var minimap_pos = building.global_position * map_scale
		minimap_pos = minimap_pos.clamp(Vector2.ZERO, map_size)
		
		var building_dot = ColorRect.new()
		building_dot.size = Vector2(4, 4)
		building_dot.position = minimap_pos - Vector2(2, 2)
		
		# Color based on faction
		if building.faction == game_manager.player_faction:
			building_dot.color = Color(0.2, 0.2, 0.8)  # Blue for player buildings
		else:
			building_dot.color = Color(0.8, 0.4, 0.2)  # Orange for enemy buildings
		
		map_display.add_child(building_dot)

func setup_production_queue():
	if not production_queue_panel:
		return
	
	# Style the production queue panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.1, 0.05, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.8, 0.6, 0.3)
	production_queue_panel.add_theme_stylebox_override("panel", style_box)
	
	# Update queue periodically
	var queue_timer = Timer.new()
	queue_timer.wait_time = 0.5
	queue_timer.timeout.connect(_update_production_queue)
	queue_timer.autostart = true
	add_child(queue_timer)

func _update_production_queue():
	if not game_manager or not queue_items_container:
		return
	
	# Clear previous queue items
	for child in queue_items_container.get_children():
		child.queue_free()
	
	var has_any_production = false
	
	# Check all buildings for production
	for building in game_manager.all_buildings:
		if building.faction == game_manager.player_faction and building.has_method("get_building_info"):
			var building_info = building.get_building_info()
			
			# Show current production
			if building_info.current_production != "":
				has_any_production = true
				create_production_item(building, building_info.current_production, true)
			
			# Show queue
			if building.has_method("get_production_queue_info"):
				var queue_info = building.get_production_queue_info()
				for i in range(queue_info.size()):
					has_any_production = true
					create_production_item(building, queue_info[i].type, false, i + 1)
	
	# Show/hide panel based on whether there's any production
	production_queue_panel.visible = has_any_production
	
	if not has_any_production:
		var no_production_label = Label.new()
		no_production_label.text = "No units in production"
		no_production_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_production_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		queue_items_container.add_child(no_production_label)

func create_production_item(building, unit_type: String, is_current: bool, queue_position: int = 0):
	var item_container = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(230, 30)
	
	# Building icon
	var building_icon = ColorRect.new()
	building_icon.custom_minimum_size = Vector2(20, 20)
	building_icon.color = Color(0.2, 0.4, 0.8) if building.building_name == "Barracks" else Color(0.8, 0.6, 0.2)
	item_container.add_child(building_icon)
	
	# Unit icon  
	var unit_icon = ColorRect.new()
	unit_icon.custom_minimum_size = Vector2(20, 20)
	unit_icon.color = get_unit_color(unit_type)
	item_container.add_child(unit_icon)
	
	# Info container
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.add_child(info_container)
	
	# Unit name and building
	var name_label = Label.new()
	if is_current:
		name_label.text = "⚙️ %s - %s" % [unit_type, building.building_name]
		name_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	else:
		name_label.text = "⏳ %s - %s (#%d)" % [unit_type, building.building_name, queue_position]
		name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
	
	name_label.add_theme_font_size_override("font_size", 10)
	info_container.add_child(name_label)
	
	# Progress/Time info
	var progress_label = Label.new()
	if is_current and building.has_method("get_production_progress"):
		var progress_info = building.get_production_progress()
		var percentage = int(progress_info.percentage)
		var remaining_time = int(progress_info.remaining_time)
		progress_label.text = "%d%% - %ds left" % [percentage, remaining_time]
		progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		# Add progress bar
		var progress_bar = ProgressBar.new()
		progress_bar.max_value = 100
		progress_bar.value = percentage
		progress_bar.custom_minimum_size = Vector2(150, 8)
		info_container.add_child(progress_bar)
	else:
		progress_label.text = "Waiting in queue..."
		progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
	progress_label.add_theme_font_size_override("font_size", 8)
	info_container.add_child(progress_label)
	
	queue_items_container.add_child(item_container)

func create_unit_icons_display():
	if not unit_icons_container or not game_manager:
		return
	
	for unit in game_manager.get_selected_units():
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.color = get_unit_color(unit.unit_name)
		
		# Add health indicator
		var health_percentage = unit.current_health / unit.max_health
		if health_percentage < 0.3:
			icon.modulate = Color(1, 0.3, 0.3)  # Red tint for low health
		elif health_percentage < 0.6:
			icon.modulate = Color(1, 1, 0.3)   # Yellow tint for medium health
		
		# Add tooltip with unit info
		var tooltip = "%s\nHealth: %d/%d\nStatus: %s" % [
			unit.unit_name,
			unit.current_health,
			unit.max_health,
			"Moving" if unit.is_moving else ("Attacking" if unit.is_attacking else "Idle")
		]
		icon.tooltip_text = tooltip
		
		# Make clickable for individual selection
		icon.mouse_entered.connect(_on_unit_icon_hover.bind(unit))
		icon.gui_input.connect(_on_unit_icon_clicked.bind(unit))
		
		unit_icons_container.add_child(icon)

func _on_unit_icon_hover(unit):
	# Could add hover effect here
	pass

func _on_unit_icon_clicked(event: InputEvent, unit):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Select only this unit
			game_manager.deselect_all_units()
			game_manager.select_unit(unit)

func select_building(building):
	selected_building = building
	show_production_options()

func deselect_building():
	selected_building = null
	hide_production_options()

func show_production_options():
	if not selected_building or not production_panel or not production_button_container:
		return
	
	# Show the production panel
	production_panel.visible = true
	
	# Clear existing buttons
	for child in production_button_container.get_children():
		child.queue_free()
	
	# Show building info
	if selected_building.has_method("can_produce_unit"):
		var building_info = selected_building.get_building_info()
		selection_label.text = "🏭 %s\n❤️ Health: %d/%d" % [
			building_info.name,
			building_info.health,
			building_info.max_health
		]
		
		if building_info.is_constructed and selected_building.has_method("get_producible_units"):
			var units = selected_building.get_producible_units()
			
			for unit_type in units.keys():
				var unit_data = units[unit_type]
				
				# Create container for icon + text layout
				var button_container = HBoxContainer.new()
				production_button_container.add_child(button_container)
				
				# Create unit icon
				var icon = ColorRect.new()
				icon.custom_minimum_size = Vector2(32, 32)
				icon.color = get_unit_color(unit_type)
				button_container.add_child(icon)
				
				# Create info container
				var info_container = VBoxContainer.new()
				button_container.add_child(info_container)
				
				# Create button
				var button = Button.new()
				button.text = unit_type
				button.custom_minimum_size = Vector2(100, 25)
				button.pressed.connect(_on_production_button_pressed.bind(unit_type))
				info_container.add_child(button)
				
				# Create cost label
				var cost_label = Label.new()
				cost_label.text = "Cost: %d spice" % unit_data.cost
				cost_label.add_theme_font_size_override("font_size", 10)
				info_container.add_child(cost_label)
				
				# Create description label
				var desc_label = Label.new()
				desc_label.text = unit_data.get("description", "")
				desc_label.add_theme_font_size_override("font_size", 8)
				desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				info_container.add_child(desc_label)
				
				# Disable if not enough spice
				if game_manager and game_manager.get_player_spice() < unit_data.cost:
					button.disabled = true
					button.text += " (No Spice)"
					icon.modulate = Color(0.5, 0.5, 0.5)

func get_unit_color(unit_type: String) -> Color:
	match unit_type:
		"Infantry":
			return Color(0.2, 0.4, 0.8)  # Blue
		"Tank":
			return Color(0.6, 0.6, 0.6)  # Gray  
		"Harvester":
			return Color(0.8, 0.6, 0.2)  # Orange
		_:
			return Color(0.5, 0.5, 0.5)  # Default gray

func hide_production_options():
	if production_panel:
		production_panel.visible = false

func update_command_panel():
	if not command_button_container or not game_manager:
		return
	
	# Clear existing buttons
	for child in command_button_container.get_children():
		child.queue_free()
	
	var selected_units = game_manager.get_selected_units()
	
	if selected_units.size() == 0:
		command_panel.visible = false
		return
	
	command_panel.visible = true
	
	# Add unit commands
	add_command_button("MOVE", "Move units to target location", _on_move_command)
	add_command_button("ATTACK", "Attack enemy units", _on_attack_command)
	add_command_button("GUARD", "Guard current position", _on_guard_command)
	add_command_button("STOP", "Stop all current actions", _on_stop_command)
	
	# Special commands for specific unit types
	if selected_units[0] is Harvester:
		add_command_button("HARVEST", "Find spice to harvest", _on_harvest_command)

func add_command_button(text: String, tooltip: String, callback: Callable):
	var button = Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(70, 50)
	button.pressed.connect(callback)
	
	# Style the button
	button.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	button.add_theme_font_size_override("font_size", 10)
	
	command_button_container.add_child(button)

# Command callbacks
func _on_move_command():
	pass

func _on_attack_command():
	pass

func _on_guard_command():
	if game_manager:
		for unit in game_manager.get_selected_units():
			unit.movement_path.clear()
			unit.is_moving = false

func _on_stop_command():
	if game_manager:
		for unit in game_manager.get_selected_units():
			unit.movement_path.clear()
			unit.is_moving = false
			unit.attack_target = null

func _on_harvest_command():
	if game_manager:
		for unit in game_manager.get_selected_units():
			if unit is Harvester:
				unit.harvester_state = GlobalEnums.HarvesterState.IDLE
				unit.find_spice_deposit()

func _on_production_button_pressed(unit_type: String):
	if selected_building and selected_building.has_method("produce_unit"):
		var success = selected_building.produce_unit(unit_type)
		if success:
			pass
			# Refresh the production options to update spice costs
			show_production_options()
