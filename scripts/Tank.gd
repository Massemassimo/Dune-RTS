extends Unit
class_name Tank

@export var tank_type: String = "Light"

func _ready():
	super()
	unit_name = "Tank"
	max_health = 150.0
	current_health = max_health
	move_speed = 120.0
	attack_damage = 35.0
	attack_range = 200.0
	armor = 2.0
	cost = 400
	attack_cooldown = 2.0
	
	setup_tank_visuals()

func setup_tank_visuals():
	if sprite:
		sprite.queue_free()
	
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(36, 24, false, Image.FORMAT_RGB8)
	
	var color: Color
	match faction:
		GlobalEnums.Faction.ATREIDES:
			color = Color(0.3, 0.5, 0.9)
		GlobalEnums.Faction.HARKONNEN:
			color = Color(0.9, 0.3, 0.3)
		GlobalEnums.Faction.ORDOS:
			color = Color(0.3, 0.9, 0.3)
		_:
			color = Color.GRAY
	
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func perform_attack():
	if not attack_target or not is_instance_valid(attack_target):
		return
	
	super()
	print("%s attacks %s" % [unit_name, attack_target.unit_name])