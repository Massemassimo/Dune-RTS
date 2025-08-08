extends StaticBody2D
class_name SpiceDeposit

# Spice deposit properties
@export var max_spice: int = 500
@export var remaining_spice: int = 500
@export var regeneration_rate: int = 0  # Spice per second (0 = no regeneration)

# Visual components
var sprite: Sprite2D
var label: Label

# Regeneration timer
var regen_timer: float = 0.0
var initial_position: Vector2

func _ready():
	add_to_group("spice_deposits")
	remaining_spice = max_spice
	initial_position = global_position
	setup_visuals()
	setup_collision()
	
	# Enable transform notifications for position locking
	set_notify_transform(true)

func setup_visuals():
	# Create spice sprite (orange/brown deposit)
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(48, 48, false, Image.FORMAT_RGB8)
	image.fill(Color(0.8, 0.4, 0.1))  # Orange-brown color for spice
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)
	
	# Add label showing remaining spice
	label = Label.new()
	label.text = str(remaining_spice)
	label.position = Vector2(-15, -30)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)

func setup_collision():
	# Check if collision shape already exists (from scene)
	var existing_collision = get_node_or_null("CollisionShape2D")
	if not existing_collision:
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 25
		collision.shape = shape
		add_child(collision)
	
	collision_layer = 8  # Spice layer
	collision_mask = 0   # Spice doesn't collide with anything

func _process(delta):
	handle_regeneration(delta)
	update_visuals()


func handle_regeneration(delta):
	if regeneration_rate > 0 and remaining_spice < max_spice:
		regen_timer += delta
		if regen_timer >= 1.0:  # Regenerate every second
			regen_timer = 0.0
			remaining_spice = min(remaining_spice + regeneration_rate, max_spice)

func collect_spice(amount: int) -> int:
	var collected = min(amount, remaining_spice)
	remaining_spice -= collected
	
	if remaining_spice <= 0:
		deplete_deposit()
	
	return collected

func deplete_deposit():
	print("Spice deposit depleted")
	# Could add depletion effects here
	
	# For now, just hide the deposit
	visible = false
	# Could queue_free() to remove completely, or keep for potential regeneration

func update_visuals():
	if label:
		label.text = str(remaining_spice)
	
	if sprite:
		# Fade sprite as spice depletes
		var alpha = float(remaining_spice) / float(max_spice)
		sprite.modulate = Color(1.0, 1.0, 1.0, max(alpha, 0.3))

func get_deposit_info() -> Dictionary:
	return {
		"remaining_spice": remaining_spice,
		"max_spice": max_spice,
		"position": global_position,
		"regeneration_rate": regeneration_rate
	}
