extends "res://scripts/Unit.gd"
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
	var image = Image.create(36, 24, false, Image.FORMAT_RGBA8)
	var primary_color = get_faction_color()
	var dark_color = primary_color.darkened(0.5)
	var light_color = primary_color.lightened(0.2)
	var metal_color = Color(0.6, 0.6, 0.6)
	create_tank_texture(image, primary_color, dark_color, light_color, metal_color)
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func create_tank_texture(image: Image, primary: Color, dark: Color, light: Color, accent: Color):
	# Create tank-specific visual (with turret and tracks)
	# Fill background
	image.fill(Color.TRANSPARENT)
	
	# Draw tank body (main hull)
	for y in range(6, 18):
		for x in range(4, 32):
			var edge_dist = min(min(x-4, 32-x), min(y-6, 18-y))
			if edge_dist >= 0:
				if edge_dist < 1:
					image.set_pixel(x, y, dark)  # Border
				else:
					image.set_pixel(x, y, primary)  # Fill
	
	# Draw turret
	for y in range(8, 16):
		for x in range(12, 28):
			if (x-20)*(x-20) + (y-12)*(y-12) < 25:  # Circular turret
				image.set_pixel(x, y, primary.darkened(0.2))
	
	# Draw cannon
	for y in range(11, 13):
		for x in range(28, 34):
			image.set_pixel(x, y, dark)
	
	# Add tracks using accent color
	for y in range(4, 6):  # Top track
		for x in range(4, 32):
			image.set_pixel(x, y, accent)
	for y in range(18, 20):  # Bottom track  
		for x in range(4, 32):
			image.set_pixel(x, y, accent)

func perform_attack():
	if not attack_target or not is_instance_valid(attack_target):
		return
	
	super()
