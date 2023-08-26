extends Node3D

@export var CharacterScene: PackedScene
@export var height:= 15
@export var radius:= 20

func _ready():
	_on_timer_timeout()




func _on_timer_timeout():
	var character= CharacterScene.instantiate()
	character.position= Vector3(randf_range(-1, 1) * radius, height, randf_range(-1, 1) * radius)
	character.rotation_degrees= Vector3(0, randi() % 360, 0)
	$Characters.add_child(character)
