@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("LLM", "LLM", preload("llm.gd"), preload("llm_icon.png"))
	pass


func _exit_tree() -> void:
	remove_custom_type("LLM")
	pass
