@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("AdaptiveMusicPlayer", "AnimationPlayer", preload("res://addons/AMP/Nodes/AdaptiveMusicPlayer.gd"), preload("res://addons/AMP/icons/AMP_icon.png"))
	add_custom_type("AudioStemPlayer", "AudioStreamPlayer", preload("res://addons/AMP/Nodes/AudioStemPlayer.gd"), preload("res://addons/AMP/icons/ASP_icon.png"))

func _exit_tree() -> void:
	remove_custom_type("AdaptiveMusicPlayer")
	remove_custom_type("AudioStemPlayer")
	
