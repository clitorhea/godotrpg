extends BaseCharacter

# Enemy-specific properties
@export var detection_range = 170
@export var min_distance = 40

@onready var player: Node2D
@onready var knight: CharacterBody2D = %knight
@onready var woodblue: CharacterBody2D = $"."

# Enemy AI states
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK
}

# Enemy-specific variables
var enemy_state = EnemyState.IDLE
var patrol_points = []
var current_patrol_index = 0
var original_position: Vector2
var idle_timer = 0.0
var idle_duration = 0.0
var is_idle_type = false
var unique_seed: int

func setup_character() -> void:
	# Set enemy-specific values
	speed = 100
	health = 3
	attack_cooldown = 1.0
	current_state = State.IDLE
	
	add_to_group("enemies")
	original_position = global_position
	
	# Create unique seed for this enemy instance
	unique_seed = int(global_position.x * 1000 + global_position.y * 100 + randf() * 10000)
	var rng = RandomNumberGenerator.new()
	rng.seed = unique_seed
	
	setup_patrol_points(rng)
	
	# Find the player node
	player = get_node("../../knight")
	
	# Randomly decide if this enemy is idle type or patrol type using unique RNG
	is_idle_type = rng.randf() < 0.4  # 40% chance to be idle type
	
	if is_idle_type:
		enemy_state = EnemyState.IDLE
		set_random_idle_duration(rng)
	else:
		enemy_state = EnemyState.PATROL

func setup_patrol_points(rng: RandomNumberGenerator):
	patrol_points.append(original_position)
	
	# Create varied patrol patterns for each enemy
	var pattern_type = rng.randi() % 4
	match pattern_type:
		0:  # Square pattern
			patrol_points.append(original_position + Vector2(100, 0))
			patrol_points.append(original_position + Vector2(100, 100))
			patrol_points.append(original_position + Vector2(0, 100))
		1:  # Line pattern
			patrol_points.append(original_position + Vector2(150, 0))
			patrol_points.append(original_position + Vector2(-150, 0))
		2:  # Triangle pattern
			patrol_points.append(original_position + Vector2(80, -80))
			patrol_points.append(original_position + Vector2(-80, -80))
		3:  # L-shape pattern
			patrol_points.append(original_position + Vector2(120, 0))
			patrol_points.append(original_position + Vector2(120, 80))

func _physics_process(delta):
	# Update enemy AI state machine
	match enemy_state:
		EnemyState.IDLE:
			enemy_idle_state()
		EnemyState.PATROL:
			patrol_state()
		EnemyState.CHASE:
			chase_state()
		EnemyState.ATTACK:
			enemy_attack_state()
	
	# Call parent physics process for movement and base functionality
	super._physics_process(delta)

func patrol_state():
	var target = patrol_points[current_patrol_index]
	var direction = (target - global_position).normalized()
	
	# Use base character movement system
	set_movement_direction(direction * 0.5)
	current_state = State.MOVE
	
	if global_position.distance_to(target) < 10:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		
		# If this is an idle-type enemy, randomly return to idle
		if is_idle_type:
			var rng = RandomNumberGenerator.new()
			rng.seed = unique_seed + int(Time.get_ticks_msec())
			if rng.randf() < 0.3:  # 30% chance to return to idle
				enemy_state = EnemyState.IDLE
				set_random_idle_duration(rng)
				return
	
	check_for_player()

func enemy_idle_state():
	# Set movement to zero and use base character idle handling
	set_movement_direction(Vector2.ZERO)
	current_state = State.IDLE
	
	# Update idle timer
	idle_timer -= get_physics_process_delta_time()
	
	if idle_timer <= 0:
		# Randomly decide what to do next with unique seed
		var rng = RandomNumberGenerator.new()
		rng.seed = unique_seed + int(Time.get_ticks_msec())
		if rng.randf() < 0.7:  # 70% chance to stay idle
			set_random_idle_duration(rng)
		else:  # 30% chance to patrol briefly
			enemy_state = EnemyState.PATROL
	
	check_for_player()

func set_random_idle_duration(rng: RandomNumberGenerator = null):
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = unique_seed + int(Time.get_ticks_msec())
	
	idle_duration = rng.randf_range(1.5, 8.0)  # Varied idle times
	idle_timer = idle_duration

func chase_state():
	if not player:
		# Return to original behavior type
		if is_idle_type:
			enemy_state = EnemyState.IDLE
			set_random_idle_duration()
		else:
			enemy_state = EnemyState.PATROL
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_range * 1.5:
		# Return to original behavior type
		if is_idle_type:
			enemy_state = EnemyState.IDLE
			set_random_idle_duration()
		else:
			enemy_state = EnemyState.PATROL
		return
	
	if distance_to_player <= attack_range:
		enemy_state = EnemyState.ATTACK
		return
	
	# Only move if we're not too close to maintain minimum distance
	if distance_to_player > min_distance:
		var direction = (player.global_position - global_position).normalized()
		set_movement_direction(direction)
		current_state = State.MOVE
	else:
		# Stop moving when close enough
		set_movement_direction(Vector2.ZERO)
		current_state = State.IDLE

func enemy_attack_state():
	if not player:
		# Return to original behavior type
		if is_idle_type:
			enemy_state = EnemyState.IDLE
			set_random_idle_duration()
		else:
			enemy_state = EnemyState.PATROL
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > attack_range:
		enemy_state = EnemyState.CHASE
		return
	
	# Maintain distance while attacking
	if distance_to_player < min_distance:
		# Move away slightly if too close
		var direction = (global_position - player.global_position).normalized()
		set_movement_direction(direction * 0.3)
		current_state = State.MOVE
	else:
		set_movement_direction(Vector2.ZERO)
		current_state = State.IDLE
	
	# Attack with cooldown using base character system
	if attack_timer <= 0:
		start_attack()


func check_for_player():
	if not player:
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= detection_range:
		enemy_state = EnemyState.CHASE


# Override base character take_damage to handle enemy death
func take_damage(damage: int):
	super.take_damage(damage)
	if health <= 0:
		current_state = State.DEAD
