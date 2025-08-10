extends CanvasLayer
class_name UIManager

# UI References
@onready var spice_label: Label = $ResourceDisplay/SpiceLabel
@onready var selection_label: Label = $SelectionInfo/SelectionPanel/SelectionLabel
@onready var production_panel: VBoxContainer = $ProductionPanel
@onready var production_button_container: VBoxContainer = $ProductionPanel/ProductionButtons

# Game references
var game_manager
var selected_building

func _ready():
	setup_ui_styling()
	setup_production_panel()
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.spice_changed.connect(_on_spice_changed)
		game_manager.unit_selected.connect(_on_unit_selected)
		game_manager.unit_deselected.connect(_on_unit_deselected)

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
		spice_label.text = "🧿 Spice: %d" % new_amount

func _on_unit_selected(_unit):
	update_selection_display()

func _on_unit_deselected(_unit):
	update_selection_display()

func update_selection_display():
	if not game_manager or not selection_label:
		return
	
	var selected_count = game_manager.selected_units.size()
	
	if selected_count == 0:
		selection_label.text = "🔍 No Selection\n\nClick to select units\nRight-click to move"
	elif selected_count == 1:
		var unit = game_manager.selected_units[0]
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
		selection_label.text = "👥 %d units selected\n\nRight-click to move all" % selected_count

func setup_production_panel():
	if production_panel:
		production_panel.visible = false

func select_building(building):
	selected_building = building
	show_production_options()

func deselect_building():
	selected_building = null
	hide_production_options()

func show_production_options():
	if not selected_building or not production_panel or not production_button_container:
		return
	
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
				var button = Button.new()
				button.text = "%s (%d spice)" % [unit_type, unit_data.cost]
				button.pressed.connect(_on_production_button_pressed.bind(unit_type))
				
				# Disable if not enough spice
				if game_manager and game_manager.get_player_spice() < unit_data.cost:
					button.disabled = true
					button.text += " (Not enough spice)"
				
				production_button_container.add_child(button)
		
		production_panel.visible = true

func hide_production_options():
	if production_panel:
		production_panel.visible = false

func _on_production_button_pressed(unit_type: String):
	if selected_building and selected_building.has_method("produce_unit"):
		var success = selected_building.produce_unit(unit_type)
		if success:
			print("Started producing %s" % unit_type)
			# Refresh the production options to update spice costs
			show_production_options()
