extends Building
class_name Refinery

# Refinery-specific properties
@export var processing_capacity: int = 1000
@export var processing_rate: int = 50

# Refinery state
var stored_spice: int = 0

func _ready():
	super._ready()
	building_name = "Refinery"
	max_health = 300.0
	current_health = max_health
	armor = 3.0
	cost = 400
	power_required = 20
	construction_time = 8.0

func _process(delta):
	super._process(delta)

func process_spice(raw_spice: int) -> int:
	var processed = min(raw_spice, processing_rate)
	stored_spice += processed
	
	# Auto-transfer to game manager resources
	if stored_spice >= processing_rate:
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			game_manager.add_spice(stored_spice)
			stored_spice = 0
	
	return processed

func can_produce_unit(_unit_type: String) -> bool:
	# Refineries don't produce units
	return false

func get_refinery_info() -> Dictionary:
	var info = get_building_info()
	info["stored_spice"] = stored_spice
	info["processing_capacity"] = processing_capacity
	return info
