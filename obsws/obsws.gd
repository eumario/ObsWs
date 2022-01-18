tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("ObsWs","Node",preload("lib/obsws.gd"),preload("assets/obs.png"))


func _exit_tree() -> void:
	remove_custom_type("ObsWs")
