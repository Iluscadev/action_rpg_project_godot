extends Node2D
	
const GrassEffect = preload("res://Scenes/World/GrassEffect.tscn")

func create_grass_effect():
	var grassEffect = GrassEffect.instance()
	var world = get_tree().current_scene
	world.add_child(grassEffect)
	grassEffect.global_position = global_position


func _on_Hurtbox_area_entered(_area):
	create_grass_effect()
	queue_free()
