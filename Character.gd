extends RigidBody3D


@export var max_speed= 1.0
@export var push_force:= 3.0

@onready var ground_check = $GroundCheck
@onready var animation_feet = $AnimationPlayerFeet
@onready var animation_hands = $AnimationPlayerHands

@onready var character_detector = $CharacterDetector
@onready var ground_detector = $GroundDetector

@onready var stun_timer = $StunTimer
@onready var push_cooldown = $PushCooldown


enum State { FALLING, STUNNED, WALKING, IDLE }

var state
var target_velocity: Vector3= Vector3.ZERO

func _ready():
	randomize()
	new_state(State.FALLING)


func _physics_process(delta):
	if character_detector.is_colliding() and push_cooldown:
		push()
		return

	handle_state(delta)
	
func handle_state(delta: float):

	
	match state:
		State.STUNNED:
			turn(delta)
			return
		State.FALLING:
			if is_on_ground():
				new_state(State.WALKING)
				return
			if global_position.y < -50:
				queue_free()
				
		State.WALKING:
			if not is_on_ground():
				new_state(State.FALLING)
				return
				
			if delta_chance(25, delta):
				new_state(State.WALKING)
				return
			
			
			if target_velocity.normalized().dot(-global_transform.basis.z) < 0.95:
				if animation_feet.is_playing():
					animation_feet.play("RESET", 0.5)
				turn(delta)
			else:
				if not ground_detector.is_colliding() and delta_chance(30, delta):
					new_state(State.WALKING)

				apply_central_force(target_velocity.normalized() * 100 * delta)
				if not animation_feet.is_playing():
					animation_feet.play("Walk")
			
			
				
func new_state(next_state: State):
	var old_state= state
	
	state= next_state
	
	prints("New state", state)
	
	match state:
		State.WALKING:
			random_velocity()
			animation_hands.play("RESET")
		State.FALLING:
			animation_feet.play("RESET")
			animation_hands.play("Fall")
		State.STUNNED:
			animation_hands.play("Stun")
			animation_feet.play("RESET")
			if not stun_timer.is_stopped():
				stun_timer.stop()
			stun_timer.start()


func turn(delta: float):
	var torque= 50 * delta * target_velocity.normalized().dot(-global_transform.basis.x)
	apply_torque(Vector3(0, torque, 0))


func push():
	var victim= character_detector.get_collider()
	if victim.state == State.FALLING: return
	
	victim.stun(global_position)
	victim.apply_central_impulse((victim.global_position - global_position).normalized() * push_force)

	animation_hands.play("Push")
	push_cooldown.start()
	
func random_velocity():
	target_velocity= Vector3(randf_range(-1, 1) * max_speed, 0, randf_range(-1, 1) * max_speed)
	prints("New velocity", target_velocity)

func is_on_ground()-> bool:
	return ground_check.is_colliding()


func _on_push_cooldown_timeout():
	animation_hands.play("RESET")

func stun(origin: Vector3):
	target_velocity= (origin - global_position).normalized() * max_speed
	new_state(State.STUNNED)


func _on_stun_timer_timeout():
	new_state(State.WALKING)


static func delta_chance(chance: float, delta: float)-> bool:
	return randf() < chance / 100.0 * delta


