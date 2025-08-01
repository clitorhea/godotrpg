extends CharacterBody2D

@export_group("Movement")
@export var speed: float = 120.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

@export_group("Combat")
@export var attack_damage: int = 1
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 0.5

@export_group("Stats")
@export var max_health: int = 10
@export var current_health: int = 10

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

enum State {
	MOVE,
	ATTACK,
	HURT,
	DEAD
}

var state := State.MOVE
var last_direction := Vector2(0, 1)
var attack_timer := 0.0

signal health_changed(new_health: int)
signal died

func _ready():
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	current_health = max_health

func _physics_process(delta):
	match state:
		State.MOVE:
			handle_movement(delta)
		State.ATTACK:
			handle_attack(delta)
		State.HURT:
			handle_hurt(delta)
		State.DEAD:
			handle_dead(delta)
	
	attack_timer = max(0.0, attack_timer - delta)

func handle_movement(delta):
	var input_direction := Input.get_vector("left", "right", "up", "down")
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
		last_direction = input_direction
		update_sprite_direction()
		sprite.play("walking")
	else:
		velocity = Vector2(0, 0)
		sprite.play("idle")
	
	move_and_slide()
	
	if Input.is_action_just_pressed("swing") and attack_timer <= 0:
		start_attack()

func handle_attack(delta):
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()

func handle_hurt(delta):
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()

func handle_dead(delta):
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()

func start_attack():
	state = State.ATTACK
	attack_timer = attack_cooldown
	set_attack_animation()
	
	await get_tree().process_frame
	check_for_enemy_hit()

func set_attack_animation():
	if abs(last_direction.x) > abs(last_direction.y):
		sprite.flip_h = last_direction.x < 0
		sprite.play("right_attack")
	else:
		sprite.flip_h = false
		if last_direction.y > 0:
			sprite.play("down_attack")
		else:
			sprite.play("up_attack")

func update_sprite_direction():
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func check_for_enemy_hit():
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= attack_range:
			var direction_to_enemy = (enemy.global_position - global_position).normalized()
			var dot_product = last_direction.dot(direction_to_enemy)
			
			if dot_product > 0.3:
				if enemy.has_method("take_damage"):
					enemy.take_damage(attack_damage)

func take_damage(damage: int):
	if state == State.DEAD:
		return
	
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		die()
	else:
		state = State.HURT
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		sprite.modulate = Color.WHITE
		if state == State.HURT:
			state = State.MOVE

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func die():
	state = State.DEAD
	sprite.play("idle")
	sprite.modulate = Color(0.5, 0.5, 0.5)
	died.emit()

func _on_sprite_animation_finished():
	if state == State.ATTACK:
		state = State.MOVE
