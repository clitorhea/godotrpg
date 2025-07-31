extends CharacterBody2D

# Export variables for easy tweaking in editor
@export var speed: float = 250.0
@export var acceleration: float = 1000.0
@export var friction: float = 1000.0

# Cached node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# State management
enum State { MOVE, ATTACK }
var current_state: State = State.MOVE

# Movement variables
var input_direction: Vector2
var last_direction: Vector2 = Vector2.DOWN
var current_animation: String = ""

# Attack state management
var is_attacking: bool = false

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	match current_state:
		State.MOVE:
			handle_movement(delta)
		State.ATTACK:
			handle_attack(delta)

func handle_movement(delta: float) -> void:
	# Get input once per frame
	input_direction = Input.get_vector("left", "right", "up", "down")
	
	# Apply acceleration/friction for smoother movement
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
		last_direction = input_direction
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	update_movement_animation()
	
	# Check for attack input
	if Input.is_action_just_pressed("swing") and not is_attacking:
		start_attack()

func handle_attack(delta: float) -> void:
	# Stop movement during attack
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()

func start_attack() -> void:
	current_state = State.ATTACK
	is_attacking = true
	play_attack_animation()

func play_attack_animation() -> void:
	var anim_name: String
	var flip_sprite: bool = false
	
	# Determine attack animation based on last direction
	if abs(last_direction.x) > abs(last_direction.y):
		# Horizontal attack
		anim_name = "right_attack"
		flip_sprite = last_direction.x < 0
	else:
		# Vertical attack
		anim_name = "up_attack" if last_direction.y < 0 else "down_attack"
		flip_sprite = false
	
	sprite.flip_h = flip_sprite
	play_animation(anim_name)

func update_movement_animation() -> void:
	var target_anim: String
	
	if velocity.length() < 10.0:  # Small threshold to avoid jitter
		target_anim = "idle"
	else:
		target_anim = "walking"
		# Update sprite flip for horizontal movement
		if input_direction.x > 0:
			sprite.flip_h = false
		elif input_direction.x < 0:
			sprite.flip_h = true
	
	play_animation(target_anim)

func play_animation(anim_name: String) -> void:
	# Only play if different from current to avoid unnecessary calls
	if current_animation != anim_name:
		current_animation = anim_name
		sprite.play(anim_name)

func _on_animation_finished() -> void:
	# Handle attack animation completion
	if is_attacking and sprite.animation.ends_with("_attack"):
		is_attacking = false
		current_state = State.MOVE
		current_animation = ""  # Force animation update
