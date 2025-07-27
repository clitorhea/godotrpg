extends CharacterBody2D

@export var speed = 400

@onready var animation_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D

var state = MOVE
var last_direction = Vector2(0, 1)

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
	animation_player.play("attack")
	
func update_animation():
	if velocity == Vector2.ZERO:
		sprite.play("idle")
	else:
		sprite.play("walking")
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true
			
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		state = MOVE
