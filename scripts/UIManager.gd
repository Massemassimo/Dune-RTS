extends Control
class_name UIManager

# UI References
@onready var spice_label: Label = $ResourceDisplay/SpiceLabel
@onready var selection_label: Label = $SelectionInfo/SelectionPanel/SelectionLabel

# Game references
var game_manager: GameManager

func _ready():
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.spice_changed.connect(_on_spice_changed)
		game_manager.unit_selected.connect(_on_unit_selected)
		game_manager.unit_deselected.connect(_on_unit_deselected)

func _on_spice_changed(new_amount: int):
	if spice_label:
		spice_label.text = "Spice: %d" % new_amount

func _on_unit_selected(unit: Unit):
	update_selection_display()

func _on_unit_deselected(unit: Unit):
	update_selection_display()

func update_selection_display():
	if not game_manager or not selection_label:
		return
	
	var selected_count = game_manager.selected_units.size()
	
	if selected_count == 0:
		selection_label.text = "No selection"
	elif selected_count == 1:
		var unit = game_manager.selected_units[0]
		selection_label.text = "%s\nHealth: %d/%d" % [unit.unit_name, unit.current_health, unit.max_health]
	else:
		selection_label.text = "%d units selected" % selected_count