extends Node3D

@export var mob_scene: PackedScene 
@export var batch_count := 10 # จำนวนที่จะเกิดต่อหนึ่งครั้งของ Timer 
@export var speed_range := Vector2(150.0, 170.0) 

@onready var spawner: PathFollow3D = $enemyPath3D/PathFollow3D

func _ready() -> void:
	$player.create_player($PlayerMarker.position)
	$enemyTimer.start()
	$labeltimer.start()
	$"Kucuk-kurbaga-205928".play()

func _on_enemytimer_timeout() -> void: 
	var _mob = mob_scene.instantiate()
	for i in batch_count: 
		_spawn_one()


func _spawn_one() -> void: 
	if mob_scene == null: 
		push_warning("mob_scene is not set") 
		return

	# สุ่มตำแหน่งตามเส้น
	spawner.progress_ratio = randf()
	var spawn_pos: Vector3 = spawner.global_position

	# หาทิศ "ไปข้างหน้า" ของเส้น (ใน Godot forward คือ -Z)
	var forward: Vector3 = -spawner.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	# สุ่มมุมเบี่ยงซ้าย/ขวาเล็กน้อย
	var yaw_offset := randf_range(-PI/4.0, PI/4.0)
	var dir: Vector3 = (Basis(Vector3.UP, yaw_offset) * forward).normalized()

	# สร้าง mob หนึ่งตัว
	var m = mob_scene.instantiate()
	add_child(m)
	m.global_position = spawn_pos

	# หันหน้าไปทางที่วิ่ง
	# ถ้าโมเดลหันหน้า -Z ตามปกติ ใช้ look_at ได้
	m.look_at(spawn_pos + dir, Vector3.UP)
	# หรือใช้ yaw ตรงๆ:
	# m.rotation.y = atan2(dir.x, dir.z)

	# ตั้งความเร็ว (เลือกตามชนิดของ mob)
	var speed := randf_range(speed_range.x, speed_range.y)
	if m is RigidBody3D:
		m.linear_velocity = dir * speed
	elif m is CharacterBody3D:
		# ถ้าในสคริปต์ของ mob มีการอัปเดต velocity เอง คุณอาจต้องใส่ฟังก์ชัน set_move_dir()
		m.velocity.x = dir.x * speed
		m.velocity.z = dir.z * speed

func _on_player_hited() -> void:
	$enemyTimer.stop()


func _on_labeltimer_timeout() -> void:
	$Label3D.hide()
