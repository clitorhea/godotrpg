extends CharacterBody2D


const SPEED = 300.0
#const JUMP_VELOCITY = -400.0

func _getInput(){
	
}


func _physics_process(delta):
	# This gets a direction vector from the input actions.
	# It returns a vector like (1, 0) for right, (-1, 0) for left, (0, -1) for up, etc.
	# and also handles diagonals like (0.707, 0.707).
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Set the velocity.	
	velocity = direction * speed

	# This is the built-in function that moves the character.
	# It handles collisions with the TileMap and other bodies automatically.
	move_and_slide()
