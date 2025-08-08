extends CanvasLayer
class_name UIManager

# UI References
@onready var spice_label: Label = $ResourceDisplay/SpiceLabel
@onready var selection_label: Label = $SelectionInfo/SelectionPanel/SelectionLabel

# Game references
var game_manager

func _ready():
	setup_ui_styling()
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
