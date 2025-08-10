extends Unit
class_name Infantry

func _ready():
	super._ready()
	unit_name = "Infantry"
	max_health = 50.0
	current_health = max_health
	move_speed = 80.0
	armor = 0.0
	attack_damage = 15.0
	attack_range = 120.0
	attack_cooldown = 1.5
	cost = 60

func create_unit_texture() -> ImageTexture:
	var texture = ImageTexture.new()
	var image = Image.create(20, 20, false, Image.FORMAT_RGB8)
	
	# Base infantry color based on faction
	var base_color: Color
	match faction:
		GlobalEnums.Faction.ATREIDES:
			base_color = Color.BLUE
		GlobalEnums.Faction.HARKONNEN:
			base_color = Color.RED
		GlobalEnums.Faction.ORDOS:
			base_color = Color.GREEN
		_:
			base_color = Color.GRAY
	
	# Fill base
	image.fill(base_color)
	
	# Add helmet detail (lighter color on top)
	var helmet_color = base_color.lightened(0.3)
	for y in range(2, 8):
		for x in range(6, 14):
			image.set_pixel(x, y, helmet_color)
	
	# Add weapon (darker vertical line on side)
	var weapon_color = base_color.darkened(0.4)
	for y in range(8, 18):
		image.set_pixel(16, y, weapon_color)
		image.set_pixel(17, y, weapon_color)
	
	texture.set_image(image)
	return texture

func get_unit_info() -> Dictionary:
	var info = super.get_unit_info()
	info["unit_type"] = "Infantry"
	return info