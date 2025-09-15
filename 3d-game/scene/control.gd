extends Control

func _ready() -> void:
	$death.play()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main.tscn")
