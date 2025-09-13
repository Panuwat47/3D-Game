extends CharacterBody3D

@export var move_speed: float = 6.0
@export var gravity: float = 24.0
@export var jump_force: float = 10.0
@export var stomp_bounce: float = 8.0
@export var rotate_speed: float = 10.0
@export var camera_rig_path: NodePath  # ชี้ไปที่ $"CameraRig"
@export var follow_smooth := 1.0       # ค่าความนุ่มในการตาม (ยิ่งมากยิ่งไว)
@export var camera_path: NodePath

@onready var cam: Camera3D = get_node(camera_path)
@onready var camera_rig: Node3D = get_node(camera_rig_path)
@onready var visual: Node3D = $pivot
@onready var anim_tree: AnimationTree = $"pivot/Root Scene/AnimationTree"
var sm: AnimationNodeStateMachinePlayback

var stomped_this_frame := false

func _ready() -> void:
	add_to_group("player")
	anim_tree.active = true
	sm = anim_tree.get("parameters/playback")

func _physics_process(delta: float) -> void:
	var input_vec := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	input_vec = input_vec.normalized()
	var move_dir := Vector3.ZERO
	if input_vec.length() > 0.0:
		var forward := cam.global_transform.basis.z
		var right := cam.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		# ผสมทิศ: ขวา/ซ้าย = x, หน้า/หลัง = y (ของ input_vec)
		move_dir = (right * input_vec.x + forward * input_vec.y).normalized()

	# ตั้งความเร็วแนวนอนให้วิ่งตามทิศของกล้อง
	var horiz_vel := move_dir * move_speed
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_force

	move_and_slide()

	# หมุนให้หันตามทิศ
	if move_dir.length() > 0.001:
		var target_yaw := atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 5.0 * delta)
		
		
	# เลือกสถานะอนิเมชัน
	_update_animation_state()

	# ชนศัตรูด้านข้าง/ล่าง -> ตาย
	if not stomped_this_frame:
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			var b := col.get_collider()
			if b and b.is_in_group("mob"):
				die()
				break
	stomped_this_frame = false

func _update_animation_state() -> void:
	if not is_on_floor():
		if velocity.y > 0.0:
			sm.travel("CharacterArmature|Jump")
		else:
			sm.travel("CharacterArmature|Jump_Land")
		return

	var speed_xz := Vector2(velocity.x, velocity.z).length()
	if speed_xz > 0.1:
		sm.travel("CharacterArmature|Run")
		# ถ้าต้องการปรับความเร็วเล่นอนิเมชันตามความเร็วเดิน:
		anim_tree.set("parameters/Run/TimeScale/scale", clamp(speed_xz / move_speed, 0.6, 1.4))
	else:
		sm.travel("CharacterArmature|Idle")

func _on_Foot_body_entered(body: Node) -> void:
	if body and body.is_in_group("mob") and velocity.y < 0.0:
		if body.has_method("defeat"):
			body.defeat()
		velocity.y = stomp_bounce
		stomped_this_frame = true

func die() -> void:
	print("Player died")
