extends Unit
class_name Harvester

@export var spice_capacity: int = 100
@export var collection_rate: int = 5
@export var collection_range: float = 50.0

var current_spice: int = 0
var target_spice_deposit = null
var target_refinery = null
var harvester_state: GlobalEnums.HarvesterState = GlobalEnums.HarvesterState.IDLE
var collection_timer: float = 0.0
var collection_interval: float = 1.0

func _ready():
	super()
	unit_name = "Harvester"
	max_health = 120.0
	current_health = max_health
	move_speed = 80.0
	attack_damage = 0.0
	attack_range = 0.0
	cost = 300
	
	setup_harvester_visuals()

func setup_harvester_visuals():
	if sprite:
		sprite.queue_free()
	
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(40, 30, false, Image.FORMAT_RGB8)
	
	var color: Color
	match faction:
		GlobalEnums.Faction.ATREIDES:
			color = Color(0.2, 0.4, 0.8)
		GlobalEnums.Faction.HARKONNEN:
			color = Color(0.8, 0.2, 0.2)
		GlobalEnums.Faction.ORDOS:
			color = Color(0.2, 0.8, 0.2)
		_:
			color = Color.GRAY
	
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func _process(delta):
	super(delta)
	handle_harvester_behavior(delta)

func handle_harvester_behavior(delta):
	match harvester_state:
		GlobalEnums.HarvesterState.IDLE:
			find_spice_deposit()
		GlobalEnums.HarvesterState.COLLECTING_SPICE:
			handle_spice_collection(delta)

func handle_spice_collection(delta):
	if not target_spice_deposit or not is_instance_valid(target_spice_deposit):
		harvester_state = GlobalEnums.HarvesterState.IDLE
		return
	
	collection_timer += delta
	if collection_timer >= collection_interval:
		collection_timer = 0.0
		var collected = target_spice_deposit.collect_spice(collection_rate)
		current_spice += collected
		print("%s collected %d spice" % [unit_name, collected])

func find_spice_deposit():
	var spice_deposits = get_tree().get_nodes_in_group("spice_deposits")
	var nearest_deposit = null
	var nearest_distance: float = INF
	
	for deposit in spice_deposits:
		if deposit.remaining_spice > 0:
			var distance = global_position.distance_to(deposit.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_deposit = deposit
	
	if nearest_deposit:
		target_spice_deposit = nearest_deposit
		move_to(target_spice_deposit.global_position)
		harvester_state = GlobalEnums.HarvesterState.COLLECTING_SPICE

func attack_unit(target):
	pass

func perform_attack():
	pass