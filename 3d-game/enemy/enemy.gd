extends CharacterBody3D

@export var move_speed: float = 4.0
@export var change_dir_time_min: float = 1.0
@export var change_dir_time_max: float = 2.8
@export var rotate_speed: float = 10.0

@onready var visual: Node3D = $pivot
@onready var anim_tree: AnimationTree = $"pivot/Root Scene/AnimationTree"
var sm: AnimationNodeStateMachinePlayback

var dead := false
var current_dir: Vector3 = Vector3.ZERO
var change_timer: Timer

func _ready() -> void:
	add_to_group("mob")
	anim_tree.active = true
	sm = anim_tree.get("parameters/playback")
	randomize()
	change_timer = Timer.new()
	change_timer.one_shot = true
	add_child(change_timer)
	_pick_dir()
	_schedule_dir_change()

func _physics_process(_delta: float) -> void:
	if dead: 
		return
	sm.travel("CharacterArmature|Run")
	if change_timer.time_left <= 0.0:
		_pick_dir()
		_schedule_dir_change()

	if not _is_dir_free(current_dir):
		_pick_dir()

	velocity.x = current_dir.x * move_speed
	velocity.z = current_dir.z * move_speed
	velocity.y = 0.0
	move_and_slide()
	_update_facing()
	_check_hit_wall_and_kill()


func _update_facing() -> void: 
	var move_xz := Vector3(velocity.x, 0, velocity.z)
	if move_xz.length() > 0.05: 
		var target := visual.global_transform.origin + move_xz.normalized() 
		visual.look_at(target, Vector3.UP)
		visual.rotate_y(PI)

func _check_hit_wall_and_kill() -> void: 
	for i in range(get_slide_collision_count()): 
		var col := get_slide_collision(i) 
		var other := col.get_collider() 
		if other and other is Node and other.is_in_group("wall"): 
			queue_free() 
			return

func _schedule_dir_change() -> void:
	change_timer.start(randf_range(change_dir_time_min, change_dir_time_max))

func _pick_dir() -> void:
	# 4 ทิศบนระนาบ XZ
	var dirs = [
		Vector3(-1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 0, -1),
		Vector3(0, 0, 1)
	]
	dirs.shuffle()
	for d in dirs:
		if d != -current_dir and _is_dir_free(d):
			current_dir = d
			return
	current_dir = -current_dir

func _is_dir_free(d: Vector3) -> bool:
	if d == Vector3.ZERO:
		return false
	var motion := d.normalized() * 0.5
	return not test_move(global_transform, motion)

func defeat() -> void:
	if dead: return
	dead = true
	queue_free()
