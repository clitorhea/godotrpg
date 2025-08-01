extends BaseCharacter

# Player-specific properties
@export var player_speed: float = 400.0

func setup_character() -> void:
	# Set player-specific values
	speed = player_speed
	current_state = State.MOVE

func _physics_process(delta: float) -> void:
	# Get player input
	input_direction = Input.get_vector("left", "right", "up", "down")
	
	# Handle attack input
	if Input.is_action_just_pressed("swing") and current_state == State.MOVE:
		start_attack()
	
	# Call parent physics process
	super._physics_process(delta)

func handle_movement(delta: float) -> void:
	# Player-specific movement handling if needed
	super.handle_movement(delta)
