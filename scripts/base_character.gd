extends CharacterBody2D
class_name BaseCharacter

# Common character properties
@export var speed: float = 250.0
@export var acceleration: float = 1000.0
@export var friction: float = 1000.0
@export var health: int = 3
@export var max_health: int = 3

# Cached node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement variables
var input_direction: Vector2
var last_direction: Vector2 = Vector2.DOWN
var current_animation: String = ""

# Attack variables
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown: float = 1.0

# State management
enum State { IDLE, MOVE, ATTACK, DEAD }
var current_state: State = State.IDLE

func _ready() -> void:
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
	setup_character()

# Virtual function to be overridden by child classes
func setup_character() -> void:
	pass

func _physics_process(delta: float) -> void:
	if health <= 0:
		current_state = State.DEAD
		handle_death(delta)
		return
	
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	
	# Handle state-specific logic
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.MOVE:
			handle_movement(delta)
		State.ATTACK:
			handle_attack(delta)
		State.DEAD:
			handle_death(delta)

# Basic movement functionality
func handle_movement(delta: float) -> void:
	# Apply acceleration/friction for smoother movement
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
		last_direction = input_direction
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	update_movement_animation()

# Handle idle state
func handle_idle(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	play_animation("idle")

# Handle attack state
func handle_attack(delta: float) -> void:
	# Slow down during attack but don't stop completely
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta * 2)
	move_and_slide()

# Handle death state
func handle_death(delta: float) -> void:
	velocity = Vector2.ZERO
	play_animation("dead")

# Start attack with cooldown check
func start_attack() -> bool:
	if is_attacking or attack_timer > 0:
		return false
	
	current_state = State.ATTACK
	is_attacking = true
	attack_timer = attack_cooldown
	play_attack_animation()
	return true

# Play attack animation based on direction
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
	
	if sprite:
		sprite.flip_h = flip_sprite
		play_animation(anim_name)

# Update movement animations
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

# Update sprite direction based on movement
func update_sprite_direction() -> void:
	if not sprite:
		return
		
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

# Safe animation playing
func play_animation(anim_name: String) -> void:
	if not sprite or not sprite.sprite_frames:
		return
		
	# Only play if different from current to avoid unnecessary calls
	if current_animation != anim_name and sprite.sprite_frames.has_animation(anim_name):
		current_animation = anim_name
		sprite.play(anim_name)

# Take damage with visual feedback
func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		health = 0
		current_state = State.DEAD
	else:
		# Visual damage feedback
		if sprite:
			sprite.modulate = Color.RED
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color.WHITE

# Heal character
func heal(amount: int) -> void:
	health = min(health + amount, max_health)

# Check if character is alive
func is_alive() -> bool:
	return health > 0

# Virtual function called when animation finishes
func _on_animation_finished() -> void:
	# Handle attack animation completion
	if is_attacking and sprite.animation.ends_with("_attack"):
		is_attacking = false
		current_state = State.MOVE
		current_animation = ""  # Force animation update

# Get character facing direction
func get_facing_direction() -> Vector2:
	return last_direction

# Set movement direction (for AI or external control)
func set_movement_direction(direction: Vector2) -> void:
	input_direction = direction