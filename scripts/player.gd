extends CharacterBody2D

@export var speed = 350
@onready var sprite = $AnimatedSprite2D

var state = MOVE
var last_direction = Vector2(0, 1)

func _ready():
	# Connect the animation finished signal
	sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

enum {
	MOVE,
	ATTACK
}

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ATTACK:
			attack_state()

func move_state(_delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	move_and_slide()
	
	if input_direction != Vector2.ZERO:
		last_direction = input_direction
		
	update_animation()
	
	if Input.is_action_just_pressed("swing"):
		state = ATTACK

func attack_state():
	velocity = Vector2.ZERO
	
	# Set sprite flip and animation based on last direction
	set_attack_animation()

func set_attack_animation():
	# Determine attack direction based on last_direction
	if abs(last_direction.x) > abs(last_direction.y):
		# Horizontal attack - use right_attack and flip for left
		if last_direction.x > 0:
			sprite.flip_h = false
			sprite.play("right_attack")
		else:
			sprite.flip_h = true
			sprite.play("right_attack")
	else:
		# Vertical attack
		sprite.flip_h = false  # Reset flip for vertical attacks
		if last_direction.y > 0:
			sprite.play("down_attack")
		else:
			sprite.play("up_attack")

func update_animation():
	if velocity == Vector2.ZERO:
		sprite.play("idle")
	else:
		sprite.play("walking")
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true

# Connect this to your AnimatedSprite2D's animation_finished signal
func _on_animated_sprite_2d_animation_finished():
	var current_anim = sprite.animation
	
	# Check if it's an attack animation
	if current_anim.ends_with("_attack"):
		state = MOVE
