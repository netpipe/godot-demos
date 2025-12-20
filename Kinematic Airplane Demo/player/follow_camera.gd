extends Camera3D

@export var min_distance := 0
@export var max_distance := 300.0
@export var follow_offset := Vector3(0, 0, 3)
@export var follow_smooth := 8.0
@export var rotation_smooth := 8.0
@export var gravity_align_strength := 1.5     # radians/sec
@export var enable_gravity_align := true
@export var collision_mask := 1

@onready var target: Node3D = get_parent()

var _velocity := Vector3.ZERO
var _current_distance := 3.0

func _ready() -> void:
	set_as_top_level(true)
	_current_distance = clamp(follow_offset.length(), min_distance, max_distance)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# --- Desired position relative to target ---
	var target_basis := target.global_transform.basis
	var target_origin := target.global_transform.origin
	var desired_pos := target_origin + target_basis * Vector3(0, 0, _current_distance)

	# --- Optional collision avoidance ---
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(target_origin, desired_pos)
	query.collision_mask = collision_mask
	var result := space.intersect_ray(query)
	
	if result:
		#desired_pos = result.position + (target_origin - result.position).normalized() * min_distance
		print ("test")
		#global_position = global_position.lerp(desired_pos, follow_smooth * delta)
	# --- Smooth positional follow ---
	else:
		global_position = global_position.lerp(desired_pos, follow_smooth * delta)

	# --- Base target orientation (follow target orientation fully) ---
	var target_quat := target_basis.get_rotation_quaternion()

	# --- Optional gravity realignment ---
	if enable_gravity_align:
		var current_basis: Basis = Basis(global_transform.basis)
		var current_up: Vector3 = current_basis.y
		var current_forward: Vector3 = current_basis.z
		var desired_up: Vector3 = Vector3.UP

		# Ensure explicit float typing for the dot and clamp results
		var up_dot: float = clamp(current_up.dot(desired_up), -1.0, 1.0)
		var angle: float = acos(up_dot)

		if angle > 0.001:
			var roll_sign: float = sign(current_right().dot(desired_up.cross(current_up)))
			var roll_angle: float = roll_sign * min(angle, gravity_align_strength * delta)
			var align_quat: Quaternion = Quaternion(current_forward.normalized(), -roll_angle)
			target_quat = align_quat * target_quat
			target_quat = target_quat.normalized()



	# --- Smoothly interpolate orientation ---
	var current_quat := global_transform.basis.get_rotation_quaternion()
	var new_quat := current_quat.slerp(target_quat, rotation_smooth * delta)

	global_transform.basis = Basis(new_quat).orthonormalized()
	#global_position.lerp(desired_pos, follow_smooth * delta)
func current_right() -> Vector3:
	return Basis(global_transform.basis).x
