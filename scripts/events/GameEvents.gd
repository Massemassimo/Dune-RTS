extends Node
class_name GameEvents

# Global Event Bus System
# Single Responsibility: Decouple systems through event messaging

# Singleton pattern
static var instance: GameEvents

# Game Events
signal unit_created(unit: Unit)
signal unit_destroyed(unit: Unit)
signal unit_damaged(unit: Unit, damage: int, attacker: Unit)
signal unit_healed(unit: Unit, amount: int)

signal building_created(building: Building)
signal building_destroyed(building: Building)
signal building_damaged(building: Building, damage: int, attacker: Unit)
signal building_completed(building: Building)

signal resource_collected(type: String, amount: int, faction: GlobalEnums.Faction)
signal resource_spent(type: String, amount: int, faction: GlobalEnums.Faction)

signal combat_started(attacker: Unit, target: Unit)
signal combat_ended(winner: Unit, loser: Unit)

signal game_victory(winner: GlobalEnums.Faction)
signal game_defeat(loser: GlobalEnums.Faction)

signal tech_researched(tech_name: String, faction: GlobalEnums.Faction)
signal ability_used(unit: Unit, ability_name: String)

# UI Events
signal ui_notification(message: String, type: String)
signal ui_alert(message: String, position: Vector2)

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	# Ensure singleton
	if instance != self:
		queue_free()
		return
	
	# Connect to game events for logging/debugging
	connect_debug_listeners()

func connect_debug_listeners():
	unit_created.connect(_on_unit_created)
	unit_destroyed.connect(_on_unit_destroyed)
	building_created.connect(_on_building_created)
	building_destroyed.connect(_on_building_destroyed)
	resource_collected.connect(_on_resource_collected)
	resource_spent.connect(_on_resource_spent)

func _on_unit_created(unit: Unit):
	print("[EVENT] Unit created: %s (%s)" % [unit.unit_name, unit.faction])

func _on_unit_destroyed(unit: Unit):
	print("[EVENT] Unit destroyed: %s (%s)" % [unit.unit_name, unit.faction])

func _on_building_created(building: Building):
	print("[EVENT] Building created: %s (%s)" % [building.building_name, building.faction])

func _on_building_destroyed(building: Building):
	print("[EVENT] Building destroyed: %s (%s)" % [building.building_name, building.faction])

func _on_resource_collected(type: String, amount: int, faction: GlobalEnums.Faction):
	print("[EVENT] Resource collected: %d %s (%s)" % [amount, type, faction])

func _on_resource_spent(type: String, amount: int, faction: GlobalEnums.Faction):
	print("[EVENT] Resource spent: %d %s (%s)" % [amount, type, faction])

# Static access methods
static func emit_unit_created(unit: Unit):
	if instance:
		instance.unit_created.emit(unit)

static func emit_unit_destroyed(unit: Unit):
	if instance:
		instance.unit_destroyed.emit(unit)

static func emit_building_created(building: Building):
	if instance:
		instance.building_created.emit(building)

static func emit_building_destroyed(building: Building):
	if instance:
		instance.building_destroyed.emit(building)

static func emit_resource_collected(type: String, amount: int, faction: GlobalEnums.Faction):
	if instance:
		instance.resource_collected.emit(type, amount, faction)

static func emit_resource_spent(type: String, amount: int, faction: GlobalEnums.Faction):
	if instance:
		instance.resource_spent.emit(type, amount, faction)

static func emit_ui_notification(message: String, type: String = "info"):
	if instance:
		instance.ui_notification.emit(message, type)

static func emit_ui_alert(message: String, position: Vector2 = Vector2.ZERO):
	if instance:
		instance.ui_alert.emit(message, position)