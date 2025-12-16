extends CharacterBody3D

@export var accel_linear: float = 20.0
@export var max_speed: float = 20.0
@export var damping_linear: float = 5.0

@export var mouse_sensitivity: float = 0.003
@export var roll_speed: float = 1.5  # radians/sec

@onready var target: Node3D = get_parent()

#var velocity: Vector3 = Vector3.ZERO
var orientation: Quaternion = Quaternion.IDENTITY

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var dx: float = -event.relative.x * mouse_sensitivity
		var dy: float = -event.relative.y * mouse_sensitivity

		# Get local camera axes from current orientation
		var local_basis := Basis(orientation)
		var local_up := local_basis.y      # camera’s current up vector
		var local_right := local_basis.x   # camera’s right vector

		# Yaw around camera’s local up
		var q_yaw := Quaternion(local_up, dx)

		# Pitch around camera’s local right
		var q_pitch := Quaternion(local_right, dy)

		# Apply yaw then pitch
		orientation = (q_yaw * q_pitch) * orientation
		orientation = orientation.normalized()


func _physics_process(delta: float) -> void:
	# --- Roll (local forward axis) ---
	var roll_input := 0.0
	if Input.is_action_pressed("RollCW"):
		roll_input += 1.0
	if Input.is_action_pressed("RollCCW"):
		roll_input -= 1.0

	if roll_input != 0.0:
		var forward := target.global_transform.basis.z
		var roll_axis := (forward - Vector3.UP * forward.dot(Vector3.UP)).normalized()
		var q_roll := Quaternion(roll_axis, -roll_input * roll_speed * delta)
		orientation = (orientation * q_roll).normalized()


	# --- Linear input (in local camera space) ---
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("jump") - Input.get_action_strength("MoveDown")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	# Transform local input into world-space using Basis(orientation) * vector
	var world_dir := Basis(orientation) * input_dir
	var target_vel := world_dir * max_speed

	velocity = velocity.lerp(target_vel, accel_linear * delta)
	if input_dir == Vector3.ZERO:
		velocity = velocity.lerp(Vector3.ZERO, damping_linear * delta)

	# Move in world space (Node3D.global_translate is the easy world-space move)
	global_translate(velocity * delta)

	# Apply rotation: build a Basis from the quaternion and orthonormalize (prevents drift)
	transform.basis = Basis(orientation).orthonormalized()
	move_and_slide()
	
func _on_tcube_body_entered(body):
	if body == self:
		get_node(^"WinText").show()
