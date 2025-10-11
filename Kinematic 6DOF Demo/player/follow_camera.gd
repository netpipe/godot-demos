extends Camera3D

@export var min_distance := 0.5
@export var max_distance := 3.0
@export var follow_offset := Vector3(0, 0, 3)
@export var follow_smooth := 8.0
@export var rotation_smooth := 8.0
@export var gravity_align_strength := 1.5   # radians/sec
@export var collision_mask := 1
@export var enable_gravity_align := false    # toggle on/off

@onready var target: Node3D = get_parent()

var _velocity := Vector3.ZERO
var _current_distance := 3.0

func _ready() -> void:
	set_as_top_level(true)
	_current_distance = clamp(follow_offset.length(), min_distance, max_distance)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# --- desired position relative to target ---
	var target_basis := target.global_transform.basis
	var target_origin := target.global_transform.origin
	var desired_pos := target_origin + target_basis * Vector3(0, 0, _current_distance)

	# --- optional collision avoidance ---
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(target_origin, desired_pos)
	query.collision_mask = collision_mask
	var result := space.intersect_ray(query)
	if result:
		desired_pos = result.position + (target_origin - result.position).normalized() * min_distance

	# --- smooth positional follow ---
	global_position = global_position.lerp(desired_pos, follow_smooth * delta)

	# --- base orientation (match target) ---
	var target_quat := target_basis.get_rotation_quaternion()

	# --- optional gravity realignment ---
	if enable_gravity_align:
		# Current up vector (world space)
		var current_up := (Basis(global_transform.basis)).y
		# Desired up (global up)
		var desired_up := Vector3.UP

		# Axis between current and desired up
		var axis := current_up.cross(desired_up)
		var angle := acos(clamp(current_up.dot(desired_up), -1.0, 1.0))

		if axis.length() > 0.0001 and angle > 0.0001:
			var align_quat := Quaternion(axis.normalized(), angle * gravity_align_strength * delta)
			target_quat = align_quat * target_quat
			target_quat = target_quat.normalized()

	# --- smooth rotation toward target_quat ---
	var current_quat := global_transform.basis.get_rotation_quaternion()
	var new_quat := current_quat.slerp(target_quat, rotation_smooth * delta)
	global_transform.basis = Basis(new_quat).orthonormalized()
