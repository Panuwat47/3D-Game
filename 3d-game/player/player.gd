extends CharacterBody3D

@export var move_speed: float = 6.0
@export var gravity: float = 24.0
@export var jump_force: float = 10.0
@export var stomp_bounce: float = 8.0
@export var rotate_speed: float = 10.0

@onready var score_label: Label3D = %Label3D
@onready var visual: Node3D = $pivot
@onready var anim_tree: AnimationTree = $"pivot/Root Scene/AnimationTree"
var sm: AnimationNodeStateMachinePlayback
var stomped_this_frame := false
var score_value: int = 0 


func _ready() -> void:
	add_to_group("player")
	anim_tree.active = true
	sm = anim_tree.get("parameters/playback")
	_update_score_label()

func create_player(point):
	position = point
	show()

func _physics_process(delta: float) -> void:
	var input_dir := Vector3(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		0,
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()

	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_force

	move_and_slide()

	# หันหน้าตามทิศที่กำลังเดิน
	var move_xz := Vector3(velocity.x, 0, velocity.z)
	if move_xz.length() > 0.05:
		var target_yaw := atan2(move_xz.x, move_xz.z)
		# ถ้าโมเดลของคุณหันเริ่มต้นไปทาง -Z อยู่แล้ว ให้บวก PI ชดเชย:
		#target_yaw += PI
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, rotate_speed * delta)
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
		anim_tree.set("parameters/CharacterArmature|Run/TimeScale/scale", clamp(speed_xz / move_speed, 0.6, 1.4))
	else:
		sm.travel("CharacterArmature|Idle")

func _on_Foot_body_entered(body: Node) -> void:
	if body and body.is_in_group("mob") and velocity.y < 0.0:
		if body.has_method("defeat"):
			body.defeat()
		velocity.y = stomp_bounce
		stomped_this_frame = true
		add_score(1)

func die() -> void:
	get_tree().change_scene_to_file("res://scene/control.tscn")
	queue_free()
	$"../enemyTimer".stop()
	

func add_score(amount: int) -> void: 
	score_value += amount 
	_update_score_label()
	
func _update_score_label() -> void: 
	if is_instance_valid(score_label): 
		score_label.text = "Score: %d" % score_value
