extends Building
class_name Barracks

# Unit production definitions
var producible_units = {
	"Infantry": {
		"cost": 60,
		"production_time": 3.0,
		"scene": "Infantry",
		"description": "Light infantry unit"
	},
	"Tank": {
		"cost": 300,
		"production_time": 8.0,
		"scene": "Tank", 
		"description": "Heavy armored unit"
	}
}

func _ready():
	super._ready()
	building_name = "Barracks"
	max_health = 400.0
	current_health = max_health
	armor = 5.0
	cost = 300
	power_required = 15
	construction_time = 6.0

func _process(delta):
	super._process(delta)

func can_produce_unit(unit_type: String) -> bool:
	return producible_units.has(unit_type)

func get_producible_units() -> Dictionary:
	return producible_units

func produce_unit(unit_type: String) -> bool:
	if not can_produce_unit(unit_type):
		print("Barracks cannot produce %s" % unit_type)
		return false
	
	var unit_data = producible_units[unit_type]
	return add_to_production_queue(unit_type, unit_data)

func get_barracks_info() -> Dictionary:
	var info = get_building_info()
	info["producible_units"] = producible_units.keys()
	return info