extends CharacterBody3D

@export var min_flight_speed: float = 2.0
@export var max_flight_speed: float = 8.0
@export var turn_speed: float = 1.75
@export var pitch_speed: float = 0.5
@export var level_speed: float = 3.0
@export var throttle_delta: float = 30.0
@export var acceleration: float = 6.0
@export var roll_amount: float = 0.6  # how far to bank when turning

var forward_speed: float = 0.0
var target_speed: float = 0.0
var grounded: bool = false

var turn_input: float = 0.0
var pitch_input: float = 0.0

@onready var visual_mesh: Node3D = $Mesh  # the visible airplane/cube mesh

func _physics_process(delta: float) -> void:
	_get_input(delta)

	# --- Rotation (basis drives actual movement) ---
	basis = basis.rotated(basis.x, pitch_input * pitch_speed * delta)      # pitch
	basis = basis.rotated(Vector3.UP, turn_input * turn_speed * delta)     # yaw
	basis = basis.orthonormalized()

	# --- Visual roll (bank) effect ---
	#if is_instance_valid(visual_mesh):
	var target_roll = turn_input * roll_amount
	rotation.z = lerp(rotation.z, target_roll, level_speed * delta)

	# --- Speed and movement ---
	forward_speed = lerp(forward_speed, target_speed, acceleration * delta)
	velocity = -basis.z * forward_speed

	# Simple ground check
	if is_on_floor():
		velocity.y -= 1.0
		grounded = true
	else:
		grounded = false

	move_and_slide()

func _get_input(delta: float) -> void:
	# --- Throttle ---
	if Input.is_action_pressed("move_back"):
		target_speed = min(forward_speed + throttle_delta * delta, max_flight_speed)
	if Input.is_action_pressed("move_forward"):
		var limit = min_flight_speed * float(!grounded)
		target_speed = max(forward_speed - throttle_delta * delta, limit)

	# --- Turn (Yaw) ---
	turn_input = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")

	# --- Pitch ---
	pitch_input = 0.0
	if not grounded:
		pitch_input += Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
		
func _on_tcube_body_entered(body):
	if body == self:
		get_node(^"WinText").show()
